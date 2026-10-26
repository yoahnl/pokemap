import argparse
import json
import os
import plistlib
import re
import subprocess
import tarfile
import tempfile
from pathlib import Path, PurePosixPath

from package_studio_macos_engine import (
    PackagingError,
    architectures,
    canonical_directory,
    dart_revision,
    run_checked,
    sha256,
    tree_digest,
    validate_links,
)


def install_engine(*, app, archive, manifest, producer_flutter_sdk, runner=subprocess.run):
    app = canonical_directory(app, 'Release app')
    sdk = canonical_directory(producer_flutter_sdk, 'Producer Flutter SDK')
    archive = Path(archive)
    expected = json.loads(Path(manifest).read_text())
    if expected.get('schemaVersion') != 1 or expected.get('mode') != 'release':
        raise PackagingError('Expected a versioned release engine manifest')
    for key, length in (
        ('flutterRevision', 40), ('dartRevision', 40),
        ('patchSha256', 64), ('frameworkTreeSha256', 64), ('archiveSha256', 64),
    ):
        if not re.fullmatch('[0-9a-f]{' + str(length) + '}', expected.get(key, '')):
            raise PackagingError(f'Invalid engine manifest field: {key}')
    required_architectures = {'arm64', 'x86_64'}
    if set(expected.get('architectures', [])) != required_architectures:
        raise PackagingError('The release requires arm64 and x86_64 architectures')
    if sha256(archive) != expected['archiveSha256']:
        raise PackagingError('Release engine archive digest mismatch')
    if dart_revision(sdk) != expected['dartRevision']:
        raise PackagingError('Release engine Dart revision mismatch')
    commands = []
    revision = run_checked(['git', '-C', sdk, 'rev-parse', 'HEAD'], commands, runner).strip()
    if revision != expected['flutterRevision']:
        raise PackagingError('Release engine Flutter revision mismatch')
    validate_links(app)
    info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
    executable = info.get('CFBundleExecutable', '')
    if not executable or Path(executable).name != executable:
        raise PackagingError('Invalid app executable')
    app_architectures = architectures(app / 'Contents/MacOS' / executable, commands, runner)
    if app_architectures != required_architectures:
        raise PackagingError('Release app architectures must include arm64 and x86_64')
    destination = app / 'Contents/Frameworks/FlutterMacOS.framework'
    if not destination.is_dir() or destination.is_symlink():
        raise PackagingError('Missing original FlutterMacOS.framework')
    with tempfile.TemporaryDirectory(prefix='.avelune-release-engine-', dir=destination.parent) as temporary:
        staging = Path(temporary)
        with tarfile.open(archive, 'r:gz') as bundle:
            members = bundle.getmembers()
            names = set()
            for member in members:
                path = PurePosixPath(member.name)
                if (path.is_absolute() or '..' in path.parts or not path.parts
                        or path.parts[0] not in {'FlutterMacOS.framework', 'provenance.json'}
                        or member.name in names or member.islnk()
                        or not (member.isfile() or member.isdir() or member.issym())):
                    raise PackagingError(f'Unsafe release engine archive entry: {member.name}')
                names.add(member.name)
            try:
                bundle.extractall(staging, members=members, filter='data')
            except (tarfile.TarError, OSError) as error:
                raise PackagingError(f'Unsafe release engine archive entry: {error}') from error
        provenance = json.loads((staging / 'provenance.json').read_text())
        for key in ('schemaVersion', 'mode', 'flutterRevision', 'dartRevision',
                    'architectures', 'patchSha256', 'frameworkTreeSha256'):
            if provenance.get(key) != expected[key]:
                raise PackagingError(f'Release engine provenance mismatch: {key}')
        framework = staging / 'FlutterMacOS.framework'
        validate_links(framework)
        if tree_digest(framework)['sha256'] != expected['frameworkTreeSha256']:
            raise PackagingError('Release engine framework digest mismatch')
        actual_architectures = architectures(framework / 'FlutterMacOS', commands, runner)
        if actual_architectures != required_architectures:
            raise PackagingError('Release engine architectures must include arm64 and x86_64')
        previous = staging / 'previous.framework'
        os.replace(destination, previous)
        try:
            os.replace(framework, destination)
        except OSError:
            os.replace(previous, destination)
            raise
    return {
        'mode': 'release',
        'architectures': sorted(actual_architectures),
        'flutterRevision': revision,
        'dartRevision': expected['dartRevision'],
        'archiveSha256': expected['archiveSha256'],
        'frameworkTreeSha256': expected['frameworkTreeSha256'],
        'commands': commands,
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--app', required=True)
    parser.add_argument('--archive', required=True)
    parser.add_argument('--manifest', required=True)
    parser.add_argument('--producer-flutter-sdk', required=True)
    parser.add_argument('--receipt', required=True)
    arguments = vars(parser.parse_args())
    receipt = arguments.pop('receipt')
    result = install_engine(**arguments)
    Path(receipt).write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result))


if __name__ == '__main__':
    main()
