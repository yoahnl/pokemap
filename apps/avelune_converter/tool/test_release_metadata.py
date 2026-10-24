import importlib.util
import json
from pathlib import Path
import tempfile
import unittest


SPEC = importlib.util.spec_from_file_location('release_metadata', Path(__file__).with_name('release_metadata.py'))
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class ReleaseMetadataTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.spec = self.root / 'pubspec.yaml'
        self.spec.write_text('name: avelune_converter\nversion: 0.1.0+1\n')
        self.contract = MODULE.release_contract(self.spec, 'a' * 40, '0.1.0')

    def assets(self):
        self.spec.unlink()
        for suffix in ('dmg', 'app.zip'):
            (self.root / f'Avelune-Converter-0.1.0-macOS.{suffix}').write_bytes(b'original fixture archive')
        (self.root / 'appcast-macos.xml').write_text('''<rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle"><channel><item>
<sparkle:version>1</sparkle:version><sparkle:shortVersionString>0.1.0</sparkle:shortVersionString>
<enclosure url="https://github.com/yoahnl/pokemap/releases/download/avelune-converter-v0.1.0/Avelune-Converter-0.1.0-macOS.app.zip" length="24" sparkle:edSignature="synthetic"/>
</item></channel></rss><!-- sparkle-signatures: test -->''')

    def test_contract_binds_own_identity_version_and_revision(self):
        self.assertEqual(self.contract['tag'], 'avelune-converter-v0.1.0')
        self.assertEqual(self.contract['product'], 'avelune-converter')
        self.assertEqual(self.contract['buildNumber'], 1)
        self.assertEqual(self.contract['revision'], 'a' * 40)

    def test_contract_rejects_invalid_version_revision_or_requested_version(self):
        for version in ('0.1.0-beta+1', '00.1.0+1', '0.1.0+0', '0.1.0+1\nversion: 2.0.0+2'):
            with self.subTest(version=version):
                self.spec.write_text(f'version: {version}\n')
                with self.assertRaises(ValueError):
                    MODULE.release_contract(self.spec, 'a' * 40, '')
        self.spec.write_text('version: 0.1.0+1\n')
        for revision, requested in (('bad', '0.1.0'), ('a' * 40, '0.2.0')):
            with self.assertRaises(ValueError):
                MODULE.release_contract(self.spec, revision, requested)

    def test_previous_release_must_match_product_and_strictly_increase_both_counters(self):
        for changed in ({}, {'version': '0.2.0'}, {'buildNumber': 2}, {'product': 'avelune-studio'}):
            previous = {**self.contract, **changed}
            with self.assertRaises(ValueError):
                MODULE.require_newer(self.contract, previous)
        self.spec.write_text('version: 0.2.0+2\n')
        MODULE.require_newer(MODULE.release_contract(self.spec, 'b' * 40), self.contract)

    def test_manifest_round_trip_checks_every_byte_and_exact_inventory(self):
        self.assets()
        MODULE.create_manifest(self.root, self.contract)
        manifest = MODULE.verify_manifest(self.root)
        self.assertEqual(manifest['version'], '0.1.0')
        self.assertEqual(len(manifest['assets']), 3)
        self.assertEqual(len((self.root / 'SHA256SUMS').read_text().splitlines()), 4)
        (self.root / 'Avelune-Converter-0.1.0-macOS.dmg').write_bytes(b'tampered')
        with self.assertRaises(ValueError):
            MODULE.verify_manifest(self.root)

    def test_retry_requires_the_exact_same_version_build_and_revision(self):
        MODULE.require_newer(self.contract, self.contract, allow_identical=True)
        with self.assertRaises(ValueError):
            MODULE.require_newer({**self.contract, 'revision': 'b' * 40}, self.contract, allow_identical=True)
        self.spec.write_text('version: 0.2.0+2\n')
        newer = MODULE.release_contract(self.spec, 'b' * 40)
        with self.assertRaises(ValueError):
            MODULE.require_newer(self.contract, newer, allow_identical=True)

    def test_missing_extra_symlink_and_foreign_feed_are_refused(self):
        self.assets()
        (self.root / 'unplanned.zip').write_bytes(b'extra')
        with self.assertRaises(ValueError):
            MODULE.create_manifest(self.root, self.contract)
        (self.root / 'unplanned.zip').unlink()
        archive = self.root / 'Avelune-Converter-0.1.0-macOS.dmg'
        archive.unlink()
        archive.symlink_to(self.spec)
        with self.assertRaises(ValueError):
            MODULE.create_manifest(self.root, self.contract)
        archive.unlink()
        archive.write_bytes(b'original fixture archive')
        feed = self.root / 'appcast-macos.xml'
        feed.write_text(feed.read_text().replace('avelune-converter-v', 'pokemap-v'))
        with self.assertRaises(ValueError):
            MODULE.create_manifest(self.root, self.contract)

    def test_promotion_revalidates_current_stable_and_binds_retry_bytes(self):
        self.assets()
        manifest = MODULE.create_manifest(self.root, self.contract)
        MODULE.validate_promotion(self.root, manifest)
        changed = {**manifest, 'assets': []}
        with self.assertRaises(ValueError):
            MODULE.validate_promotion(self.root, changed)
        newer = {**manifest, 'version': '0.2.0', 'buildNumber': 2,
                 'tag': 'avelune-converter-v0.2.0',
                 'releaseNotesUrl': 'https://github.com/yoahnl/pokemap/releases/tag/avelune-converter-v0.2.0'}
        with self.assertRaises(ValueError):
            MODULE.validate_promotion(self.root, newer)

    def test_manifest_metadata_and_checksums_cannot_be_rewritten_independently(self):
        self.assets()
        MODULE.create_manifest(self.root, self.contract)
        index = self.root / MODULE.INDEX_NAME
        payload = json.loads(index.read_text())
        payload['releaseNotesUrl'] = 'https://example.com/untrusted'
        index.write_text(json.dumps(payload))
        with self.assertRaises(ValueError):
            MODULE.verify_manifest(self.root)


if __name__ == '__main__':
    unittest.main()
