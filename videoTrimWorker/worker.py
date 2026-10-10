"""Video Trim Worker for PictuRAS.

Consumes tasks from video_trim_queue, downloads the input MP4 from media storage,
performs frame-accurate trim via FFmpeg (H.264 / AAC), uploads the trimmed video,
and publishes the completion result to video_results_queue.
"""

import argparse
import json
import os
import re
import subprocess
import tempfile
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path

import pika
import requests

EXCHANGE = "picturas"
QUEUE = "video_trim_queue"
RESULTS_QUEUE = "video_results_queue"
PROCEDURE = "video_trim"
OBJECT_ID = re.compile(r"^[0-9a-fA-F]{24}$")


def process_trim_task(channel, message):
    if message.get("procedure") != PROCEDURE or not isinstance(message.get("messageId"), str):
        raise ValueError("Invalid video task envelope")

    parameters = message.get("parameters") or {}
    owner_id = parameters.get("ownerId")
    project_id = parameters.get("projectId")
    video_id = parameters.get("videoId")
    new_video_id = parameters.get("newVideoId")
    new_video_name = parameters.get("newVideoName")
    start_time = float(parameters.get("startTime", 0.0))
    end_time = float(parameters.get("endTime", 0.0))
    caller_id = parameters.get("callerId")
    project_version = parameters.get("projectVersion")

    for id_val in (owner_id, project_id, video_id, new_video_id):
        if not (isinstance(id_val, str) and OBJECT_ID.fullmatch(id_val)):
            raise ValueError(f"Invalid identifier: {id_val}")

    if not isinstance(new_video_name, str) or not new_video_name.strip():
        raise ValueError("Invalid new video name")

    if start_time < 0 or end_time <= start_time or (end_time - start_time) < 1.0:
        raise ValueError(f"Invalid time bounds: start={start_time}, end={end_time}")

    secret = os.environ["INTERNAL_VIDEO_KEY"]
    storage = os.getenv("MEDIA_STORAGE_URL", "http://img_storage:11000").rstrip("/")

    # 1. Obter presigned URL interna para download do vídeo original
    route = f"{storage}/video/{owner_id}/{project_id}/{video_id}/url"
    signed = requests.get(route, headers={"X-Internal-Video-Key": secret}, timeout=15)
    signed.raise_for_status()
    source_url = signed.json()["url"]

    with tempfile.TemporaryDirectory(prefix="picturas-video-trim-") as directory:
        destination = Path(directory) / "input.mp4"
        output_file = Path(directory) / "output.mp4"

        # 2. Descarregar o vídeo de entrada
        with requests.get(source_url, stream=True, timeout=(15, 300)) as response:
            response.raise_for_status()
            with destination.open("wb") as out:
                for chunk in response.iter_content(chunk_size=1024 * 1024):
                    if chunk:
                        out.write(chunk)

        # 3. Executar o recorte usando FFmpeg
        cmd = [
            "ffmpeg", "-y",
            "-ss", str(start_time),
            "-to", str(end_time),
            "-i", str(destination),
            "-c:v", "libx264",
            "-c:a", "aac",
            "-movflags", "+faststart",
            str(output_file)
        ]
        proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if proc.returncode != 0:
            raise RuntimeError(f"FFmpeg trim failed: {proc.stderr[-500:]}")

        output_size = output_file.stat().st_size
        if output_size == 0:
            raise RuntimeError("Generated trimmed video is empty")

        # 4. Upload do vídeo recortado para o media storage
        upload_route = f"{storage}/video/{owner_id}/{project_id}/{new_video_id}"
        with output_file.open("rb") as f:
            upload_resp = requests.put(
                upload_route,
                data=f,
                headers={
                    "X-Internal-Video-Key": secret,
                    "Content-Type": "video/mp4",
                    "Content-Length": str(output_size)
                },
                timeout=300
            )
            upload_resp.raise_for_status()

        # 5. Publicar evento de conclusão na fila de resultados
        result_message = {
            "messageId": f"result-{uuid.uuid4()}",
            "correlationId": message["messageId"],
            "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
            "status": "success",
            "procedure": PROCEDURE,
            "parameters": {
                "ownerId": owner_id,
                "projectId": project_id,
                "videoId": video_id,
                "newVideoId": new_video_id,
                "newVideoName": new_video_name,
                "size": output_size,
                "startTime": start_time,
                "endTime": end_time,
                "callerId": caller_id,
                "projectVersion": project_version,
            }
        }
        channel.basic_publish(
            exchange=EXCHANGE,
            routing_key=RESULTS_QUEUE,
            body=json.dumps(result_message).encode("utf-8"),
            properties=pika.BasicProperties(delivery_mode=2)
        )
        print(json.dumps({
            "status": "completed",
            "messageId": message["messageId"],
            "newVideoId": new_video_id,
            "bytes": output_size
        }), flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--once", action="store_true", help="Exit after one task")
    args = parser.parse_args()

    credentials = pika.PlainCredentials(
        os.getenv("RABBITMQ_USER", "user"),
        os.getenv("RABBITMQ_PASS", "password"),
    )
    while True:
        try:
            connection = pika.BlockingConnection(pika.ConnectionParameters(
                host=os.getenv("RABBITMQ_HOST", "rabbitmq"),
                port=int(os.getenv("RABBITMQ_PORT", "5672")),
                credentials=credentials,
                heartbeat=0,
            ))
            break
        except Exception as err:
            print(f"[video_trim] Waiting for RabbitMQ ({err}). Retrying in 2s...", flush=True)
            time.sleep(2)

    channel = connection.channel()
    channel.exchange_declare(exchange=EXCHANGE, exchange_type="direct", durable=True)

    # Declarar fila de tarefas de trim
    channel.queue_declare(queue=QUEUE, durable=True)
    channel.queue_bind(exchange=EXCHANGE, queue=QUEUE, routing_key=QUEUE)

    # Declarar fila de resultados
    channel.queue_declare(queue=RESULTS_QUEUE, durable=True)
    channel.queue_bind(exchange=EXCHANGE, queue=RESULTS_QUEUE, routing_key=RESULTS_QUEUE)

    channel.basic_qos(prefetch_count=1)
    failed = False

    def consume(ch, method, _properties, body):
        nonlocal failed
        try:
            msg = json.loads(body)
            process_trim_task(ch, msg)
        except Exception as error:
            failed = True
            print(json.dumps({"status": "error", "message": str(error)}), flush=True)
            ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
            # Notificar falha na fila de resultados se possível
            try:
                msg = json.loads(body)
                error_envelope = {
                    "messageId": f"result-{uuid.uuid4()}",
                    "correlationId": msg.get("messageId"),
                    "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
                    "status": "error",
                    "procedure": PROCEDURE,
                    "error": {"code": "TRIM_FAILED", "message": str(error)},
                    "parameters": msg.get("parameters", {})
                }
                ch.basic_publish(
                    exchange=EXCHANGE,
                    routing_key=RESULTS_QUEUE,
                    body=json.dumps(error_envelope).encode("utf-8"),
                    properties=pika.BasicProperties(delivery_mode=2)
                )
            except Exception:
                pass
        else:
            ch.basic_ack(delivery_tag=method.delivery_tag)

        if args.once:
            ch.stop_consuming()

    print(json.dumps({"status": "waiting", "queue": QUEUE}), flush=True)
    channel.basic_consume(queue=QUEUE, on_message_callback=consume, auto_ack=False)
    try:
        channel.start_consuming()
    finally:
        connection.close()

    if failed and args.once:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
