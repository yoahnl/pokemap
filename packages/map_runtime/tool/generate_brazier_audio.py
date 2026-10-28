import array
import math
from pathlib import Path
import random
import wave


def main():
    rate = 16000
    duration = 30
    rng = random.Random(238109)
    data = [0.0] * (rate * duration)
    b0 = b1 = b2 = 0.0
    for i in range(len(data)):
        white = rng.uniform(-1, 1)
        b0 = .99886 * b0 + white * .0555179
        b1 = .99332 * b1 + white * .0750759
        b2 = .969 * b2 + white * .153852
        data[i] = (b0 + b1 + b2 + white * .5362) * .028
    position = .2
    while position < duration - .3:
        heavy = rng.random() < .17
        length = rng.uniform(.11, .22) if heavy else rng.uniform(.025, .085)
        amplitude = rng.uniform(.4, .65) if heavy else rng.uniform(.19, .38)
        filtered = 0.0
        for i in range(int(length * rate)):
            t = i / rate
            filtered += (.2 if heavy else .55) * (rng.uniform(-1, 1) - filtered)
            envelope = min(1, t / .0015) * math.exp(-t * 6 / length)
            data[int(position * rate) + i] += filtered * envelope * amplitude
        position += rng.uniform(.075, .3) + (rng.random() * .45 if rng.random() < .12 else 0)
    peak = max(abs(value) for value in data)
    samples = array.array('h', [round(value * .72 / peak * 32767) for value in data])
    output = Path(__file__).resolve().parents[1] / 'assets/audio/fire/brazier-loop.wav'
    output.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(output), 'wb') as stream:
        stream.setnchannels(1)
        stream.setsampwidth(2)
        stream.setframerate(rate)
        stream.writeframes(samples.tobytes())
    print(f'{output.name}: {duration}s, {output.stat().st_size} bytes, generated original crackling')


if __name__ == '__main__':
    main()
