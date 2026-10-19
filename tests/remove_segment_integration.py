"""Run against a local Docker Compose stack: python3 tests/remove_segment_integration.py."""
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
        job = request('GET', f'/projects/{user_id}/{project_id}/video/remove-segment/jobs/{job_id}' +
            (f'?share={share}' if share else ''),
            headers=headers).json()
        if job['state'] in ('COMPLETED', 'FAILED', 'CANCELLED'):
            return job
        time.sleep(2)
    raise AssertionError('RemoveSegment job did not finish in 120 seconds')


def main():
    user_id = project_id = token = collaborator_id = collaborator_token = None
    video_ids = []
    with tempfile.TemporaryDirectory(prefix='picturas-removesegment-test-') as temp:
        source = Path(temp) / 'sample.mp4'
        result = Path(temp) / 'result.mp4'
        subprocess.run(['ffmpeg', '-nostdin', '-y', '-f', 'lavfi', '-i',
            'testsrc=size=320x240:rate=25', '-f', 'lavfi', '-i', 'sine=frequency=440',
            '-t', '6', '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-c:a', 'aac',
            str(source)], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        try:
            registration = request('POST', '/users/', expected=(201,), json={
                'name': 'RemoveSegment integration test', 'email': f'removesegment-{uuid.uuid4()}@example.invalid',
                'password': 'TemporaryTestPassword123', 'type': 'free'}).json()
            user_id = registration['user']['_id']
            token = registration['jwt']
            headers = {'Authorization': f'Bearer {token}'}

            project = request('POST', f'/projects/{user_id}', expected=(201,),
                headers=headers, json={'name': 'RemoveSegment integration test'}).json()
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

            # Get current project version
            proj = request('GET', f'/projects/{user_id}/{project_id}', headers=headers).json()
            v = proj['version']

            # 1. Test missing X-Project-Version -> 428
            no_version = request('POST', f'/projects/{user_id}/{project_id}/video/{original_id}/remove-segment',
                expected=(428,), headers=headers, json={'start': 1.0, 'end': 2.0}).json()
            assert no_version['code'] == 'VERSION_REQUIRED', no_version

            # 2. Test version conflict -> 409
            conflict = request('POST', f'/projects/{user_id}/{project_id}/video/{original_id}/remove-segment',
                expected=(409,), headers={**headers, 'X-Project-Version': '999'},
                json={'start': 1.0, 'end': 2.0}).json()
            assert conflict['code'] == 'PROJECT_CONFLICT', conflict

            # 3. Test invalid interval -> 400
            invalid = request('POST', f'/projects/{user_id}/{project_id}/video/{original_id}/remove-segment',
                expected=(400,), headers={**headers, 'X-Project-Version': str(v)},
                json={'start': 3.0, 'end': 2.0}).json()
            assert invalid['code'] == 'INVALID_INTERVAL', invalid

            # 4. Test remaining duration < 1.0s -> 400 DURATION_TOO_SHORT
            too_short = request('POST', f'/projects/{user_id}/{project_id}/video/{original_id}/remove-segment',
                expected=(400,), headers={**headers, 'X-Project-Version': str(v)},
                json={'start': 0.5, 'end': 5.8}).json()
            assert too_short['code'] == 'DURATION_TOO_SHORT', too_short

            # 5. Successful Intermediate Cut (remove 1.5 to 3.5 from 6.0s -> ~4.0s)
            submitted = request('POST', f'/projects/{user_id}/{project_id}/video/{original_id}/remove-segment',
                expected=(202,), headers={**headers, 'X-Project-Version': str(v)},
                json={'start': 1.5, 'end': 3.5}).json()
            job_id = submitted['id']
            job = wait_job(user_id, project_id, job_id, headers)
            assert job['state'] == 'COMPLETED', job
            assert job['progress'] == 100, job
            assert job['result']['id'] == job['resultId']
            assert job['result']['sourceVideoId'] == original_id
            assert job['result']['jobId'] == job_id
            assert job['result']['name'].endswith('-cut.mp4'), job['result']['name']
            assert job['result']['duration'] > 0
            assert (job['result']['width'], job['result']['height']) == (320, 240)
            video_ids.append(job['resultId'])

            # Verify non-destructive: original unchanged
            assert digest(request('GET', f'/projects/{user_id}/{project_id}/video/{original_id}',
                headers=headers).content) == digest(original), 'Original modified after RemoveSegment'

            # Verify output video properties
            result.write_bytes(request('GET', f'/projects/{user_id}/{project_id}/video/{job["resultId"]}',
                headers=headers).content)
            metadata = json.loads(subprocess.run(['ffprobe', '-v', 'error', '-show_entries',
                'format=duration:stream=codec_name,codec_type', '-of', 'json', str(result)],
                check=True, capture_output=True, text=True).stdout)
            assert abs(float(metadata['format']['duration']) - 4.0) < 0.6, metadata
            assert any(s['codec_type'] == 'video' and s['codec_name'] == 'h264' for s in metadata['streams'])
            assert any(s['codec_type'] == 'audio' and s['codec_name'] == 'aac' for s in metadata['streams'])

            # Verify project catalog updated
            project_view = request('GET', f'/projects/{user_id}/{project_id}', headers=headers).json()
            catalogued = next(item for item in project_view['videos'] if item['id'] == job['resultId'])
            assert catalogued['sourceVideoId'] == original_id and catalogued['removeSegmentJobId'] == job_id
            assert catalogued['duration'] > 0 and catalogued['width'] == 320 and catalogued['height'] == 240

            # 6. Edge Cut 1: Cut at start (0 to 2.0 -> remaining ~4.0s)
            v = project_view['version']
            edge1 = request('POST', f'/projects/{user_id}/{project_id}/video/{original_id}/remove-segment',
                expected=(202,), headers={**headers, 'X-Project-Version': str(v)},
                json={'start': 0.0, 'end': 2.0}).json()
            edge1_job = wait_job(user_id, project_id, edge1['id'], headers)
            assert edge1_job['state'] == 'COMPLETED', edge1_job
            video_ids.append(edge1_job['resultId'])

            # 7. Edge Cut 2: Cut at end (4.0 to 6.0 -> remaining ~4.0s)
            v = request('GET', f'/projects/{user_id}/{project_id}', headers=headers).json()['version']
            edge2 = request('POST', f'/projects/{user_id}/{project_id}/video/{original_id}/remove-segment',
                expected=(202,), headers={**headers, 'X-Project-Version': str(v)},
                json={'start': 4.0, 'end': 6.0}).json()
            edge2_job = wait_job(user_id, project_id, edge2['id'], headers)
            assert edge2_job['state'] == 'COMPLETED', edge2_job
            video_ids.append(edge2_job['resultId'])

            # 8. Test Sharing permissions
            collaborator = request('POST', '/users/', expected=(201,), json={
                'name': 'RemoveSegment collab test', 'email': f'rem-collab-{uuid.uuid4()}@example.invalid',
                'password': 'TemporaryTestPassword123', 'type': 'free'}).json()
            collaborator_id, collaborator_token = collaborator['user']['_id'], collaborator['jwt']
            collaborator_headers = {'Authorization': f'Bearer {collaborator_token}'}

            v = request('GET', f'/projects/{user_id}/{project_id}', headers=headers).json()['version']
            read_share = request('POST', f'/projects/{user_id}/{project_id}/share',
                expected=(201,), headers={**headers, 'X-Project-Version': str(v)},
                json={'permission': 'read'}).json()['id']

            # Read-only collaborator cannot remove-segment
            forbidden = request('POST',
                f'/projects/{user_id}/{project_id}/video/{original_id}/remove-segment?share={read_share}',
                expected=(403,), headers={**collaborator_headers, 'X-Project-Version': str(v)},
                json={'start': 1.0, 'end': 2.0}).json()
            assert forbidden['code'] == 'EDIT_REQUIRED', forbidden

            # Edit share allows remove-segment
            v = request('GET', f'/projects/{user_id}/{project_id}', headers=headers).json()['version']
            edit_share = request('POST', f'/projects/{user_id}/{project_id}/share',
                expected=(201,), headers={**headers, 'X-Project-Version': str(v)},
                json={'permission': 'edit'}).json()['id']

            v = request('GET', f'/projects/{user_id}/{project_id}', headers=headers).json()['version']
            collab_job = request('POST',
                f'/projects/{user_id}/{project_id}/video/{original_id}/remove-segment?share={edit_share}',
                expected=(202,), headers={**collaborator_headers, 'X-Project-Version': str(v)},
                json={'start': 1.0, 'end': 2.0}).json()
            collab_result = wait_job(user_id, project_id, collab_job['id'], collaborator_headers, edit_share)
            assert collab_result['state'] == 'COMPLETED', collab_result
            video_ids.append(collab_result['resultId'])

            # 9. Test Cancellation
            subprocess.run(['docker', 'pause', 'picturas-video_remove_segment_worker-1'], check=True,
                stdout=subprocess.DEVNULL)
            try:
                v = request('GET', f'/projects/{user_id}/{project_id}', headers=headers).json()['version']
                queued = request('POST', f'/projects/{user_id}/{project_id}/video/{original_id}/remove-segment',
                    expected=(202,), headers={**headers, 'X-Project-Version': str(v)},
                    json={'start': 0.0, 'end': 1.0}).json()
                cancelled = request('DELETE',
                    f'/projects/{user_id}/{project_id}/video/remove-segment/jobs/{queued["id"]}',
                    headers=headers).json()
                assert cancelled['state'] == 'CANCELLED', cancelled
            finally:
                subprocess.run(['docker', 'unpause', 'picturas-video_remove_segment_worker-1'], check=True,
                    stdout=subprocess.DEVNULL)

            # 10. Test video without audio
            silent = Path(temp) / 'silent.mp4'
            subprocess.run(['ffmpeg', '-nostdin', '-y', '-f', 'lavfi', '-i',
                'testsrc=size=160x120:rate=25', '-t', '4', '-c:v', 'libx264',
                '-pix_fmt', 'yuv420p', str(silent)], check=True,
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            v = request('GET', f'/projects/{user_id}/{project_id}', headers=headers).json()['version']
            with silent.open('rb') as stream:
                silent_upload = request('POST', f'/projects/{user_id}/{project_id}/video',
                    expected=(201,), headers={**headers, 'X-Project-Version': str(v),
                        'X-Video-Name': 'silent.mp4', 'X-Video-Size': str(silent.stat().st_size)},
                    files={'video': ('silent.mp4', stream, 'video/mp4')}).json()
            silent_id = silent_upload['id']
            video_ids.append(silent_id)

            v = request('GET', f'/projects/{user_id}/{project_id}', headers=headers).json()['version']
            silent_job = request('POST', f'/projects/{user_id}/{project_id}/video/{silent_id}/remove-segment',
                expected=(202,), headers={**headers, 'X-Project-Version': str(v)},
                json={'start': 1.0, 'end': 2.0}).json()
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
            assert not any(s['codec_type'] == 'audio' for s in streams), 'Silent output unexpectedly contains audio'

            print(json.dumps({'status': 'passed', 'jobId': job_id, 'resultId': job['resultId'],
                'duration': metadata['format']['duration']}))
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
                    f"db.removesegmentjobs.deleteMany({{projectId:ObjectId('{project_id}')}}); "
                    f"db.videostorageaccounts.deleteMany({{ownerId:ObjectId('{user_id}')}})"],
                    check=True, stdout=subprocess.DEVNULL)


if __name__ == '__main__':
    main()
