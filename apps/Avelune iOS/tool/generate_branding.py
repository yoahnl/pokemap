from io import BytesIO
from pathlib import Path
import json
import subprocess
import numpy as np
from PIL import Image

root = Path(__file__).resolve().parents[1]
assets = root / 'AveluneiOS/Resources/Assets.xcassets'
runtime = root / 'flutter_runtime/assets/branding'
runtime.mkdir(parents=True, exist_ok=True)
node = '''
const sharp = require('sharp');
const fs = require('fs');
const path = require('path');
const root = process.argv[1];
async function main() {
  if (process.argv[2] === 'symbol') {
    const layers = await Promise.all(['croissant','vague','etoile'].map(async name => ({input:await sharp(path.join(root,'AveluneiOS/AppIcon.icon/Assets',`lagune-${name}.svg`)).png().toBuffer()})));
    process.stdout.write(await sharp({create:{width:1024,height:1024,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite(layers).png().toBuffer());
  } else {
    process.stdout.write(await sharp(path.join(root,'branding/avelune-wordmark.svg')).png().toBuffer());
  }
}
main().catch(error=>{console.error(error.message);process.exitCode=1;});
'''

def raster(kind):
    data = subprocess.check_output(['node', '-e', node, str(root), kind])
    image = Image.open(BytesIO(data)).convert('RGBA')
    return image.crop(image.getbbox())

symbol = raster('symbol')
symbol.thumbnail((900, 940), Image.Resampling.LANCZOS)
moon = Image.new('RGBA', (1024, 1024))
moon.alpha_composite(symbol, ((1024-symbol.width)//2, (1024-symbol.height)//2))
moon.save(assets / 'AveluneMoon.imageset/logo application.png')
moon.save(runtime / 'avelune-lagune.png')
word = raster('wordmark')
word.thumbnail((1660, 370), Image.Resampling.LANCZOS)
wordmark = Image.new('RGBA', (2172, 724))
wordmark.alpha_composite(word, ((2172-word.width)//2, (724-word.height)//2))
wordmark.save(assets / 'AveluneWordmark.imageset/nom application.png')
wordmark.save(runtime / 'avelune-wordmark.png')

original = root.parent / 'pokemap_hub/assets/avelune/splash/avelune_eclipse.mp4'
probe = json.loads(subprocess.check_output(['ffprobe','-v','quiet','-show_streams','-show_format','-of','json',str(original)],text=True))
video = next(s for s in probe['streams'] if s['codec_type']=='video')
width, height = video['width'], video['height']
fps_top, fps_bottom = map(int,video['r_frame_rate'].split('/'))
fps = fps_top/fps_bottom
duration = float(probe['format']['duration'])
y,x = np.mgrid[0:height,0:width]
distance = np.sqrt((x-width/2)**2+(y-height/2)**2)
angle = (np.arctan2(y-height/2,x-width/2)+np.pi)/(2*np.pi)
halo = np.exp(-(distance/(width*.65))**2)[...,None]
background = np.broadcast_to(np.array([3.,3.,6.]),(height,width,3))+halo*np.array([3.,5.,12.])
palette = np.array([[84.,136.,236.],[65.,215.,196.],[255.,189.,153.],[84.,136.,236.]])
output = runtime / 'avelune-lagune-splash.mp4'
command = ['ffmpeg','-y','-hide_banner','-loglevel','error','-f','rawvideo','-pixel_format','rgb24','-video_size',f'{width}x{height}','-framerate',video['r_frame_rate'],'-i','pipe:0','-i',str(original),'-map','0:v:0','-map','1:a:0','-c:v','libx264','-preset','medium','-crf','18','-pix_fmt','yuv420p','-c:a','copy','-t',str(duration),'-movflags','+faststart',str(output)]
encoder = subprocess.Popen(command,stdin=subprocess.PIPE)

def ease(value):
    v = max(0,min(1,value))
    return v*v*(3-2*v)

try:
    for frame in range(round(duration*fps)):
        t = frame/fps
        progress = ease(t/2.6)
        radius = width*(.70-.41*progress)
        ring = np.exp(-((distance-radius)/7)**2)
        glow = np.exp(-((distance-radius)/20)**2)*.22
        opacity = 1-ease((t-1.75)/.85)
        phase = ((angle+t*.13)%1)*3
        index = phase.astype(int)
        mix = (phase-index)[...,None]
        colors = palette[index]*(1-mix)+palette[index+1]*mix
        rgb = background+(ring+glow)[...,None]*colors*opacity
        image = Image.fromarray(np.clip(rgb,0,255).astype(np.uint8),'RGB').convert('RGBA')
        settle = ease((t-1.25)/1.10)
        logo_size = round(154-82*settle)
        logo = symbol.resize((logo_size,round(logo_size*symbol.height/symbol.width)),Image.Resampling.LANCZOS)
        logo.putalpha(logo.getchannel('A').point(lambda a:int(a*ease((t-.85)/.55))))
        center_x = width/2-(width*.23)*settle
        image.alpha_composite(logo,(round(center_x-logo.width/2),round(height/2-logo.height/2)))
        title = word.resize((245,round(245*word.height/word.width)),Image.Resampling.LANCZOS)
        title.putalpha(title.getchannel('A').point(lambda a:int(a*ease((t-1.95)/.65))))
        image.alpha_composite(title,(round(width/2-73),round(height/2-title.height/2)))
        encoder.stdin.write(image.convert('RGB').tobytes())
finally:
    encoder.stdin.close()
if encoder.wait()!=0:
    raise RuntimeError('Splash encoding failed')
print(f'Generated Lagune native/runtime assets and {duration:.1f}s splash at {video["r_frame_rate"]} fps; original AAC stream copied.')
