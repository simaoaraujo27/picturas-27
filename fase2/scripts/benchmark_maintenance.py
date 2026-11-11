"""Run three maintenance scenarios in disposable copies of the baseline."""

import json
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASELINE = "ab3ae9cf8efcfa444e9599f8e291551c5930c289"
FILES = ["Tools/video/subtitles.py", "Tools/video/frame_extraction.py",
         "Tools/video/effects.py", "Tools/brightness/brightness.py",
         "projects/utils/video.js"]


def git(*args):
    return subprocess.run(["git", *args], cwd=ROOT, check=True, capture_output=True, text=True).stdout


def replace(path, old, new):
    text = path.read_text()
    if text.count(old) != 1:
        raise ValueError(f"Expected one occurrence of {old!r} in {path}")
    path.write_text(text.replace(old, new))


def run_case(name, changes, acceptance):
    with tempfile.TemporaryDirectory(prefix=f"picturas-{name}-") as tmp:
        base, work = Path(tmp) / "base", Path(tmp) / "work"
        for relative in FILES:
            original = git("show", f"{BASELINE}:{relative}")
            for folder in (base, work):
                path = folder / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(original)
        for relative, old, new in changes:
            replace(work / relative, old, new)
        script = "import sys; sys.path.insert(0, sys.argv[1]); " + acceptance
        subprocess.run([sys.executable, "-B", "-c", script, str(work / "Tools/video")], check=True,
                       cwd=work, capture_output=True, text=True)
        diff = subprocess.run(["git", "diff", "--no-index", "--name-only", str(base), str(work)],
                              capture_output=True, text=True)
        if diff.returncode not in (0, 1):
            raise RuntimeError(diff.stderr)
        files = sorted(str(Path(line).relative_to(work)) for line in diff.stdout.splitlines()
                       if line.endswith((".py", ".js")))
        services = sorted({"video_tool" if f.startswith("Tools/video/") else
                           "brightness_tool" if f.startswith("Tools/brightness/") else "projects"
                           for f in files})
        return {"scenario": name, "changed_existing_modules": files,
                "changed_existing_services": services, "new_modules": [],
                "configuration_files": [], "test_files": [], "acceptance": "passed",
                "time": "not measured; execution assisted by Codex"}


def main():
    if git("rev-parse", BASELINE).strip() != BASELINE:
        raise ValueError("Baseline commit is unavailable")
    results = [
        run_case("caption-font-size", [
            ("Tools/video/subtitles.py", "FontSize=20", "FontSize=22")],
            "import subtitles; assert 'FontSize=22' in __import__('inspect').getsource(subtitles.caption_video)"),
        run_case("frame-count-limit", [
            ("Tools/video/frame_extraction.py", "MAX_FRAMES = 100", "MAX_FRAMES = 80"),
            ("Tools/video/frame_extraction.py", "integer between 1 and 100", "integer between 1 and 80"),
            ("Tools/video/frame_extraction.py", "more than 100 frames", "more than 80 frames"),
            ("projects/utils/video.js", "params.count > 100", "params.count > 80"),
            ("projects/utils/video.js", "integer between 1 and 100", "integer between 1 and 80")],
            "from frame_extraction import validate_params, InvalidExtraction; "
            "assert validate_params({'count': 80}) == ('count', 80, 'png'); "
            "assert 'params.count > 80' in open('projects/utils/video.js').read(); "
            "\ntry: validate_params({'count': 81}); raise AssertionError('81 accepted')"
            "\nexcept InvalidExtraction: pass"),
        run_case("shared-brightness-rule", [
            ("Tools/video/effects.py", "enhance(float(brightness))", "enhance(float(brightness) * 0.9)"),
            ("Tools/brightness/brightness.py", "enhance(brightness_factor)", "enhance(brightness_factor * 0.9)")],
            "from PIL import Image; import effects; "
            "im=Image.new('RGB',(1,1),(100,100,100)); "
            "assert effects.brightness(im,1).getpixel((0,0)) == (90,90,90); "
            "s=open('Tools/brightness/brightness.py').read(); "
            "assert 'enhance(brightness_factor * 0.9)' in s"),
    ]
    print(json.dumps({"baseline": BASELINE, "method": "git show into isolated temporary directories; git diff --no-index", "results": results}, indent=2))


if __name__ == "__main__":
    main()
