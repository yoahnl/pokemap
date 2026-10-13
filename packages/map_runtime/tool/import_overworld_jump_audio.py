import argparse
import hashlib
import json
from pathlib import Path
import wave

parser = argparse.ArgumentParser()
parser.add_argument('source_project', type=Path)
options = parser.parse_args()
config_path = options.source_project / 'Data/configs/sound_design_config.json'
config = json.loads(config_path.read_text())
sounds = config.get('sounds', config)
if 'jump' not in sounds:
    sounds = next(value for value in config.values()
                  if isinstance(value, dict) and 'jump' in value)
cue = sounds['jump']
relative = cue['name']
source = (options.source_project / relative).resolve(strict=True)
if not source.is_relative_to(options.source_project.resolve(strict=True)):
    raise ValueError('Jump audio must belong to the source project')
data = source.read_bytes()
with wave.open(str(source)) as audio:
    audio_details = {'channels': audio.getnchannels(),
                     'sampleRate': audio.getframerate(),
                     'sampleWidthBytes': audio.getsampwidth(),
                     'durationSeconds': audio.getnframes() / audio.getframerate()}
target = Path(__file__).resolve().parent.parent / 'assets/audio/overworld'
target.mkdir(parents=True, exist_ok=True)
(target / 'jump.wav').write_bytes(data)
receipt = {'sourceProject': 'PSDK test project',
           'sourceRelativePath': relative,
           'sourceConfig': 'Data/configs/sound_design_config.json',
           'sourceConfigSha256': hashlib.sha256(config_path.read_bytes()).hexdigest(),
           'sha256': hashlib.sha256(data).hexdigest(),
           'bytes': len(data), 'volume': cue['volume'], 'pitch': cue['pitch'],
           'audio': audio_details, 'importer': 'tool/import_overworld_jump_audio.py'}
(target / 'jump.source.json').write_text(json.dumps(receipt, indent=2) + '\n')
print(json.dumps(receipt))
