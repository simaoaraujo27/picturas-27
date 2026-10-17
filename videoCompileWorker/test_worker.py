"""Tests for the compile worker. Needs ffmpeg/ffprobe; no network, RabbitMQ or Docker.

A small in-process HTTP server plays the role of the projects service
(/internal/compile/...) and of the media storage (/video/...).
"""
import json
import os
import re
import subprocess
import tempfile
import threading
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

os.environ.setdefault('INTERNAL_VIDEO_KEY', 'test-key')
import worker  # noqa: E402

OWNER, PROJECT = 'a' * 24, 'b' * 24
JOB, RESULT = 'c' * 24, 'd' * 24
BLUE_ID, RED_ID, BAD_ID, MISSING_ID = '1' * 24, '2' * 24, '3' * 24, '4' * 24


def make_video(path, color, seconds, size, with_audio):
    cmd = ['ffmpeg', '-y', '-loglevel', 'error', '-f', 'lavfi',
           '-i', f'color=c={color}:s={size}:d={seconds}:r=25']
    if with_audio:
        cmd += ['-f', 'lavfi', '-i', 'anullsrc=r=44100:cl=stereo', '-t', str(seconds), '-c:a', 'aac']
    else:
        cmd += ['-an']
    subprocess.run(cmd + ['-c:v', 'libx264', '-pix_fmt', 'yuv420p', str(path)], check=True)


def probe_json(path):
    out = subprocess.run(['ffprobe', '-v', 'error', '-show_entries',
                          'format=duration:stream=codec_name,codec_type,width,height',
                          '-of', 'json', str(path)], capture_output=True, text=True, check=True).stdout
    return json.loads(out)


def first_pixel(path):
    out = subprocess.run(['ffmpeg', '-loglevel', 'error', '-i', str(path), '-frames:v', '1',
                          '-vf', 'scale=1:1', '-f', 'rawvideo', '-pix_fmt', 'rgb24', 'pipe:1'],
                         capture_output=True, check=True).stdout
    return tuple(out[:3])


class Fake(ThreadingHTTPServer):
    def __init__(self, files, sources):
        super().__init__(('127.0.0.1', 0), Handler)
        self.files, self.sources = files, sources
        self.state = 'PROCESSING'
        self.uploaded = {}
        self.calls = []

    @property
    def url(self):
        return f'http://127.0.0.1:{self.server_address[1]}'


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def send_json(self, code, body=None):
        data = json.dumps(body).encode() if body is not None else b''
        self.send_response(code)
        self.send_header('Content-Length', str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def body(self):
        n = int(self.headers.get('Content-Length') or 0)
        return self.rfile.read(n)

    def do_GET(self):
        s = self.server
        if m := re.fullmatch(r'/internal/compile/(\w+)', self.path):
            return self.send_json(200, {'state': s.state, 'attempt': 1})
        if m := re.fullmatch(r'/video/\w+/\w+/(\w+)/url', self.path):
            if m[1] not in s.files:
                return self.send_json(404, {'code': 'VIDEO_NOT_FOUND'})
            return self.send_json(200, {'url': f'{s.url}/files/{m[1]}'})
        if m := re.fullmatch(r'/files/(\w+)', self.path):
            data = Path(s.files[m[1]]).read_bytes()
            self.send_response(200)
            self.send_header('Content-Length', str(len(data)))
            self.end_headers()
            return self.wfile.write(data)
        self.send_json(404, {})

    def do_POST(self):
        s = self.server
        raw = self.body()
        payload = json.loads(raw) if raw else {}
        s.calls.append((self.path, payload))
        if self.path.endswith('/claim'):
            return self.send_json(200, {'attempt': 1, 'ownerId': OWNER, 'projectId': PROJECT,
                                        'resultId': RESULT, 'sourceIds': s.sources})
        if self.path.endswith('/complete'):
            return self.send_json(200, {})
        self.send_json(204)

    def do_PUT(self):
        self.server.uploaded[self.path] = self.body()
        self.send_json(200, {})

    def do_DELETE(self):
        self.server.uploaded.pop(self.path, None)
        self.send_json(204)


class TestCompileWorker(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        t = Path(self.tmp.name)
        make_video(t / 'blue.mp4', 'blue', 3, '640x360', with_audio=False)  # no audio, bigger
        make_video(t / 'red.mp4', 'red', 2, '320x240', with_audio=True)
        (t / 'bad.mp4').write_bytes(b'not a video' * 100)
        self.files = {BLUE_ID: t / 'blue.mp4', RED_ID: t / 'red.mp4', BAD_ID: t / 'bad.mp4'}
        self.server = None
        worker.POLL_SECONDS = 0.2

    def tearDown(self):
        if self.server:
            self.server.shutdown()
            self.server.server_close()
        self.tmp.cleanup()

    def start(self, sources):
        self.server = Fake(self.files, sources)
        threading.Thread(target=self.server.serve_forever, daemon=True).start()
        worker.API = worker.STORAGE = self.server.url

    def uploaded_path(self):
        out = Path(self.tmp.name) / 'uploaded.mp4'
        out.write_bytes(self.server.uploaded[f'/video/{OWNER}/{PROJECT}/{RESULT}'])
        return out

    def test_compiles_in_order_with_mixed_formats(self):
        self.start([BLUE_ID, RED_ID])
        worker.process(JOB, {})

        out = self.uploaded_path()
        info = probe_json(out)
        self.assertAlmostEqual(float(info['format']['duration']), 5.0, delta=0.4)
        video = next(s for s in info['streams'] if s['codec_type'] == 'video')
        audio = next(s for s in info['streams'] if s['codec_type'] == 'audio')
        self.assertEqual((video['codec_name'], audio['codec_name']), ('h264', 'aac'))
        self.assertEqual((video['width'], video['height']), (640, 360))
        r, _g, b = first_pixel(out)
        self.assertGreater(b, r)  # starts with the blue video

        paths = [p for p, _ in self.server.calls]
        self.assertIn(f'/internal/compile/{JOB}/storage/reserve', paths)
        complete = dict(self.server.calls)[f'/internal/compile/{JOB}/complete']
        self.assertEqual((complete['width'], complete['height']), (640, 360))
        self.assertAlmostEqual(complete['duration'], 5.0, delta=0.4)
        self.assertGreater(complete['size'], 0)

    def test_order_can_be_swapped_and_repeated(self):
        self.start([RED_ID, BLUE_ID, RED_ID])
        worker.process(JOB, {})
        out = self.uploaded_path()
        self.assertAlmostEqual(float(probe_json(out)['format']['duration']), 7.0, delta=0.5)
        r, _g, b = first_pixel(out)
        self.assertGreater(r, b)  # starts with the red video

    def test_unreadable_video_fails_without_upload(self):
        self.start([BLUE_ID, BAD_ID])
        with self.assertRaises(ValueError) as ctx:
            worker.process(JOB, {})
        self.assertEqual(worker.error_code(ctx.exception), 'VIDEO_UNREADABLE')
        self.assertEqual(self.server.uploaded, {})

    def test_missing_video_fails_without_upload(self):
        self.start([BLUE_ID, MISSING_ID])
        with self.assertRaises(ValueError) as ctx:
            worker.process(JOB, {})
        self.assertEqual(worker.error_code(ctx.exception), 'VIDEO_UNREADABLE')
        self.assertEqual(self.server.uploaded, {})

    def test_cancelled_job_stops_and_uploads_nothing(self):
        self.start([BLUE_ID, RED_ID])
        self.server.state = 'CANCELLED'
        worker.process(JOB, {})
        self.assertEqual(self.server.uploaded, {})
        paths = [p for p, _ in self.server.calls]
        self.assertNotIn(f'/internal/compile/{JOB}/complete', paths)

    def test_needs_two_videos(self):
        self.start([BLUE_ID])
        with self.assertRaises(ValueError):
            worker.process(JOB, {})

    def test_total_length_limit(self):
        self.start([BLUE_ID, RED_ID])
        old, worker.MAX_TOTAL_SECONDS = worker.MAX_TOTAL_SECONDS, 4
        try:
            with self.assertRaises(ValueError) as ctx:
                worker.process(JOB, {})
            self.assertEqual(worker.error_code(ctx.exception), 'TOTAL_TOO_LONG')
        finally:
            worker.MAX_TOTAL_SECONDS = old
        self.assertEqual(self.server.uploaded, {})


if __name__ == '__main__':
    unittest.main()
