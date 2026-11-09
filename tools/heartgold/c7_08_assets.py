import hashlib
import importlib.util
import json
import sys
from pathlib import Path


def prepare(work, pack):
    spec = importlib.util.spec_from_file_location('native_content', work / 'revisites_preparer.py')
    native = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(native)
    data = work / 'revisites/c7-08'
    assets = data / 'assets'
    assets.mkdir(parents=True, exist_ok=True)
    prepared = json.loads((work / 'revisites/preparation.json').read_text())['lapras']
    atlas = prepared['sourceSprite']['atlases'][0]
    raw = (pack / atlas['path']).read_bytes()
    if hashlib.sha256(raw).hexdigest() != atlas['sha256']:
        raise ValueError('Native Lapras atlas differs from the prepared source.')
    item = next(row for row in json.loads((native.REFERENCE / 'mecanismes/objets.json').read_text())['records'] if row['symbol'] == 'ITEM_POISON_BARB')
    icon, proof = native.icon_png(item)
    for name, value in [('lapras.png', raw), ('poison-barb.png', icon)]:
        target = assets / name
        if target.exists() and target.read_bytes() != value:
            raise ValueError('Preserve the existing asset: ' + name)
        target.write_bytes(value)
    receipt = {'laprasSha256': atlas['sha256'], 'pixelEditing': False,
        'directionMapping': {'south': [4, 5, 6, 7], 'west': [8, 9, 10, 11], 'east': [12, 13, 14, 15], 'north': [0, 1, 2, 3]},
        'laprasAnimationTiming': '250ms per original frame, presentation adaptation; native sequence cadence not certified',
        'poisonBarb': proof, 'iconSha256': hashlib.sha256(icon).hexdigest()}
    (data / 'assets.json').write_text(json.dumps(receipt, indent=2) + '\n')
    print(json.dumps({'assets': 2, 'originalLaprasBytes': True}))


if __name__ == '__main__':
    prepare(Path(sys.argv[1]).resolve(), Path(sys.argv[2]).resolve())
