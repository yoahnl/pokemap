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

for variant in range(3):
    source = folder / f'thunder-{0 if variant != 1 else 2}.wav'
    with wave.open(str(source), 'rb') as audio:
        rate, channels = audio.getframerate(), audio.getnchannels()
        samples = array.array('h', audio.readframes(audio.getnframes()))
    if sys.byteorder != 'little':
        samples.byteswap()
    frames = len(samples) // channels
    length = 10 + variant
    offset = .35 * rate if variant == 1 else 0
    def one_shot(frame, channel):
        base = int(frame)
        if base < 0 or base + 1 >= frames:
            return 0.0
        fraction = frame - base
        return (samples[base * channels + channel] * (1 - fraction) + samples[(base + 1) * channels + channel] * fraction) / 32768
    low = [0.0] * channels
    dc = [0.0] * channels
    low_alpha = 1 - math.exp(-2 * math.pi * 1400 / rate)
    dc_alpha = 1 - math.exp(-2 * math.pi * 35 / rate)
    mixed = array.array('d')
    for frame in range(length * rate):
        envelope = min(1, frame / (rate * .25), (length * rate - frame - 1) / (rate * 2))
        for channel in range(channels):
            value = sum(one_shot((frame - delay * rate) * ratio + offset, channel) * gain for ratio, delay, gain in ((.68 + variant * .025, 0, .8), (.52, .45, .5), (.79, 1.2, .3)))
            low[channel] += low_alpha * (value - low[channel])
            dc[channel] += dc_alpha * (low[channel] - dc[channel])
            mixed.append((low[channel] - dc[channel]) * envelope)
    rms = math.sqrt(sum(value * value for value in mixed) / len(mixed))
    gain = .22 / max(rms, .0001)
    output = array.array('h', (round(math.tanh(value * gain) * .85 * 32767) for value in mixed))
    peak = max(abs(value) for value in output) / 32768
    final_rms = math.sqrt(sum(value * value for value in output) / len(output)) / 32768
    if sys.byteorder != 'little':
        output.byteswap()
    target = folder / f'thunder-roll-{variant}.wav'
    with wave.open(str(target), 'wb') as audio:
        audio.setnchannels(channels)
        audio.setsampwidth(2)
        audio.setframerate(rate)
        audio.writeframes(output.tobytes())
    provenance['sources'][f'thunder-roll-{variant}'] = {
        'derivedFrom': source.name,
        'sourceSha256': hashlib.sha256(source.read_bytes()).hexdigest(),
        'outputSha256': hashlib.sha256(target.read_bytes()).hexdigest(),
        'method': 'Pitch-stretched rolling layers, high-pass 35 Hz, low-pass 1400 Hz, soft saturation, soft onset and two-second decay',
        'durationSeconds': length, 'loop': False, 'peak': peak, 'rms': final_rms,
    }
    print(json.dumps(provenance['sources'][f'thunder-roll-{variant}']))
provenance_path.write_text(json.dumps(provenance, indent=2) + '\n')
