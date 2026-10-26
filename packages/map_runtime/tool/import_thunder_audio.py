import argparse
import array
import hashlib
import json
import math
from pathlib import Path
import subprocess
import sys
import tempfile
import wave

parser = argparse.ArgumentParser()
parser.add_argument('--source-directory', required=True, type=Path)
args = parser.parse_args()
destination = Path(__file__).resolve().parent.parent / 'assets/audio/weather'
source_metadata = json.loads((args.source_directory / 'provenance.json').read_text())
provenance_path = destination / 'provenance.json'
provenance = json.loads(provenance_path.read_text())

for item in source_metadata['items']:
    index = item['index']
    if index not in (0, 1, 2):
        raise ValueError('Expected three thunder variants')
    source = args.source_directory / f'thunder-{index}.mp3'
    with tempfile.TemporaryDirectory(dir=args.source_directory) as temporary:
        decoded = Path(temporary) / 'decoded.wav'
        subprocess.run(['ffmpeg', '-v', 'error', '-i', str(source), '-ar', '22050', '-ac', '2', '-c:a', 'pcm_s16le', str(decoded)], check=True)
        with wave.open(str(decoded), 'rb') as audio:
            rate, channels = audio.getframerate(), audio.getnchannels()
            samples = array.array('h', audio.readframes(audio.getnframes()))
    if sys.byteorder != 'little':
        samples.byteswap()
    source_start = 0
    if item.get('recorded'):
        step = rate * channels // 20
        levels = [sum(float(v) ** 2 for v in samples[at:at+step]) / len(samples[at:at+step]) for at in range(0, len(samples), step)]
        threshold = max(levels) * .025
        onset = next(at for at, level in enumerate(levels) if level >= threshold)
        source_start = max(0, onset * step - rate * channels // 10)
        samples = samples[source_start:source_start + rate * channels * 12]
    peak = max(abs(value) for value in samples)
    rms = math.sqrt(sum(value * value for value in samples) / len(samples))
    gain = min(.16 * 32767 / max(rms, 1), .85 * 32767 / max(peak, 1))
    for frame in range(len(samples) // channels):
        envelope = min(1, frame / (rate * .008), (len(samples) // channels - frame - 1) / (rate * (.8 if item.get('recorded') else .08)))
        for channel in range(channels):
            at = frame * channels + channel
            samples[at] = round(samples[at] * gain * max(0, envelope))
    variant = (2, 1, 0)[index] if item.get('recorded') else index
    target = destination / f"thunder-{'recorded-' if item.get('recorded') else ''}{variant}.wav"
    encoded = samples.tobytes()
    if sys.byteorder != 'little':
        samples.byteswap()
        encoded = samples.tobytes()
    with wave.open(str(target), 'wb') as output:
        output.setnchannels(channels)
        output.setsampwidth(2)
        output.setframerate(rate)
        output.writeframes(encoded)
    provenance['sources'][target.stem] = {
        'model': source_metadata['model'], 'jobId': item.get('jobId'), 'prompt': item.get('prompt'), 'url': item['url'],
        'sourceSha256': hashlib.sha256(source.read_bytes()).hexdigest(),
        'outputSha256': hashlib.sha256(target.read_bytes()).hexdigest(),
        'durationSeconds': len(samples) / channels / rate, 'loop': False,
        'normalizationGain': gain,
        'author': item.get('author'), 'license': item.get('license'), 'licenseUrl': item.get('licenseUrl'),
        'sourcePage': item.get('sourcePage'), 'recorded': item.get('recorded', False),
        'trimStartSeconds': source_start / channels / rate,
    }
    print(json.dumps({'file': target.name, 'durationSeconds': len(samples) / channels / rate, 'peak': max(abs(value) for value in samples) / 32768}))
provenance_path.write_text(json.dumps(provenance, indent=2) + '\n')
