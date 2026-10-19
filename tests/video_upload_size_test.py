#!/usr/bin/env python3
"""Upload valid MP4 files at the Free/Premium size limits and clean up all data.

Run from the repository root with:
    python3 tests/video_upload_size_test.py

The MP4 contains one second of synthetic video followed by sparse zero padding
to reach the exact decimal byte limit. This exercises transfer, size checks,
storage and metadata association without encoding multi-gigabyte video content.
"""
import json
import os
import shutil
import subprocess
import tempfile
import time
import uuid
import warnings
from pathlib import Path
from urllib.parse import quote

import requests
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
warnings.filterwarnings("ignore", category=urllib3.exceptions.InsecureRequestWarning)

API = os.environ.get("PICTURAS_API", "https://localhost:8080/api-gateway").rstrip("/")
CHUNK_SIZE = 1024 * 1024
TIMEOUT = (15, 7200)


class MultipartBody:
    def __init__(self, path, boundary, name):
        self.path = path
        self.prefix = (
            f"--{boundary}\r\n"
            f'Content-Disposition: form-data; name="video"; filename="{name}"\r\n'
            "Content-Type: video/mp4\r\n\r\n"
        ).encode()
        self.suffix = f"\r\n--{boundary}--\r\n".encode()
        self.content_length = len(self.prefix) + path.stat().st_size + len(self.suffix)

    def __len__(self):
        return self.content_length

    def __iter__(self):
        yield self.prefix
        with self.path.open("rb") as video:
            while chunk := video.read(CHUNK_SIZE):
                yield chunk
        yield self.suffix


class UploadSizeTest:
    def __init__(self):
        self.session = requests.Session()
        self.session.verify = False
        self.created = []
        self.failed_cleanup = []

    def request(self, method, path, *, expected, **kwargs):
        response = self.session.request(method, API + path, timeout=TIMEOUT, **kwargs)
        if response.status_code not in expected:
            raise RuntimeError(
                f"{method} {path}: HTTP {response.status_code}: {response.text[:500]}"
            )
        return response

    def create_account_and_project(self, plan, run_id):
        account = self.request("POST", "/users/", expected=(201,), json={
            "name": f"Video size test {plan}",
            "email": f"video-size-{plan}-{run_id}@example.invalid",
            "password": f"Temp-{uuid.uuid4()}-Aa9!",
            "type": plan,
        }).json()
        user_id = account["user"]["_id"]
        token = account["jwt"]
        auth = {"Authorization": f"Bearer {token}"}
        self.created.append({"user": user_id, "token": token, "project": None, "video_ids": []})
        project = self.request(
            "POST", f"/projects/{user_id}", expected=(201,), headers=auth,
            json={"name": f"Upload size test {plan} {run_id}"},
        ).json()
        self.created[-1]["project"] = project["_id"]
        return self.created[-1]

    @staticmethod
    def make_mp4(path, target_bytes):
        subprocess.run([
            "ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error",
            "-f", "lavfi", "-i", "color=c=black:s=32x32:r=1",
            "-t", "1", "-an", "-c:v", "libx264", "-pix_fmt", "yuv420p",
            "-movflags", "+faststart", "-y", str(path),
        ], check=True)
        with path.open("r+b") as video:
            video.truncate(target_bytes)
        if path.stat().st_size != target_bytes:
            raise RuntimeError(f"Could not create the exact {target_bytes}-byte test file")
        probe = subprocess.run([
            "ffprobe", "-v", "error", "-show_entries",
            "format=format_name:stream=codec_name,codec_type", "-of", "json", str(path),
        ], check=True, capture_output=True, text=True)
        metadata = json.loads(probe.stdout)
        formats = metadata.get("format", {}).get("format_name", "")
        streams = metadata.get("streams", [])
        if "mp4" not in formats or not any(
            stream.get("codec_type") == "video" and stream.get("codec_name") == "h264"
            for stream in streams
        ):
            raise RuntimeError(f"Generated test file failed MP4/H.264 validation: {metadata}")

    @staticmethod
    def multipart_stream(path, boundary, name):
        body = MultipartBody(path, boundary, name)
        return body, len(body)

    def upload_one(self, account, plan, size, temp_dir):
        project_id = account["project"]
        user_id = account["user"]
        token = account["token"]
        name = f"upload-size-{plan}-{uuid.uuid4().hex}.mp4"
        video_path = Path(temp_dir) / name
        self.make_mp4(video_path, size)

        project = self.request(
            "GET", f"/projects/{user_id}/{project_id}", expected=(200,),
            headers={"Authorization": f"Bearer {token}"},
        ).json()
        boundary = f"picturas-{uuid.uuid4().hex}"
        body, content_length = self.multipart_stream(video_path, boundary, name)
        headers = {
            "Authorization": f"Bearer {token}",
            "X-Project-Version": str(project["version"]),
            "X-Video-Name": quote(name, safe=""),
            "X-Video-Size": str(size),
            "Content-Type": f"multipart/form-data; boundary={boundary}",
            "Content-Length": str(content_length),
        }
        start = time.monotonic()
        response = self.request(
            "POST", f"/projects/{user_id}/{project_id}/video", expected=(201,),
            headers=headers, data=body,
        )
        result = response.json()
        account["video_ids"].append(result["id"])
        elapsed = time.monotonic() - start
        if result.get("size") != size or result.get("name") != name:
            raise RuntimeError(f"Upload metadata does not match the request: {result}")

        # Delete immediately to release account quota and object storage before
        # the next large test file is uploaded.
        self.delete_video(account, result["id"])
        video_path.unlink(missing_ok=True)
        print(f"PASS {plan}: {size:,} bytes uploaded and deleted in {elapsed:.1f}s")

    def delete_video(self, account, video_id):
        user_id, project_id, token = account["user"], account["project"], account["token"]
        auth = {"Authorization": f"Bearer {token}"}
        project = self.request(
            "GET", f"/projects/{user_id}/{project_id}", expected=(200,), headers=auth,
        ).json()
        self.request(
            "DELETE", f"/projects/{user_id}/{project_id}/video/{video_id}", expected=(204,),
            headers={**auth, "X-Project-Version": str(project["version"])},
        )
        if video_id in account["video_ids"]:
            account["video_ids"].remove(video_id)

    def cleanup(self):
        for account in reversed(self.created):
            user_id, project_id, token = account["user"], account["project"], account["token"]
            auth = {"Authorization": f"Bearer {token}"}
            if project_id:
                try:
                    # Also find a video if the upload response was lost after
                    # the server committed it.
                    project = self.request(
                        "GET", f"/projects/{user_id}/{project_id}", expected=(200,), headers=auth,
                    ).json()
                    for video in project.get("videos", []):
                        video_id = video.get("id") or video.get("_id")
                        if video_id:
                            self.delete_video(account, video_id)
                except Exception as error:
                    self.failed_cleanup.append(f"project {project_id}: {error}")
            try:
                self.request("DELETE", f"/users/{user_id}", expected=(204,), headers=auth)
            except Exception as error:
                self.failed_cleanup.append(f"test user {user_id}: {error}")


def main():
    for tool in ("ffmpeg", "ffprobe"):
        if not shutil.which(tool):
            raise SystemExit(f"Required command not found: {tool}")

    test = UploadSizeTest()
    run_id = uuid.uuid4().hex[:10]
    try:
        with tempfile.TemporaryDirectory(prefix="picturas-video-size-") as temp_dir:
            for plan, size in (("free", 1_000_000_000), ("premium", 5_000_000_000)):
                account = test.create_account_and_project(plan, run_id)
                test.upload_one(account, plan, size, temp_dir)
    finally:
        test.cleanup()
    if test.failed_cleanup:
        raise SystemExit("Cleanup errors:\n- " + "\n- ".join(test.failed_cleanup))
    print("All size-limit upload tests passed; test videos, projects and accounts were deleted.")


if __name__ == "__main__":
    main()
