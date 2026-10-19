"""Test the actual speed worker with synthetic MP4s and mocked transport."""

import copy
import hashlib
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import MagicMock, patch

import worker


def interval(start, end, speed):
    return {"startTime": start, "endTime": end, "speed": speed}


def task():
    return {
        "procedure": "video_speed", "messageId": "request-speed-test",
        "parameters": {
            "ownerId": "a" * 24, "projectId": "b" * 24,
            "videoId": "c" * 24, "newVideoId": "d" * 24,
            "newVideoName": "speed.mp4", "intervals": [interval(2, 4, 2)],
            "callerId": "e" * 24, "projectVersion": 3,
        },
    }


def ffprobe(path):
    process = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries",
         "format=duration:stream=codec_name,codec_type,duration", "-of", "json", str(path)],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True, text=True,
    )
    return json.loads(process.stdout)


class TestValidation(unittest.TestCase):
    def test_invalid_intervals(self):
        cases = [
            [interval(2, 4, 0.25)], [interval(2, 4, 4)],
            [interval(-1, 4, 2)], [interval(4, 4, 2)], [interval(4, 2, 2)],
            [interval(2, 5, 2), interval(4, 6, 0.5)],
            [interval(9, 11, 2)], [interval(10, 11, 2)], [], None, {},
            [interval(float("nan"), 4, 2)], [interval(2, float("inf"), 2)],
            [interval(2, 4, float("nan"))], [interval(True, 4, 2)],
            [interval(2, 4, True)], [interval("2", 4, 2)], [None],
            [{"startTime": 2, "endTime": 4}],
        ]
        for intervals in cases:
            with self.subTest(intervals=intervals), self.assertRaises(ValueError):
                worker.validate_intervals(intervals, duration=10)

    def test_unsorted_adjacent_intervals_are_valid_without_mutation(self):
        intervals = [interval(4, 6, 0.5), interval(2, 4, 2)]
        original = copy.deepcopy(intervals)
        self.assertEqual(worker.validate_intervals(intervals, 10), list(reversed(intervals)))
        self.assertEqual(intervals, original)

    def test_invalid_envelopes(self):
        cases = [None, [], {}, {**task(), "procedure": "video_trim"}]
        for field, value in (("messageId", ""), ("messageId", "  "), ("messageId", 1),
                             ("parameters", [])):
            cases.append({**task(), field: value})
        for field in ("ownerId", "projectId", "videoId", "newVideoId"):
            cases.append({**task(), "parameters": {**task()["parameters"], field: "invalid"}})
        for field, value in (("newVideoName", "  "), ("newVideoName", None),
                             ("newVideoId", "c" * 24)):
            cases.append({**task(), "parameters": {**task()["parameters"], field: value}})
        for message in cases:
            with self.subTest(message=message), self.assertRaises(ValueError):
                worker.validate_message(message)

    def test_segments_cover_original_timeline(self):
        self.assertEqual(
            worker.build_segments([interval(6, 8, 0.5), interval(2, 4, 2)], 10),
            [interval(0, 2, 1), interval(2, 4, 2), interval(4, 6, 1),
             interval(6, 8, 0.5), interval(8, 10, 1)],
        )

    def test_probe_rejects_missing_video_or_invalid_duration(self):
        cases = [
            {"streams": [{"codec_type": "audio"}]},
            {"streams": [{"codec_type": "video", "codec_name": "h264", "duration": "nan"}],
             "format": {"format_name": "mov,mp4"}},
            {"streams": [{"codec_type": "video", "codec_name": "hevc", "duration": "10"}],
             "format": {"format_name": "mov,mp4"}},
        ]
        for info in cases:
            with self.subTest(info=info), patch("worker.subprocess.run") as run:
                run.return_value = SimpleNamespace(returncode=0, stdout=json.dumps(info))
                with self.assertRaises(ValueError):
                    worker.probe_video("input.mp4")


class TestVideoSpeed(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.directory = tempfile.TemporaryDirectory(prefix="picturas-speed-tests-")
        cls.addClassCleanup(cls.directory.cleanup)
        cls.root = Path(cls.directory.name)
        cls.with_audio = cls.root / "with-audio.mp4"
        cls.without_audio = cls.root / "without-audio.mp4"
        # Each two-second section has a different colour, to check segment order.
        video_filter = (
            "color=c=red:s=160x120:r=30:d=10,"
            "drawbox=c=green:t=fill:enable='gte(t,2)*lt(t,4)',"
            "drawbox=c=blue:t=fill:enable='gte(t,4)*lt(t,6)',"
            "drawbox=c=yellow:t=fill:enable='gte(t,6)*lt(t,8)',"
            "drawbox=c=white:t=fill:enable='gte(t,8)'"
        )
        subprocess.run([
            "ffmpeg", "-y", "-loglevel", "error", "-f", "lavfi", "-i", video_filter,
            "-f", "lavfi", "-i", "sine=frequency=440:sample_rate=48000:duration=10",
            "-t", "10", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-c:a", "aac",
            str(cls.with_audio),
        ], check=True)
        subprocess.run([
            "ffmpeg", "-y", "-loglevel", "error", "-i", str(cls.with_audio),
            "-map", "0:v:0", "-c:v", "copy", "-an", str(cls.without_audio),
        ], check=True)

    def render(self, intervals, expected_duration, has_audio=True):
        source = self.with_audio if has_audio else self.without_audio
        original_hash = hashlib.sha256(source.read_bytes()).digest()
        output = self.root / f"{self._testMethodName}.mp4"
        worker.process_video(source, output, intervals)
        self.assertEqual(hashlib.sha256(source.read_bytes()).digest(), original_hash)
        info = ffprobe(output)
        self.assertAlmostEqual(float(info["format"]["duration"]), expected_duration, delta=0.2)
        video = next(stream for stream in info["streams"] if stream["codec_type"] == "video")
        self.assertEqual(video["codec_name"], "h264")
        self.assertAlmostEqual(float(video["duration"]), expected_duration, delta=0.2)
        audio = [stream for stream in info["streams"] if stream["codec_type"] == "audio"]
        if has_audio:
            self.assertEqual(len(audio), 1)
            self.assertEqual(audio[0]["codec_name"], "aac")
            self.assertAlmostEqual(float(audio[0]["duration"]), expected_duration, delta=0.2)
        else:
            self.assertEqual(audio, [])
        return output

    def test_faster_interval(self):
        # Eight untouched seconds plus two seconds at 2x: 8 + 2/2 = 9.
        self.render([interval(2, 4, 2)], 9)

    def test_slower_interval(self):
        self.render([interval(2, 4, 0.5)], 12)

    def test_multiple_intervals_and_temporal_order(self):
        # Six untouched seconds plus 2/2 + 2/0.5 = 11.
        output = self.render([interval(6, 8, 0.5), interval(2, 4, 2)], 11)
        for timestamp, expected in (
            (1, (255, 0, 0)), (2.5, (0, 128, 0)), (4, (0, 0, 255)),
            (7, (255, 255, 0)), (10, (255, 255, 255)),
        ):
            with self.subTest(timestamp=timestamp):
                process = subprocess.run([
                    "ffmpeg", "-v", "error", "-ss", str(timestamp), "-i", str(output),
                    "-frames:v", "1", "-vf", "scale=1:1", "-pix_fmt", "rgb24",
                    "-f", "rawvideo", "pipe:1",
                ], stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
                self.assertEqual(len(process.stdout), 3)
                for actual, target in zip(process.stdout, expected):
                    self.assertAlmostEqual(actual, target, delta=10)

    def test_without_audio(self):
        self.render([interval(2, 4, 2), interval(6, 8, 0.5)], 11, has_audio=False)

    def test_full_duration_and_speed_one(self):
        self.render([interval(0, 10, 1)], 10)

    def test_adjacent_intervals_covering_entire_video(self):
        self.render([interval(0, 4, 2), interval(4, 10, 0.5)], 14)

    def test_interval_outside_actual_duration_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "duration"):
            worker.process_video(self.with_audio, self.root / "invalid.mp4", [interval(9, 11, 2)])
        self.assertFalse((self.root / "invalid.mp4").exists())

    def test_original_path_cannot_be_overwritten(self):
        with self.assertRaisesRegex(ValueError, "original"):
            worker.process_video(self.with_audio, self.with_audio, [interval(2, 4, 2)])

    def test_storage_and_result_contract(self):
        message = task()
        channel = MagicMock()
        signed = MagicMock()
        signed.json.return_value = {"url": "https://storage.test/signed.mp4"}
        signed.__enter__.return_value = signed
        download = MagicMock()
        download.iter_content.return_value = [b"", self.with_audio.read_bytes()]
        download.__enter__.return_value = download
        upload = MagicMock()
        upload.__enter__.return_value = upload
        uploaded = []

        def capture_upload(url, data, headers, timeout):
            uploaded.append((url, data.read(), headers, timeout, Path(data.name)))
            return upload

        with patch.dict(os.environ, {"INTERNAL_VIDEO_KEY": "test-key",
                                     "MEDIA_STORAGE_URL": "http://storage.test/"}), \
                patch("worker.requests.get", side_effect=[signed, download]) as get, \
                patch("worker.requests.put", side_effect=capture_upload) as put:
            worker.process_speed_task(channel, message)

        get.assert_any_call(
            f"http://storage.test/video/{'a' * 24}/{'b' * 24}/{'c' * 24}/url",
            headers={"X-Internal-Video-Key": "test-key"}, timeout=15,
        )
        get.assert_any_call("https://storage.test/signed.mp4", stream=True, timeout=(15, 300))
        put.assert_called_once()
        url, content, headers, timeout, path = uploaded[0]
        self.assertEqual(url, f"http://storage.test/video/{'a' * 24}/{'b' * 24}/{'d' * 24}")
        self.assertEqual(headers, {"X-Internal-Video-Key": "test-key",
                                  "Content-Type": "video/mp4", "Content-Length": str(len(content))})
        self.assertEqual(timeout, 300)
        self.assertFalse(path.exists())
        inspected = self.root / "uploaded.mp4"
        inspected.write_bytes(content)
        self.assertAlmostEqual(float(ffprobe(inspected)["format"]["duration"]), 9, delta=0.2)
        published = channel.basic_publish.call_args.kwargs
        self.assertEqual(published["exchange"], "picturas")
        self.assertEqual(published["routing_key"], "video_results_queue")
        self.assertEqual(published["properties"].delivery_mode, 2)
        result = json.loads(published["body"])
        self.assertEqual(result["procedure"], "video_speed")
        self.assertEqual(result["status"], "success")
        self.assertEqual(result["correlationId"], message["messageId"])
        self.assertTrue(result["messageId"].startswith("result-"))
        self.assertTrue(result["timestamp"].endswith("Z"))
        self.assertEqual(result["parameters"], {**message["parameters"], "size": len(content)})


class TestConsumer(unittest.TestCase):
    def test_non_finite_json_produces_a_valid_error_envelope(self):
        for number in ("NaN", "Infinity", "-Infinity", "1e999"):
            with self.subTest(number=number):
                channel = MagicMock()
                body = json.dumps(task()).replace('"startTime": 2', f'"startTime": {number}')
                with patch("worker.requests.get") as get:
                    self.assertFalse(worker.consume_task(
                        channel, SimpleNamespace(delivery_tag=7), None, body.encode(),
                    ))
                get.assert_not_called()
                channel.basic_nack.assert_called_once_with(delivery_tag=7, requeue=False)
                published = channel.basic_publish.call_args.kwargs["body"]
                result = json.loads(published, parse_constant=worker.parse_finite_float)
                self.assertEqual(result["status"], "error")
                self.assertEqual(result["error"]["code"], "VIDEO_SPEED_FAILED")

    def test_success_ack(self):
        channel = MagicMock()
        with patch("worker.process_speed_task"):
            self.assertTrue(worker.consume_task(channel, SimpleNamespace(delivery_tag=7), None,
                                                json.dumps(task()).encode()))
        channel.basic_ack.assert_called_once_with(delivery_tag=7)
        channel.basic_nack.assert_not_called()

    def test_errors_nack_and_publish(self):
        for body in (json.dumps(task()).encode(), b"invalid json", b"[]"):
            with self.subTest(body=body):
                channel = MagicMock()
                with patch("worker.process_speed_task", side_effect=RuntimeError("processing failed")):
                    self.assertFalse(worker.consume_task(channel, SimpleNamespace(delivery_tag=7), None, body))
                channel.basic_nack.assert_called_once_with(delivery_tag=7, requeue=False)
                channel.basic_ack.assert_not_called()
                result = json.loads(channel.basic_publish.call_args.kwargs["body"])
                self.assertEqual(result["status"], "error")
                self.assertEqual(result["procedure"], "video_speed")
                self.assertEqual(result["error"]["code"], "VIDEO_SPEED_FAILED")
                if body == json.dumps(task()).encode():
                    self.assertEqual(result["correlationId"], task()["messageId"])
                    self.assertEqual(result["parameters"], task()["parameters"])

    def test_once_stops_and_returns_failure_exit_code(self):
        for success in (True, False):
            with self.subTest(success=success):
                connection = MagicMock()
                channel = connection.channel.return_value

                def deliver():
                    callback = channel.basic_consume.call_args.kwargs["on_message_callback"]
                    callback(channel, SimpleNamespace(delivery_tag=7), None, b"{}")

                channel.start_consuming.side_effect = deliver
                with patch("sys.argv", ["worker.py", "--once"]), \
                        patch("worker.pika.BlockingConnection", return_value=connection), \
                        patch("worker.consume_task", return_value=success):
                    if success:
                        worker.main()
                    else:
                        with self.assertRaises(SystemExit) as raised:
                            worker.main()
                        self.assertEqual(raised.exception.code, 1)
                channel.stop_consuming.assert_called_once()
                connection.close.assert_called_once()
                channel.basic_qos.assert_called_once_with(prefetch_count=1)
                channel.queue_declare.assert_any_call(queue="video_speed_queue", durable=True)
                channel.queue_declare.assert_any_call(queue="video_results_queue", durable=True)


if __name__ == "__main__":
    unittest.main()
