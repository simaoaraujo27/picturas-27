"""Consumes durable trim jobs; the projects service owns job state and authorization."""
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
SESSION = requests.Session()
SESSION.verify = False


def call(method, path, **kwargs):
    response = SESSION.request(method, API + path, headers=HEADERS, timeout=30, **kwargs)
    response.raise_for_status()
    return response.json() if response.content else None


def status(job_id):
    return call('GET', f'/internal/trim/{job_id}')


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
    result = subprocess.run(['ffprobe', '-v', 'error', '-show_entries',
        'format=format_name,duration:stream=codec_name,codec_type,width,height', '-of', 'json', str(path)],
        capture_output=True, text=True, timeout=30, check=True)
    data = json.loads(result.stdout)
    video = next((s for s in data.get('streams', []) if s.get('codec_type') == 'video'), None)
    if not video or video.get('codec_name') != 'h264' or 'mp4' not in data.get('format', {}).get('format_name', ''):
        raise ValueError('UNSUPPORTED_VIDEO')
    return data, video


def keyframe_at(path, instant):
    if instant == 0:
        return True
    result = subprocess.run(['ffprobe', '-v', 'error', '-skip_frame', 'nokey',
        '-select_streams', 'v:0', '-read_intervals', f'{max(0, instant - 2)}%+4',
        '-show_entries', 'frame=best_effort_timestamp_time', '-of', 'csv=p=0', str(path)],
        capture_output=True, text=True, timeout=30, check=True)
    return any(abs(float(line.split(',', 1)[0].strip()) - instant) <= 0.015
               for line in result.stdout.splitlines() if line.split(',', 1)[0].strip())


def process(job_id, context):
    job = call('POST', f'/internal/trim/{job_id}/claim')
    context['attempt'] = job['attempt']
    owner, project, source, result = (job[k] for k in ('ownerId', 'projectId', 'sourceId', 'resultId'))
    if not all(OBJECT_ID.fullmatch(x) for x in (owner, project, source, result)):
        raise ValueError('INVALID_ID')
    with tempfile.TemporaryDirectory(prefix=f'picturas-trim-{job_id}-') as tmp:
        source_path, output_path = Path(tmp) / 'source.mp4', Path(tmp) / 'result.mp4'
        signed = requests.get(f'{STORAGE}/video/{owner}/{project}/{source}/url', headers=HEADERS, timeout=15)
        signed.raise_for_status()
        with requests.get(signed.json()['url'], stream=True, timeout=(15, 300)) as response:
            response.raise_for_status()
            with source_path.open('wb') as output:
                for chunk in response.iter_content(1024 * 1024):
                    if not active(job_id, job['attempt']):
                        return
                    output.write(chunk)
        info, video = probe(source_path)
        if job['end'] > float(info['format']['duration']) + 0.01:
            raise ValueError('OUTSIDE_VIDEO')
        has_audio = any(s.get('codec_type') == 'audio' for s in info.get('streams', []))
        if job['mode'] == 'fast':
            if has_audio and any(s.get('codec_type') == 'audio' and s.get('codec_name') != 'aac'
                                 for s in info.get('streams', [])):
                raise ValueError('FAST_REQUIRES_AAC')
            if not keyframe_at(source_path, job['start']) or (
                job['end'] < float(info['format']['duration']) - 0.01 and
                not keyframe_at(source_path, job['end'])
            ):
                raise ValueError('FAST_REQUIRES_KEYFRAMES')
        args = ['ffmpeg', '-nostdin', '-y']
        if job['mode'] == 'fast':
            args += ['-ss', str(job['start'])]
        args += ['-i', str(source_path)]
        if job['mode'] != 'fast':
            args += ['-ss', str(job['start'])]
        args += ['-t', str(round(job['end'] - job['start'], 2)), '-map', '0:v:0']
        if has_audio:
            args += ['-map', '0:a:0']
        if job['mode'] == 'fast':
            args += ['-c', 'copy']
        else:
            args += ['-c:v', 'libx264', '-preset', 'medium']
            if has_audio:
                args += ['-c:a', 'aac']
        args += ['-movflags', '+faststart', '-progress', str(Path(tmp) / 'progress.txt'), '-loglevel', 'error', str(output_path)]
        proc = subprocess.Popen(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, text=True)
        progress_file = Path(tmp) / 'progress.txt'
        last_progress = -1
        started = time.monotonic()
        try:
            while proc.poll() is None:
                if not active(job_id, job['attempt']) or time.monotonic() - started > 600:
                    proc.terminate()
                    try: proc.wait(timeout=5)
                    except subprocess.TimeoutExpired: proc.kill()
                    if not active(job_id, job['attempt']): return
                    raise TimeoutError('PROCESSING_TIMEOUT')
                if progress_file.exists():
                    try:
                        lines = progress_file.read_text(errors='ignore').splitlines()
                        elapsed = next((int(line.split('=', 1)[1]) for line in reversed(lines) if line.startswith('out_time_us=')), 0) / 1000000
                        progress = min(99, max(0, int(100 * elapsed / (job['end'] - job['start']))))
                        if progress > last_progress:
                            call('POST', f'/internal/trim/{job_id}/progress', json={'progress': progress, 'attempt': job['attempt']})
                            last_progress = progress
                    except (ValueError, OSError):
                        pass
                time.sleep(1)
        finally:
            if proc.poll() is None:
                proc.kill()
        if proc.returncode != 0:
            raise RuntimeError('FFMPEG_FAILED')
        output_info, output_video = probe(output_path)
        if any(s.get('codec_type') == 'audio' and s.get('codec_name') != 'aac'
               for s in output_info.get('streams', [])):
            raise ValueError('INVALID_OUTPUT_AUDIO')
        duration = float(output_info['format']['duration'])
        if abs(duration - (job['end'] - job['start'])) > 0.5:
            raise ValueError('INVALID_OUTPUT_DURATION')
        if not active(job_id, job['attempt']): return
        size = output_path.stat().st_size
        call('POST', f'/internal/trim/{job_id}/storage/reserve',
             json={'size': size, 'attempt': job['attempt']})
        with output_path.open('rb') as stream:
            response = requests.put(f'{STORAGE}/video/{owner}/{project}/{result}', data=stream,
                headers={**HEADERS, 'Content-Type': 'video/mp4', 'Content-Length': str(size)}, timeout=600)
            response.raise_for_status()
        if not active(job_id, job['attempt']):
            requests.delete(f'{STORAGE}/video/{owner}/{project}/{result}', headers=HEADERS, timeout=30)
            call('POST', f'/internal/trim/{job_id}/storage/release')
            return
        try:
            call('POST', f'/internal/trim/{job_id}/complete', json={'size': size, 'duration': duration,
                'width': output_video['width'], 'height': output_video['height'], 'attempt': job['attempt']})
        except Exception:
            requests.delete(f'{STORAGE}/video/{owner}/{project}/{result}', headers=HEADERS, timeout=30)
            call('POST', f'/internal/trim/{job_id}/storage/release')
            raise


def main():
    import urllib3
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
    credentials = pika.PlainCredentials(os.getenv('RABBITMQ_USER', 'user'), os.getenv('RABBITMQ_PASS', 'password'))
    while True:
        try:
            connection = pika.BlockingConnection(pika.ConnectionParameters(host=os.getenv('RABBITMQ_HOST', 'rabbitmq'),
                port=int(os.getenv('RABBITMQ_PORT', '5672')), credentials=credentials, heartbeat=0))
            channel = connection.channel()
            channel.exchange_declare(exchange='picturas', exchange_type='direct', durable=True)
            channel.queue_declare(queue='video_trim_queue', durable=True)
            channel.queue_bind(exchange='picturas', queue='video_trim_queue', routing_key='video_trim_queue')
            channel.basic_qos(prefetch_count=1)
            def consume(ch, method, _properties, body):
                job_id = None
                context = {}
                try:
                    job_id = json.loads(body)['jobId']
                    if not OBJECT_ID.fullmatch(job_id): raise ValueError('INVALID_ID')
                    process(job_id, context)
                except Exception as error:
                    print(f'Trim {job_id} failed: {error_code(error)}', flush=True)
                    if job_id and context.get('attempt'):
                        try: call('POST', f'/internal/trim/{job_id}/fail', json={
                            'error': error_code(error), 'attempt': context['attempt'],
                            'recoverable': isinstance(error, TimeoutError) or (
                                isinstance(error, requests.RequestException) and
                                not (isinstance(error, requests.HTTPError) and
                                     error.response is not None and error.response.status_code < 500))})
                        except Exception: pass
                finally:
                    ch.basic_ack(delivery_tag=method.delivery_tag)
            channel.basic_consume(queue='video_trim_queue', on_message_callback=consume)
            channel.start_consuming()
        except Exception as error:
            print(f'Trim worker reconnecting: {error}', flush=True)
            time.sleep(5)

if __name__ == '__main__': main()
