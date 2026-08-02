import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory temporaryDirectory;
  late File temporaryPubspec;
  late String dartExecutable;

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
      'pokemap-release-version-test-',
    );
    temporaryPubspec = File(
      p.join(temporaryDirectory.path, 'pubspec.yaml'),
    );
    await temporaryPubspec.writeAsString(
      'name: map_editor\nversion: 0.3.0+300\n',
    );
  });

  tearDown(() async {
    await temporaryDirectory.delete(recursive: true);
  });

  test('release version CLI accepts a matching stable release', () async {
    final result = await Process.run(
      dartExecutable,
      [
        'tool/release/validate_release_version.dart',
        '--tag',
        'pokemap-v0.3.0',
        '--pubspec',
        temporaryPubspec.path,
        '--previous-build',
        '299',
      ],
    );

    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(
      result.stdout,
      contains('Validated PokeMap Editor 0.3.0 build 300.'),
    );
  });

  test('release version CLI fails closed on a mismatched tag', () async {
    final result = await Process.run(
      dartExecutable,
      [
        'tool/release/validate_release_version.dart',
        '--tag',
        'pokemap-v0.3.1',
        '--pubspec',
        temporaryPubspec.path,
      ],
    );

    expect(result.exitCode, isNot(0));
    expect(
      result.stderr,
      contains(
        'Tag version 0.3.1 does not match pubspec version 0.3.0.',
      ),
    );
  });
}
