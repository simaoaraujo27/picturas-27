"""Automated tests for Video Trim functionality using FFmpeg."""

import json
import subprocess
import tempfile
from pathlib import Path
import unittest


class TestVideoTrim(unittest.TestCase):
    def test_ffmpeg_trim_duration_and_codecs(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            input_file = Path(tmpdir) / "test_input.mp4"
            output_file = Path(tmpdir) / "test_output.mp4"

            # 1. Gerar um vídeo sintético de 4 segundos com áudio
            create_cmd = [
                "ffmpeg", "-y", "-loglevel", "error",
                "-f", "lavfi", "-i", "color=c=blue:s=320x240:d=4",
                "-f", "lavfi", "-i", "anullsrc=r=44100:cl=stereo",
                "-t", "4",
                "-c:v", "libx264", "-c:a", "aac",
                "-pix_fmt", "yuv420p",
                str(input_file)
            ]
            subprocess.run(create_cmd, check=True)
            self.assertTrue(input_file.exists())

            # 2. Executar o corte de t=1.0s até t=3.0s (duração esperada = 2.0s)
            trim_cmd = [
                "ffmpeg", "-y", "-loglevel", "error",
                "-ss", "1.0",
                "-to", "3.0",
                "-i", str(input_file),
                "-c:v", "libx264",
                "-c:a", "aac",
                "-movflags", "+faststart",
                str(output_file)
            ]
            subprocess.run(trim_cmd, check=True)
            self.assertTrue(output_file.exists())
            self.assertGreater(output_file.stat().st_size, 0)

            # 3. Analisar o vídeo recortado com ffprobe
            probe_cmd = [
                "ffprobe", "-v", "error",
                "-show_entries", "format=duration,format_name:stream=codec_name,codec_type",
                "-of", "json",
                str(output_file)
            ]
            probe_proc = subprocess.run(probe_cmd, stdout=subprocess.PIPE, check=True, text=True)
            info = json.loads(probe_proc.stdout)

            duration = float(info["format"]["duration"])
            # Permitir pequena tolerância de timestamp (0.1s)
            self.assertAlmostEqual(duration, 2.0, delta=0.2)

            # Verificar codecs
            streams = info["streams"]
            video_stream = next((s for s in streams if s["codec_type"] == "video"), None)
            audio_stream = next((s for s in streams if s["codec_type"] == "audio"), None)

            self.assertIsNotNone(video_stream)
            self.assertEqual(video_stream["codec_name"], "h264")
            self.assertIsNotNone(audio_stream)
            self.assertEqual(audio_stream["codec_name"], "aac")


if __name__ == "__main__":
    unittest.main()
