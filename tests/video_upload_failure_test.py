#!/usr/bin/env python3
"""Fault-injection check for failed video storage and cleanup (TST-UPL-12)."""
import json
import os
import shutil
import subprocess
import tempfile
import uuid
from pathlib import Path

import requests
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
API = os.environ.get("PICTURAS_API", "https://localhost:8080/api-gateway").rstrip("/")
ROOT = Path(__file__).resolve().parents[1]


def compose(*args):
    subprocess.run(["docker", "compose", *args], cwd=ROOT, check=True,
                   stdout=subprocess.DEVNULL)


def main():
    if not shutil.which("ffmpeg"):
        raise SystemExit("ffmpeg is required")
    s = requests.Session()
    s.verify = False
    suffix = uuid.uuid4().hex[:10]
    account = s.post(API + "/users/", json={
        "name": "Upload failure test", "email": f"upload-failure-{suffix}@example.invalid",
        "password": f"Temp-{uuid.uuid4()}-Aa9!", "type": "free",
    }, timeout=30)
    account.raise_for_status()
    account = account.json()
    owner = account["user"]["_id"]
    token = account["jwt"]
    auth = {"Authorization": f"Bearer {token}"}
    project = s.post(API + f"/projects/{owner}", headers=auth,
                     json={"name": f"Upload failure {suffix}"}, timeout=30)
    project.raise_for_status()
    pid = project.json()["_id"]

    try:
        with tempfile.TemporaryDirectory(prefix="picturas-failure-") as temp:
            video = Path(temp) / "fault-injection.mp4"
            subprocess.run([
                "ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error", "-y",
                "-f", "lavfi", "-i", "color=c=black:s=32x32:r=1", "-t", "1",
                "-an", "-c:v", "libx264", "-pix_fmt", "yuv420p", str(video),
            ], check=True)
            project_data = s.get(API + f"/projects/{owner}/{pid}", headers=auth, timeout=30).json()
            before = s.get(API + f"/projects/{owner}/video-storage", headers=auth, timeout=30).json()
            baseline = subprocess.run([
                "docker", "exec", "picturas-projects-1", "sh", "-lc",
                "find /tmp -maxdepth 1 -name 'picturas-video-*' -printf '%f\\n'",
            ], check=True, capture_output=True, text=True).stdout.splitlines()
            compose("stop", "img_storage")
            try:
                with video.open("rb") as stream:
                    response = s.post(
                        API + f"/projects/{owner}/{pid}/video",
                        headers={**auth, "X-Project-Version": str(project_data["version"]),
                                 "X-Video-Name": video.name, "X-Video-Size": str(video.stat().st_size)},
                        files={"video": (video.name, stream, "video/mp4")}, timeout=(15, 90),
                    )
            finally:
                compose("start", "img_storage")

            assert response.status_code == 502, (response.status_code, response.text[:300])
            assert response.json().get("code") == "VIDEO_UPLOAD_FAILED", response.text[:300]
            after_project = s.get(API + f"/projects/{owner}/{pid}", headers=auth, timeout=30).json()
            assert not after_project.get("videos"), after_project.get("videos")
            after = s.get(API + f"/projects/{owner}/video-storage", headers=auth, timeout=30).json()
            assert after["usedBytes"] == before["usedBytes"], (before, after)
            quota_result = subprocess.run([
                "docker", "exec", "picturas-projects_mongoDB-1", "mongo", "--quiet",
                "--port", "27018", "project", "--eval",
                f'JSON.stringify(db.videostorageaccounts.findOne({{ownerId:ObjectId("{owner}")}}))',
            ], check=True, capture_output=True, text=True)
            quota = json.loads(quota_result.stdout.strip().splitlines()[-1])
            assert quota["used"] == 0, quota
            assert quota["entries"][-1]["state"] == "released", quota
            leftovers = subprocess.run([
                "docker", "exec", "picturas-projects-1", "sh", "-lc",
                "find /tmp -maxdepth 1 -name 'picturas-video-*' -printf '%f\\n'",
            ], check=True, capture_output=True, text=True).stdout.splitlines()
            assert set(leftovers) <= set(baseline), leftovers
            print("PASS TST-UPL-12: falha de armazenamento devolve erro, não associa vídeo, "
                  "liberta quota e remove o temporário")
    finally:
        compose("start", "img_storage")
        s.delete(API + f"/users/{owner}", headers=auth, timeout=30)


if __name__ == "__main__":
    main()
