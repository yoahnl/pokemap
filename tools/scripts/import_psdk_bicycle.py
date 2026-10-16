import argparse
import hashlib
import json
from pathlib import Path
import struct


def import_bicycle(source_root, output, variant):
    source_root = Path(source_root).resolve(strict=True)
    output = Path(output).resolve()
    sources = [source_root / 'graphics' / 'characters' /
               f'player_{variant}_cycle_{suffix}.png'
               for suffix in ('roll', 'stop')]
    assets = []
    for source in sources:
        data = source.read_bytes()
        if data[:8] != b'\x89PNG\r\n\x1a\n' or struct.unpack('>II', data[16:24]) != (128, 128):
            raise ValueError(f'Expected an unmodified 128x128 PSDK sheet: {source}')
        if output == source_root or output == source.parent or source_root in output.parents:
            raise ValueError('Output must be outside the source checkout')
        assets.append((source, data))
    output.mkdir(parents=True, exist_ok=True)
    receipt = {'source': str(source_root), 'variant': variant,
               'layout': {'frameWidth': 32, 'frameHeight': 32,
                          'columns': 4, 'directions': ['south', 'west', 'east', 'north'],
                          'durationMs': 100, 'anchor': 'feet', 'displayHeightTiles': 2},
               'assets': []}
    for source, data in assets:
        target = output / source.name
        target.write_bytes(data)
        receipt['assets'].append({'source': str(source), 'output': str(target),
                                  'sha256': hashlib.sha256(data).hexdigest()})
    (output / 'bicycle_provenance.json').write_text(json.dumps(receipt, indent=2) + '\n')
    return receipt


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source-root', required=True)
    parser.add_argument('--output', required=True)
    parser.add_argument('--variant', choices=['m', 'f'], default='m')
    args = parser.parse_args()
    print(json.dumps(import_bicycle(args.source_root, args.output, args.variant), indent=2))


if __name__ == '__main__':
    main()
