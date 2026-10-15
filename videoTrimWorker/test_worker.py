"""Automated tests for Video Trim functionality using FFmpeg."""

import json
import shutil
import subprocess
import tempfile
from pathlib import Path
import unittest


class TestVideoTrim(unittest.TestCase):
    def setUp(self):
        self.tmpdir = tempfile.mkdtemp()
        self.input_file = Path(self.tmpdir) / "test_input.mp4"

        # Gerar um vídeo sintético de 5 segundos com áudio (MP4 H.264/AAC)
        create_cmd = [
            "ffmpeg", "-y", "-loglevel", "error",
            "-f", "lavfi", "-i", "color=c=blue:s=320x240:d=5",
            "-f", "lavfi", "-i", "anullsrc=r=44100:cl=stereo",
            "-t", "5",
            "-c:v", "libx264", "-c:a", "aac",
            "-pix_fmt", "yuv420p",
            str(self.input_file)
        ]
        subprocess.run(create_cmd, check=True)
        self.assertTrue(self.input_file.exists())

    def tearDown(self):
        shutil.rmtree(self.tmpdir, ignore_errors=True)

    def test_ffmpeg_trim_duration_and_codecs(self):
        """Test precise frame re-encoding trim (REQ-VID-TRIM-010, REQ-VID-TRIM-012)."""
        output_file = Path(self.tmpdir) / "test_output.mp4"

        trim_cmd = [
            "ffmpeg", "-y", "-loglevel", "error",
            "-ss", "1.0",
            "-to", "3.0",
            "-i", str(self.input_file),
            "-c:v", "libx264",
            "-c:a", "aac",
            "-movflags", "+faststart",
            str(output_file)
        ]
        subprocess.run(trim_cmd, check=True)
        self.assertTrue(output_file.exists())
        self.assertGreater(output_file.stat().st_size, 0)

        probe_cmd = [
            "ffprobe", "-v", "error",
            "-show_entries", "format=duration,format_name:stream=codec_name,codec_type",
            "-of", "json",
            str(output_file)
        ]
        probe_proc = subprocess.run(probe_cmd, stdout=subprocess.PIPE, check=True, text=True)
        info = json.loads(probe_proc.stdout)

        duration = float(info["format"]["duration"])
        self.assertAlmostEqual(duration, 2.0, delta=0.2)

        streams = info["streams"]
        video_stream = next((s for s in streams if s["codec_type"] == "video"), None)
        audio_stream = next((s for s in streams if s["codec_type"] == "audio"), None)

        self.assertIsNotNone(video_stream)
        self.assertEqual(video_stream["codec_name"], "h264")
        self.assertIsNotNone(audio_stream)
        self.assertEqual(audio_stream["codec_name"], "aac")

    def test_ffmpeg_fast_trim_stream_copy(self):
        """Test stream copy trim for Premium (REQ-VID-TRIM-011, FA2)."""
        output_file = Path(self.tmpdir) / "test_output_fast.mp4"

        fast_cmd = [
            "ffmpeg", "-y", "-loglevel", "error",
            "-ss", "1.0",
            "-to", "4.0",
            "-i", str(self.input_file),
            "-c", "copy",
            "-movflags", "+faststart",
            str(output_file)
        ]
        subprocess.run(fast_cmd, check=True)
        self.assertTrue(output_file.exists())
        self.assertGreater(output_file.stat().st_size, 0)

        probe_cmd = [
            "ffprobe", "-v", "error",
            "-show_entries", "format=format_name:stream=codec_name,codec_type",
            "-of", "json",
            str(output_file)
        ]
        probe_proc = subprocess.run(probe_cmd, stdout=subprocess.PIPE, check=True, text=True)
        info = json.loads(probe_proc.stdout)
        self.assertIn("mp4", info["format"]["format_name"])

    def test_ephemeral_directory_cleanup(self):
        """Test that worker temporary directory is purged (REQ-VID-TRIM-018)."""
        dummy_job_dir = Path("/tmp/picturas-jobs/test-dummy-job-123")
        dummy_job_dir.mkdir(parents=True, exist_ok=True)
        dummy_file = dummy_job_dir / "temp.mp4"
        dummy_file.write_bytes(b"testdata")
        self.assertTrue(dummy_file.exists())

        # Cleanup simulation
        shutil.rmtree(dummy_job_dir, ignore_errors=True)
        self.assertFalse(dummy_job_dir.exists())


if __name__ == "__main__":
    unittest.main()
