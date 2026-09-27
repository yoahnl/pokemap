from math import atan2, exp, hypot, pi
from pathlib import Path

from PIL import Image


OUTPUT = Path(__file__).resolve().parents[1] / 'assets' / 'splash'
OUTPUT.mkdir(parents=True, exist_ok=True)


def mix(first, second, amount):
    return tuple(round(a + (b - a) * amount) for a, b in zip(first, second))


def sweep(angle, colors):
    position = (angle % (2 * pi)) / (2 * pi) * (len(colors) - 1)
    index = min(int(position), len(colors) - 2)
    return mix(colors[index], colors[index + 1], position - index)


def orbit(name, colors, soft):
    size = 1536
    center = (size - 1) / 2
    radius = size / 2.5
    width = radius * (0.13 if soft else 0.09)
    spread = radius * 0.05 if soft else 1.5
    pixels = bytearray(size * size * 4)
    reach = width / 2 + spread * (3.5 if soft else 1)
    for y in range(size):
        dy = y - center
        for x in range(size):
            dx = x - center
            distance = hypot(dx, dy) - radius
            if abs(distance) > reach:
                continue
            if soft:
                outside = max(0.0, abs(distance) - width / 2)
                alpha = exp(-0.5 * (outside / spread) ** 2)
            else:
                alpha = min(1.0, max(0.0, width / 2 + 1.5 - abs(distance)) / 1.5)
            red, green, blue = sweep(atan2(dy, dx), colors)
            offset = (y * size + x) * 4
            pixels[offset:offset + 4] = bytes((red, green, blue, round(alpha * 255)))
    Image.frombytes('RGBA', (size, size), bytes(pixels)).save(OUTPUT / name, optimize=True)


def disc():
    size = 1024
    center = (size - 1) / 2
    radius = size / 2.5
    pixels = bytearray(size * size * 4)
    for y in range(size):
        dy = y - center
        for x in range(size):
            dx = x - center
            distance = hypot(dx, dy)
            if distance > radius * 1.22:
                continue
            gradient = min(1.0, hypot(dx - radius * 0.12, dy + radius * 0.2) / (radius * 1.3))
            red, green, blue = mix((9, 11, 22), (1, 2, 7), gradient)
            if distance <= radius * 0.94:
                alpha = 1.0
            else:
                fade = (distance - radius * 0.94) / (radius * 0.28)
                alpha = (1 - min(1.0, fade)) ** 2
            offset = (y * size + x) * 4
            pixels[offset:offset + 4] = bytes((red, green, blue, round(alpha * 255)))
    Image.frombytes('RGBA', (size, size), bytes(pixels)).save(OUTPUT / 'eclipse_disc.png', optimize=True)


orbit('eclipse_orbit_soft.png', [(60, 137, 255), (168, 84, 255), (251, 123, 189), (60, 137, 255)], True)
orbit('eclipse_orbit_sharp.png', [(29, 113, 245), (56, 224, 228), (255, 247, 194), (243, 106, 196), (139, 86, 238), (29, 113, 245)], False)
disc()
