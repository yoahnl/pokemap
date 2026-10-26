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
destination.mkdir(parents=True, exist_ok=True)
provenance = json.loads((args.source_directory.parent / 'provenance.json').read_text())
receipt_path = destination / 'provenance.json'
receipt = {'model': provenance['model'], 'sampleRate': 22050, 'channels': 2, 'crossfadeSeconds': .65, 'sources': json.loads(receipt_path.read_text()).get('sources', {}) if receipt_path.exists() else {}}
for kind in ['rain', 'wind']:
    source = args.source_directory / (kind + '-source.mp3')
    with tempfile.TemporaryDirectory(prefix='avelune-weather-audio-', dir=args.source_directory) as temporary:
        decoded = Path(temporary) / 'decoded.wav'
        subprocess.run(['ffmpeg', '-v', 'error', '-i', str(source), '-ar', '22050', '-ac', '2', '-c:a', 'pcm_s16le', str(decoded)], check=True)
        with wave.open(str(decoded), 'rb') as audio:
            rate = audio.getframerate()
            channels = audio.getnchannels()
            samples = array.array('h', audio.readframes(audio.getnframes()))
    if sys.byteorder != 'little':
        samples.byteswap()
    overlap = round(rate * .65) * channels
    output = array.array('h', samples[overlap:])
    start = len(output) - overlap
    for index in range(overlap):
        progress = (index // channels) / (overlap / channels - 1)
        value = output[start + index] * math.cos(progress * math.pi / 2) + samples[index] * math.sin(progress * math.pi / 2)
        output[start + index] = max(-32768, min(32767, round(value)))
    rms = math.sqrt(sum(float(value) ** 2 for value in output) / len(output))
    peak = max(abs(value) for value in output)
    gain = min(.16 * 32767 / max(1, rms), .85 * 32767 / max(1, peak))
    output = array.array('h', (round(value * gain) for value in output))
    if sys.byteorder != 'little':
        output.byteswap()
    target = destination / (kind + '-loop.wav')
    with wave.open(str(target), 'wb') as audio:
        audio.setnchannels(channels)
        audio.setsampwidth(2)
        audio.setframerate(rate)
        audio.writeframes(output.tobytes())
    receipt['sources'][kind] = {
        'jobId': provenance[kind]['id'],
        'prompt': provenance[kind]['prompt'],
        'url': provenance[kind]['url'],
        'sourceSha256': hashlib.sha256(source.read_bytes()).hexdigest(),
        'outputSha256': hashlib.sha256(target.read_bytes()).hexdigest(),
        'durationSeconds': len(output) / channels / rate,
    }
(destination / 'provenance.json').write_text(json.dumps(receipt, indent=2) + '\n')
print(json.dumps(receipt, indent=2))

subprocess.run([sys.executable, str(Path(__file__).with_name('derive_storm_audio.py'))], check=True)
