import argparse
import hashlib
import json
import re
from pathlib import Path
import xml.etree.ElementTree as ET


INDEX_NAME = 'avelune-converter-update-index.json'
REPOSITORY = 'https://github.com/yoahnl/pokemap'
PRODUCT = 'avelune-converter'
BUNDLE_ID = 'com.yoahnl.avelune.converter'
VERSION = r'(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)'
SPARKLE = '{http://www.andymatuschak.org/xml-namespaces/sparkle}'


def canonical_json(value):
    return (json.dumps(value, indent=2, sort_keys=True) + '\n').encode()


def validate_identity(value):
    version = value.get('version', '')
    if (value.get('schemaVersion') != 1 or value.get('product') != PRODUCT
            or value.get('bundleId') != BUNDLE_ID or value.get('channel') != 'stable'
            or not isinstance(version, str) or not re.fullmatch(VERSION, version)
            or type(value.get('buildNumber')) is not int or not 0 < value['buildNumber'] <= 2147483647
            or not re.fullmatch(r'[0-9a-f]{40}', value.get('revision', ''))
            or value.get('tag') != f'avelune-converter-v{version}'
            or value.get('releaseNotesUrl') != f'{REPOSITORY}/releases/tag/avelune-converter-v{version}'):
        raise ValueError('Invalid Converter release identity, version, build or origin')


def release_contract(pubspec, revision, requested=''):
    versions = re.findall(r'^version: (.+)$', Path(pubspec).read_text(), re.MULTILINE)
    if len(versions) != 1:
        raise ValueError('Expected one pubspec version')
    match = re.fullmatch(VERSION + r'\+([1-9][0-9]*)', versions[0])
    if not match:
        raise ValueError('Expected a stable semantic version and positive build')
    version, build = versions[0].split('+')
    if requested and requested != version:
        raise ValueError('Requested release differs from pubspec')
    tag = f'avelune-converter-v{version}'
    value = dict(schemaVersion=1, product=PRODUCT, bundleId=BUNDLE_ID,
                 channel='stable', version=version, buildNumber=int(build),
                 revision=revision, tag=tag,
                 releaseNotesUrl=f'{REPOSITORY}/releases/tag/{tag}')
    validate_identity(value)
    return value


def require_newer(value, previous, allow_identical=False):
    validate_identity(value)
    validate_identity(previous)
    identity_fields = ('version', 'buildNumber', 'revision', 'tag')
    if allow_identical and all(value[key] == previous[key] for key in identity_fields):
        return
    current_version = tuple(map(int, value['version'].split('.')))
    previous_version = tuple(map(int, previous['version'].split('.')))
    if current_version <= previous_version or value['buildNumber'] <= previous['buildNumber']:
        raise ValueError('Both semantic version and build must increase over stable')


def asset_names(value):
    prefix = f'Avelune-Converter-{value["version"]}-macOS'
    return [prefix + '.dmg', prefix + '.app.zip', 'appcast-macos.xml']


def digest(path):
    with path.open('rb') as source:
        return hashlib.file_digest(source, 'sha256').hexdigest()


def require_inventory(directory, names):
    actual = {entry.name for entry in directory.iterdir()}
    if actual != set(names):
        raise ValueError(f'Release inventory mismatch: {sorted(actual ^ set(names))}')
    for name in names:
        path = directory / name
        if path.is_symlink() or not path.is_file() or path.stat().st_size == 0:
            raise ValueError(f'Expected nonempty regular release file: {name}')


def validate_appcast(directory, value):
    feed = directory / 'appcast-macos.xml'
    if feed.stat().st_size > 1024 * 1024:
        raise ValueError('Appcast exceeds release size limit')
    raw = feed.read_bytes()
    if raw.count(b'<!-- sparkle-signatures:') != 1 or not raw.rstrip().endswith(b'-->'):
        raise ValueError('Appcast must carry a Sparkle feed signature')
    root = ET.fromstring(raw)
    items = root.findall('./channel/item')
    if len(items) != 1:
        raise ValueError('Expected exactly the current release in the appcast')
    item = items[0]
    enclosure = item.find('enclosure')
    if enclosure is None:
        raise ValueError('Appcast has no enclosure')
    name = asset_names(value)[1]
    expected_url = f'{REPOSITORY}/releases/download/{value["tag"]}/{name}'
    if (item.findtext(SPARKLE + 'version') != str(value['buildNumber'])
            or item.findtext(SPARKLE + 'shortVersionString') != value['version']
            or enclosure.get('url') != expected_url
            or enclosure.get('length') != str((directory / name).stat().st_size)
            or not enclosure.get(SPARKLE + 'edSignature')):
        raise ValueError('Appcast identity, enclosure, size or signature does not match')


def create_manifest(directory, value):
    directory = Path(directory)
    validate_identity(value)
    names = asset_names(value)
    require_inventory(directory, names)
    validate_appcast(directory, value)
    manifest = {**value, 'assets': [dict(name=name, bytes=(directory / name).stat().st_size,
        sha256=digest(directory / name),
        url=f'{REPOSITORY}/releases/download/{value["tag"]}/{name}') for name in names]}
    (directory / INDEX_NAME).write_bytes(canonical_json(manifest))
    checksums = ''.join(f'{digest(directory / name)}  {name}\n' for name in [*names, INDEX_NAME])
    (directory / 'SHA256SUMS').write_text(checksums)
    verify_manifest(directory)
    return manifest


def verify_manifest(directory):
    directory = Path(directory)
    index = directory / INDEX_NAME
    if index.is_symlink() or index.stat().st_size > 65536:
        raise ValueError('Invalid update index file')
    value = json.loads(index.read_bytes())
    validate_identity(value)
    names = asset_names(value)
    require_inventory(directory, [*names, INDEX_NAME, 'SHA256SUMS'])
    if index.read_bytes() != canonical_json(value):
        raise ValueError('Noncanonical update index')
    expected_assets = [dict(name=name, bytes=(directory / name).stat().st_size,
        sha256=digest(directory / name),
        url=f'{REPOSITORY}/releases/download/{value["tag"]}/{name}') for name in names]
    if value.get('assets') != expected_assets:
        raise ValueError('Release asset hash, size, URL or inventory mismatch')
    expected_checksums = ''.join(f'{digest(directory / name)}  {name}\n' for name in [*names, INDEX_NAME])
    if (directory / 'SHA256SUMS').read_text() != expected_checksums:
        raise ValueError('SHA256SUMS does not match the complete release')
    validate_appcast(directory, value)
    return value


def validate_promotion(directory, previous):
    value = verify_manifest(directory)
    require_newer(value, previous, allow_identical=True)
    if value['version'] == previous['version'] and value != previous:
        raise ValueError('An identical stable version must retain exactly the same manifest')
    return value


def main():
    parser = argparse.ArgumentParser()
    commands = parser.add_subparsers(dest='command', required=True)
    contract = commands.add_parser('contract')
    contract.add_argument('--pubspec', required=True, type=Path)
    contract.add_argument('--revision', required=True)
    contract.add_argument('--version', default='')
    contract.add_argument('--previous', type=Path)
    contract.add_argument('--allow-identical', action='store_true')
    contract.add_argument('--output', required=True, type=Path)
    create = commands.add_parser('create')
    create.add_argument('--contract', required=True, type=Path)
    create.add_argument('--directory', required=True, type=Path)
    verify = commands.add_parser('verify')
    verify.add_argument('--directory', required=True, type=Path)
    promotion = commands.add_parser('promotion')
    promotion.add_argument('--directory', required=True, type=Path)
    promotion.add_argument('--previous', required=True, type=Path)
    args = parser.parse_args()
    if args.command == 'contract':
        value = release_contract(args.pubspec, args.revision, args.version)
        if args.previous:
            require_newer(value, json.loads(args.previous.read_bytes()), args.allow_identical)
        args.output.write_bytes(canonical_json(value))
    elif args.command == 'create':
        value = create_manifest(args.directory, json.loads(args.contract.read_bytes()))
    elif args.command == 'promotion':
        value = validate_promotion(args.directory, json.loads(args.previous.read_bytes()))
    else:
        value = verify_manifest(args.directory)
    print(json.dumps({key: value[key] for key in ('version', 'buildNumber', 'tag', 'revision')}))


if __name__ == '__main__':
    main()
