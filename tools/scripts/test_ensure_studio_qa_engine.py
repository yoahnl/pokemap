import hashlib
import io
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import ensure_studio_qa_engine as qa
from package_studio_macos_engine import PackagingError


class EnsureStudioQaEngineTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name).resolve()
        self.env = {
            'PRODUCT_BUNDLE_IDENTIFIER': 'com.avelune.qa.griotte',
            'CONFIGURATION': 'Release',
            'TARGET_BUILD_DIR': str(self.root),
            'FULL_PRODUCT_NAME': 'Studio.app',
            'FLUTTER_ROOT': '/sdk',
            'TARGET_TEMP_DIR': str(self.root / 'temporary'),
        }
        self.app = self.root / 'Studio.app'
        self.binary = self.app / 'Contents/Frameworks/FlutterMacOS.framework/FlutterMacOS'
        self.binary.parent.mkdir(parents=True)
        self.binary.write_bytes(b'fixed engine')
        self.commands = []

    def runner(self, command, **kwargs):
        self.commands.append(command)
        output = (
            '-[FlutterSurfaceManager presentSurfaces:atTime:notify:]:\n'
            '00001 bl 0x1 ; Objc message: -[x0 waitUntilCompleted]\n'
            '-[FlutterSurfaceManager nextMethod]:\n'
        ) if command[0] == 'otool' else ''
        return subprocess.CompletedProcess(command, 0, output, '')

    def test_regular_profile_build_is_unchanged(self):
        self.env.update(PRODUCT_BUNDLE_IDENTIFIER='com.yoahnl.pokemap.editor', CONFIGURATION='Profile')
        self.assertIsNone(qa.ensure_engine(self.env, runner=self.runner))
        self.assertEqual(self.commands, [])

    def test_qa_profile_fails_instead_of_shipping_stock_engine(self):
        self.env['CONFIGURATION'] = 'Profile'
        with self.assertRaisesRegex(PackagingError, 'Release'):
            qa.ensure_engine(self.env, runner=self.runner)
        self.assertEqual(self.commands, [])

    def test_explicit_qa_cannot_bypass_guard_with_standard_bundle_id(self):
        self.env.update(PRODUCT_BUNDLE_IDENTIFIER='com.yoahnl.pokemap.editor', AVELUNE_QA_BUILD='1', CONFIGURATION='Debug')
        with self.assertRaisesRegex(PackagingError, 'Release'):
            qa.ensure_engine(self.env, runner=self.runner)

    def test_conflicting_flutter_mode_is_rejected(self):
        self.env['FLUTTER_BUILD_MODE'] = 'profile'
        with self.assertRaisesRegex(PackagingError, 'Release'):
            qa.ensure_engine(self.env, runner=self.runner)

    def test_installs_signs_verifies_and_records_actual_binary(self):
        with patch.object(qa, 'engine_archive', return_value=self.root / 'engine.tar.gz'), patch.object(qa, 'install_engine', return_value={'mode': 'release'}) as install:
            result = qa.ensure_engine(self.env, runner=self.runner)
        self.assertFalse(install.call_args.kwargs['require_universal_app'])
        self.assertEqual(result['binarySha256'], qa.sha256(self.binary))
        self.assertEqual([command[0] for command in self.commands], ['codesign', 'codesign', 'otool'])
        receipt = self.app / 'Contents/Resources/avelune-native-engine-receipt.json'
        self.assertEqual(json.loads(receipt.read_text())['binarySha256'], result['binarySha256'])

    def test_scheduled_only_binary_is_rejected_even_with_completion_elsewhere(self):
        def runner(command, **kwargs):
            output = (
                '-[FlutterSurfaceManager presentSurfaces:atTime:notify:]:\n'
                '00001 bl 0x1 ; Objc message: -[x0 waitUntilScheduled]\n'
                '-[Other method]:\n'
                '00002 bl 0x2 ; Objc message: -[x0 waitUntilCompleted]\n'
            )
            return subprocess.CompletedProcess(command, 0, output, '')
        with self.assertRaisesRegex(PackagingError, 'completion'):
            qa.verify_completion_fence(self.binary, runner=runner)

    def test_missing_method_is_not_accepted(self):
        with self.assertRaisesRegex(PackagingError, 'completion'):
            qa.verify_completion_fence(self.binary, runner=lambda *a, **k: subprocess.CompletedProcess(a[0], 0, 'waitUntilCompleted', ''))

    def test_valid_archive_is_reused_without_network(self):
        payload = b'engine archive'
        digest = hashlib.sha256(payload).hexdigest()
        expected = {'archiveSha256': digest, 'archiveUrl': 'https://example.invalid/engine'}
        with patch.object(qa.urllib.request, 'urlopen', return_value=io.BytesIO(payload)) as download:
            first = qa.engine_archive(self.env, expected)
            second = qa.engine_archive(self.env, expected)
        self.assertEqual(first, second)
        self.assertEqual(download.call_count, 1)

    def test_corrupt_download_is_removed_and_never_accepted(self):
        expected = {'archiveSha256': '0' * 64, 'archiveUrl': 'https://example.invalid/engine'}
        with patch.object(qa.urllib.request, 'urlopen', return_value=io.BytesIO(b'corruption')):
            with self.assertRaisesRegex(PackagingError, 'digest'):
                qa.engine_archive(self.env, expected)
        self.assertEqual(list((self.root / 'temporary/avelune-qa-engine').iterdir()), [])

    def test_failed_verification_removes_stale_receipt(self):
        receipt = self.app / 'Contents/Resources/avelune-native-engine-receipt.json'
        receipt.parent.mkdir(parents=True)
        receipt.write_text('{"completionFenceVerified": true}')
        with patch.object(qa, 'engine_archive', side_effect=PackagingError('digest mismatch')):
            with self.assertRaisesRegex(PackagingError, 'digest'):
                qa.ensure_engine(self.env, runner=self.runner)
        self.assertFalse(receipt.exists())

    def test_dev_entrypoint_also_requires_corrected_engine(self):
        self.env.update(PRODUCT_BUNDLE_IDENTIFIER='com.yoahnl.pokemap.editor', FLUTTER_TARGET='dev/marionette_main.dart', CONFIGURATION='Profile')
        with self.assertRaisesRegex(PackagingError, 'Release'):
            qa.ensure_engine(self.env, runner=self.runner)

    def test_xcode_embedding_cannot_skip_qa_engine_step(self):
        project = Path(__file__).resolve().parents[2] / 'apps/avelune_studio/macos/Runner.xcodeproj/project.pbxproj'
        content = project.read_text()
        script = next(line for line in content.splitlines() if 'macos_assemble.sh embed' in line)
        self.assertIn('ensure_studio_qa_engine.py', script)
        self.assertLess(script.index('macos_assemble.sh embed'), script.index('ensure_studio_qa_engine.py'))
        self.assertIn('set -e', script)

    def test_xcode_python_uses_available_secure_archive_runtime(self):
        with patch.dict(qa.os.environ, self.env, clear=True), patch.object(qa.tarfile, 'data_filter', create=True):
            del qa.tarfile.data_filter
            with patch.object(qa.shutil, 'which', return_value='/qualified/python3'), patch.object(qa.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0)), patch.object(qa.subprocess, 'call', return_value=0) as call:
                self.assertEqual(qa.main(), 0)
        self.assertEqual(call.call_args.args[0][0], '/qualified/python3')

    def test_missing_secure_archive_runtime_fails_closed(self):
        with patch.dict(qa.os.environ, self.env, clear=True), patch.object(qa.tarfile, 'data_filter', create=True), patch.object(qa.sys, 'stderr', io.StringIO()):
            del qa.tarfile.data_filter
            with patch.object(qa.shutil, 'which', return_value=None):
                self.assertEqual(qa.main(), 1)

    def test_normal_build_needs_no_additional_python_runtime(self):
        with patch.dict(qa.os.environ, {'PRODUCT_BUNDLE_IDENTIFIER': 'com.yoahnl.pokemap.editor'}, clear=True), patch.object(qa.tarfile, 'data_filter', create=True), patch.object(qa.shutil, 'which') as which:
            del qa.tarfile.data_filter
            self.assertEqual(qa.main(), 0)
        which.assert_not_called()


if __name__ == '__main__':
    unittest.main()
