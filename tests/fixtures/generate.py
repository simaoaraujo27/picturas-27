"""Create small deterministic media; generated files are ignored by Git."""
from pathlib import Path
import subprocess
from PIL import Image, ImageDraw

root = Path(__file__).parent
for category in ('images', 'videos', 'invalid'):
    (root / category).mkdir(exist_ok=True)
im = Image.new('RGB', (160, 120), (70, 100, 140))
ImageDraw.Draw(im).rectangle((0, 0, 79, 59), fill=(220, 30, 20))
im.save(root / 'images' / 'pattern.png')
im.save(root / 'images' / 'pattern.jpg')
text = Image.new('RGB', (640, 200), 'white')
ImageDraw.Draw(text).text((30, 50), 'PICTURAS TEST 123', fill='black', font_size=48)
text.save(root / 'images' / 'text.png')
(root / 'invalid' / 'invalid.png').write_bytes(b'this is not an image')
(root / 'invalid' / 'corrupt.mp4').write_bytes(b'this is not a video')
for name, seconds, audio in [('clip.mp4', 4, True), ('silent.mov', 2, False), ('long.mp4', 61, False), ('clip.webm', 2, False)]:
    command = ['ffmpeg', '-y', '-v', 'error', '-f', 'lavfi', '-i', f'testsrc=size=160x120:rate=10:duration={seconds}']
    if audio:
        command += ['-f', 'lavfi', '-i', f'sine=frequency=440:duration={seconds}', '-c:a', 'aac']
    command += ['-c:v', 'libvpx-vp9' if name.endswith('webm') else 'libx264', '-pix_fmt', 'yuv420p', '-shortest', str(root / 'videos' / name)]
    subprocess.run(command, check=True)

speech = Path(__file__).resolve().parents[2] / 'samples/video/speech_mandela_177s_1080p.webm'
if speech.exists():
    subprocess.run(['ffmpeg', '-y', '-v', 'error', '-f', 'lavfi', '-i', 'color=black:size=320x240:rate=10:duration=6',
                    '-ss', '40', '-i', str(speech), '-map', '0:v', '-map', '1:a', '-t', '6',
                    '-c:v', 'libx264', '-c:a', 'aac', '-pix_fmt', 'yuv420p', str(root / 'videos' / 'speech.mp4')], check=True)
