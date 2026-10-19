#!/usr/bin/env python3
"""Small, repeatable Upload API checks; never creates large test videos.

Run from the repository root with:
    python3 tests/video_upload_smoke_test.py

The size-boundary cases exercise the JSON pre-validation endpoint only. The
only generated media files are one-second, low-resolution test clips. Temporary
accounts, projects, and any successfully uploaded test videos are removed.
"""
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
TIMEOUT = (10, 90)
LIMITS = {"free": 1_000_000_000, "premium": 5_000_000_000}


class UploadSmokeTest:
    def __init__(self):
        self.session = requests.Session()
        self.session.verify = os.environ.get("PICTURAS_VERIFY_TLS", "0") == "1"
        self.accounts = []
        self.results = []

    def request(self, method, path, expected, **kwargs):
        response = self.session.request(method, API + path, timeout=TIMEOUT, **kwargs)
        if response.status_code not in expected:
            raise AssertionError(
                f"{method} {path}: HTTP {response.status_code}, expected {expected}; "
                f"body={response.text[:300]}"
            )
        return response

    def check(self, test_id, description, callback):
        try:
            callback()
            self.results.append((test_id, "PASS", description))
        except Exception as error:  # Continue so the run reports every independent case.
            self.results.append((test_id, "FAIL", f"{description}: {error}"))

    def create_account(self, plan):
        run_id = uuid.uuid4().hex[:10]
        response = self.request("POST", "/users/", (201,), json={
            "name": f"Upload smoke test {plan}",
            "email": f"upload-smoke-{plan}-{run_id}@example.invalid",
            "password": f"Temp-{uuid.uuid4()}-Aa9!",
            "type": plan,
        }).json()
        account = {
            "user": response["user"]["_id"],
            "token": response["jwt"],
            "plan": plan,
            "project": None,
            "video_ids": [],
        }
        account["headers"] = {"Authorization": f"Bearer {account['token']}"}
        self.accounts.append(account)
        project = self.request(
            "POST", f"/projects/{account['user']}", (201,),
            headers=account["headers"], json={"name": f"Upload smoke {run_id}"},
        ).json()
        account["project"] = project["_id"]
        return account

    def current_version(self, account):
        project = self.request(
            "GET", f"/projects/{account['user']}/{account['project']}", (200,),
            headers=account["headers"],
        ).json()
        return int(project["version"])

    def precheck(self, account, name, size, *, share=None, expected=(200,), headers=None):
        path = f"/projects/{account['user']}/{account['project']}/video/check"
        if share:
            path += f"?share={share}"
        return self.request(
            "POST", path, expected,
            headers={**(headers or account["headers"]), "X-Project-Version": str(self.current_version(account))},
            json={"name": name, "size": size},
        )

    def create_clip(self, path, codec):
        command = [
            "ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error", "-y",
            "-f", "lavfi", "-i", "color=c=black:s=32x32:r=1", "-t", "1",
            "-an", "-c:v", codec,
        ]
        if codec == "libx264":
            command += ["-pix_fmt", "yuv420p"]
        command.append(str(path))
        subprocess.run(command, check=True)

    def upload(self, account, path, name):
        with path.open("rb") as stream:
            return self.request(
                "POST", f"/projects/{account['user']}/{account['project']}/video", (201,),
                headers={
                    **account["headers"],
                    "X-Project-Version": str(self.current_version(account)),
                    "X-Video-Name": name,
                    "X-Video-Size": str(path.stat().st_size),
                },
                files={"video": (name, stream, "video/mp4")},
            ).json()

    def run(self):
        if shutil.which("ffmpeg") is None:
            raise SystemExit("Required command not found: ffmpeg")

        owner = self.create_account("free")
        premium = self.create_account("premium")
        collaborator = self.create_account("free")

        self.check("TST-UPL-03", "Pedido sem autenticação devolve HTTP 401", lambda:
            self.request(
                "POST", f"/projects/{owner['user']}/{owner['project']}/video/check", (401,),
                json={"name": "x.mp4", "size": 1},
            ))

        def check_exact_limits():
            for plan_account, plan in ((owner, "free"), (premium, "premium")):
                accepted = self.precheck(plan_account, f"at-limit-{plan}.mp4", LIMITS[plan])
                assert accepted.json().get("accepted") is True

        def check_above_limits():
            for plan_account, plan in ((owner, "free"), (premium, "premium")):
                rejected = self.precheck(
                    plan_account, f"over-limit-{plan}.mp4", LIMITS[plan] + 1, expected=(413,),
                )
                assert rejected.json().get("code") == "VIDEO_TOO_LARGE"

        self.check(
            "TST-UPL-06",
            "Tamanhos no limite Free/Premium aceites pela pré-validação, sem transferir vídeo",
            check_exact_limits,
        )
        self.check(
            "TST-UPL-07",
            "Tamanhos +1 byte acima dos limites Free/Premium devolvem HTTP 413",
            check_above_limits,
        )

        def check_invalid_metadata():
            bad_name = self.precheck(owner, "not-video.mov", 100, expected=(400,))
            assert bad_name.json().get("code") == "INVALID_VIDEO"
            bad_size = self.precheck(owner, "empty.mp4", 0, expected=(400,))
            assert bad_size.json().get("code") == "INVALID_VIDEO"

        self.check("TST-UPL-02", "Pré-validação rejeita extensão e tamanho inválidos", check_invalid_metadata)

        def check_permissions():
            links = {}
            for permission in ("read", "edit"):
                response = self.request(
                    "POST", f"/projects/{owner['user']}/{owner['project']}/share", (201,),
                    headers={**owner["headers"], "X-Project-Version": str(self.current_version(owner))},
                    json={"permission": permission},
                )
                links[permission] = response.json()["id"]
            denied = self.precheck(
                owner, "read.mp4", 100, share=links["read"], expected=(403,),
                headers=collaborator["headers"],
            )
            assert denied.json().get("code") == "ACCESS_FORBIDDEN"
            accepted = self.precheck(
                owner, "edit.mp4", 100, share=links["edit"], expected=(200,),
                headers=collaborator["headers"],
            )
            assert accepted.json().get("accepted") is True

        self.check("TST-UPL-04", "Partilha read é recusada e partilha edit é aceite", check_permissions)

        with tempfile.TemporaryDirectory(prefix="picturas-upload-smoke-") as temp_dir:
            temp = Path(temp_dir)
            fake = temp / "fake.mp4"
            fake.write_bytes(b"not an MP4 file")

            def reject_fake_mp4():
                with fake.open("rb") as stream:
                    response = self.request(
                        "POST", f"/projects/{owner['user']}/{owner['project']}/video", (415,),
                        headers={
                            **owner["headers"], "X-Project-Version": str(self.current_version(owner)),
                            "X-Video-Name": "fake.mp4", "X-Video-Size": str(fake.stat().st_size),
                        },
                        files={"video": ("fake.mp4", stream, "video/mp4")},
                    )
                assert response.json().get("code") == "INVALID_MP4"

            self.check("TST-UPL-05", "Conteúdo falso declarado como MP4 devolve HTTP 415", reject_fake_mp4)

            non_h264 = temp / "non-h264.mp4"
            self.create_clip(non_h264, "mpeg4")

            def reject_non_h264():
                with non_h264.open("rb") as stream:
                    response = self.request(
                        "POST", f"/projects/{owner['user']}/{owner['project']}/video", (415,),
                        headers={
                            **owner["headers"], "X-Project-Version": str(self.current_version(owner)),
                            "X-Video-Name": "non-h264.mp4", "X-Video-Size": str(non_h264.stat().st_size),
                        },
                        files={"video": ("non-h264.mp4", stream, "video/mp4")},
                    )
                    assert response.json().get("code") == "INVALID_MP4"

            self.check("TST-UPL-05", "MP4 com codec MPEG-4 em vez de H.264 devolve HTTP 415", reject_non_h264)

            valid = temp / "valid-h264.mp4"
            self.create_clip(valid, "libx264")
            uploaded_id = None

            def upload_small_valid_video():
                nonlocal uploaded_id
                uploaded = self.upload(owner, valid, f"valid-{uuid.uuid4().hex[:8]}.mp4")
                uploaded_id = uploaded["id"]
                owner["video_ids"].append(uploaded_id)
                project = self.request(
                    "GET", f"/projects/{owner['user']}/{owner['project']}", (200,),
                    headers=owner["headers"],
                ).json()
                assert any(item.get("id") == uploaded_id for item in project.get("videos", []))

            self.check(
                "TST-UPL-08",
                "Upload MP4/H.264 pequeno conclui e fica associado ao projeto",
                upload_small_valid_video,
            )

            if uploaded_id:
                def reject_duplicate_name():
                    name = next(item["name"] for item in self.request(
                        "GET", f"/projects/{owner['user']}/{owner['project']}", (200,),
                        headers=owner["headers"],
                    ).json()["videos"] if item.get("id") == uploaded_id)
                    response = self.precheck(owner, name, valid.stat().st_size, expected=(409,))
                    assert response.json().get("code") == "VIDEO_NAME_EXISTS"

                self.check("TST-UPL-10", "Nome de vídeo repetido no projeto é rejeitado", reject_duplicate_name)
            else:
                self.results.append(("TST-UPL-10", "SKIP", "Upload bem-sucedido necessário para preparar a duplicação"))

        self.cleanup()
        for test_id, status, description in self.results:
            print(f"{status} {test_id}: {description}")
        failures = [item for item in self.results if item[1] == "FAIL"]
        skips = [item for item in self.results if item[1] == "SKIP"]
        print(f"Resumo: {len(self.results) - len(failures) - len(skips)} passou; {len(failures)} falhou; {len(skips)} ignorado.")
        if failures:
            raise SystemExit(1)

    def cleanup(self):
        errors = []
        for account in reversed(self.accounts):
            user_id = account["user"]
            try:
                if account["project"]:
                    project = self.request(
                        "GET", f"/projects/{user_id}/{account['project']}", (200,), headers=account["headers"],
                    ).json()
                    for video in project.get("videos", []):
                        video_id = video.get("id") or video.get("_id")
                        if video_id:
                            self.request(
                                "DELETE", f"/projects/{user_id}/{account['project']}/video/{video_id}", (204,),
                                headers={**account["headers"], "X-Project-Version": str(project["version"])},
                            )
                            project = self.request(
                                "GET", f"/projects/{user_id}/{account['project']}", (200,), headers=account["headers"],
                            ).json()
                self.request("DELETE", f"/users/{user_id}", (204,), headers=account["headers"])
            except Exception as error:
                errors.append(f"{user_id}: {error}")
        if errors:
            raise RuntimeError("Could not clean up temporary test accounts: " + "; ".join(errors))
        self.accounts.clear()


if __name__ == "__main__":
    suite = UploadSmokeTest()
    try:
        suite.run()
    finally:
        if suite.accounts:
            suite.cleanup()
