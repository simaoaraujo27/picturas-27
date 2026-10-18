"""Run against a local Docker Compose stack: python3 tests/trim_integration.py."""
import hashlib
import json
import subprocess
import tempfile
import time
import uuid
from pathlib import Path

import requests
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
API = 'https://localhost:8080/api-gateway'
client = requests.Session()
client.verify = False


def request(method, path, *, expected=(200,), **kwargs):
    response = client.request(method, API + path, timeout=120, **kwargs)
    if response.status_code not in expected:
        raise AssertionError(f'{method} {path}: {response.status_code} {response.text[:500]}')
    return response


def digest(data):
    return hashlib.sha256(data).hexdigest()


def wait_job(user_id, project_id, job_id, headers, share=None):
    deadline = time.monotonic() + 120
    while time.monotonic() < deadline:
        job = request('GET', f'/projects/{user_id}/{project_id}/video/trim/jobs/{job_id}' +
            (f'?share={share}' if share else ''),
            headers=headers).json()
        if job['state'] in ('COMPLETED', 'FAILED', 'CANCELLED'):
            return job
        time.sleep(2)
    raise AssertionError('Trim job did not finish in 120 seconds')


def main():
    user_id = project_id = token = collaborator_id = collaborator_token = None
    video_ids = []
    with tempfile.TemporaryDirectory(prefix='picturas-trim-test-') as temp:
        source = Path(temp) / 'sample.mp4'
        result = Path(temp) / 'result.mp4'
        subprocess.run(['ffmpeg', '-nostdin', '-y', '-f', 'lavfi', '-i',
            'testsrc=size=320x240:rate=25', '-f', 'lavfi', '-i', 'sine=frequency=440',
            '-t', '6', '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-c:a', 'aac',
            str(source)], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        try:
            registration = request('POST', '/users/', expected=(201,), json={
                'name': 'Trim integration test', 'email': f'trim-{uuid.uuid4()}@example.invalid',
                'password': 'TemporaryTestPassword123', 'type': 'free' }).json()
            user_id = registration['user']['_id']
            token = registration['jwt']
            headers = {'Authorization': f'Bearer {token}'}
            project = request('POST', f'/projects/{user_id}', expected=(201,),
                headers=headers, json={'name': 'Trim integration test'}).json()
            project_id = project['_id']
            upload_headers = {**headers, 'X-Project-Version': '0',
                'X-Video-Name': 'sample.mp4', 'X-Video-Size': str(source.stat().st_size)}
            with source.open('rb') as stream:
                uploaded = request('POST', f'/projects/{user_id}/{project_id}/video',
                    expected=(201,), headers=upload_headers,
                    files={'video': ('sample.mp4', stream, 'video/mp4')}).json()
            original_id = uploaded['id']
            video_ids.append(original_id)
            original = request('GET', f'/projects/{user_id}/{project_id}/video/{original_id}',
                headers=headers).content
            assert digest(original) == digest(source.read_bytes()), 'Original changed during upload'
            playback = request('GET',
                f'/projects/{user_id}/{project_id}/video/{original_id}/playback',
                headers=headers).json()['url']
            ranged = client.get('https://localhost:8080' + playback,
                headers={'Range': 'bytes=0-99'}, timeout=30)
            assert ranged.status_code == 206 and ranged.content == original[:100], ranged.status_code
            outsider = requests.Session()
            outsider.verify = False
            assert outsider.get('https://localhost:8080' + playback, timeout=30).status_code == 403
            invalid = request('POST', f'/projects/{user_id}/{project_id}/video/{original_id}/trim',
                expected=(400,), headers=headers, json={'start': 3, 'end': 3.5}).json()
            assert invalid['code'] == 'INVALID_INTERVAL', invalid
            submitted = request('POST', f'/projects/{user_id}/{project_id}/video/{original_id}/trim',
                expected=(202,), headers=headers, json={'start': 1.25, 'end': 3.75}).json()
            job_id = submitted['id']
            job = wait_job(user_id, project_id, job_id, headers)
            assert job['state'] == 'COMPLETED', job
            assert job['progress'] == 100, job
            assert job['result']['id'] == job['resultId']
            assert job['result']['sourceVideoId'] == original_id
            assert job['result']['jobId'] == job_id
            assert job['result']['duration'] > 0
            assert (job['result']['width'], job['result']['height']) == (320, 240)
            video_ids.append(job['resultId'])
            project_view = request('GET', f'/projects/{user_id}/{project_id}', headers=headers).json()
            catalogued = next(item for item in project_view['videos'] if item['id'] == job['resultId'])
            assert catalogued['sourceVideoId'] == original_id and catalogued['trimJobId'] == job_id
            assert catalogued['duration'] > 0 and catalogued['width'] == 320 and catalogued['height'] == 240
            result.write_bytes(request('GET', f'/projects/{user_id}/{project_id}/video/{job["resultId"]}',
                headers=headers).content)
            metadata = json.loads(subprocess.run(['ffprobe', '-v', 'error', '-show_entries',
                'format=duration:stream=codec_name,codec_type', '-of', 'json', str(result)],
                check=True, capture_output=True, text=True).stdout)
            assert abs(float(metadata['format']['duration']) - 2.5) < 0.5, metadata
            assert any(s['codec_type'] == 'video' and s['codec_name'] == 'h264' for s in metadata['streams'])
            assert any(s['codec_type'] == 'audio' and s['codec_name'] == 'aac' for s in metadata['streams'])
            assert digest(request('GET', f'/projects/{user_id}/{project_id}/video/{original_id}',
                headers=headers).content) == digest(original), 'Original changed after Trim'
            account = request('GET', f'/users/{user_id}').json()
            assert account['remaining_operations'] == 4, account
            collaborator = request('POST', '/users/', expected=(201,), json={
                'name': 'Trim collaborator test', 'email': f'trim-collab-{uuid.uuid4()}@example.invalid',
                'password': 'TemporaryTestPassword123', 'type': 'free' }).json()
            collaborator_id, collaborator_token = collaborator['user']['_id'], collaborator['jwt']
            collaborator_headers = {'Authorization': f'Bearer {collaborator_token}'}
            request('GET', f'/projects/{user_id}/{project_id}/video/{original_id}',
                expected=(401,), headers=collaborator_headers)
            version = request('GET', f'/projects/{user_id}/{project_id}', headers=headers).json()['version']
            read_share = request('POST', f'/projects/{user_id}/{project_id}/share',
                expected=(201,), headers={**headers, 'X-Project-Version': str(version)},
                json={'permission': 'read'}).json()['id']
            assert request('GET', f'/projects/{user_id}/{project_id}/video/{original_id}?share={read_share}',
                headers=collaborator_headers).content == original
            forbidden = request('POST',
                f'/projects/{user_id}/{project_id}/video/{original_id}/trim?share={read_share}',
                expected=(403,), headers=collaborator_headers,
                json={'start': 0, 'end': 1}).json()
            assert forbidden['code'] == 'EDIT_REQUIRED', forbidden
            version = request('GET', f'/projects/{user_id}/{project_id}', headers=headers).json()['version']
            edit_share = request('POST', f'/projects/{user_id}/{project_id}/share',
                expected=(201,), headers={**headers, 'X-Project-Version': str(version)},
                json={'permission': 'edit'}).json()['id']
            collab_job = request('POST',
                f'/projects/{user_id}/{project_id}/video/{original_id}/trim?share={edit_share}',
                expected=(202,), headers=collaborator_headers,
                json={'start': 0, 'end': 1}).json()
            collab_result = wait_job(user_id, project_id, collab_job['id'], collaborator_headers, edit_share)
            assert collab_result['state'] == 'COMPLETED', collab_result
            video_ids.append(collab_result['resultId'])
            assert request('GET', f'/users/{collaborator_id}').json()['remaining_operations'] == 4
            assert request('GET', f'/users/{user_id}').json()['remaining_operations'] == 4
            request('PUT', f'/users/{collaborator_id}', expected=(204,),
                headers=collaborator_headers, json={'type': 'premium'})
            fast = request('POST',
                f'/projects/{user_id}/{project_id}/video/{original_id}/trim?share={edit_share}',
                expected=(202,), headers=collaborator_headers,
                json={'start': 0, 'end': 6, 'mode': 'fast'}).json()
            fast_result = wait_job(user_id, project_id, fast['id'], collaborator_headers, edit_share)
            assert fast_result['state'] == 'COMPLETED', fast_result
            video_ids.append(fast_result['resultId'])
            bad_fast = request('POST',
                f'/projects/{user_id}/{project_id}/video/{original_id}/trim?share={edit_share}',
                expected=(202,), headers=collaborator_headers,
                json={'start': 1.25, 'end': 3.75, 'mode': 'fast'}).json()
            bad_fast_result = wait_job(user_id, project_id, bad_fast['id'], collaborator_headers, edit_share)
            assert bad_fast_result['state'] == 'FAILED' and \
                bad_fast_result['error'] == 'FAST_REQUIRES_KEYFRAMES', bad_fast_result
            subprocess.run(['docker', 'pause', 'picturas-video_trim_worker-1'], check=True,
                stdout=subprocess.DEVNULL)
            try:
                queued = request('POST', f'/projects/{user_id}/{project_id}/video/{original_id}/trim',
                    expected=(202,), headers=headers, json={'start': 0, 'end': 1}).json()
                cancelled = request('DELETE',
                    f'/projects/{user_id}/{project_id}/video/trim/jobs/{queued["id"]}',
                    headers=headers).json()
                assert cancelled['state'] == 'CANCELLED', cancelled
            finally:
                subprocess.run(['docker', 'unpause', 'picturas-video_trim_worker-1'], check=True,
                    stdout=subprocess.DEVNULL)
            time.sleep(2)
            cancelled_status = request('GET',
                f'/projects/{user_id}/{project_id}/video/trim/jobs/{queued["id"]}',
                headers=headers).json()
            assert cancelled_status['state'] == 'CANCELLED' and cancelled_status['resultId'] is None
            assert request('GET', f'/users/{user_id}').json()['remaining_operations'] == 4
            silent = Path(temp) / 'silent.mp4'
            subprocess.run(['ffmpeg', '-nostdin', '-y', '-f', 'lavfi', '-i',
                'testsrc=size=160x120:rate=25', '-t', '4', '-c:v', 'libx264',
                '-pix_fmt', 'yuv420p', str(silent)], check=True,
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            version = request('GET', f'/projects/{user_id}/{project_id}', headers=headers).json()['version']
            with silent.open('rb') as stream:
                silent_upload = request('POST', f'/projects/{user_id}/{project_id}/video',
                    expected=(201,), headers={**headers, 'X-Project-Version': str(version),
                        'X-Video-Name': 'silent.mp4', 'X-Video-Size': str(silent.stat().st_size)},
                    files={'video': ('silent.mp4', stream, 'video/mp4')}).json()
            silent_id = silent_upload['id']
            video_ids.append(silent_id)
            silent_job = request('POST', f'/projects/{user_id}/{project_id}/video/{silent_id}/trim',
                expected=(202,), headers=headers, json={'start': 0, 'end': 1}).json()
            silent_result = wait_job(user_id, project_id, silent_job['id'], headers)
            assert silent_result['state'] == 'COMPLETED', silent_result
            video_ids.append(silent_result['resultId'])
            silent_output = Path(temp) / 'silent-result.mp4'
            silent_output.write_bytes(request('GET',
                f'/projects/{user_id}/{project_id}/video/{silent_result["resultId"]}',
                headers=headers).content)
            streams = json.loads(subprocess.run(['ffprobe', '-v', 'error', '-show_entries',
                'stream=codec_type', '-of', 'json', str(silent_output)], check=True,
                capture_output=True, text=True).stdout)['streams']
            assert not any(stream['codec_type'] == 'audio' for stream in streams)
            for start, end in [(0, 1), (2, 3), (4, 6)]:
                extra = request('POST', f'/projects/{user_id}/{project_id}/video/{original_id}/trim',
                    expected=(202,), headers=headers, json={'start': start, 'end': end}).json()
                extra_result = wait_job(user_id, project_id, extra['id'], headers)
                assert extra_result['state'] == 'COMPLETED', extra_result
                video_ids.append(extra_result['resultId'])
            exhausted = request('POST', f'/projects/{user_id}/{project_id}/video/{original_id}/trim',
                expected=(429,), headers=headers, json={'start': 0, 'end': 1}).json()
            assert exhausted['code'] == 'DAILY_QUOTA_EXHAUSTED', exhausted
            usage = request('GET', f'/projects/{user_id}/{project_id}/video/storage',
                headers=headers).json()
            assert usage['used'] > 0 and usage['used'] < usage['limit'], usage
            version = request('GET', f'/projects/{user_id}/{project_id}', headers=headers).json()['version']
            request('DELETE', f'/projects/{user_id}/{project_id}/video/{silent_result["resultId"]}',
                headers={**headers, 'X-Project-Version': str(version)}, expected=(204,))
            video_ids.remove(silent_result['resultId'])
            after_delete = request('GET', f'/projects/{user_id}/{project_id}', headers=headers).json()
            assert all(item['id'] != silent_result['resultId'] for item in after_delete['videos'])
            assert request('GET', f'/projects/{user_id}/{project_id}/video/storage',
                headers=headers).json()['used'] < usage['used']
            request('GET', f'/projects/{user_id}/{project_id}/video/{silent_result["resultId"]}',
                headers=headers, expected=(404,))
            print(json.dumps({'status': 'passed', 'jobId': job_id, 'resultId': job['resultId'],
                'duration': metadata['format']['duration'], 'remainingOperations': 0,
                'silentResultId': silent_result['resultId'], 'storageBytes': usage['used']}))
        finally:
            if token and project_id:
                headers = {'Authorization': f'Bearer {token}'}
                for video_id in reversed(video_ids):
                    project = client.get(API + f'/projects/{user_id}/{project_id}', headers=headers, timeout=30)
                    if project.ok:
                        client.delete(API + f'/projects/{user_id}/{project_id}/video/{video_id}',
                            headers={**headers, 'X-Project-Version': str(project.json()['version'])}, timeout=30)
                project = client.get(API + f'/projects/{user_id}/{project_id}', headers=headers, timeout=30)
                if project.ok:
                    client.delete(API + f'/projects/{user_id}/{project_id}',
                        headers={**headers, 'X-Project-Version': str(project.json()['version'])}, timeout=30)
            if token and user_id:
                client.delete(API + f'/users/{user_id}', headers={'Authorization': f'Bearer {token}'}, timeout=30)
            if collaborator_id and collaborator_token:
                client.delete(API + f'/users/{collaborator_id}',
                    headers={'Authorization': f'Bearer {collaborator_token}'}, timeout=30)
            if project_id and user_id:
                subprocess.run(['docker', 'exec', 'picturas-projects_mongoDB-1', 'mongo',
                    '--quiet', '--port', '27018', 'project', '--eval',
                    f"db.trimjobs.deleteMany({{projectId:ObjectId('{project_id}')}}); "
                    f"db.videostorageaccounts.deleteMany({{ownerId:ObjectId('{user_id}')}})"],
                    check=True, stdout=subprocess.DEVNULL)


if __name__ == '__main__':
    main()
