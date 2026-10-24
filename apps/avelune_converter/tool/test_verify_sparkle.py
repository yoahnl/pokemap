import base64
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

import verify_sparkle


class VerifySparkleTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='converter-signature-test-')
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.openssl = shutil.which(os.environ.get('OPENSSL_BIN', 'openssl'))
        if self.openssl is None:
            self.fail('OpenSSL Ed25519 support is required for the release tests')
        self.private = self.root / 'original-test-private.pem'
        self._run('genpkey', '-algorithm', 'ED25519', '-out', str(self.private))
        der = self._run('pkey', '-in', str(self.private), '-pubout', '-outform', 'DER')
        self.assertEqual(der[:12], verify_sparkle.PUBLIC_KEY_DER_PREFIX)
        self.public = base64.b64encode(der[12:]).decode('ascii')
        self.distribution = self.root / 'release'
        self.distribution.mkdir()
        self.archive = self.distribution / 'Avelune-Converter-0.1.0-macOS.app.zip'
        self.archive.write_bytes(b'original synthetic update archive\x00\x01')
        self.feed = self.distribution / 'appcast-macos.xml'
        self._write_feed()

    def _run(self, *arguments):
        return subprocess.run([self.openssl, *arguments], check=True,
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                              timeout=15).stdout

    def _sign(self, content):
        message = self.root / 'signing-message'
        message.write_bytes(content)
        return base64.b64encode(self._run(
            'pkeyutl', '-sign', '-inkey', str(self.private), '-rawin',
            '-in', str(message))).decode('ascii')

    def _write_feed(self, *, length_delta=0, archive_signature=None, url=None):
        signature = archive_signature or self._sign(self.archive.read_bytes())
        url = url or ('https://github.com/yoahnl/pokemap/releases/download/'
                      'avelune-converter-v0.1.0/Avelune-Converter-0.1.0-macOS.app.zip')
        content = (
            '<?xml version="1.0" encoding="UTF-8"?>\n'
            '<!-- sparkle-sign-warning: Original résumé signé. -->\n'
            '<rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">'
            '<channel><item><sparkle:version>1</sparkle:version>'
            '<sparkle:shortVersionString>0.1.0</sparkle:shortVersionString>'
            f'<enclosure url="{url}" length="{self.archive.stat().st_size}" '
            f'type="application/octet-stream" sparkle:edSignature="{signature}"/>'
            '</item></channel></rss>\n'
        ).encode('utf-8')
        block = (f'<!-- sparkle-signatures:\nedSignature: {self._sign(content)}\n'
                 f'length: {len(content) + length_delta}\n-->\n').encode('ascii')
        self.feed.write_bytes(content + block)

    def test_verifies_exact_utf8_feed_and_archive_bytes(self):
        result = verify_sparkle.verify(self.distribution, self.public)
        self.assertTrue(result['verified'])
        self.assertEqual(result['archive'], self.archive.name)

    def test_cli_accepts_the_release_directory(self):
        result = subprocess.run(
            [shutil.which('python3'), str(Path(verify_sparkle.__file__)),
             '--directory', str(self.distribution), '--public-key', self.public],
            check=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=20)
        self.assertEqual(result.returncode, 0, result.stderr.decode())

    def test_refuses_same_length_feed_tampering(self):
        self.feed.write_bytes(self.feed.read_bytes().replace(b'Original', b'Modified', 1))
        with self.assertRaisesRegex(ValueError, 'feed Ed25519 signature'):
            verify_sparkle.verify(self.distribution, self.public)

    def test_refuses_same_length_archive_tampering(self):
        data = self.archive.read_bytes()
        self.archive.write_bytes(bytes([data[0] ^ 1]) + data[1:])
        with self.assertRaisesRegex(ValueError, 'archive Ed25519 signature'):
            verify_sparkle.verify(self.distribution, self.public)

    def test_refuses_invalid_or_wrong_size_public_keys(self):
        for value in ['bad!', '', base64.b64encode(b'x' * 31).decode('ascii')]:
            with self.subTest(value=value), self.assertRaises(ValueError):
                verify_sparkle.verify(self.distribution, value)

    def test_refuses_a_different_valid_public_key(self):
        private = self.root / 'other-original-test-key.pem'
        self._run('genpkey', '-algorithm', 'ED25519', '-out', str(private))
        public = self._run('pkey', '-in', str(private), '-pubout', '-outform', 'DER')[12:]
        with self.assertRaisesRegex(ValueError, 'feed Ed25519 signature'):
            verify_sparkle.verify(self.distribution, base64.b64encode(public).decode('ascii'))

    def test_refuses_a_missing_or_nonterminal_feed_signature(self):
        raw = self.feed.read_bytes()
        for content in [raw.split(b'<!-- sparkle-signatures:')[0], raw + b'<rss/>']:
            self.feed.write_bytes(content)
            with self.assertRaisesRegex(ValueError, 'terminal Sparkle signature'):
                verify_sparkle.verify(self.distribution, self.public)

    def test_refuses_wrong_signed_feed_length(self):
        self._write_feed(length_delta=1)
        with self.assertRaisesRegex(ValueError, 'Signed-feed length'):
            verify_sparkle.verify(self.distribution, self.public)

    def test_refuses_crlf_signing_block_unrecognized_by_sparkle(self):
        content, block = self.feed.read_bytes().split(b'<!-- sparkle-signatures:')
        self.feed.write_bytes(content + b'<!-- sparkle-signatures:' +
                              block.replace(b'\n', b'\r\n'))
        with self.assertRaisesRegex(ValueError, 'terminal Sparkle signature'):
            verify_sparkle.verify(self.distribution, self.public)

    def test_refuses_validly_signed_feed_with_wrong_archive_signature(self):
        self._write_feed(archive_signature=base64.b64encode(b'x' * 64).decode('ascii'))
        with self.assertRaisesRegex(ValueError, 'archive Ed25519 signature'):
            verify_sparkle.verify(self.distribution, self.public)

    def test_refuses_validly_signed_foreign_product_url(self):
        self._write_feed(url='https://github.com/yoahnl/pokemap/releases/download/'
                         'pokemap-v0.1.0/Avelune-Converter-0.1.0-macOS.app.zip')
        with self.assertRaisesRegex(ValueError, 'exact Converter GitHub release'):
            verify_sparkle.verify(self.distribution, self.public)

    def test_refuses_an_archive_symlink(self):
        target = self.root / 'foreign-archive.zip'
        target.write_bytes(self.archive.read_bytes())
        self.archive.unlink()
        self.archive.symlink_to(target)
        with self.assertRaisesRegex(ValueError, 'regular release file'):
            verify_sparkle.verify(self.distribution, self.public)


if __name__ == '__main__':
    unittest.main()
