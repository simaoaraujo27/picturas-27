#!/usr/bin/env python3
"""Measure per-upload application-container memory for TST-UPL-13.

Streams a synthetic 128 MB MP4/H.264 fixture without reading it into client RAM,
measures relevant container usage from Docker, then deletes the video and account.
"""
import json
import os
import re
import shutil
import subprocess
import tempfile
import threading
import time
import uuid
from pathlib import Path
from urllib.parse import quote

import requests
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
API = os.environ.get("PICTURAS_API", "https://localhost:8080/api-gateway").rstrip("/")
TARGET_BYTES = 128_000_000
LIMIT_BYTES = 1_000_000_000
CHUNK = 1024 * 1024
CONTAINERS = ("picturas-nginx-1", "picturas-api_gateway-1", "picturas-projects-1",
              "picturas-img_storage-1", "picturas-seaweedfs-1")


def as_bytes(text):
    match = re.search(r"([0-9.]+)\s*([KMGT]?i?B|[KMGT]?B)", text.strip())
    if not match:
        raise ValueError(f"Unrecognized Docker memory value: {text!r}")
    number, unit = match.groups()
    scale = {"B": 1, "KiB": 1024, "MiB": 1024**2, "GiB": 1024**3,
             "kB": 1000, "MB": 1000**2, "GB": 1000**3}[unit]
    return int(float(number) * scale)


def memory_sample():
    result = subprocess.run([
        "docker", "stats", "--no-stream", "--format", "{{.Name}}|{{.MemUsage}}", *CONTAINERS,
    ], check=True, capture_output=True, text=True)
    values = {}
    for line in result.stdout.splitlines():
        name, usage = line.split("|", 1)
        values[name] = as_bytes(usage.split("/", 1)[0])
    if len(values) != len(CONTAINERS):
        raise RuntimeError(f"Could not sample every upload container: {values}")
    return sum(values.values())


class Body:
    def __init__(self, path, boundary, name):
        self.path = path
        self.prefix = (f"--{boundary}\r\nContent-Disposition: form-data; name=\"video\"; "
                       f"filename=\"{name}\"\r\nContent-Type: video/mp4\r\n\r\n").encode()
        self.suffix = f"\r\n--{boundary}--\r\n".encode()
        self.length = len(self.prefix) + path.stat().st_size + len(self.suffix)

    def __len__(self):
        return self.length

    def __iter__(self):
        yield self.prefix
        with self.path.open("rb") as source:
            while data := source.read(CHUNK):
                yield data
        yield self.suffix


def main():
    for tool in ("ffmpeg", "ffprobe", "docker"):
        if shutil.which(tool) is None:
            raise SystemExit(f"{tool} is required")
    session = requests.Session()
    session.verify = False
    user_id = token = project_id = video_id = None
    account_auth = {}
    try:
        tag = uuid.uuid4().hex[:10]
        response = session.post(API + "/users/", json={
            "name": "Upload memory test", "email": f"upload-memory-{tag}@example.invalid",
            "password": f"Temp-{uuid.uuid4()}-Aa9!", "type": "free",
        }, timeout=30)
        response.raise_for_status()
        account = response.json()
        user_id, token = account["user"]["_id"], account["jwt"]
        account_auth = {"Authorization": f"Bearer {token}"}
        response = session.post(API + f"/projects/{user_id}", headers=account_auth,
                                json={"name": f"Upload memory {tag}"}, timeout=30)
        response.raise_for_status()
        project_id = response.json()["_id"]

        with tempfile.TemporaryDirectory(prefix="picturas-upload-memory-") as temp:
            video = Path(temp) / "memory-measure.mp4"
            subprocess.run([
                "ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error", "-y",
                "-f", "lavfi", "-i", "color=c=black:s=32x32:r=1", "-t", "1",
                "-an", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-movflags", "+faststart",
                str(video),
            ], check=True)
            with video.open("r+b") as stream:
                stream.truncate(TARGET_BYTES)
            metadata = json.loads(subprocess.run([
                "ffprobe", "-v", "error", "-show_entries", "format=format_name:stream=codec_name,codec_type",
                "-of", "json", str(video),
            ], check=True, capture_output=True, text=True).stdout)
            assert "mp4" in metadata["format"]["format_name"]
            assert any(s.get("codec_type") == "video" and s.get("codec_name") == "h264"
                       for s in metadata["streams"])

            project = session.get(API + f"/projects/{user_id}/{project_id}",
                                  headers=account_auth, timeout=30).json()
            before_samples = [memory_sample() for _ in range(4)]
            baseline = sum(before_samples) // len(before_samples)
            peak = baseline
            running = True
            def monitor():
                nonlocal peak
                while running:
                    try:
                        peak = max(peak, memory_sample())
                    except Exception:
                        pass
                    time.sleep(0.15)
            watcher = threading.Thread(target=monitor, daemon=True)
            watcher.start()
            boundary = f"picturas-{uuid.uuid4().hex}"
            body = Body(video, boundary, video.name)
            headers = {
                **account_auth,
                "X-Project-Version": str(project["version"]),
                "X-Video-Name": quote(video.name, safe=""),
                "X-Video-Size": str(TARGET_BYTES),
                "Content-Type": f"multipart/form-data; boundary={boundary}",
                "Content-Length": str(len(body)),
            }
            try:
                response = session.post(API + f"/projects/{user_id}/{project_id}/video",
                                        headers=headers, data=body, timeout=(15, 300))
            finally:
                running = False
                watcher.join(timeout=5)
            response.raise_for_status()
            video_id = response.json()["id"]
            delta = max(0, peak - baseline)
            if delta > LIMIT_BYTES:
                raise AssertionError(f"Additional container memory {delta:,} exceeds {LIMIT_BYTES:,} bytes")
            print(f"PASS TST-UPL-13: baseline agregado {baseline:,} bytes; pico agregado {peak:,} bytes; "
                  f"incremento máximo observado {delta:,} bytes num upload de {TARGET_BYTES:,} bytes "
                  f"(limite {LIMIT_BYTES:,})")
    finally:
        if user_id and token:
            auth = {"Authorization": f"Bearer {token}"}
            try:
                project = session.get(API + f"/projects/{user_id}/{project_id}",
                                      headers=auth, timeout=30).json()
                for video in project.get("videos", []):
                    vid = video.get("id") or video.get("_id")
                    if vid:
                        current = session.get(API + f"/projects/{user_id}/{project_id}",
                                              headers=auth, timeout=30).json()
                        session.delete(API + f"/projects/{user_id}/{project_id}/video/{vid}",
                                       headers={**auth, "X-Project-Version": str(current["version"])},
                                       timeout=30).raise_for_status()
            except Exception as error:
                print(f"Cleanup warning for upload memory test: {error}")
            try:
                session.delete(API + f"/users/{user_id}", headers=auth, timeout=30)
            except Exception as error:
                print(f"Cleanup warning for test account: {error}")


if __name__ == "__main__":
    main()
