"""Publish one test task using the current PictuRAS RabbitMQ message envelope."""

import argparse
import json
import os
import re
import uuid
from datetime import datetime, timezone

import pika


EXCHANGE = "picturas"
QUEUE = "video_example_queue"
OBJECT_ID = re.compile(r"^[0-9a-fA-F]{24}$")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--owner-id", required=True)
    parser.add_argument("--project-id", required=True)
    parser.add_argument("--video-id", required=True)
    parser.add_argument("--size", required=True, type=int)
    args = parser.parse_args()
    if not all(OBJECT_ID.fullmatch(value)
               for value in (args.owner_id, args.project_id, args.video_id)):
        parser.error("IDs must be 24-digit MongoDB ObjectIds")
    if args.size < 1:
        parser.error("size must be positive")

    message = {
        "messageId": f"request-{uuid.uuid4()}",
        "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "procedure": "video_example",
        "parameters": {
            "ownerId": args.owner_id,
            "projectId": args.project_id,
            "videoId": args.video_id,
            "size": args.size,
        },
    }
    credentials = pika.PlainCredentials(
        os.getenv("RABBITMQ_USER", "user"),
        os.getenv("RABBITMQ_PASS", "password"),
    )
    connection = pika.BlockingConnection(pika.ConnectionParameters(
        host=os.getenv("RABBITMQ_HOST", "rabbitmq"),
        port=int(os.getenv("RABBITMQ_PORT", "5672")),
        credentials=credentials,
    ))
    try:
        channel = connection.channel()
        channel.exchange_declare(exchange=EXCHANGE, exchange_type="direct", durable=True)
        channel.queue_declare(queue=QUEUE, durable=True)
        channel.queue_bind(exchange=EXCHANGE, queue=QUEUE, routing_key=QUEUE)
        channel.basic_publish(exchange=EXCHANGE, routing_key=QUEUE,
                              body=json.dumps(message).encode("utf-8"))
        print(json.dumps(message))
    finally:
        connection.close()


if __name__ == "__main__":
    main()
