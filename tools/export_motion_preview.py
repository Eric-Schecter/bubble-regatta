"""Encode the actual Godot --motion-test frames; preserve frame timings and music pause."""
import json
import pathlib
import subprocess
import sys

root = pathlib.Path(__file__).resolve().parents[1]
kind = 'face' if len(sys.argv)>1 and sys.argv[1]=='face' else 'motion'
folder = root / 'captures' / kind
meta = json.loads((folder / 'audio-timing.json').read_text())
if 'pause_clock' in meta:
    pre = meta['pause_clock'] - meta['start_clock']
    silence = meta['resume_clock'] - meta['pause_clock']
    after = max(0.01, meta['duration'] - pre - silence)
    a0 = meta['audio_start']
    a1 = a0 + pre
    filters = (
        f'[1:a]atrim=start={a0}:duration={pre},asetpts=PTS-STARTPTS,volume=0.25[first];'
        f'anullsrc=r=22050:cl=mono,atrim=duration={silence}[silence];'
        f'[1:a]atrim=start={a1}:duration={after},asetpts=PTS-STARTPTS,volume=0.25[last];'
        '[first][silence][last]concat=n=3:v=0:a=1[audio]'
    )
else:
    filters = f"[1:a]atrim=start={meta['audio_start']}:duration={meta['duration']},asetpts=PTS-STARTPTS,volume=0.25[audio]"
output = root / 'captures' / ('captain-faces.mp4' if kind=='face' else 'captain-actions.mp4')
subprocess.run([
    'ffmpeg', '-hide_banner', '-loglevel', 'error', '-y',
    '-f', 'concat', '-safe', '0', '-i', str(folder / 'timing.txt'),
    '-i', str(root / 'assets' / 'boats' / 'harbor-day.wav'),
    '-filter_complex', filters, '-map', '0:v', '-map', '[audio]',
    '-r', '24', '-c:v', 'libx264', '-preset', 'fast', '-crf', '22',
    '-pix_fmt', 'yuv420p', '-c:a', 'aac', '-b:a', '128k',
    '-shortest', '-movflags', '+faststart', str(output)
], check=True)
print(output)
