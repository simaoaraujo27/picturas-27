"""Example worker: receive one video task and download its original MP4."""

import argparse
import hashlib
import json
import os
import re
import tempfile
from pathlib import Path

import pika
import requests


EXCHANGE = "picturas"
QUEUE = "video_example_queue"
PROCEDURE = "video_example"
OBJECT_ID = re.compile(r"^[0-9a-fA-F]{24}$")


def download_video(message):
    if message.get("procedure") != PROCEDURE or not isinstance(message.get("messageId"), str):
        raise ValueError("Invalid video task envelope")

    parameters = message.get("parameters") or {}
    owner_id = parameters.get("ownerId")
    project_id = parameters.get("projectId")
    video_id = parameters.get("videoId")
    expected_size = parameters.get("size")
    if not all(isinstance(value, str) and OBJECT_ID.fullmatch(value)
               for value in (owner_id, project_id, video_id)):
        raise ValueError("Invalid video identifiers")
    if type(expected_size) is not int or expected_size < 1:
        raise ValueError("Invalid video size")

    secret = os.environ["INTERNAL_VIDEO_KEY"]
    storage = os.getenv("MEDIA_STORAGE_URL", "http://img_storage:11000").rstrip("/")
    route = f"{storage}/video/{owner_id}/{project_id}/{video_id}/url"
    signed = requests.get(route, headers={"X-Internal-Video-Key": secret}, timeout=15)
    signed.raise_for_status()
    url = signed.json()["url"]

    digest = hashlib.sha256()
    total = 0
    with tempfile.TemporaryDirectory(prefix="picturas-video-example-") as directory:
        destination = Path(directory) / "input.mp4"
        with requests.get(url, stream=True, timeout=(15, 300)) as response:
            response.raise_for_status()
            with destination.open("wb") as output:
                for chunk in response.iter_content(chunk_size=1024 * 1024):
                    if chunk:
                        output.write(chunk)
                        digest.update(chunk)
                        total += len(chunk)
        if total != expected_size:
            raise ValueError(f"Incomplete video: expected {expected_size} bytes, received {total}")
        # Processing would use destination here. This example only verifies the input.
        print(json.dumps({
            "status": "downloaded",
            "messageId": message["messageId"],
            "bytes": total,
            "sha256": digest.hexdigest(),
        }), flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--once", action="store_true", help="Exit after one task")
    args = parser.parse_args()

    credentials = pika.PlainCredentials(
        os.getenv("RABBITMQ_USER", "user"),
        os.getenv("RABBITMQ_PASS", "password"),
    )
    connection = pika.BlockingConnection(pika.ConnectionParameters(
        host=os.getenv("RABBITMQ_HOST", "rabbitmq"),
        port=int(os.getenv("RABBITMQ_PORT", "5672")),
        credentials=credentials,
        heartbeat=0,
    ))
    channel = connection.channel()
    channel.exchange_declare(exchange=EXCHANGE, exchange_type="direct", durable=True)
    channel.queue_declare(queue=QUEUE, durable=True)
    channel.queue_bind(exchange=EXCHANGE, queue=QUEUE, routing_key=QUEUE)
    channel.basic_qos(prefetch_count=1)
    failed = False

    def consume(ch, method, _properties, body):
        nonlocal failed
        try:
            download_video(json.loads(body))
        except Exception as error:
            failed = True
            print(json.dumps({"status": "error", "message": str(error)}), flush=True)
            ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
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
    if failed:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
