"""Process PictuRAS video_speed tasks using FFmpeg and media storage."""

import argparse
import json
import math
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
QUEUE = "video_speed_queue"
RESULTS_QUEUE = "video_results_queue"
PROCEDURE = "video_speed"
OBJECT_ID = re.compile(r"^[0-9a-fA-F]{24}$")
SPEEDS = (0.5, 1, 2)


def is_finite_number(value):
    return (
        isinstance(value, (int, float))
        and not isinstance(value, bool)
        and math.isfinite(value)
    )


def validate_intervals(intervals, duration=None):
    if not isinstance(intervals, list) or not intervals:
        raise ValueError("intervals must be a non-empty list")
    if duration is not None and (not is_finite_number(duration) or duration <= 0):
        raise ValueError("Invalid video duration")

    normalized = []
    for interval in intervals:
        if not isinstance(interval, dict):
            raise ValueError("Each interval must be an object")
        start = interval.get("startTime")
        end = interval.get("endTime")
        speed = interval.get("speed")
        if not is_finite_number(start) or not is_finite_number(end):
            raise ValueError("Interval bounds must be finite numbers")
        if start < 0 or end <= start:
            raise ValueError("Invalid interval bounds")
        if not is_finite_number(speed) or speed not in SPEEDS:
            raise ValueError("speed must be 0.5, 1 or 2")
        if duration is not None and end > duration:
            raise ValueError("Interval exceeds video duration")
        normalized.append({"startTime": start, "endTime": end, "speed": speed})

    normalized.sort(key=lambda item: item["startTime"])
    for previous, current in zip(normalized, normalized[1:]):
        if current["startTime"] < previous["endTime"]:
            raise ValueError("Intervals must not overlap")
    return normalized


def validate_message(message):
    if not isinstance(message, dict) or message.get("procedure") != PROCEDURE:
        raise ValueError("Invalid video task procedure")
    message_id = message.get("messageId")
    if not isinstance(message_id, str) or not message_id.strip():
        raise ValueError("Invalid messageId")
    parameters = message.get("parameters")
    if not isinstance(parameters, dict):
        raise ValueError("Invalid task parameters")
    for field in ("ownerId", "projectId", "videoId", "newVideoId"):
        identifier = parameters.get(field)
        if not isinstance(identifier, str) or not OBJECT_ID.fullmatch(identifier):
            raise ValueError(f"Invalid {field}")
    if parameters["videoId"].lower() == parameters["newVideoId"].lower():
        raise ValueError("newVideoId must differ from the original videoId")
    name = parameters.get("newVideoName")
    if not isinstance(name, str) or not name.strip():
        raise ValueError("Invalid new video name")
    return {**parameters, "intervals": validate_intervals(parameters.get("intervals"))}


def probe_video(input_file):
    process = subprocess.run(
        [
            "ffprobe", "-v", "error", "-show_entries",
            "format=duration,format_name:stream=codec_type,codec_name,duration",
            "-of", "json", str(input_file),
        ],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
    )
    if process.returncode != 0:
        raise RuntimeError(f"FFprobe failed: {process.stderr[-1000:]}")
    info = json.loads(process.stdout)
    streams = info.get("streams", [])
    video = next((stream for stream in streams if stream.get("codec_type") == "video"), None)
    if video is None:
        raise ValueError("Input has no video stream")
    if video.get("codec_name") != "h264":
        raise ValueError("Input video must use H.264")
    if "mp4" not in info.get("format", {}).get("format_name", "").split(","):
        raise ValueError("Input must be an MP4 video")
    # Use the video timeline, rather than a potentially longer audio stream.
    duration = float(video.get("duration", info.get("format", {}).get("duration", "nan")))
    if not math.isfinite(duration) or duration <= 0:
        raise ValueError("Invalid video duration")
    return {
        "duration": duration,
        "has_video": True,
        "has_audio": any(stream.get("codec_type") == "audio" for stream in streams),
    }


def build_segments(intervals, duration):
    segments = []
    position = 0
    for interval in validate_intervals(intervals, duration):
        if interval["startTime"] > position:
            segments.append({"startTime": position, "endTime": interval["startTime"], "speed": 1})
        segments.append(interval)
        position = interval["endTime"]
    if position < duration:
        segments.append({"startTime": position, "endTime": duration, "speed": 1})
    return segments


def build_filter_graph(segments, has_audio):
    count = len(segments)
    video_inputs = "".join(f"[vs{i}]" for i in range(count))
    filters = [f"[0:v:0]setpts=PTS-STARTPTS,split={count}{video_inputs}"]
    if has_audio:
        audio_inputs = "".join(f"[as{i}]" for i in range(count))
        filters.append(f"[0:a:0]asetpts=PTS-STARTPTS,asplit={count}{audio_inputs}")

    concat_inputs = []
    for i, segment in enumerate(segments):
        start = segment["startTime"]
        end = segment["endTime"]
        speed = segment["speed"]
        filters.append(
            f"[vs{i}]trim=start={start}:end={end},"
            f"setpts=(PTS-STARTPTS)/{speed}[v{i}]"
        )
        concat_inputs.append(f"[v{i}]")
        if has_audio:
            filters.append(
                f"[as{i}]atrim=start={start}:end={end},"
                f"asetpts=PTS-STARTPTS,atempo={speed}[a{i}]"
            )
            concat_inputs.append(f"[a{i}]")
    outputs = "[v][a]" if has_audio else "[v]"
    filters.append(
        f"{''.join(concat_inputs)}concat=n={count}:v=1:a={int(has_audio)}{outputs}"
    )
    return ";".join(filters)


def process_video(input_file, output_file, intervals):
    if Path(input_file).resolve() == Path(output_file).resolve():
        raise ValueError("Output must differ from the original file")
    metadata = probe_video(input_file)
    segments = build_segments(intervals, metadata["duration"])
    command = [
        "ffmpeg", "-y", "-loglevel", "error", "-i", str(input_file),
        "-filter_complex", build_filter_graph(segments, metadata["has_audio"]),
        "-map", "[v]",
    ]
    if metadata["has_audio"]:
        command.extend(["-map", "[a]", "-c:a", "aac"])
    command.extend([
        "-c:v", "libx264", "-pix_fmt", "yuv420p",
        "-movflags", "+faststart", "-f", "mp4", str(output_file),
    ])
    process = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if process.returncode != 0:
        raise RuntimeError(f"FFmpeg video speed failed: {process.stderr[-1000:]}")
    if not Path(output_file).is_file() or Path(output_file).stat().st_size == 0:
        raise RuntimeError("Generated video is empty")


def result_envelope(message, status, parameters):
    return {
        "messageId": f"result-{uuid.uuid4()}",
        "correlationId": message.get("messageId"),
        "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "status": status,
        "procedure": PROCEDURE,
        "parameters": parameters,
    }


def publish_result(channel, result):
    channel.basic_publish(
        exchange=EXCHANGE, routing_key=RESULTS_QUEUE,
        body=json.dumps(result, allow_nan=False).encode("utf-8"),
        properties=pika.BasicProperties(delivery_mode=2),
    )


def process_speed_task(channel, message):
    parameters = validate_message(message)
    owner_id = parameters["ownerId"]
    project_id = parameters["projectId"]
    video_id = parameters["videoId"]
    new_video_id = parameters["newVideoId"]
    secret = os.environ["INTERNAL_VIDEO_KEY"]
    storage = os.getenv("MEDIA_STORAGE_URL", "http://img_storage:11000").rstrip("/")
    route = f"{storage}/video/{owner_id}/{project_id}/{video_id}/url"
    with requests.get(route, headers={"X-Internal-Video-Key": secret}, timeout=15) as signed:
        signed.raise_for_status()
        source_url = signed.json()["url"]

    with tempfile.TemporaryDirectory(prefix="picturas-video-speed-") as directory:
        input_file = Path(directory) / "input.mp4"
        output_file = Path(directory) / "output.mp4"
        with requests.get(source_url, stream=True, timeout=(15, 300)) as response:
            response.raise_for_status()
            with input_file.open("wb") as destination:
                for chunk in response.iter_content(chunk_size=1024 * 1024):
                    if chunk:
                        destination.write(chunk)

        process_video(input_file, output_file, parameters["intervals"])
        output_size = output_file.stat().st_size
        upload_route = f"{storage}/video/{owner_id}/{project_id}/{new_video_id}"
        with output_file.open("rb") as source:
            with requests.put(
                upload_route, data=source,
                headers={
                    "X-Internal-Video-Key": secret,
                    "Content-Type": "video/mp4",
                    "Content-Length": str(output_size),
                },
                timeout=300,
            ) as response:
                response.raise_for_status()

        result_parameters = {
            field: parameters.get(field) for field in (
                "ownerId", "projectId", "videoId", "newVideoId", "newVideoName",
                "intervals", "callerId", "projectVersion",
            )
        }
        result_parameters["size"] = output_size
        publish_result(channel, result_envelope(message, "success", result_parameters))
        print(json.dumps({
            "status": "completed", "messageId": message["messageId"],
            "newVideoId": new_video_id, "bytes": output_size,
        }), flush=True)


def parse_finite_float(value):
    number = float(value)
    if not math.isfinite(number):
        raise ValueError("JSON numbers must be finite")
    return number


def consume_task(channel, method, _properties, body):
    message = {}
    try:
        decoded = json.loads(body, parse_float=parse_finite_float, parse_constant=parse_finite_float)
        if isinstance(decoded, dict):
            message = decoded
        process_speed_task(channel, decoded)
    except Exception as error:
        print(json.dumps({"status": "error", "message": str(error)}), flush=True)
        channel.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
        parameters = message.get("parameters")
        result = result_envelope(message, "error", parameters if isinstance(parameters, dict) else {})
        result["error"] = {"code": "VIDEO_SPEED_FAILED", "message": str(error)}
        try:
            publish_result(channel, result)
        except Exception as publish_error:
            print(json.dumps({"status": "error", "message": str(publish_error)}), flush=True)
        return False
    channel.basic_ack(delivery_tag=method.delivery_tag)
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--once", action="store_true", help="Exit after one task")
    args = parser.parse_args()
    credentials = pika.PlainCredentials(
        os.getenv("RABBITMQ_USER", "user"), os.getenv("RABBITMQ_PASS", "password"),
    )
    while True:
        try:
            connection = pika.BlockingConnection(pika.ConnectionParameters(
                host=os.getenv("RABBITMQ_HOST", "rabbitmq"),
                port=int(os.getenv("RABBITMQ_PORT", "5672")),
                credentials=credentials, heartbeat=0,
            ))
            break
        except Exception as error:
            print(f"[video_speed] Waiting for RabbitMQ ({error}). Retrying in 2s...", flush=True)
            time.sleep(2)

    channel = connection.channel()
    channel.exchange_declare(exchange=EXCHANGE, exchange_type="direct", durable=True)
    for queue in (QUEUE, RESULTS_QUEUE):
        channel.queue_declare(queue=queue, durable=True)
        channel.queue_bind(exchange=EXCHANGE, queue=queue, routing_key=queue)
    channel.basic_qos(prefetch_count=1)
    failed = False

    def consume(ch, method, properties, body):
        nonlocal failed
        if not consume_task(ch, method, properties, body):
            failed = True
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
