part of 'validate_update_assets.dart';

const _sparkleNamespace = 'http://www.andymatuschak.org/xml-namespaces/sparkle';

Future<void> _validateAppcast({
  required String label,
  required File appcast,
  required File archive,
  required String expectedUrl,
  required String expectedVersion,
  required String expectedShortVersion,
  required List<int> publicKey,
  required bool requireSignedFeed,
  required List<String> errors,
}) async {
  final rawBytes = await appcast.readAsBytes();
  late String rawText;
  late XmlDocument document;
  try {
    rawText = utf8.decode(rawBytes);
    document = XmlDocument.parse(rawText);
  } on FormatException {
    errors.add('$label appcast must be valid UTF-8 XML.');
    return;
  }
  final items = document.findAllElements('item').toList();
  if (items.length != 1) {
    errors.add('$label appcast must contain exactly one release item.');
    return;
  }
  final enclosures = items.single.findElements('enclosure').toList();
  if (enclosures.length != 1) {
    errors.add('$label appcast must contain exactly one enclosure.');
    return;
  }
  final item = items.single;
  final enclosure = enclosures.single;
  final version = _sparkleValue(item, enclosure, 'version');
  final shortVersion = _sparkleValue(item, enclosure, 'shortVersionString');
  if (version != expectedVersion || shortVersion != expectedShortVersion) {
    errors.add('$label appcast version does not match the release contract.');
  }
  if (enclosure.getAttribute('url') != expectedUrl) {
    errors.add('$label enclosure URL must use the trusted GitHub HTTPS URL.');
  }
  if (enclosure.getAttribute('type') != 'application/octet-stream') {
    errors.add('$label enclosure MIME type must be application/octet-stream.');
  }
  final expectedLength = await archive.length();
  final declaredLength = int.tryParse(enclosure.getAttribute('length') ?? '');
  if (declaredLength != expectedLength) {
    errors.add('$label enclosure length does not match its archive.');
  }

  final signature = _decodeSignature(
    enclosure.getAttribute('edSignature', namespaceUri: _sparkleNamespace),
    '$label archive',
    errors,
  );
  if (signature != null &&
      !await _verifyEd25519(
        await archive.readAsBytes(),
        signature,
        publicKey,
      )) {
    errors.add('$label archive signature is invalid.');
  }

  if (requireSignedFeed) {
    final match = RegExp(
      r'<!-- sparkle-signatures:\r?\n'
      r'edSignature: ([A-Za-z0-9+/=]+)\r?\n'
      r'length: (\d+)\r?\n-->\s*$',
    ).firstMatch(rawText);
    if (match == null) {
      errors.add('$label appcast must contain a Sparkle signed-feed block.');
      return;
    }
    final content = utf8.encode(rawText.substring(0, match.start));
    if (int.tryParse(match.group(2)!) != content.length) {
      errors.add('$label signed-feed length does not match its XML content.');
    }
    final feedSignature = _decodeSignature(
      match.group(1),
      '$label feed',
      errors,
    );
    if (feedSignature != null &&
        !await _verifyEd25519(content, feedSignature, publicKey)) {
      errors.add('$label feed signature is invalid.');
    }
  }
}

String? _sparkleValue(XmlElement item, XmlElement enclosure, String localName) {
  final attribute = enclosure.getAttribute(
    localName,
    namespaceUri: _sparkleNamespace,
  );
  if (attribute != null) {
    return attribute;
  }
  final elements = item
      .findElements(localName, namespaceUri: _sparkleNamespace)
      .toList();
  return elements.length == 1 ? elements.single.innerText.trim() : null;
}

List<int>? _decodeSignature(
  String? encoded,
  String label,
  List<String> errors,
) {
  if (encoded == null) {
    errors.add('$label must contain an Ed25519 signature.');
    return null;
  }
  try {
    final bytes = base64Decode(encoded);
    if (bytes.length != 64) {
      errors.add('$label Ed25519 signature must encode exactly 64 bytes.');
      return null;
    }
    return bytes;
  } on FormatException {
    errors.add('$label Ed25519 signature must be valid base64.');
    return null;
  }
}

Future<bool> _verifyEd25519(
  List<int> message,
  List<int> signature,
  List<int> publicKey,
) {
  return Ed25519().verify(
    message,
    signature: Signature(
      signature,
      publicKey: SimplePublicKey(publicKey, type: KeyPairType.ed25519),
    ),
  );
}
