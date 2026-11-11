"""Collect video baseline metrics with explicit production-file exclusions."""

import argparse
import hashlib
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "fase2/documentacao/video-cases.json"


def run(command, output):
    result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
    output.write_text(result.stdout + result.stderr)
    if result.returncode:
        raise RuntimeError(f"Command failed ({result.returncode}): {' '.join(map(str, command))}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("output", type=Path)
    parser.add_argument("--python", default=sys.executable)
    parser.add_argument("--jscpd", default="jscpd")
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    cases = json.loads(MANIFEST.read_text())
    for case in cases["cases"]:
        path = ROOT / case["input"]
        actual = hashlib.sha256(path.read_bytes()).hexdigest()
        if actual != case["sha256"]:
            raise ValueError(f"Input hash changed: {path}")
    production = sorted((ROOT / "Tools/video").glob("*.py"))
    if not production:
        raise ValueError("No production modules found")
    # Only top-level production files: excludes tests, venvs, caches, and generated files.
    run([args.python, str(ROOT / "fase2/scripts/collect_video_baseline.py")], output / "static.json")
    for metric in ("cc", "raw"):
        run([args.python, "-m", "radon", metric, *map(str, production), "-j"], output / f"radon-{metric}.json")
    run([args.jscpd, "Tools/video", "--pattern", "**/*.py", "--ignore", "**/tests/**,**/.venv/**,**/__pycache__/**", "--reporters", "json", "--output", str(output), "--silent"], output / "jscpd-command.txt")
    run([sys.executable, str(ROOT / "fase2/scripts/test_video_docker.py"), str(output / "pytest-docker.txt")], output / "docker-test-command.txt")
    (output / "commands.json").write_text(json.dumps({"python": args.python, "jscpd": args.jscpd, "production_files": [str(p.relative_to(ROOT)) for p in production], "manifest": str(MANIFEST.relative_to(ROOT))}, indent=2))


if __name__ == "__main__":
    main()
