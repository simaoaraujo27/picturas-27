"""PictuRAS video subtitles processing (microservice).

Runs Faster-Whisper CPU speech recognition and burns captions into the video
using FFmpeg. Can process stages if temporal tools (trim/speed) are interleaved.
"""
import json
import os
import subprocess
import tempfile
from fractions import Fraction
from pathlib import Path
from PIL import Image

from effects import SUPPORTED, UnsupportedEffect, apply_frame_effects
from subtitles import caption_video

PREVIEW_SECONDS = float(os.getenv("VIDEO_PREVIEW_SECONDS", "3"))
MIN_SPEED = 0.25
MAX_SPEED = 5.0


class InvalidVideo(Exception):
    """File is not a readable video (corrupted, no video stream, ...)."""


class InvalidTrim(Exception):
    """Trim parameters outside the video duration or with end before start."""


class InvalidSpeed(Exception):
    """Speed factor outside the allowed range or not numeric."""


class ProcessingError(Exception):
    """ffmpeg failure while decoding or encoding."""


def probe(path: str, prefer_video_duration: bool = False) -> dict:
    """Reads the video characteristics with ffprobe."""
    cmd = [
        "ffprobe", "-v", "error", "-print_format", "json",
        "-show_format", "-show_streams", path,
    ]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        raise InvalidVideo(f"Unreadable video file: {res.stderr.strip()[:200]}")

    data = json.loads(res.stdout or "{}")
    streams = data.get("streams", [])
    video = next((s for s in streams if s.get("codec_type") == "video"), None)
    audio = next((s for s in streams if s.get("codec_type") == "audio"), None)
    if video is None:
        raise InvalidVideo("The file has no video stream")

    fmt = data.get("format", {})
    duration = float(
        (video.get("duration") if prefer_video_duration else None)
        or fmt.get("duration") or video.get("duration") or 0
    )
    if duration <= 0:
        raise InvalidVideo("Could not determine the video duration")

    fps_str = video.get("avg_frame_rate") or video.get("r_frame_rate") or "0/1"
    try:
        fps = float(Fraction(fps_str))
    except (ZeroDivisionError, ValueError):
        fps = 0.0
    if fps <= 0:
        fps_str, fps = "25/1", 25.0

    return {
        "duration": duration,
        "width": int(video["width"]),
        "height": int(video["height"]),
        "fps": fps,
        "fps_str": fps_str,
        "video_codec": video.get("codec_name"),
        "audio_codec": audio.get("codec_name") if audio else None,
        "has_audio": audio is not None,
        "format_name": fmt.get("format_name"),
        "size_bytes": int(fmt.get("size") or os.path.getsize(path)),
    }


def resolve_trim(tools: list, duration: float) -> tuple:
    start, end = 0.0, float(duration)
    for tool in tools:
        if tool.get("procedure") != "trim":
            continue
        params = tool.get("params") or {}
        try:
            t_start = float(params.get("start", 0))
            t_end = float(params.get("end"))
        except (TypeError, ValueError):
            raise InvalidTrim("Trim requires numeric start and end (seconds)")
        length = end - start
        if t_start < 0 or t_end <= t_start:
            raise InvalidTrim("Trim end must be after its start")
        if t_start >= length or t_end > length + 1e-3:
            raise InvalidTrim(
                f"Trim [{t_start}, {t_end}] s is outside the video duration ({length:.2f} s)"
            )
        start, end = start + t_start, start + min(t_end, length)
    return start, end


def resolve_speed(tools: list) -> float:
    factor = 1.0
    for tool in tools:
        if tool.get("procedure") != "speed":
            continue
        try:
            f = float((tool.get("params") or {}).get("factor"))
        except (TypeError, ValueError):
            raise InvalidSpeed("Speed requires a numeric factor")
        if not MIN_SPEED <= f <= MAX_SPEED:
            raise InvalidSpeed(f"Speed must be between {MIN_SPEED}x and {MAX_SPEED}x (got {f}x)")
        factor *= f
    return factor


def atempo_chain(factor: float) -> str:
    stages = []
    while factor > 2.0:
        stages.append(2.0)
        factor /= 2.0
    while factor < 0.5:
        stages.append(0.5)
        factor /= 0.5
    stages.append(factor)
    return ",".join(f"atempo={s:.6f}" for s in stages)


def validate_tools(tools: list) -> None:
    for tool in tools:
        if tool.get("procedure") not in SUPPORTED | {"subtitles"}:
            raise UnsupportedEffect(
                f"Effect '{tool.get('procedure')}' is not available for video_subtitles"
            )


def _process_video(input_path: str, output_path: str, tools: list,
                   progress_cb=None, preview: bool = False) -> dict:
    validate_tools(tools)
    speed = resolve_speed(tools)
    info = probe(input_path)
    start, end = resolve_trim(tools, info["duration"])
    if preview:
        end = min(end, start + PREVIEW_SECONDS * speed)
    duration = end - start

    w, h = info["width"], info["height"]
    frame_bytes = w * h * 3
    expected_frames = max(1, round(duration / speed * info["fps"]))

    decode_cmd = [
        "ffmpeg", "-v", "error", "-ss", f"{start:.3f}", "-t", f"{duration:.3f}",
        "-i", input_path, "-map", "0:v:0", "-an",
        "-vf", f"setpts=PTS/{speed:.6f},fps={info['fps_str']}",
        "-f", "rawvideo", "-pix_fmt", "rgb24", "-",
    ]

    os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
    tmp_out = output_path + ".part.mp4"
    dec_err = tempfile.TemporaryFile()
    enc_err = tempfile.TemporaryFile()

    try:
        dec = subprocess.Popen(decode_cmd, stdout=subprocess.PIPE, stderr=dec_err)
        enc = None
        frames = 0
        last_pct = -1

        while True:
            raw = dec.stdout.read(frame_bytes)
            if not raw or len(raw) < frame_bytes:
                break

            img = Image.frombytes("RGB", (w, h), raw)
            img = apply_frame_effects(img, tools)

            if enc is None:
                enc = _start_encoder(input_path, tmp_out, img.size, info, start, duration, speed, enc_err)

            enc.stdin.write(img.tobytes())
            frames += 1

            if progress_cb and frames % 10 == 0:
                pct = min(99, int(frames / expected_frames * 100))
                if pct != last_pct:
                    last_pct = pct
                    progress_cb(pct)

        dec.wait()
        if dec.returncode != 0:
            raise ProcessingError(f"ffmpeg decode error: {_read(dec_err)}")

        if enc is not None:
            enc.stdin.close()
            enc.wait()
            if enc.returncode != 0:
                raise ProcessingError(f"ffmpeg encode error: {_read(enc_err)}")

        if frames == 0:
            raise ProcessingError("No frames could be decoded from the video")

        os.replace(tmp_out, output_path)

    except Exception:
        if os.path.exists(tmp_out):
            os.remove(tmp_out)
        raise
    finally:
        dec_err.close()
        enc_err.close()

    if progress_cb:
        progress_cb(100)

    result = probe(output_path)
    result["frames"] = frames
    return result


def _start_encoder(input_path, out_path, size, info, start, duration, speed, err_file):
    ow, oh = size
    cmd = [
        "ffmpeg", "-y", "-v", "error",
        "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{ow}x{oh}",
        "-r", info["fps_str"], "-i", "-",
    ]
    if info["has_audio"]:
        cmd += ["-ss", f"{start:.3f}", "-t", f"{duration:.3f}", "-i", input_path,
                "-map", "0:v:0", "-map", "1:a:0", "-c:a", "aac", "-b:a", "128k"]
        if abs(speed - 1.0) > 1e-6:
            cmd += ["-af", atempo_chain(speed)]
    else:
        cmd += ["-map", "0:v:0"]
    cmd += [
        "-vf", "pad=ceil(iw/2)*2:ceil(ih/2)*2",
        "-c:v", "libx264", "-preset", "veryfast", "-crf", "23",
        "-pix_fmt", "yuv420p", "-movflags", "+faststart",
        "-shortest", "-f", "mp4", out_path,
    ]
    return subprocess.Popen(cmd, stdin=subprocess.PIPE, stderr=err_file)


def _read(f) -> str:
    f.seek(0)
    return f.read().decode(errors="replace").strip()[-500:]


def process_video(input_path: str, output_path: str, tools=None,
                  progress_cb=None, preview: bool = False) -> dict:
    if not tools:
        tools = [{"procedure": "subtitles", "params": {}}]
    validate_tools(tools)

    if not any(t.get("procedure") == "subtitles" for t in tools):
        return _process_video(input_path, output_path, tools, progress_cb, preview)

    stages, pending = [], []
    for tool in tools:
        if tool.get("procedure") == "subtitles":
            if pending or not stages:
                stages.append(pending)
                pending = []
            stages.append(None)
        else:
            pending.append(tool)
    if pending:
        stages.append(pending)

    preview_stage = max(
        (index for index, stage in enumerate(stages)
         if stage is not None and any(
             tool.get("procedure") in {"trim", "speed"} for tool in stage)),
        default=0,
    )

    target = Path(output_path).resolve()
    target.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="captions-", dir=target.parent) as work:
        current = input_path
        for index, stage in enumerate(stages):
            next_path = str(Path(work) / f"stage-{index}.mp4")

            def progress(percent):
                if progress_cb:
                    progress_cb(min(99, int((index + percent / 100) * 100 / len(stages))))

            progress(0)
            if stage is None:
                caption_video(current, next_path, probe(current), progress)
            else:
                _process_video(current, next_path, stage, progress,
                               preview=preview and index == preview_stage)
            current = next_path
        result = probe(current)
        result["frames"] = round(result["duration"] * result["fps"])
        os.replace(current, target)
    if progress_cb:
        progress_cb(100)
    return result
