from math import cos, pi, sin
from pathlib import Path
from subprocess import PIPE, Popen

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[3]
WIDTH = 590
HEIGHT = 1278
SCALE = WIDTH / 390
FRAMES = 252
RATE = 60
OUTPUT = ROOT / 'apps/pokemap_hub/assets/avelune/splash/avelune_eclipse.mp4'
ASSETS = ROOT / 'packages/map_player_ui/assets/splash'
LOGOS = ROOT / 'apps/pokemap_hub/assets/avelune/logo'
AUDIO = ROOT / 'packages/map_runtime/assets/audio/premium_splash_jingle.wav'


def smooth(value, start, end):
    fraction = max(0.0, min(1.0, (value - start) / (end - start)))
    return fraction * fraction * (3 - 2 * fraction)


def between(first, second, fraction):
    return first + (second - first) * fraction


def place(canvas, source, width, x, y, angle=0.0, opacity=1.0):
    if opacity <= 0:
        return
    step = width / source.width
    turn = angle * pi / 180
    a = cos(turn) / step
    b = sin(turn) / step
    d = -sin(turn) / step
    e = cos(turn) / step
    transform = (a, b, source.width / 2 - a * x - b * y,
                 d, e, source.height / 2 - d * x - e * y)
    layer = source.transform(
        canvas.size, Image.Transform.AFFINE, transform,
        resample=Image.Resampling.BILINEAR,
    )
    if opacity < 1:
        layer.putalpha(layer.getchannel('A').point(lambda alpha: round(alpha * opacity)))
    canvas.alpha_composite(layer)


background = Image.new('RGBA', (WIDTH, HEIGHT), (3, 3, 6, 255))
glow = Image.new('RGBA', (WIDTH, HEIGHT))
draw = ImageDraw.Draw(glow)
draw.ellipse((WIDTH * .04, HEIGHT * .22, WIDTH * .96, HEIGHT * .70), fill=(82, 69, 108, 35))
background.alpha_composite(glow.filter(ImageFilter.GaussianBlur(WIDTH * .28)))
soft = Image.open(ASSETS / 'eclipse_orbit_soft.png').convert('RGBA')
sharp = Image.open(ASSETS / 'eclipse_orbit_sharp.png').convert('RGBA')
disc = Image.open(ASSETS / 'eclipse_disc.png').convert('RGBA')
logo = Image.open(LOGOS / 'avelune_moon.png').convert('RGBA')
wordmark = Image.open(LOGOS / 'avelune_glass_wordmark.png').convert('RGBA')
OUTPUT.parent.mkdir(parents=True, exist_ok=True)

command = [
    'ffmpeg', '-hide_banner', '-loglevel', 'error', '-y',
    '-f', 'rawvideo', '-pixel_format', 'rgb24', '-video_size', f'{WIDTH}x{HEIGHT}',
    '-framerate', str(RATE), '-i', '-', '-i', str(AUDIO),
    '-filter_complex', '[1:a]atrim=duration=4.2,asetpts=PTS-STARTPTS[a]',
    '-map', '0:v', '-map', '[a]', '-frames:v', str(FRAMES),
    '-c:v', 'libx264', '-preset', 'medium', '-crf', '17',
    '-pix_fmt', 'yuv420p', '-c:a', 'aac', '-b:a', '192k',
    '-movflags', '+faststart', '-shortest', str(OUTPUT),
]

with Popen(command, stdin=PIPE) as encoder:
    for frame in range(FRAMES):
        elapsed = frame / RATE
        progress = min(elapsed / 4.2, .82)
        time = 3.4 * progress
        collapse = smooth(time, .03, 1.55)
        orbit_opacity = .93 * smooth(time, 0, .2) * (1 - smooth(time, 1.42, 2.04))
        soft_opacity = .62 * smooth(time, 0, .26) * (1 - smooth(time, 1.35, 1.94))
        disc_opacity = smooth(time, .08, .3) * (1 - smooth(time, 1.35, 1.72))
        crossing = smooth(time, .2, 1.35)
        logo_opacity = smooth(time, .55, 1.1) * (1 - smooth(time, 1.35, 1.72))
        mark_opacity = smooth(time, 1.46, 2.04)
        canvas = background.copy()
        center_x = WIDTH / 2
        center_y = HEIGHT * .47
        place(canvas, soft, 390 * .81 * 2.5 * between(.85, .58, collapse) * SCALE,
              center_x, center_y, between(40, 155, collapse), soft_opacity)
        place(canvas, sharp, 390 * .725 * 2.5 * between(1.0, .55, collapse) * SCALE,
              center_x, center_y, between(-75, 42, collapse), orbit_opacity)
        place(canvas, disc, 390 * .485 * 2.5 * between(1.3, .76, collapse) * SCALE,
              center_x + between(-390 * .27, 390 * .37, crossing) * SCALE,
              center_y, opacity=disc_opacity)
        place(canvas, logo, 390 * .42 * between(1.0, .55, smooth(time, .68, 1.45)) * SCALE,
              center_x, center_y, between(-9, 0, collapse), logo_opacity)
        lockup_width = 390 * .74
        symbol_size = min(lockup_width * .24, 844 * .14, 120)
        lockup_left = (390 - lockup_width) / 2
        place(canvas, logo, symbol_size * SCALE,
              (lockup_left + symbol_size / 2) * SCALE, center_y,
              opacity=mark_opacity)
        wordmark_width = lockup_width - symbol_size - lockup_width * .04
        place(canvas, wordmark, wordmark_width * SCALE,
              (lockup_left + symbol_size + lockup_width * .04 + wordmark_width / 2) * SCALE,
              center_y, opacity=mark_opacity)
        encoder.stdin.write(canvas.convert('RGB').tobytes())
    encoder.stdin.close()
    if encoder.wait() != 0:
        raise RuntimeError('Video encoding failed')
