import json
import os
import re
import shutil
import subprocess
import sys
import tarfile
import urllib.request
from pathlib import Path

from install_studio_release_engine import install_engine
from package_studio_macos_engine import PackagingError, run_checked, sha256


MANIFEST = Path(__file__).resolve().parents[1] / 'flutter_engine_patches/macos_release_engine.json'


def engine_archive(environment, expected):
    supplied = environment.get('AVELUNE_QA_ENGINE_ARCHIVE')
    if supplied:
        archive = Path(supplied)
        if sha256(archive) != expected['archiveSha256']:
            raise PackagingError('QA engine archive digest mismatch')
        return archive
    cache = Path(environment['TARGET_TEMP_DIR']) / 'avelune-qa-engine'
    cache.mkdir(parents=True, exist_ok=True)
    archive = cache / (expected['archiveSha256'] + '.tar.gz')
    if archive.is_file() and sha256(archive) == expected['archiveSha256']:
        return archive
    temporary = archive.with_suffix('.download')
    try:
        with urllib.request.urlopen(expected['archiveUrl'], timeout=60) as source, temporary.open('wb') as destination:
            while chunk := source.read(1024 * 1024):
                destination.write(chunk)
        if sha256(temporary) != expected['archiveSha256']:
            raise PackagingError('Downloaded QA engine archive digest mismatch')
        os.replace(temporary, archive)
    finally:
        temporary.unlink(missing_ok=True)
    return archive


def verify_completion_fence(binary, runner=subprocess.run):
    commands = []
    output = run_checked(['otool', '-tvV', binary], commands, runner)
    blocks = re.findall(
        r'^-\[FlutterSurfaceManager presentSurfaces:atTime:notify:\]:\n(.*?)(?=^\S[^\n]*:\s*$|\Z)',
        output, re.MULTILINE | re.DOTALL,
    )
    if not blocks or any('waitUntilCompleted' not in block or 'waitUntilScheduled' in block for block in blocks):
        raise PackagingError('The packaged QA engine is missing the GPU completion fence')
    return commands


def is_qa_build(environment):
    bundle = environment.get('PRODUCT_BUNDLE_IDENTIFIER', '').lower()
    target = environment.get('FLUTTER_TARGET', '')
    return (
        environment.get('AVELUNE_QA_BUILD') == '1'
        or re.search(r'\.(?:qa|releaseqa)(?:\.|\d|$)', bundle) is not None
        or '/dev/' in '/' + target
    )


def ensure_engine(environment, runner=subprocess.run):
    if not is_qa_build(environment):
        return None
    configuration = environment.get('CONFIGURATION', '').lower()
    mode = environment.get('FLUTTER_BUILD_MODE', configuration).lower()
    if configuration != 'release' or mode != 'release':
        raise PackagingError(
            'Studio QA requires Release with the pinned corrected engine. '
            'Use -configuration Release FLUTTER_BUILD_MODE=release or flutter build macos --release. '
            'Debug/Profile QA requires a separately qualified engine; the stock engine is refused.'
        )
    app = Path(environment['TARGET_BUILD_DIR']) / environment['FULL_PRODUCT_NAME']
    receipt_path = app / 'Contents/Resources/avelune-native-engine-receipt.json'
    receipt_path.unlink(missing_ok=True)
    expected = json.loads(MANIFEST.read_text())
    archive = engine_archive(environment, expected)
    receipt = install_engine(
        app=app, archive=archive, manifest=MANIFEST,
        producer_flutter_sdk=environment['FLUTTER_ROOT'], runner=runner,
        require_universal_app=False,
    )
    framework = app / 'Contents/Frameworks/FlutterMacOS.framework'
    commands = []
    run_checked(['codesign', '--force', '--sign', '-', framework], commands, runner)
    run_checked(['codesign', '--verify', '--strict', framework], commands, runner)
    binary = framework / 'FlutterMacOS'
    commands.extend(verify_completion_fence(binary, runner=runner))
    receipt.update(
        schemaVersion=1, purpose='mandatory Studio QA engine packaging',
        bundleIdentifier=environment.get('PRODUCT_BUNDLE_IDENTIFIER', ''), binarySha256=sha256(binary),
        completionFenceVerified=True, verificationCommands=commands,
    )
    receipt_path.parent.mkdir(parents=True, exist_ok=True)
    receipt_path.write_text(json.dumps(receipt, indent=2) + '\n')
    return receipt


def main():
    if not is_qa_build(os.environ):
        return 0
    if not hasattr(tarfile, 'data_filter'):
        for name in ('python3.14', 'python3.13', 'python3.12', 'python3.11', 'python3'):
            executable = shutil.which(name)
            if executable is None or Path(executable).resolve() == Path(sys.executable).resolve():
                continue
            probe = subprocess.run(
                [executable, '-c', 'import tarfile; assert hasattr(tarfile, "data_filter")'],
                capture_output=True,
            )
            if probe.returncode == 0:
                return subprocess.call([executable, str(Path(__file__).resolve())])
        print('error: Studio QA engine packaging requires Python with tarfile.data_filter (Python 3.12+).', file=sys.stderr)
        return 1
    try:
        result = ensure_engine(os.environ)
    except (PackagingError, OSError, KeyError, ValueError, subprocess.SubprocessError) as error:
        print(f'error: {error}', file=sys.stderr)
        return 1
    if result is not None:
        print('Studio QA: pinned Release engine installed; GPU completion fence verified.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
