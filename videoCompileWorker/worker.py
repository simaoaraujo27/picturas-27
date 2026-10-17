"""Consumes durable compile jobs; the projects service owns job state and authorization.

Same model as videoTrimWorker: the queue message only carries {"jobId": ...}; everything
else (claim, progress, storage reservation, completion, failure) goes through the
internal endpoints of the projects service (/internal/compile/<jobId>/...).

The worker downloads N source videos, normalizes them (resolution of the first video,
30 fps, yuv420p, stereo AAC; silence is generated for videos without audio) and
concatenates them in the requested order with FFmpeg (H.264 / AAC).
The original videos are only read; the result is uploaded only after FFmpeg succeeded.
"""
import json
import os
import re
import subprocess
import tempfile
import time
from pathlib import Path

import pika
import requests

KEY = os.environ['INTERNAL_VIDEO_KEY']
API = os.getenv('PROJECTS_URL', 'https://projects:9001').rstrip('/')
STORAGE = os.getenv('MEDIA_STORAGE_URL', 'http://img_storage:11000').rstrip('/')
HEADERS = {'X-Internal-Video-Key': KEY}
OBJECT_ID = re.compile(r'^[a-f0-9]{24}$')
QUEUE = 'video_compile_queue'

MIN_VIDEOS = 2
MAX_TOTAL_SECONDS = float(os.getenv('COMPILE_MAX_TOTAL_SECONDS', '3600'))
TIMEOUT_SECONDS = float(os.getenv('COMPILE_TIMEOUT_SECONDS', '1800'))
POLL_SECONDS = float(os.getenv('COMPILE_POLL_SECONDS', '1'))
OUTPUT_FPS = 30
AUDIO_RATE = 44100

SESSION = requests.Session()
SESSION.verify = False


def call(method, path, **kwargs):
    response = SESSION.request(method, API + path, headers=HEADERS, timeout=30, **kwargs)
    response.raise_for_status()
    return response.json() if response.content else None


def status(job_id):
    return call('GET', f'/internal/compile/{job_id}')


def active(job_id, attempt):
    current = status(job_id)
    return current['state'] == 'PROCESSING' and current['attempt'] == attempt


def error_code(error):
    if isinstance(error, requests.HTTPError):
        try:
            code = error.response.json().get('code')
            if isinstance(code, str) and re.fullmatch(r'[A-Z_]{3,80}', code):
                return code
        except (ValueError, AttributeError):
            pass
        return 'SERVICE_UNAVAILABLE' if error.response.status_code >= 500 else 'REQUEST_REJECTED'
    if isinstance(error, requests.RequestException):
        return 'NETWORK_FAILURE'
    if isinstance(error, TimeoutError):
        return 'PROCESSING_TIMEOUT'
    if isinstance(error, (ValueError, RuntimeError)) and re.fullmatch(r'[A-Z_]{3,80}', str(error)):
        return str(error)
    return 'PROCESSING_FAILED'


def probe(path):
    """Return {'duration', 'has_audio', 'width', 'height'} or raise VIDEO_UNREADABLE."""
    try:
        result = subprocess.run(
            ['ffprobe', '-v', 'error', '-show_entries',
             'format=duration:stream=codec_type,width,height', '-of', 'json', str(path)],
            capture_output=True, text=True, timeout=30, check=True)
        data = json.loads(result.stdout)
        streams = data.get('streams', [])
        video = next(s for s in streams if s.get('codec_type') == 'video')
        duration = float(data['format']['duration'])
        width, height = int(video['width']), int(video['height'])
    except (subprocess.SubprocessError, StopIteration, KeyError, TypeError, ValueError):
        raise ValueError('VIDEO_UNREADABLE')
    if duration <= 0:
        raise ValueError('VIDEO_UNREADABLE')
    return {'duration': duration, 'width': width, 'height': height,
            'has_audio': any(s.get('codec_type') == 'audio' for s in streams)}


def build_ffmpeg_command(files, probes, output_path, progress_path):
    """Normalize every input to the first video's size and concat them in order."""
    width = max(2, probes[0]['width'] - probes[0]['width'] % 2)
    height = max(2, probes[0]['height'] - probes[0]['height'] % 2)
    args = ['ffmpeg', '-nostdin', '-y']
    for f in files:
        args += ['-i', str(f)]
    filters, concat_inputs = [], ''
    for i, p in enumerate(probes):
        filters.append(
            f'[{i}:v:0]scale={width}:{height}:force_original_aspect_ratio=decrease,'
            f'pad={width}:{height}:(ow-iw)/2:(oh-ih)/2,setsar=1,'
            f'fps={OUTPUT_FPS},format=yuv420p[v{i}]')
        if p['has_audio']:
            filters.append(f'[{i}:a:0]aresample={AUDIO_RATE},'
                           f'aformat=sample_fmts=fltp:channel_layouts=stereo[a{i}]')
        else:  # concat needs an audio stream in every segment
            filters.append(f'anullsrc=r={AUDIO_RATE}:cl=stereo,'
                           f'atrim=duration={p["duration"]:.3f}[a{i}]')
        concat_inputs += f'[v{i}][a{i}]'
    filters.append(f'{concat_inputs}concat=n={len(files)}:v=1:a=1[outv][outa]')
    args += ['-filter_complex', ';'.join(filters), '-map', '[outv]', '-map', '[outa]',
             '-c:v', 'libx264', '-preset', 'veryfast', '-c:a', 'aac',
             '-movflags', '+faststart', '-progress', str(progress_path),
             '-loglevel', 'error', str(output_path)]
    return args


def download(owner, project, video_id, destination, job_id, attempt, deadline):
    """Download one source. Returns False if the job is no longer active (cancelled)."""
    signed = requests.get(f'{STORAGE}/video/{owner}/{project}/{video_id}/url', headers=HEADERS, timeout=15)
    if signed.status_code == 404:
        raise ValueError('VIDEO_UNREADABLE')
    signed.raise_for_status()
    with requests.get(signed.json()['url'], stream=True, timeout=(15, 300)) as response:
        if response.status_code == 404:
            raise ValueError('VIDEO_UNREADABLE')
        response.raise_for_status()
        with destination.open('wb') as output:
            for index, chunk in enumerate(response.iter_content(1024 * 1024)):
                if index % 10 == 0 and not active(job_id, attempt):
                    return False
                if time.monotonic() > deadline:
                    raise TimeoutError('PROCESSING_TIMEOUT')
                output.write(chunk)
    return active(job_id, attempt)


def process(job_id, context):
    job = call('POST', f'/internal/compile/{job_id}/claim')
    attempt = job['attempt']
    context['attempt'] = attempt
    owner, project, result = job['ownerId'], job['projectId'], job['resultId']
    sources = job['sourceIds']
    ids = [owner, project, result, *sources]
    if len(sources) < MIN_VIDEOS or not all(OBJECT_ID.fullmatch(x) for x in ids):
        raise ValueError('INVALID_ID')
    deadline = time.monotonic() + TIMEOUT_SECONDS

    with tempfile.TemporaryDirectory(prefix=f'picturas-compile-{job_id}-') as directory:
        tmp = Path(directory)

        # 1. Download each distinct source once (originals are only read)
        local = {}
        for index, video_id in enumerate(dict.fromkeys(sources)):
            path = tmp / f'source_{index}.mp4'
            if not download(owner, project, video_id, path, job_id, attempt, deadline):
                return
            local[video_id] = path

        # 2. Check every video is readable and the total length is allowed
        probes = {video_id: probe(path) for video_id, path in local.items()}
        files = [local[v] for v in sources]          # user's order
        ordered = [probes[v] for v in sources]
        total = sum(p['duration'] for p in ordered)
        if total > MAX_TOTAL_SECONDS:
            raise ValueError('TOTAL_TOO_LONG')

        # 3. Normalize + concatenate
        output_path, progress_file = tmp / 'result.mp4', tmp / 'progress.txt'
        log_path = tmp / 'ffmpeg.log'
        args = build_ffmpeg_command(files, ordered, output_path, progress_file)
        with log_path.open('wb') as log:
            proc = subprocess.Popen(args, stdout=subprocess.DEVNULL, stderr=log)
        last_progress = -1
        try:
            while proc.poll() is None:
                if not active(job_id, attempt) or time.monotonic() > deadline:
                    proc.terminate()
                    try:
                        proc.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        proc.kill()
                    if not active(job_id, attempt):
                        return
                    raise TimeoutError('PROCESSING_TIMEOUT')
                if progress_file.exists():
                    try:
                        lines = progress_file.read_text(errors='ignore').splitlines()
                        elapsed = next((int(line.split('=', 1)[1]) for line in reversed(lines)
                                        if line.startswith('out_time_us=')), 0) / 1_000_000
                        progress = min(99, max(0, int(100 * elapsed / total)))
                        if progress > last_progress:
                            call('POST', f'/internal/compile/{job_id}/progress',
                                 json={'progress': progress, 'attempt': attempt})
                            last_progress = progress
                    except (ValueError, OSError):
                        pass
                time.sleep(POLL_SECONDS)
        finally:
            if proc.poll() is None:
                proc.kill()
        if proc.returncode != 0:
            print(log_path.read_text(errors='ignore')[-500:], flush=True)
            raise RuntimeError('FFMPEG_FAILED')

        # 4. Validate the result
        output_info = probe(output_path)
        if abs(output_info['duration'] - total) > max(1.0, 0.05 * total):
            raise ValueError('INVALID_OUTPUT_DURATION')
        if not active(job_id, attempt):
            return

        # 5. Reserve storage, upload as a NEW video, complete
        size = output_path.stat().st_size
        call('POST', f'/internal/compile/{job_id}/storage/reserve', json={'size': size, 'attempt': attempt})
        with output_path.open('rb') as stream:
            response = requests.put(f'{STORAGE}/video/{owner}/{project}/{result}', data=stream,
                                    headers={**HEADERS, 'Content-Type': 'video/mp4',
                                             'Content-Length': str(size)}, timeout=600)
            response.raise_for_status()
        if not active(job_id, attempt):
            requests.delete(f'{STORAGE}/video/{owner}/{project}/{result}', headers=HEADERS, timeout=30)
            call('POST', f'/internal/compile/{job_id}/storage/release')
            return
        try:
            call('POST', f'/internal/compile/{job_id}/complete', json={
                'size': size, 'duration': output_info['duration'],
                'width': output_info['width'], 'height': output_info['height'], 'attempt': attempt})
        except Exception:
            requests.delete(f'{STORAGE}/video/{owner}/{project}/{result}', headers=HEADERS, timeout=30)
            call('POST', f'/internal/compile/{job_id}/storage/release')
            raise


def main():
    import urllib3
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
    credentials = pika.PlainCredentials(os.getenv('RABBITMQ_USER', 'user'), os.getenv('RABBITMQ_PASS', 'password'))
    while True:
        try:
            connection = pika.BlockingConnection(pika.ConnectionParameters(
                host=os.getenv('RABBITMQ_HOST', 'rabbitmq'),
                port=int(os.getenv('RABBITMQ_PORT', '5672')), credentials=credentials, heartbeat=0))
            channel = connection.channel()
            channel.exchange_declare(exchange='picturas', exchange_type='direct', durable=True)
            channel.queue_declare(queue=QUEUE, durable=True)
            channel.queue_bind(exchange='picturas', queue=QUEUE, routing_key=QUEUE)
            channel.basic_qos(prefetch_count=1)

            def consume(ch, method, _properties, body):
                job_id = None
                context = {}
                try:
                    job_id = json.loads(body)['jobId']
                    if not OBJECT_ID.fullmatch(job_id):
                        raise ValueError('INVALID_ID')
                    process(job_id, context)
                except Exception as error:
                    print(f'Compile {job_id} failed: {error_code(error)}', flush=True)
                    if job_id and context.get('attempt'):
                        try:
                            call('POST', f'/internal/compile/{job_id}/fail', json={
                                'error': error_code(error), 'attempt': context['attempt'],
                                'recoverable': isinstance(error, TimeoutError) or (
                                    isinstance(error, requests.RequestException) and
                                    not (isinstance(error, requests.HTTPError) and
                                         error.response is not None and error.response.status_code < 500))})
                        except Exception:
                            pass
                finally:
                    ch.basic_ack(delivery_tag=method.delivery_tag)

            channel.basic_consume(queue=QUEUE, on_message_callback=consume)
            channel.start_consuming()
        except Exception as error:
            print(f'Compile worker reconnecting: {error}', flush=True)
            time.sleep(5)


if __name__ == '__main__':
    main()
