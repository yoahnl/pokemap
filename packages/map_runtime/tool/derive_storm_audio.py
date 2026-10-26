import array
import hashlib
import json
import math
from pathlib import Path
import sys
import wave

folder = Path(__file__).resolve().parent.parent / 'assets/audio/weather'
provenance_path = folder / 'provenance.json'
provenance = json.loads(provenance_path.read_text())
for kind in ('rain', 'wind'):
    source = folder / f'{kind}-loop.wav'
    with wave.open(str(source), 'rb') as audio:
        rate, channels, width = audio.getframerate(), audio.getnchannels(), audio.getsampwidth()
        samples = array.array('h', audio.readframes(audio.getnframes()))
    if width != 2 or channels != 2:
        raise ValueError('Expected stereo PCM16 source')
    if sys.byteorder != 'little':
        samples.byteswap()
    frames = len(samples) // channels
    layers = ((1, 0, .75), (.81, .31, .6), (.63, .67, .4))
    def at(frame, channel):
        base = math.floor(frame)
        fraction = frame - base
        return (samples[(base % frames) * channels + channel] * (1 - fraction) +
                samples[((base + 1) % frames) * channels + channel] * fraction) / 32768
    mixed = array.array('d', (
        sum(at(frame * ratio + offset * frames, channel) * gain for ratio, offset, gain in layers)
        for frame in range(frames) for channel in range(channels)
    ))
    rms = math.sqrt(sum(value * value for value in mixed) / len(mixed))
    gain = .22 / max(rms, .0001)
    output = array.array('h', (round(math.tanh(value * gain) * .9 * 32767) for value in mixed))
    peak = max(abs(value) for value in output) / 32768
    final_rms = math.sqrt(sum(value * value for value in output) / len(output)) / 32768
    if sys.byteorder != 'little':
        output.byteswap()
    target = folder / f'storm-{kind}-loop.wav'
    with wave.open(str(target), 'wb') as audio:
        audio.setnchannels(channels)
        audio.setsampwidth(width)
        audio.setframerate(rate)
        audio.writeframes(output.tobytes())
    provenance['sources'][f'storm-{kind}'] = {
        'derivedFrom': source.name,
        'sourceSha256': hashlib.sha256(source.read_bytes()).hexdigest(),
        'outputSha256': hashlib.sha256(target.read_bytes()).hexdigest(),
        'method': 'Three decorrelated, pitch-shifted layers with soft saturation; runtime equal-power overlap',
        'layers': layers,
        'durationSeconds': frames / rate,
        'peak': peak,
        'rms': final_rms,
        'loop': True,
    }
    print(json.dumps(provenance['sources'][f'storm-{kind}']))
provenance_path.write_text(json.dumps(provenance, indent=2) + '\n')
