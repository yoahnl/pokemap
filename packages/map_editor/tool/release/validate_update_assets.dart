import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

const _sparkleNamespace = 'http://www.andymatuschak.org/xml-namespaces/sparkle';

Future<void> main(List<String> arguments) async {
  exitCode = await validateUpdateAssetsCommand(arguments);
}

Future<int> validateUpdateAssetsCommand(
  List<String> arguments, {
  IOSink? output,
  IOSink? errorOutput,
}) async {
  final stdoutSink = output ?? stdout;
  final stderrSink = errorOutput ?? stderr;
  final directoryPath = _readOption(arguments, '--directory');
  final version = _readOption(arguments, '--version');
  final buildNumber = _readOption(arguments, '--build-number');
  final tag = _readOption(arguments, '--tag');
  final repository = _readOption(arguments, '--repository');
  final macosPublicKeyText = _readOption(arguments, '--macos-public-key');
  final windowsPublicKeyText = _readOption(arguments, '--windows-public-key');
  final windowsManual = arguments.contains('--windows-manual');
  final writeChecksums = arguments.contains('--write-checksums');

  if ([
    directoryPath,
    version,
    buildNumber,
    tag,
    repository,
    macosPublicKeyText,
    if (!windowsManual) windowsPublicKeyText,
  ].any((value) => value == null)) {
    stderrSink.writeln(
      'Usage: validate_update_assets.dart --directory path '
      '--version X.Y.Z --build-number N --tag pokemap-vX.Y.Z '
      '--repository owner/repo --macos-public-key base64 '
      '(--windows-public-key base64 | --windows-manual) '
      '[--write-checksums]',
    );
    return 64;
  }

  final errors = <String>[];
  if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version!)) {
    errors.add('Version must be a stable X.Y.Z version.');
  }
  if (!RegExp(r'^[1-9]\d*$').hasMatch(buildNumber!)) {
    errors.add('Build number must be a positive integer.');
  }
  if (tag != 'pokemap-v$version') {
    errors.add('Tag must exactly match pokemap-v$version.');
  }
  if (!RegExp(r'^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$').hasMatch(repository!)) {
    errors.add('Repository must match owner/repo.');
  }
  final macosPublicKey = _decodePublicKey(
    macosPublicKeyText!,
    'macOS',
    errors,
  );
  final windowsPublicKey = windowsManual
      ? null
      : _decodePublicKey(
          windowsPublicKeyText!,
          'Windows',
          errors,
        );

  final directory = Directory(directoryPath!);
  if (!await directory.exists()) {
    errors.add('Release asset directory does not exist: $directoryPath');
  }
  final assetNames = <String>[
    'PokeMap-Editor-Setup-$version.exe',
    'PokeMap-Editor-$version-macOS.dmg',
    'PokeMap-Editor-$version-macOS.app.zip',
    'PokeMap-Editor-$version-linux-x64.tar.gz',
    'appcast-macos.xml',
    if (!windowsManual) 'appcast-windows.xml',
    'pokemap-update-index.json',
  ]..sort();
  final assets = <String, File>{
    for (final name in assetNames) name: File(p.join(directory.path, name)),
  };
  if (await directory.exists()) {
    for (final entry in assets.entries) {
      if (!await entry.value.exists()) {
        errors.add('Missing required release asset: ${entry.key}');
      } else if (await entry.value.length() == 0) {
        errors.add('Required release asset is empty: ${entry.key}');
      }
    }
  }

  if (errors.isEmpty) {
    await _validateIndex(
      assets['pokemap-update-index.json']!,
      version: version,
      tag: tag!,
      repository: repository,
      errors: errors,
    );
    await _validateAppcast(
      label: 'macOS',
      appcast: assets['appcast-macos.xml']!,
      archive: assets['PokeMap-Editor-$version-macOS.app.zip']!,
      expectedUrl: 'https://github.com/$repository/releases/download/$tag/'
          'PokeMap-Editor-$version-macOS.app.zip',
      expectedVersion: buildNumber,
      expectedShortVersion: version,
      publicKey: macosPublicKey!,
      requireSignedFeed: true,
      errors: errors,
    );
    if (!windowsManual) {
      await _validateAppcast(
        label: 'Windows',
        appcast: assets['appcast-windows.xml']!,
        archive: assets['PokeMap-Editor-Setup-$version.exe']!,
        expectedUrl: 'https://github.com/$repository/releases/download/$tag/'
            'PokeMap-Editor-Setup-$version.exe',
        expectedVersion: version,
        expectedShortVersion: version,
        publicKey: windowsPublicKey!,
        requireSignedFeed: false,
        errors: errors,
      );
    }
  }

  final checksumFile = File(p.join(directory.path, 'SHA256SUMS'));
  if (writeChecksums && errors.isEmpty) {
    await _writeChecksums(checksumFile, assets);
  }
  if (errors.isEmpty || await checksumFile.exists()) {
    await _validateChecksums(checksumFile, assets, errors);
  } else if (!writeChecksums) {
    errors.add('Missing required release asset: SHA256SUMS');
  }

  if (errors.isNotEmpty) {
    for (final error in errors) {
      stderrSink.writeln(error);
    }
    return 65;
  }

  stdoutSink.writeln(
    'Validated ${assetNames.length} '
    '${windowsManual ? 'release' : 'update'} assets and SHA256SUMS.',
  );
  return 0;
}

List<int>? _decodePublicKey(
  String encoded,
  String label,
  List<String> errors,
) {
  try {
    final bytes = base64Decode(encoded);
    if (bytes.length != 32) {
      errors.add('$label public key must encode exactly 32 bytes.');
      return null;
    }
    return bytes;
  } on FormatException {
    errors.add('$label public key must be valid base64.');
    return null;
  }
}

Future<void> _validateIndex(
  File file, {
  required String version,
  required String tag,
  required String repository,
  required List<String> errors,
}) async {
  Object? decoded;
  try {
    decoded = jsonDecode(await file.readAsString());
  } on FormatException {
    errors.add('Update index must contain valid JSON.');
    return;
  }
  if (decoded is! Map<String, dynamic>) {
    errors.add('Update index must be a JSON object.');
    return;
  }
  const requiredKeys = <String>{
    'schemaVersion',
    'channel',
    'version',
    'tag',
    'publishedAt',
    'releaseNotesUrl',
  };
  if (decoded.keys.toSet().difference(requiredKeys).isNotEmpty ||
      requiredKeys.difference(decoded.keys.toSet()).isNotEmpty) {
    errors.add('Update index must use the exact stable schema keys.');
  }
  if (decoded['schemaVersion'] != 1) {
    errors.add('Update index schemaVersion must be 1.');
  }
  if (decoded['channel'] != 'stable') {
    errors.add('Update index channel must be stable.');
  }
  if (decoded['version'] != version || decoded['tag'] != tag) {
    errors.add('Update index version and tag must match the release.');
  }
  if (decoded['releaseNotesUrl'] !=
      'https://github.com/$repository/releases/tag/$tag') {
    errors.add('Update index release notes URL is not trusted.');
  }
  final publishedAtText = decoded['publishedAt'];
  final publishedAt =
      publishedAtText is String ? DateTime.tryParse(publishedAtText) : null;
  if (publishedAt == null || !publishedAt.isUtc) {
    errors.add('Update index publishedAt must be a valid UTC timestamp.');
  }
}

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
  final shortVersion = _sparkleValue(
    item,
    enclosure,
    'shortVersionString',
  );
  if (version != expectedVersion || shortVersion != expectedShortVersion) {
    errors.add('$label appcast version does not match the release contract.');
  }
  if (enclosure.getAttribute('url') != expectedUrl) {
    errors.add(
      '$label enclosure URL must use the trusted GitHub HTTPS URL.',
    );
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

String? _sparkleValue(
  XmlElement item,
  XmlElement enclosure,
  String localName,
) {
  final attribute = enclosure.getAttribute(
    localName,
    namespaceUri: _sparkleNamespace,
  );
  if (attribute != null) {
    return attribute;
  }
  final elements =
      item.findElements(localName, namespaceUri: _sparkleNamespace).toList();
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

Future<void> _writeChecksums(
  File checksumFile,
  Map<String, File> assets,
) async {
  final lines = <String>[];
  for (final entry in assets.entries) {
    final digest = sha256.convert(await entry.value.readAsBytes());
    lines.add('$digest  ${entry.key}');
  }
  await checksumFile.writeAsString('${lines.join('\n')}\n', flush: true);
}

Future<void> _validateChecksums(
  File checksumFile,
  Map<String, File> assets,
  List<String> errors,
) async {
  if (!await checksumFile.exists()) {
    errors.add('Missing required release asset: SHA256SUMS');
    return;
  }
  final declared = <String, String>{};
  for (final line in await checksumFile.readAsLines()) {
    final match = RegExp(r'^([0-9a-f]{64})  ([^/\\]+)$').firstMatch(line);
    if (match == null) {
      errors.add('SHA256SUMS contains an invalid line.');
      continue;
    }
    final name = match.group(2)!;
    if (declared.containsKey(name)) {
      errors.add('SHA256SUMS contains duplicate entry: $name');
    }
    declared[name] = match.group(1)!;
  }
  if (declared.keys.toSet().difference(assets.keys.toSet()).isNotEmpty ||
      assets.keys.toSet().difference(declared.keys.toSet()).isNotEmpty) {
    errors.add('SHA256SUMS must list exactly every release asset once.');
  }
  for (final entry in assets.entries) {
    final expected = declared[entry.key];
    if (expected == null || !await entry.value.exists()) {
      continue;
    }
    final actual = sha256.convert(await entry.value.readAsBytes()).toString();
    if (expected != actual) {
      errors.add('SHA256 mismatch for ${entry.key}.');
    }
  }
}

String? _readOption(List<String> arguments, String option) {
  final index = arguments.indexOf(option);
  if (index == -1 || index + 1 >= arguments.length) {
    return null;
  }
  return arguments[index + 1];
}
