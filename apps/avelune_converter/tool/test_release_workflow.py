from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[3]
WORKFLOW = ROOT / '.github/workflows/avelune_converter_release.yml'


class ReleaseWorkflowTests(unittest.TestCase):
    def setUp(self):
        self.workflow = WORKFLOW.read_text()

    def test_publication_is_manual_main_only_and_separate_from_studio(self):
        self.assertIn('workflow_dispatch:', self.workflow)
        self.assertNotRegex(self.workflow, r'(?m)^  (push|pull_request|schedule):')
        for gate in ('default: preflight', 'test "$GITHUB_REF" = refs/heads/main',
                     'test "$CONFIRMATION" = RELEASE', "if: inputs.mode == 'release'",
                     'group: avelune-converter-stable-release', 'cancel-in-progress: false'):
            self.assertIn(gate, self.workflow)
        self.assertNotIn('pokemap-editor-update-stable', self.workflow)
        self.assertNotIn('--force', self.workflow)
        self.assertEqual(self.workflow.count('contents: write'), 1)
        self.assertEqual(self.workflow.count('environment: pokemap-release'), 2)
        self.assertIn('flutter test ../avelune_studio/test/release/macos_notarization_script_test.dart --concurrency=1', self.workflow)

    def test_release_is_verified_before_publication_and_feed_promotion(self):
        stages = ['name: Verify immutable release payload', 'name: Create versioned draft',
                  'name: Download draft assets', 'name: Publish verified immutable release',
                  'name: Verify public versioned download URLs', 'name: Promote Converter stable feed',
                  'name: Verify public stable feed bytes']
        positions = [self.workflow.index(stage) for stage in stages]
        self.assertEqual(positions, sorted(positions))
        self.assertGreaterEqual(self.workflow.count('tool/verify_sparkle.py --directory'), 3)
        promotion = self.workflow[self.workflow.index('name: Promote Converter stable feed'):]
        self.assertLess(promotion.index('--clobber public/appcast-macos.xml'),
                        promotion.index('--clobber public/avelune-converter-update-index.json'))
        self.assertLess(promotion.index('release_metadata.py promotion'),
                        promotion.index('--clobber public/appcast-macos.xml'))
        self.assertIn('--draft --title', promotion)
        self.assertLess(promotion.index('--clobber public/avelune-converter-update-index.json'),
                        promotion.index('--draft=false'))
        self.assertIn('test "$result" = 2', self.workflow)
        self.assertIn('HTTP 404', self.workflow)
        self.assertIn('--previous', self.workflow)

    def test_actions_sdk_and_sparkle_are_immutable(self):
        refs = re.findall(r'uses: ([^\s]+)', self.workflow)
        self.assertTrue(refs)
        for ref in refs:
            self.assertRegex(ref, r'@[0-9a-f]{40}$')
        self.assertRegex(self.workflow, r'FLUTTER_REVISION: [0-9a-f]{40}')
        self.assertIn('rev-parse HEAD)', self.workflow)
        project = (ROOT / 'apps/avelune_converter/macos/Runner.xcodeproj/project.pbxproj').read_text()
        self.assertIn('version = 2.9.5', project)

    def test_release_builder_binds_identity_and_cleans_private_signing_material(self):
        builder = (ROOT / 'apps/avelune_converter/tool/build_macos_release.sh').read_text()
        for required in ('trap cleanup EXIT', 'umask 077', 'security delete-keychain',
                         'AVELUNE_CONVERTER_SPARKLE_PRIVATE_ED_KEY_BASE64',
                         '--dart-define="AVELUNE_CONVERTER_REVISION=$revision"',
                         '--dart-define="AVELUNE_CONVERTER_VERSION=$version"',
                         '--dart-define="AVELUNE_CONVERTER_BUILD_NUMBER=$build_number"',
                         '--notary-keychain "$keychain_path"', "--volume-name 'Avelune Converter'",
                         'SUAllowsAutomaticUpdates', 'SUSignedFeedFailureExpirationInterval',
                         'verify_sparkle.py'):
            self.assertIn(required, builder)
        self.assertNotIn('set -x', builder)
        self.assertNotIn('--dart-define="FLUTTER_BUILD_', builder)
        self.assertNotIn('SPARKLE_PRIVATE_ED_KEY_BASE64:', self.workflow.replace('AVELUNE_CONVERTER_SPARKLE_PRIVATE_ED_KEY_BASE64:', ''))


if __name__ == '__main__':
    unittest.main()
