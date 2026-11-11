"""Measure fixed video cases inside the video_tool image."""

import hashlib
import json
import statistics
import sys
import tempfile
import time
from pathlib import Path

from video_processor import InvalidVideo, process_video


def main():
    manifest = json.loads(Path(sys.argv[1]).read_text())
    samples = Path(sys.argv[2])
    results = []
    for case in manifest["cases"]:
        if case["name"] == "subtitles-real-speech":
            continue  # Model-backed case is measured separately.
        source = samples / Path(case["input"]).name
        if hashlib.sha256(source.read_bytes()).hexdigest() != case["sha256"]:
            raise ValueError(f"Hash mismatch: {source}")
        times = []
        for _ in range(3):
            with tempfile.TemporaryDirectory(prefix="video-case-") as work:
                output = str(Path(work) / "out.mp4")
                started = time.perf_counter()
                try:
                    info = process_video(str(source), output, case["pipeline"], preview=case["preview"])
                    if case["name"] == "invalid-input":
                        raise AssertionError("Corrupt video was accepted")
                    status = "success"
                    details = {key: info.get(key) for key in ("output_type", "duration", "width", "height", "has_audio", "frames")}
                except InvalidVideo:
                    if case["name"] != "invalid-input":
                        raise
                    if Path(output).exists():
                        raise AssertionError("Partial output exists")
                    status, details = "expected_invalid_video", {}
                times.append(round(time.perf_counter() - started, 3))
        results.append({"case": case["name"], "status": status, "seconds": times,
                        "median_seconds": statistics.median(times), "result": details})
    print(json.dumps({"source_commit": manifest["source_commit"], "results": results}, indent=2))


if __name__ == "__main__":
    main()
