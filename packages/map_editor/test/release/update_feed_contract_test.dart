import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  const version = '0.3.1';
  const tag = 'pokemap-v0.3.1';
  const repository = 'yoahnl/pokemap';

  late Directory temporaryDirectory;
  late String dartExecutable;
  late SimpleKeyPair macosKeyPair;
  late SimpleKeyPair windowsKeyPair;
  late String macosPublicKey;
  late String windowsPublicKey;

  setUp(() async {
    dartExecutable = p.join(
      Platform.environment['FLUTTER_ROOT']!,
      'bin',
      'cache',
      'dart-sdk',
      'bin',
      'dart',
    );
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'pokemap-update-assets-test-',
    );
    final algorithm = Ed25519();
    macosKeyPair = await algorithm.newKeyPairFromSeed(
      List<int>.generate(32, (index) => index + 1),
    );
    windowsKeyPair = await algorithm.newKeyPairFromSeed(
      List<int>.generate(32, (index) => index + 33),
    );
    macosPublicKey = base64Encode(
      (await macosKeyPair.extractPublicKey()).bytes,
    );
    windowsPublicKey = base64Encode(
      (await windowsKeyPair.extractPublicKey()).bytes,
    );
  });

  tearDown(() async {
    await temporaryDirectory.delete(recursive: true);
  });

  test('update index generator writes the catalog contract consumed by app',
      () async {
    final output = File(
      p.join(temporaryDirectory.path, 'pokemap-update-index.json'),
    );

    final result = await _runIndexGenerator(
      dartExecutable: dartExecutable,
      output: output,
      publishedAt: '2026-08-03T12:00:00Z',
    );

    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(jsonDecode(await output.readAsString()), {
      'schemaVersion': 1,
      'channel': 'stable',
      'version': version,
      'tag': tag,
      'publishedAt': '2026-08-03T12:00:00.000Z',
      'releaseNotesUrl': 'https://github.com/$repository/releases/tag/$tag',
    });
  });

  test('validator accepts coherent assets and writes complete checksums',
      () async {
    await _writeSignedAssets(
      directory: temporaryDirectory,
      macosKeyPair: macosKeyPair,
      windowsKeyPair: windowsKeyPair,
      dartExecutable: dartExecutable,
    );

    final result = await _runValidator(
      dartExecutable: dartExecutable,
      directory: temporaryDirectory,
      macosPublicKey: macosPublicKey,
      windowsPublicKey: windowsPublicKey,
      writeChecksums: true,
    );

    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(
        result.stdout, contains('Validated 7 update assets and SHA256SUMS.'));
    final checksums = await File(
      p.join(temporaryDirectory.path, 'SHA256SUMS'),
    ).readAsLines();
    expect(checksums, hasLength(7));
    expect(checksums, everyElement(matches(r'^[0-9a-f]{64}  [^/]+$')));
  });

  test('validator accepts a manual Windows installer without an appcast',
      () async {
    await _writeSignedAssets(
      directory: temporaryDirectory,
      macosKeyPair: macosKeyPair,
      windowsKeyPair: windowsKeyPair,
      dartExecutable: dartExecutable,
      writeWindowsAppcast: false,
    );

    final result = await _runValidator(
      dartExecutable: dartExecutable,
      directory: temporaryDirectory,
      macosPublicKey: macosPublicKey,
      windowsManual: true,
      writeChecksums: true,
    );

    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(result.stdout, contains('Validated 6 release assets'));
    final checksums = await File(
      p.join(temporaryDirectory.path, 'SHA256SUMS'),
    ).readAsLines();
    expect(checksums, hasLength(6));
    expect(
      checksums,
      everyElement(isNot(contains('appcast-windows.xml'))),
    );
  });

  test('validator fails closed when a signed asset changes after upload',
      () async {
    await _writeSignedAssets(
      directory: temporaryDirectory,
      macosKeyPair: macosKeyPair,
      windowsKeyPair: windowsKeyPair,
      dartExecutable: dartExecutable,
    );
    final initial = await _runValidator(
      dartExecutable: dartExecutable,
      directory: temporaryDirectory,
      macosPublicKey: macosPublicKey,
      windowsPublicKey: windowsPublicKey,
      writeChecksums: true,
    );
    expect(initial.exitCode, 0, reason: initial.stderr.toString());

    await File(
      p.join(temporaryDirectory.path, 'PokeMap-Editor-Setup-$version.exe'),
    ).writeAsString('xindows-installer');
    final result = await _runValidator(
      dartExecutable: dartExecutable,
      directory: temporaryDirectory,
      macosPublicKey: macosPublicKey,
      windowsPublicKey: windowsPublicKey,
    );

    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('Windows archive signature is invalid.'));
    expect(result.stderr, contains('SHA256 mismatch'));
  });

  test('validator refuses non-HTTPS release asset URLs', () async {
    await _writeSignedAssets(
      directory: temporaryDirectory,
      macosKeyPair: macosKeyPair,
      windowsKeyPair: windowsKeyPair,
      dartExecutable: dartExecutable,
      windowsScheme: 'http',
    );

    final result = await _runValidator(
      dartExecutable: dartExecutable,
      directory: temporaryDirectory,
      macosPublicKey: macosPublicKey,
      windowsPublicKey: windowsPublicKey,
      writeChecksums: true,
    );

    expect(result.exitCode, isNot(0));
    expect(
      result.stderr,
      contains('Windows enclosure URL must use the trusted GitHub HTTPS URL.'),
    );
  });
}

Future<ProcessResult> _runIndexGenerator({
  required String dartExecutable,
  required File output,
  required String publishedAt,
}) {
  return Process.run(dartExecutable, [
    'tool/release/generate_update_index.dart',
    '--output',
    output.path,
    '--version',
    '0.3.1',
    '--tag',
    'pokemap-v0.3.1',
    '--published-at',
    publishedAt,
    '--repository',
    'yoahnl/pokemap',
  ]);
}

Future<ProcessResult> _runValidator({
  required String dartExecutable,
  required Directory directory,
  required String macosPublicKey,
  String? windowsPublicKey,
  bool windowsManual = false,
  bool writeChecksums = false,
}) {
  return Process.run(dartExecutable, [
    'tool/release/validate_update_assets.dart',
    '--directory',
    directory.path,
    '--version',
    '0.3.1',
    '--build-number',
    '301',
    '--tag',
    'pokemap-v0.3.1',
    '--repository',
    'yoahnl/pokemap',
    '--macos-public-key',
    macosPublicKey,
    if (windowsPublicKey != null) ...[
      '--windows-public-key',
      windowsPublicKey,
    ],
    if (windowsManual) '--windows-manual',
    if (writeChecksums) '--write-checksums',
  ]);
}

Future<void> _writeSignedAssets({
  required Directory directory,
  required SimpleKeyPair macosKeyPair,
  required SimpleKeyPair windowsKeyPair,
  required String dartExecutable,
  String windowsScheme = 'https',
  bool writeWindowsAppcast = true,
}) async {
  final files = <String, List<int>>{
    'PokeMap-Editor-Setup-0.3.1.exe': utf8.encode('windows-installer'),
    'PokeMap-Editor-0.3.1-macOS.dmg': utf8.encode('macos-dmg'),
    'PokeMap-Editor-0.3.1-macOS.app.zip': utf8.encode('macos-archive'),
    'PokeMap-Editor-0.3.1-linux-x64.tar.gz': utf8.encode('linux-archive'),
  };
  for (final entry in files.entries) {
    await File(p.join(directory.path, entry.key)).writeAsBytes(entry.value);
  }

  final indexResult = await _runIndexGenerator(
    dartExecutable: dartExecutable,
    output: File(p.join(directory.path, 'pokemap-update-index.json')),
    publishedAt: '2026-08-03T12:00:00Z',
  );
  expect(indexResult.exitCode, 0, reason: indexResult.stderr.toString());

  final algorithm = Ed25519();
  final macosArchive = files['PokeMap-Editor-0.3.1-macOS.app.zip']!;
  final macosArchiveSignature = await algorithm.sign(
    macosArchive,
    keyPair: macosKeyPair,
  );
  final unsignedMacosAppcast = '''<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel><item><enclosure
    url="https://github.com/yoahnl/pokemap/releases/download/pokemap-v0.3.1/PokeMap-Editor-0.3.1-macOS.app.zip"
    sparkle:version="301" sparkle:shortVersionString="0.3.1"
    sparkle:edSignature="${base64Encode(macosArchiveSignature.bytes)}"
    length="${macosArchive.length}" type="application/octet-stream" />
  </item></channel>
</rss>
''';
  final macosFeedSignature = await algorithm.sign(
    utf8.encode(unsignedMacosAppcast),
    keyPair: macosKeyPair,
  );
  await File(p.join(directory.path, 'appcast-macos.xml')).writeAsString(
    '$unsignedMacosAppcast<!-- sparkle-signatures:\n'
    'edSignature: ${base64Encode(macosFeedSignature.bytes)}\n'
    'length: ${utf8.encode(unsignedMacosAppcast).length}\n'
    '-->\n',
  );

  if (writeWindowsAppcast) {
    final windowsInstaller = files['PokeMap-Editor-Setup-0.3.1.exe']!;
    final windowsSignature = await algorithm.sign(
      windowsInstaller,
      keyPair: windowsKeyPair,
    );
    await File(p.join(directory.path, 'appcast-windows.xml')).writeAsString('''
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel><item>
    <sparkle:version>0.3.1</sparkle:version>
    <sparkle:shortVersionString>0.3.1</sparkle:shortVersionString>
    <enclosure
      url="$windowsScheme://github.com/yoahnl/pokemap/releases/download/pokemap-v0.3.1/PokeMap-Editor-Setup-0.3.1.exe"
      sparkle:os="windows-x64"
      sparkle:edSignature="${base64Encode(windowsSignature.bytes)}"
      length="${windowsInstaller.length}" type="application/octet-stream" />
  </item></channel>
</rss>
''');
  }
}
