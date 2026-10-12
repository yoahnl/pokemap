import gzip
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import struct
import sys
import tempfile
import unittest
import zipfile
import zlib

ROOT = Path(__file__).parent
SPEC = importlib.util.spec_from_file_location('distribution', ROOT / 'package_distribution.py')
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


@unittest.skipUnless(sys.platform == 'darwin', 'Native ditto packaging requires macOS')
class DistributionTests(unittest.TestCase):
    def setUp(self):
        self.work = Path(tempfile.mkdtemp(prefix='avelune-package-test-'))
        self.app = self.work / 'project/build/macos/Build/Products/Release/Converter.app'
        contents = self.app / 'Contents'
        (contents / 'MacOS').mkdir(parents=True)
        self.executable = contents / 'MacOS/converter'
        self.executable.write_bytes(b'original synthetic executable')
        self.executable.chmod(0o755)
        (contents / 'Info.plist').write_bytes(plistlib.dumps({'CFBundleExecutable': 'converter'}))
        (contents / 'Resources').mkdir()
        self.notice = contents / 'Resources/NOTICES.Z'
        self.notice.write_bytes(gzip.compress(b'Actual synthetic third-party notice\n', mtime=0))
        framework = contents / 'Frameworks/Synthetic.framework/Versions'
        (framework / 'A').mkdir(parents=True)
        (framework / 'A/Synthetic').write_bytes(b'original synthetic library')
        (framework / 'A/Synthetic').chmod(0o755)
        (framework / 'Current').symlink_to('A', target_is_directory=True)
        (framework.parent / 'Synthetic').symlink_to('Versions/Current/Synthetic')
        self.cli = self.work / 'avelune-converter'
        self.cli.write_bytes(b'original synthetic CLI')
        self.cli.chmod(0o755)
        self.fixture = self.work / 'source'
        self.addCleanup(shutil.rmtree, self.work)
        (self.fixture / 'Data').mkdir(parents=True)
        (self.fixture / 'Graphics/Tilesets').mkdir(parents=True)
        (self.fixture / 'FIXTURE_LICENSE.txt').write_bytes(MODULE.FIXTURE_LICENSE)
        (self.fixture / 'README.md').write_text('Original inert packaging fixture.\n')
        for name in ['MapInfos', 'Tilesets', 'Map001', 'Map008']:
            (self.fixture / f'Data/{name}.rxdata').write_bytes(b'\x04\x080')
        def png_chunk(kind, payload):
            return (struct.pack('>I', len(payload)) + kind + payload
                    + struct.pack('>I', zlib.crc32(kind + payload)))
        (self.fixture / 'Graphics/Tilesets/OriginalAtlas0.png').write_bytes(
            b'\x89PNG\r\n\x1a\n'
            + png_chunk(b'IHDR', struct.pack('>IIBBBBB', 1, 1, 8, 6, 0, 0, 0))
            + png_chunk(b'IDAT', zlib.compress(b'\x00\xff\x00\x00\xff'))
            + png_chunk(b'IEND', b''))
        self.output = self.work / 'distribution'

    def invoke(self):
        return MODULE.package_distribution(self.app, self.cli, self.fixture, self.output)

    def refusal(self):
        with self.assertRaises(MODULE.PackageError):
            self.invoke()
        self.assertFalse(os.path.lexists(self.output))

    def test_copy_zip_hashes_modes_links_and_exact_notices(self):
        source_hash = hashlib.sha256(self.executable.read_bytes()).hexdigest()
        result = self.invoke()
        self.assertEqual(result['kind'], 'localPrivateValidationDistribution')
        archive = Path(result['archivePath'])
        self.assertEqual(result['archiveSha256'], hashlib.sha256(archive.read_bytes()).hexdigest())
        self.assertEqual(result['archiveBytes'], archive.stat().st_size)
        inventory_file = Path(result['inventoryPath'])
        self.assertEqual(result['inventorySha256'], hashlib.sha256(inventory_file.read_bytes()).hexdigest())
        inventory = json.loads(inventory_file.read_text())
        entries = {entry['path']: entry for entry in inventory['entries']}
        executable = entries['Converter.app/Contents/MacOS/converter']
        self.assertEqual(executable['sha256'], source_hash)
        self.assertEqual(executable['mode'], '0755')
        self.assertEqual(entries['Converter.app/Contents/Frameworks/Synthetic.framework/Versions/Current']['target'], 'A')
        self.assertEqual(Path(result['payloadPath'], 'notices/Flutter-NOTICES-1.txt').read_bytes(), b'Actual synthetic third-party notice\n')
        self.assertEqual(result['fileCount'], sum(entry['type'] == 'file' for entry in inventory['entries']))
        self.assertEqual(result['symlinkCount'], 2)
        with zipfile.ZipFile(archive) as zipped:
            path = 'AveluneConverter-local-validation/Converter.app/Contents/MacOS/converter'
            self.assertEqual(zipped.read(path), self.executable.read_bytes())
            linked = zipped.getinfo('AveluneConverter-local-validation/Converter.app/Contents/Frameworks/Synthetic.framework/Versions/Current')
            self.assertEqual(zipped.read(linked), b'A')
            self.assertEqual((linked.external_attr >> 16) & 0o170000, 0o120000)
        self.assertFalse(result['notarized'])
        self.assertFalse(result['publiclyUploaded'])
        self.assertEqual(hashlib.sha256(self.executable.read_bytes()).hexdigest(), source_hash)

    def test_existing_output_refused_unchanged(self):
        self.output.mkdir()
        (self.output / 'foreign').write_bytes(b'preserve')
        with self.assertRaises(MODULE.PackageError):
            self.invoke()
        self.assertEqual((self.output / 'foreign').read_bytes(), b'preserve')
        self.assertEqual(list(self.output.iterdir()), [self.output / 'foreign'])

    def test_output_inside_app_refused(self):
        self.output = self.app / 'Contents/new-output'
        self.refusal()

    def test_output_inside_fixture_refused(self):
        self.output = self.fixture / 'Graphics/new-output'
        self.refusal()

    def test_output_symlink_parent_into_fixture_refused(self):
        alias = self.work / 'alias'
        alias.symlink_to(self.fixture, target_is_directory=True)
        self.output = alias / 'new-output'
        self.refusal()

    def test_escape_app_symlink_refused(self):
        (self.app / 'Contents/Resources/escape').symlink_to(self.cli)
        self.refusal()

    def test_escape_fixture_symlink_refused(self):
        (self.fixture / 'Data/Map009.rxdata').symlink_to(self.cli)
        self.refusal()

    def test_absolute_internal_app_symlink_refused(self):
        (self.app / 'Contents/Resources/internal').symlink_to(self.executable)
        self.refusal()

    def test_dangling_app_symlink_refused(self):
        (self.app / 'Contents/Resources/dangling').symlink_to('absent')
        self.refusal()

    def test_secret_and_token_filenames_refused(self):
        for name in ('.env', '.env.local', 'api_token.txt', 'credentials.json', 'private.pem', '.npmrc'):
            with self.subTest(name=name):
                suspect = self.app / 'Contents/Resources' / name
                suspect.write_bytes(b'synthetic secret')
                self.refusal()
                suspect.unlink()

    def test_forbidden_packages_and_media_refused(self):
        for name in ('avelune_studio', 'map_runtime', 'map_player_ui', 'map_render_3d', 'flame'):
            with self.subTest(name=name):
                directory = self.app / 'Contents/Resources/packages' / name
                directory.mkdir(parents=True)
                self.refusal()
                directory.rmdir()
        media = self.app / 'Contents/Resources/Pokemon.png'
        media.write_bytes(b'original placeholder for refusal')
        self.refusal()

    def test_fixture_scripts_or_unknown_media_refused(self):
        for relative in ('Data/Scripts.rxdata', 'Graphics/Tilesets/Unknown.png', 'Graphics/Characters/Pokemon.png'):
            with self.subTest(relative=relative):
                suspect = self.fixture / relative
                suspect.parent.mkdir(parents=True, exist_ok=True)
                suspect.write_bytes(b'original placeholder for refusal')
                self.refusal()
                suspect.unlink()
                if suspect.parent.name == 'Characters':
                    suspect.parent.rmdir()

    def test_fixture_licence_mismatch_refused(self):
        (self.fixture / 'FIXTURE_LICENSE.txt').write_text('Unknown source')
        self.refusal()

    def test_missing_or_corrupt_notices_refused(self):
        self.notice.unlink()
        self.refusal()
        self.notice.write_bytes(b'invalid compressed notices')
        self.refusal()

    def test_zlib_notices_and_actual_pods_acknowledgements(self):
        self.notice.write_bytes(zlib.compress(b'Actual zlib notice\n'))
        acknowledgement = self.work / 'project/macos/Pods/Target Support Files/Pods-Runner/Pods-Runner-acknowledgements.plist'
        acknowledgement.parent.mkdir(parents=True)
        acknowledgement.write_bytes(plistlib.dumps({'PreferenceSpecifiers': [{'Title': 'SyntheticPlugin', 'FooterText': 'Actual plugin licence'}]}))
        result = self.invoke()
        notice_files = sorted(Path(result['payloadPath'], 'notices').iterdir())
        self.assertEqual(len(notice_files), 2)
        self.assertEqual(Path(result['payloadPath'], 'notices/Pods-Runner-acknowledgements.plist').read_bytes(), acknowledgement.read_bytes())
        self.assertEqual(Path(result['payloadPath'], 'notices/Flutter-NOTICES-1.txt').read_bytes(), b'Actual zlib notice\n')

    def test_relative_args_and_non_executable_cli_refused(self):
        with self.assertRaises(MODULE.PackageError):
            MODULE.package_distribution(Path('Converter.app'), self.cli, self.fixture, self.output)
        self.cli.chmod(0o644)
        self.refusal()

    def test_link_cannot_hide_forbidden_resolved_name(self):
        actual = self.app / 'Contents/Resources/map_runtime'
        actual.mkdir()
        (self.app / 'Contents/Resources/innocent').symlink_to('map_runtime', target_is_directory=True)
        self.refusal()


    def test_symlink_lexically_escapes_then_returns_refused(self):
        bounce = self.work / 'bounce'
        bounce.symlink_to(self.executable)
        resources = self.app / 'Contents/Resources'
        (resources / 'roundtrip').symlink_to(os.path.relpath(bounce, resources))
        self.refusal()

    def test_pods_sidecar_cannot_escape_known_project(self):
        actual = self.work / 'outside-support'
        actual.mkdir()
        (actual / 'Pods-Runner-acknowledgements.plist').write_bytes(plistlib.dumps({'Title': 'Actual external sidecar'}))
        support = self.work / 'project/macos/Pods/Target Support Files'
        support.mkdir(parents=True)
        (support / 'Pods-Runner').symlink_to(actual, target_is_directory=True)
        self.refusal()

    def test_identical_acknowledgements_deduplicate_exact_bytes(self):
        content = plistlib.dumps({'Title': 'Actual duplicate acknowledgement'})
        (self.app / 'Contents/Resources/Pods-Runner-acknowledgements.plist').write_bytes(content)
        sidecar = self.work / 'project/macos/Pods/Target Support Files/Pods-Runner/Pods-Runner-acknowledgements.plist'
        sidecar.parent.mkdir(parents=True)
        sidecar.write_bytes(content)
        result = self.invoke()
        self.assertEqual(result['podsAcknowledgementCount'], 1)
        self.assertEqual(Path(result['payloadPath'], 'notices/Pods-Runner-acknowledgements.plist').read_bytes(), content)

    def test_conflicting_acknowledgements_refused_before_output(self):
        (self.app / 'Contents/Resources/Pods-Runner-acknowledgements.plist').write_bytes(b'actual first notice')
        sidecar = self.work / 'project/macos/Pods/Target Support Files/Pods-Runner/Pods-Runner-acknowledgements.plist'
        sidecar.parent.mkdir(parents=True)
        sidecar.write_bytes(b'actual conflicting notice')
        self.refusal()


    def test_cli_json_transport_with_spaces_and_existing_output_exit2(self):
        renamed = self.app.with_name('Avelune Converter.app')
        self.app.rename(renamed)
        self.app = renamed
        command = [sys.executable, '-B', str(SPEC.origin), '--app', str(self.app), '--cli', str(self.cli), '--fixture', str(self.fixture), '--output', str(self.output)]
        process = subprocess.run(command, check=True, capture_output=True, text=True)
        result = json.loads(process.stdout)
        receipt_path = self.output / 'receipt.json'
        receipt_bytes = receipt_path.read_bytes()
        self.assertEqual(result, json.loads(receipt_bytes))
        self.assertTrue(Path(result['payloadPath'], 'Avelune Converter.app').is_dir())
        refused = subprocess.run(command, capture_output=True, text=True)
        self.assertEqual(refused.returncode, 2)
        self.assertEqual(refused.stdout, '')
        self.assertEqual(receipt_path.read_bytes(), receipt_bytes)


if __name__ == '__main__':
    unittest.main(verbosity=2)
