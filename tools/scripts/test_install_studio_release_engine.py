import io
import json
import plistlib
import subprocess
import tarfile
import tempfile
import unittest
from pathlib import Path

import install_studio_release_engine as installer
import package_studio_macos_engine as packaging


class InstallStudioReleaseEngineTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name).resolve()
        self.app = self.root / 'Studio.app'
        self.framework = self.app / 'Contents/Frameworks/FlutterMacOS.framework'
        self.framework.mkdir(parents=True)
        (self.framework / 'FlutterMacOS').write_bytes(b'old engine')
        binary = self.app / 'Contents/MacOS/Runner'
        binary.parent.mkdir()
        binary.write_bytes(b'app code')
        (self.app / 'Contents/Info.plist').write_bytes(plistlib.dumps({
            'CFBundleExecutable': 'Runner',
        }))
        self.sdk = self.root / 'sdk'
        self.sdk.mkdir()
        (self.sdk / 'DEPS').write_text("vars = {'dart_revision': '" + 'a' * 40 + "'}")
        self.staging = self.root / 'staging'
        built = self.staging / 'FlutterMacOS.framework'
        (built / 'Versions/A').mkdir(parents=True)
        (built / 'Versions/A/FlutterMacOS').write_bytes(b'fixed engine')
        (built / 'Versions/Current').symlink_to('A', target_is_directory=True)
        (built / 'FlutterMacOS').symlink_to('Versions/Current/FlutterMacOS')
        self.provenance = {
            'schemaVersion': 1,
            'mode': 'release',
            'flutterRevision': 'b' * 40,
            'dartRevision': 'a' * 40,
            'architectures': ['arm64', 'x86_64'],
            'patchSha256': 'c' * 64,
            'frameworkTreeSha256': packaging.tree_digest(built)['sha256'],
        }
        self.archive = self.root / 'engine.tar.gz'
        self.manifest = self.root / 'manifest.json'
        self.repack()
        self.commands = []
        self.binary_architectures = 'arm64 x86_64'

    def repack(self, extra=None):
        (self.staging / 'provenance.json').write_text(json.dumps(self.provenance))
        with tarfile.open(self.archive, 'w:gz') as archive:
            archive.add(self.staging / 'FlutterMacOS.framework', arcname='FlutterMacOS.framework')
            archive.add(self.staging / 'provenance.json', arcname='provenance.json')
            if extra is not None:
                entry = tarfile.TarInfo(extra)
                entry.size = 4
                archive.addfile(entry, io.BytesIO(b'evil'))
        self.manifest.write_text(json.dumps({
            **self.provenance,
            'archiveSha256': packaging.sha256(self.archive),
        }))

    def runner(self, command, **kwargs):
        self.commands.append(command)
        result = 'b' * 40 if command[0] == 'git' else self.binary_architectures
        return subprocess.CompletedProcess(command, 0, result, '')

    def install(self):
        return installer.install_engine(
            app=self.app, archive=self.archive, manifest=self.manifest,
            producer_flutter_sdk=self.sdk, runner=self.runner,
        )

    def assert_unchanged(self, before):
        self.assertEqual(packaging.tree_digest(self.app), before)

    def test_installs_verified_release_framework_without_changing_app_code(self):
        receipt = self.install()
        self.assertEqual((self.framework / 'FlutterMacOS').read_bytes(), b'fixed engine')
        self.assertTrue((self.framework / 'FlutterMacOS').is_symlink())
        self.assertEqual((self.app / 'Contents/MacOS/Runner').read_bytes(), b'app code')
        self.assertEqual(receipt['mode'], 'release')
        self.assertEqual(receipt['architectures'], ['arm64', 'x86_64'])

    def test_corrupt_archive_does_not_change_app(self):
        before = packaging.tree_digest(self.app)
        self.archive.write_bytes(self.archive.read_bytes() + b'corruption')
        with self.assertRaisesRegex(packaging.PackagingError, 'archive digest'):
            self.install()
        self.assert_unchanged(before)

    def test_profile_engine_is_refused(self):
        before = packaging.tree_digest(self.app)
        self.provenance['mode'] = 'profile'
        self.repack()
        with self.assertRaisesRegex(packaging.PackagingError, 'release'):
            self.install()
        self.assert_unchanged(before)

    def test_dart_revision_mismatch_does_not_change_app(self):
        before = packaging.tree_digest(self.app)
        (self.sdk / 'DEPS').write_text("vars = {'dart_revision': '" + 'd' * 40 + "'}")
        with self.assertRaisesRegex(packaging.PackagingError, 'Dart revision'):
            self.install()
        self.assert_unchanged(before)

    def test_flutter_revision_mismatch_does_not_change_app(self):
        before = packaging.tree_digest(self.app)
        def different_revision(command, **kwargs):
            return subprocess.CompletedProcess(command, 0, 'e' * 40, '')
        self.runner = different_revision
        with self.assertRaisesRegex(packaging.PackagingError, 'Flutter revision'):
            self.install()
        self.assert_unchanged(before)

    def test_arm_only_engine_cannot_replace_universal_release(self):
        before = packaging.tree_digest(self.app)
        self.binary_architectures = 'arm64'
        with self.assertRaisesRegex(packaging.PackagingError, 'architectures'):
            self.install()
        self.assert_unchanged(before)

    def test_framework_tampering_does_not_change_app(self):
        before = packaging.tree_digest(self.app)
        self.provenance['frameworkTreeSha256'] = '0' * 64
        self.repack()
        with self.assertRaisesRegex(packaging.PackagingError, 'framework digest'):
            self.install()
        self.assert_unchanged(before)

    def test_archive_traversal_is_refused_before_extraction(self):
        before = packaging.tree_digest(self.app)
        self.repack(extra='../escaped')
        with self.assertRaisesRegex(packaging.PackagingError, 'archive entry'):
            self.install()
        self.assertFalse((self.root / 'escaped').exists())
        self.assert_unchanged(before)

    def test_archive_link_cannot_escape_temporary_directory(self):
        before = packaging.tree_digest(self.app)
        (self.staging / 'FlutterMacOS.framework/escape').symlink_to('../../outside')
        self.repack()
        with self.assertRaisesRegex(packaging.PackagingError, 'archive entry'):
            self.install()
        self.assert_unchanged(before)

    def test_provenance_must_match_pinned_manifest(self):
        before = packaging.tree_digest(self.app)
        expected = json.loads(self.manifest.read_text())
        expected['patchSha256'] = '0' * 64
        self.manifest.write_text(json.dumps(expected))
        with self.assertRaisesRegex(packaging.PackagingError, 'provenance mismatch'):
            self.install()
        self.assert_unchanged(before)


if __name__ == '__main__':
    unittest.main()
