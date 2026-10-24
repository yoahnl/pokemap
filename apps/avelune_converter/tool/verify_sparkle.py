import argparse
import base64
import binascii
import json
import os
from pathlib import Path
import re
import shutil
import stat
import subprocess
import sys
import tempfile
from urllib.parse import urlsplit
import xml.etree.ElementTree as ET


SPARKLE = '{http://www.andymatuschak.org/xml-namespaces/sparkle}'
PUBLIC_KEY_DER_PREFIX = bytes.fromhex('302a300506032b6570032100')
FEED_SIGNATURE = re.compile(
    rb'<!-- sparkle-signatures:\n'
    rb'edSignature: ([A-Za-z0-9+/=]+)\n'
    rb'length: ([0-9]+)\n-->[ \t\r\n]*\Z'
)


def _decode(encoded, length, label):
    if not isinstance(encoded, str):
        raise ValueError(f'{label} must be valid base64')
    try:
        raw = base64.b64decode(encoded, validate=True)
    except (ValueError, binascii.Error, UnicodeError) as error:
        raise ValueError(f'{label} must be valid base64') from error
    if len(raw) != length or base64.b64encode(raw).decode('ascii') != encoded:
        raise ValueError(f'{label} must encode exactly {length} bytes')
    return raw


def _identity(path):
    value = path.lstat()
    if not stat.S_ISREG(value.st_mode):
        raise ValueError(f'Expected a regular release file: {path.name}')
    return (value.st_dev, value.st_ino, value.st_size,
            value.st_mtime_ns, value.st_ctime_ns)


def _verify_file(openssl, public_key, signature, message, scratch, label):
    signature_path = scratch / f'{label}.signature'
    signature_path.write_bytes(signature)
    try:
        result = subprocess.run(
            [openssl, 'pkeyutl', '-verify', '-pubin', '-inkey', str(public_key),
             '-keyform', 'DER', '-rawin', '-in', str(message),
             '-sigfile', str(signature_path)],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=120,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired) as error:
        raise ValueError('OpenSSL Ed25519 verification could not complete') from error
    if result.returncode != 0:
        raise ValueError(
            f'{label} Ed25519 signature verification failed; '
            'OpenSSL with pkeyutl -rawin Ed25519 support is required'
        )


def verify(directory, public_key):
    key = _decode(public_key, 32, 'Public key')
    openssl = shutil.which(os.environ.get('OPENSSL_BIN', 'openssl'))
    if openssl is None:
        raise ValueError('OpenSSL with Ed25519 support is required')
    directory = Path(directory)
    if not directory.is_dir() or directory.is_symlink():
        raise ValueError('Expected a release directory without a symlink')
    feed_path = directory / 'appcast-macos.xml'
    feed_identity = _identity(feed_path)
    if feed_identity[2] > 1024 * 1024:
        raise ValueError('Appcast exceeds the 1 MiB release limit')
    raw = feed_path.read_bytes()
    raw.decode('utf-8', errors='strict')
    match = FEED_SIGNATURE.search(raw)
    if match is None or raw.count(b'<!-- sparkle-signatures:') != 1:
        raise ValueError('Appcast requires exactly one terminal Sparkle signature block')
    content = raw[:match.start()]
    if int(match.group(2)) != len(content):
        raise ValueError('Signed-feed length differs from its exact XML bytes')
    signature = _decode(match.group(1).decode('ascii'), 64, 'Feed signature')
    with tempfile.TemporaryDirectory(prefix='converter-sparkle-verify-') as temporary:
        scratch = Path(temporary)
        key_path = scratch / 'public.der'
        key_path.write_bytes(PUBLIC_KEY_DER_PREFIX + key)
        message_path = scratch / 'feed.xml'
        message_path.write_bytes(content)
        _verify_file(openssl, key_path, signature, message_path, scratch, 'feed')
        if re.search(rb'<!\s*(?:DOCTYPE|ENTITY)\b', content, re.IGNORECASE):
            raise ValueError('Appcast must not declare XML entities or a document type')
        document = ET.fromstring(content)
        items = document.findall('./channel/item')
        if document.tag != 'rss' or len(items) != 1:
            raise ValueError('Appcast requires exactly one release item')
        enclosures = items[0].findall('enclosure')
        if len(enclosures) != 1:
            raise ValueError('Appcast requires exactly one update enclosure')
        enclosure = enclosures[0]
        version = items[0].findtext(SPARKLE + 'shortVersionString')
        version = enclosure.get(SPARKLE + 'shortVersionString', version)
        if version is None or re.fullmatch(r'[0-9]+\.[0-9]+\.[0-9]+', version) is None:
            raise ValueError('Appcast requires a stable Converter version')
        name = f'Avelune-Converter-{version}-macOS.app.zip'
        url = enclosure.get('url', '')
        expected_url = ('https://github.com/yoahnl/pokemap/releases/download/'
                        f'avelune-converter-v{version}/{name}')
        if url != expected_url or urlsplit(url).query or urlsplit(url).fragment:
            raise ValueError('Enclosure must reference the exact Converter GitHub release')
        if enclosure.get('type') != 'application/octet-stream':
            raise ValueError('Enclosure requires application/octet-stream')
        archive = directory / name
        archive_identity = _identity(archive)
        length = enclosure.get('length', '')
        if not re.fullmatch(r'[0-9]+', length) or int(length) != archive_identity[2]:
            raise ValueError('Enclosure length differs from the update archive')
        archive_signature = _decode(enclosure.get(SPARKLE + 'edSignature'),
                                    64, 'Archive signature')
        _verify_file(openssl, key_path, archive_signature, archive, scratch, 'archive')
        if archive_identity != _identity(archive) or feed_identity != _identity(feed_path):
            raise ValueError('Release files changed during verification')
    return {'verified': True, 'feed': feed_path.name, 'archive': name,
            'signedFeedBytes': len(content), 'archiveBytes': archive_identity[2]}


def main(arguments=None):
    parser = argparse.ArgumentParser()
    parser.add_argument('--directory', required=True)
    parser.add_argument('--public-key', required=True)
    arguments = parser.parse_args(arguments)
    try:
        result = verify(arguments.directory, arguments.public_key)
    except (ValueError, TypeError, OSError, ET.ParseError) as error:
        print(f'Sparkle verification refused: {error}', file=sys.stderr)
        return 1
    print(json.dumps(result, sort_keys=True))
    return 0


if __name__ == '__main__':
    sys.exit(main())
