#!/usr/bin/env python3
"""Browser and integration checks for Upload UI, cancellation, and image regression.

Requires requests, ffmpeg, Firefox, and geckodriver. Starts a temporary test
account/project, removes uploaded media, and deletes the account on completion.
"""
import base64
import os
import shutil
import socket
import subprocess
import tempfile
import time
import uuid
from pathlib import Path

import requests
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

API = os.environ.get("PICTURAS_API", "https://localhost:8080/api-gateway").rstrip("/")
WEB = os.environ.get("PICTURAS_WEB", "https://localhost:8080").rstrip("/")
POLL = 0.25
ELEMENT_KEY = "element-6066-11e4-a52e-4f735466cecf"


class Browser:
    def __init__(self):
        with socket.socket() as sock:
            sock.bind(("127.0.0.1", 0))
            self.port = sock.getsockname()[1]
        self.base = f"http://127.0.0.1:{self.port}"
        self.http = requests.Session()
        self.process = subprocess.Popen(
            ["geckodriver", "--host", "127.0.0.1", "--port", str(self.port)],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        self.session_id = None
        deadline = time.monotonic() + 20
        while time.monotonic() < deadline:
            try:
                if self.http.get(self.base + "/status", timeout=1).ok:
                    break
            except requests.RequestException:
                time.sleep(POLL)
        else:
            raise RuntimeError("geckodriver did not become ready")

    def start(self):
        response = self.http.post(
            self.base + "/session",
            json={
                "capabilities": {
                    "alwaysMatch": {
                        "browserName": "firefox",
                        "acceptInsecureCerts": True,
                        "moz:firefoxOptions": {"args": ["-headless"]},
                    }
                }
            },
            timeout=30,
        )
        response.raise_for_status()
        payload = response.json()["value"]
        self.session_id = payload["sessionId"]
        return self

    def command(self, method, path, **kwargs):
        response = self.http.request(method, self.base + path, timeout=30, **kwargs)
        if not response.ok:
            raise RuntimeError(f"WebDriver HTTP {response.status_code}: {response.text[:500]}")
        payload = response.json().get("value")
        if isinstance(payload, dict) and payload.get("error"):
            raise RuntimeError(f"WebDriver {payload['error']}: {payload.get('message', '')}")
        return payload

    def navigate(self, url):
        self.command("POST", f"/session/{self.session_id}/url", json={"url": url})

    def script(self, script, args=None):
        return self.command(
            "POST", f"/session/{self.session_id}/execute/sync",
            json={"script": script, "args": args or []},
        )

    def element(self, selector, using="css selector"):
        return self.command(
            "POST", f"/session/{self.session_id}/element",
            json={"using": using, "value": selector},
        )[ELEMENT_KEY]

    def send_text(self, element_id, value):
        self.command(
            "POST", f"/session/{self.session_id}/element/{element_id}/value",
            json={"text": value, "value": list(value)},
        )

    def send_file(self, element_id, path):
        path = Path(path)
        self.script(
            """const input = arguments[0];
               const raw = atob(arguments[1]);
               const bytes = Uint8Array.from(raw, c => c.charCodeAt(0));
               const file = new File([bytes], arguments[2], {type: arguments[3]});
               const transfer = new DataTransfer(); transfer.items.add(file);
               Object.defineProperty(input, 'files', {configurable: true, value: transfer.files});
               input.dispatchEvent(new Event('change', {bubbles: true}));""",
            [{ELEMENT_KEY: element_id}, base64.b64encode(path.read_bytes()).decode(), path.name,
             "video/mp4" if path.suffix.lower() == ".mp4" else "video/quicktime"],
        )

    def click_text(self, text):
        clicked = self.script(
            """const text = arguments[0];
               const button = [...document.querySelectorAll('button')]
                 .find(node => node.textContent.trim() === text);
               if (!button) return false;
               button.click(); return true;""",
            [text],
        )
        if not clicked:
            raise AssertionError(f"Button not found: {text}; page={self.body_text()[:1000]!r}")

    def body_text(self):
        return self.script("return document.body.innerText") or ""

    def wait_for(self, predicate, description, timeout=30):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            try:
                result = predicate()
                if result:
                    return result
            except (requests.RequestException, RuntimeError):
                pass
            time.sleep(POLL)
        raise AssertionError(f"Timed out waiting for {description}; page={self.body_text()[:1000]!r}")

    def close(self):
        if self.session_id:
            try:
                self.command("DELETE", f"/session/{self.session_id}")
            except Exception:
                pass
        self.process.terminate()
        try:
            self.process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            self.process.kill()


class UploadAdditionalChecks:
    def __init__(self):
        self.api = requests.Session()
        self.api.verify = False
        self.user_id = None
        self.token = None
        self.password = None
        self.email = None
        self.project_id = None
        self.browser = None

    def request(self, method, path, expected, **kwargs):
        response = self.api.request(method, API + path, timeout=(10, 90), **kwargs)
        if response.status_code not in expected:
            raise AssertionError(
                f"{method} {path}: HTTP {response.status_code}, expected {expected}; "
                f"body={response.text[:300]}"
            )
        return response

    def set_up(self):
        run_id = uuid.uuid4().hex[:10]
        self.email = f"upload-ui-{run_id}@example.invalid"
        self.password = f"Temp-{uuid.uuid4()}-Aa9!"
        account = self.request("POST", "/users/", (201,), json={
            "name": f"Upload UI test {run_id}",
            "email": self.email,
            "password": self.password,
            "type": "free",
        }).json()
        self.user_id = account["user"]["_id"]
        self.token = account["jwt"]
        self.auth = {"Authorization": f"Bearer {self.token}"}
        project = self.request(
            "POST", f"/projects/{self.user_id}", (201,), headers=self.auth,
            json={"name": f"Upload UI test {run_id}"},
        ).json()
        self.project_id = project["_id"]
        return account

    def project(self):
        return self.request(
            "GET", f"/projects/{self.user_id}/{self.project_id}", (200,), headers=self.auth,
        ).json()

    def add_regression_image(self, png_path):
        project = self.project()
        with png_path.open("rb") as image:
            response = self.request(
                "POST", f"/projects/{self.user_id}/{self.project_id}/img", (201, 204),
                headers={**self.auth, "X-Project-Version": str(project["version"])},
                files={"image": ("regression.png", image, "image/png")},
            )
        return response

    def run(self):
        for tool in ("ffmpeg", "geckodriver", "firefox"):
            if shutil.which(tool) is None:
                raise SystemExit(f"Required command not found: {tool}")
        account = self.set_up()
        results = []
        with tempfile.TemporaryDirectory(prefix="picturas-upload-ui-", dir=Path.home() / ".cache") as tmp:
            temp = Path(tmp)
            valid = temp / "valid.mp4"
            fake = temp / "invalid-content.mp4"
            wrong_extension = temp / "not-video.mov"
            png = temp / "regression.png"
            subprocess.run([
                "ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error", "-y",
                "-f", "lavfi", "-i", "color=c=black:s=32x32:r=1", "-t", "1",
                "-an", "-c:v", "libx264", "-pix_fmt", "yuv420p", str(valid),
            ], check=True)
            fake.write_bytes(b"not a valid MP4 video")
            wrong_extension.write_bytes(b"not an MP4")
            png.write_bytes(base64.b64decode(
                "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/"
                "2ioAAAAASUVORK5CYII="
            ))
            self.add_regression_image(png)
            project_url = f"{WEB}/dashboard/{self.project_id}"
            self.browser = Browser().start()
            self.browser.navigate(WEB + "/login")
            self.browser.wait_for(lambda: self.browser.element("#email"), "login form")
            self.browser.send_text(self.browser.element("#email"), self.email)
            self.browser.send_text(self.browser.element("#password"), self.password)
            self.browser.click_text("Login")
            self.browser.wait_for(
                lambda: self.email in self.browser.body_text(), "authenticated session to load"
            )
            self.browser.navigate(project_url)
            self.browser.wait_for(
                lambda: "Add Video" in self.browser.body_text(), "project UI to load"
            )
            self.browser.wait_for(
                lambda: self.browser.script(
                    "return [...document.querySelectorAll('img')].some(img => img.alt === 'regression.png')"
                ),
                "uploaded image card to appear",
            )

            # TST-UPL-11: select a valid file, cancel before confirmation, and
            # verify that no video was sent or associated.
            before = len(self.project().get("videos", []))
            self.browser.click_text("Add Video")
            self.browser.send_file(self.browser.element('input[aria-label="Select MP4 video"]'), valid)
            self.browser.click_text("Cancel")
            self.browser.wait_for(
                lambda: "Select or drag an MP4 video" not in self.browser.body_text(),
                "upload dialog to close",
            )
            assert len(self.project().get("videos", [])) == before
            results.append(("TST-UPL-11", "PASS"))

            # TST-UPL-15: invalid extension is rejected by the UI before upload.
            self.browser.click_text("Add Video")
            self.browser.send_file(self.browser.element('input[aria-label="Select MP4 video"]'), wrong_extension)
            self.browser.wait_for(
                lambda: "Please select a valid MP4 video file." in self.browser.body_text(),
                "invalid file message",
            )
            assert not self.browser.script(
                "return [...document.querySelectorAll('button')].some(b => b.textContent.includes('Upload Video') && !b.disabled)"
            )
            self.browser.click_text("Cancel")
            results.append(("TST-UPL-15", "PASS"))

            # TST-UPL-09: observe both the successful and rejected upload states.
            self.browser.click_text("Add Video")
            self.browser.send_file(self.browser.element('input[aria-label="Select MP4 video"]'), valid)
            selected = self.browser.script(
                "const f = document.querySelector('input[aria-label=\"Select MP4 video\"]')?.files?.[0]; return f ? {name:f.name,size:f.size,type:f.type} : null"
            )
            if not selected or selected["size"] == 0:
                raise AssertionError(f"Browser did not select the generated MP4: {selected}")
            print(f"Selected browser fixture: {selected}", flush=True)
            self.browser.click_text("Upload Video")
            self.browser.wait_for(
                lambda: "Video added to project successfully." in self.browser.body_text(),
                "successful upload notification",
                timeout=60,
            )
            project = self.project()
            assert len(project.get("videos", [])) == before + 1
            assert len(project.get("imgs", [])) == 1
            assert self.browser.script(
                "return [...document.querySelectorAll('img')].some(img => img.alt === 'regression.png')"
            )
            results.append(("TST-UPL-14", "PASS"))

            self.browser.click_text("Add Video")
            self.browser.send_file(self.browser.element('input[aria-label="Select MP4 video"]'), fake)
            self.browser.click_text("Upload Video")
            self.browser.wait_for(
                lambda: "Invalid video" in self.browser.body_text(),
                "failed upload notification",
                timeout=60,
            )
            results.append(("TST-UPL-09", "PASS"))

        self.cleanup()
        for test_id, status in results:
            print(f"{status} {test_id}")

    def cleanup(self):
        if self.browser:
            self.browser.close()
            self.browser = None
        if not self.user_id or not self.token:
            return
        try:
            project = self.project()
            for video in project.get("videos", []):
                video_id = video.get("id") or video.get("_id")
                if video_id:
                    current = self.project()
                    self.request(
                        "DELETE", f"/projects/{self.user_id}/{self.project_id}/video/{video_id}", (204,),
                        headers={**self.auth, "X-Project-Version": str(current["version"])},
                    )
            project = self.project()
            for image in project.get("imgs", []):
                image_id = image.get("_id") or image.get("id")
                if image_id:
                    current = self.project()
                    self.request(
                        "DELETE", f"/projects/{self.user_id}/{self.project_id}/img/{image_id}", (204,),
                        headers={**self.auth, "X-Project-Version": str(current["version"])},
                    )
            self.request("DELETE", f"/users/{self.user_id}", (204,), headers=self.auth)
        finally:
            self.user_id = None
            self.project_id = None
            self.token = None


if __name__ == "__main__":
    test = UploadAdditionalChecks()
    try:
        test.run()
    finally:
        test.cleanup()
