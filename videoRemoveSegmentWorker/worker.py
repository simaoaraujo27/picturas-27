"""Consumes durable remove-segment jobs; the projects service owns job state and authorization."""
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
    return call('GET', f'/internal/remove-segment/{job_id}')


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


def process(job_id, context):
    job = call('POST', f'/internal/remove-segment/{job_id}/claim')
    context['attempt'] = job['attempt']
    owner, project, source, result = (job[k] for k in ('ownerId', 'projectId', 'sourceId', 'resultId'))
    if not all(OBJECT_ID.fullmatch(x) for x in (owner, project, source, result)):
        raise ValueError('INVALID_ID')
    with tempfile.TemporaryDirectory(prefix=f'picturas-removesegment-{job_id}-') as tmp:
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
        total_duration = float(info['format']['duration'])
        start, end = float(job['start']), float(job['end'])
        if start < 0 or end > total_duration + 0.05 or start >= end:
            raise ValueError('OUTSIDE_VIDEO')
        expected_duration = total_duration - (end - start)
        if expected_duration < 1.0 - 0.05:
            raise ValueError('DURATION_TOO_SHORT')
        has_audio = any(s.get('codec_type') == 'audio' for s in info.get('streams', []))

        progress_file = Path(tmp) / 'progress.txt'
        args = ['ffmpeg', '-nostdin', '-y']
        is_cut_at_start = (start <= 0.02)
        is_cut_at_end = (end >= total_duration - 0.02)

        if is_cut_at_start:
            # Cut from 0 to end; keep from end to duration
            args += ['-ss', str(round(end, 2)), '-i', str(source_path), '-map', '0:v:0']
            if has_audio:
                args += ['-map', '0:a:0']
            args += ['-c:v', 'libx264', '-preset', 'medium']
            if has_audio:
                args += ['-c:a', 'aac']
        elif is_cut_at_end:
            # Cut from start to end; keep from 0 to start
            args += ['-i', str(source_path), '-t', str(round(start, 2)), '-map', '0:v:0']
            if has_audio:
                args += ['-map', '0:a:0']
            args += ['-c:v', 'libx264', '-preset', 'medium']
            if has_audio:
                args += ['-c:a', 'aac']
        else:
            # Intermediate cut: keep [0, start] and [end, total_duration], concat them
            s_round, e_round = round(start, 2), round(end, 2)
            if has_audio:
                filter_spec = (
                    f"[0:v]trim=start=0:end={s_round},setpts=PTS-STARTPTS[v1];"
                    f"[0:a]atrim=start=0:end={s_round},asetpts=PTS-STARTPTS[a1];"
                    f"[0:v]trim=start={e_round},setpts=PTS-STARTPTS[v2];"
                    f"[0:a]atrim=start={e_round},asetpts=PTS-STARTPTS[a2];"
                    f"[v1][a1][v2][a2]concat=n=2:v=1:a=1[outv][outa]"
                )
                args += ['-i', str(source_path), '-filter_complex', filter_spec,
                         '-map', '[outv]', '-map', '[outa]',
                         '-c:v', 'libx264', '-preset', 'medium', '-c:a', 'aac']
            else:
                filter_spec = (
                    f"[0:v]trim=start=0:end={s_round},setpts=PTS-STARTPTS[v1];"
                    f"[0:v]trim=start={e_round},setpts=PTS-STARTPTS[v2];"
                    f"[v1][v2]concat=n=2:v=1:a=0[outv]"
                )
                args += ['-i', str(source_path), '-filter_complex', filter_spec,
                         '-map', '[outv]',
                         '-c:v', 'libx264', '-preset', 'medium']

        args += ['-movflags', '+faststart', '-progress', str(progress_file), '-loglevel', 'error', str(output_path)]

        proc = subprocess.Popen(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, text=True)
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
                        if expected_duration > 0:
                            progress = min(99, max(0, int(100 * elapsed / expected_duration)))
                            if progress > last_progress:
                                call('POST', f'/internal/remove-segment/{job_id}/progress', json={'progress': progress, 'attempt': job['attempt']})
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
        if abs(duration - expected_duration) > 0.6:
            raise ValueError('INVALID_OUTPUT_DURATION')
        if not active(job_id, job['attempt']): return
        size = output_path.stat().st_size
        call('POST', f'/internal/remove-segment/{job_id}/storage/reserve',
             json={'size': size, 'attempt': job['attempt']})
        with output_path.open('rb') as stream:
            response = requests.put(f'{STORAGE}/video/{owner}/{project}/{result}', data=stream,
                headers={**HEADERS, 'Content-Type': 'video/mp4', 'Content-Length': str(size)}, timeout=600)
            response.raise_for_status()
        if not active(job_id, job['attempt']):
            requests.delete(f'{STORAGE}/video/{owner}/{project}/{result}', headers=HEADERS, timeout=30)
            call('POST', f'/internal/remove-segment/{job_id}/storage/release')
            return
        try:
            call('POST', f'/internal/remove-segment/{job_id}/complete', json={'size': size, 'duration': duration,
                'width': output_video['width'], 'height': output_video['height'], 'attempt': job['attempt']})
        except Exception:
            requests.delete(f'{STORAGE}/video/{owner}/{project}/{result}', headers=HEADERS, timeout=30)
            call('POST', f'/internal/remove-segment/{job_id}/storage/release')
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
            channel.queue_declare(queue='video_remove_segment_queue', durable=True)
            channel.queue_bind(exchange='picturas', queue='video_remove_segment_queue', routing_key='video_remove_segment_queue')
            channel.basic_qos(prefetch_count=1)
            def consume(ch, method, _properties, body):
                job_id = None
                context = {}
                try:
                    job_id = json.loads(body)['jobId']
                    if not OBJECT_ID.fullmatch(job_id): raise ValueError('INVALID_ID')
                    process(job_id, context)
                except Exception as error:
                    print(f'RemoveSegment {job_id} failed: {error_code(error)}', flush=True)
                    if job_id and context.get('attempt'):
                        try: call('POST', f'/internal/remove-segment/{job_id}/fail', json={
                            'error': error_code(error), 'attempt': context['attempt'],
                            'recoverable': isinstance(error, TimeoutError) or (
                                isinstance(error, requests.RequestException) and
                                not (isinstance(error, requests.HTTPError) and
                                     error.response is not None and error.response.status_code < 500))})
                        except Exception: pass
                finally:
                    ch.basic_ack(delivery_tag=method.delivery_tag)
            channel.basic_consume(queue='video_remove_segment_queue', on_message_callback=consume)
            channel.start_consuming()
        except Exception as error:
            print(f'RemoveSegment worker reconnecting: {error}', flush=True)
            time.sleep(5)

if __name__ == '__main__': main()
