"""Run the video worker test suite in a disposable Compose container."""

import argparse
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("output", type=Path, help="Path for the captured test log")
    parser.add_argument("--build", action="store_true", help="Rebuild video_tool first")
    args = parser.parse_args()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    if args.build:
        subprocess.run(["docker", "compose", "build", "video_tool"], cwd=ROOT, check=True)
    command = [
        "docker", "compose", "run", "--no-deps", "--rm",
        "-v", f"{ROOT / 'Tools/video/tests'}:/app/tests:ro",
        "--entrypoint", "sh", "video_tool", "-c",
        "python -m pip install --quiet pytest==9.2.0 && "
        "python --version && ffmpeg -version | head -n 1 && "
        "python -m pytest -q tests",
    ]
    with args.output.open("w") as log:
        result = subprocess.run(command, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT)
    if result.returncode:
        raise SystemExit(f"Docker tests failed ({result.returncode}); see {args.output}")
    print(f"Docker tests passed; log: {args.output}")


if __name__ == "__main__":
    main()
