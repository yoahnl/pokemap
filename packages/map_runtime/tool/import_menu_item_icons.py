import argparse
import concurrent.futures
import hashlib
import json
from pathlib import Path
import re
import struct
import tempfile
import time
import urllib.error
import urllib.request
import zipfile


REVISION = 'a314f271cab74db3ff559477646688a01c4bb30b'
ITEMS_TREE = 'df95f7a6e708277ffb375ef265c40ad25d4384f4'
REPOSITORY = 'https://github.com/PokeAPI/sprites'
OUTPUT = Path(__file__).resolve().parents[1] / 'assets' / 'menu' / 'items'
ILLUSTRATIONS = Path(__file__).resolve().parent / 'assets' / 'menu_item_illustrations' / 'manifest.json'


def download(path):
    url = f'https://raw.githubusercontent.com/PokeAPI/sprites/{REVISION}/{path}'
    for attempt in range(3):
        try:
            with urllib.request.urlopen(url, timeout=30) as response:
                return response.read()
        except urllib.error.URLError:
            if attempt == 2:
                raise
            time.sleep(attempt + 1)


def fingerprint(contents):
    return hashlib.sha256(contents).hexdigest()


def verify():
    manifest = json.loads((OUTPUT / 'manifest.json').read_text())
    archive = OUTPUT / 'icons.zip'
    if fingerprint(archive.read_bytes()) != manifest['archiveSha256']:
        raise ValueError('Item archive fingerprint differs from its manifest.')
    with zipfile.ZipFile(archive) as bundle:
        expected_files = {'LICENCE.txt'}
        for item_id, entry in manifest['items'].items():
            name = f'{item_id}.png'
            expected_files.add(name)
            contents = bundle.read(name)
            if fingerprint(contents) != entry['sha256']:
                raise ValueError(f'Invalid fingerprint for {item_id}.')
            if len(contents) != entry['bytes']:
                raise ValueError(f'Invalid length for {item_id}.')
            dimensions = struct.unpack('>II', contents[16:24])
            if dimensions != (entry['width'], entry['height']):
                raise ValueError(f'Invalid dimensions for {item_id}.')
        if set(bundle.namelist()) != expected_files:
            raise ValueError('Archive and manifest inventories differ.')
        if fingerprint(bundle.read('LICENCE.txt')) != manifest['licenseSha256']:
            raise ValueError('Source license fingerprint differs.')
    print(f"Verified {len(manifest['items'])} item icons at {manifest['revision']}.")


def apply_illustrations(assets):
    if not ILLUSTRATIONS.exists():
        return assets
    manifest = json.loads(ILLUSTRATIONS.read_text())
    if manifest['schemaVersion'] != 1:
        raise ValueError('Unsupported item illustration source manifest.')
    result = {Path(name).stem: (name, contents, entry)
              for name, contents, entry in assets}
    for item_id, source in manifest['items'].items():
        if item_id not in result:
            raise ValueError(f'Illustration has no canonical item: {item_id}.')
        file = (ILLUSTRATIONS.parent / source['file']).resolve()
        if not file.is_relative_to(ILLUSTRATIONS.parent.resolve()):
            raise ValueError('Illustration escapes its source directory.')
        contents = file.read_bytes()
        if (fingerprint(contents) != source['sha256'] or
                len(contents) != source['bytes'] or
                not contents.startswith(b'\x89PNG\r\n\x1a\n') or
                struct.unpack('>II', contents[16:24]) !=
                (source['width'], source['height'])):
            raise ValueError(f'Illustration differs from its manifest: {item_id}.')
        result[item_id] = (f'{item_id}.png', contents, {
            **source,
            'sourcePath': file.relative_to(Path(__file__).resolve().parents[1]).as_posix(),
            'provenance': {**manifest['provenance'], **source.get('provenance', {})},
            'canonicalSource': result[item_id][2],
        })
    return [result[item_id] for item_id in sorted(result)]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--verify', action='store_true')
    parser.add_argument('--cache', type=Path, default=Path(tempfile.gettempdir()) /
                        'pokemap-item-icon-source' / REVISION)
    arguments = parser.parse_args()
    if arguments.verify:
        verify()
        return
    url = f'https://api.github.com/repos/PokeAPI/sprites/git/trees/{ITEMS_TREE}'
    with urllib.request.urlopen(url, timeout=30) as response:
        tree = json.load(response)
    if tree['sha'] != ITEMS_TREE or tree.get('truncated'):
        raise ValueError('Unexpected or incomplete source inventory.')
    sources = sorted(
        (entry for entry in tree['tree']
         if entry['type'] == 'blob' and entry['path'].endswith('.png')),
        key=lambda entry: entry['path'],
    )
    arguments.cache.mkdir(parents=True, exist_ok=True)

    def read(entry):
        name = entry['path']
        if not re.fullmatch(r'[a-z0-9][a-z0-9-]*\.png', name):
            raise ValueError(f'Unexpected source filename: {name}.')
        cached = arguments.cache / name
        contents = cached.read_bytes() if cached.exists() else b''
        git_contents = f'blob {len(contents)}\0'.encode() + contents
        if hashlib.sha1(git_contents).hexdigest() != entry['sha']:
            contents = download(f'sprites/items/{name}')
        git_contents = f'blob {len(contents)}\0'.encode() + contents
        if hashlib.sha1(git_contents).hexdigest() != entry['sha']:
            raise ValueError(f'Source Git blob differs: {name}.')
        if not contents.startswith(b'\x89PNG\r\n\x1a\n'):
            raise ValueError(f'Invalid PNG: {name}.')
        width, height = struct.unpack('>II', contents[16:24])
        if width <= 0 or height <= 0 or width > 128 or height > 128:
            raise ValueError(f'Unexpected source dimensions: {name}.')
        cached.write_bytes(contents)
        return name, contents, {
            'sourcePath': f'sprites/items/{name}',
            'gitBlob': entry['sha'],
            'sha256': fingerprint(contents),
            'bytes': len(contents),
            'width': width,
            'height': height,
        }

    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as executor:
        assets = list(executor.map(read, sources))
    assets = apply_illustrations(assets)
    license_contents = download('LICENCE.txt')
    OUTPUT.mkdir(parents=True, exist_ok=True)
    archive = OUTPUT / 'icons.zip'
    with zipfile.ZipFile(archive, 'w') as bundle:
        for name, contents, _ in assets:
            bundle.writestr(zipfile.ZipInfo(name), contents)
        bundle.writestr(zipfile.ZipInfo('LICENCE.txt'), license_contents)
    manifest = {
        'schemaVersion': 1,
        'repository': REPOSITORY,
        'revision': REVISION,
        'sourceTree': ITEMS_TREE,
        'importer': 'tool/import_menu_item_icons.py',
        'sampling': 'nearest',
        'aliases': {'king-s-rock': 'kings-rock'},
        'aliasProvenance': {
            'repository': 'https://github.com/PokeAPI/pokeapi',
            'revision': 'd4f9a4af58ade123fbc0558f68b1c69daa97d9e4',
            'paths': ['data/v2/csv/items.csv', 'data/v2/csv/item_names.csv'],
            'pokeApiItemId': 198,
            'englishName': 'King’s Rock',
            'frenchName': 'Roche Royale',
        },
        'licensePath': 'LICENCE.txt',
        'licenseSha256': fingerprint(license_contents),
        'canonicalImageCopyright': 'The Pokémon Company',
        'repositoryLicense': 'CC0-1.0',
        'archiveSha256': fingerprint(archive.read_bytes()),
        'items': {Path(name).stem: entry for name, _, entry in assets},
    }
    (OUTPUT / 'manifest.json').write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + '\n'
    )
    verify()


if __name__ == '__main__':
    main()
