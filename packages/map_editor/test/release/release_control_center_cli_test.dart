import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory temporaryDirectory;
  late File pokeMapPubspec;
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
      'pokemap-release-control-center-test-',
    );
    pokeMapPubspec = File(p.join(temporaryDirectory.path, 'pokemap.yaml'));
    await pokeMapPubspec.writeAsString(
      'name: map_editor\nversion: 0.3.3+303\n',
    );
  });

  tearDown(() async {
    await temporaryDirectory.delete(recursive: true);
  });

  Future<ProcessResult> runRequest({
    required String product,
    required String action,
    String ref = 'refs/heads/main',
    String? pokeMapVersion,
    String? confirmation,
    File? githubOutput,
  }) {
    return Process.run(dartExecutable, [
      '../../tool/release_control_center/validate_release_request.dart',
      '--product',
      product,
      '--action',
      action,
      '--ref',
      ref,
      '--pokemap-pubspec',
      pokeMapPubspec.path,
      if (pokeMapVersion != null) ...['--pokemap-version', pokeMapVersion],
      if (confirmation != null) ...['--confirmation', confirmation],
      if (githubOutput != null) ...['--github-output', githubOutput.path],
    ]);
  }

  test('accepts a confirmed PokeMap publication from main', () async {
    final githubOutput = File(
      p.join(temporaryDirectory.path, 'github-output.txt'),
    );
    final result = await runRequest(
      product: 'pokemap',
      action: 'publish',
      pokeMapVersion: '0.3.3',
      confirmation: 'RELEASE',
      githubOutput: githubOutput,
    );

    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(result.stdout, contains('Validated PokeMap publish request.'));
    expect(
      await githubOutput.readAsLines(),
      containsAll(<String>[
        'pokemap_selected=true',
        'pokemap_version=0.3.3',
        'pokemap_tag=pokemap-v0.3.3',
      ]),
    );
  });

  test('retired Avelune publication cannot be selected', () async {
    final result = await runRequest(product: 'avelune', action: 'preflight');

    expect(result.exitCode, 64);
    expect(result.stderr, contains('--product must be pokemap.'));
  });

  test('publication requires the exact RELEASE confirmation', () async {
    final result = await runRequest(
      product: 'pokemap',
      action: 'publish',
      pokeMapVersion: '0.3.3',
      confirmation: 'release',
    );

    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('Type RELEASE to confirm publication.'));
  });

  test('publication is restricted to the main branch', () async {
    final result = await runRequest(
      product: 'pokemap',
      action: 'publish',
      ref: 'refs/heads/feature/test',
      pokeMapVersion: '0.3.3',
      confirmation: 'RELEASE',
    );

    expect(result.exitCode, isNot(0));
    expect(
      result.stderr,
      contains('Publications must be dispatched from refs/heads/main.'),
    );
  });

  test('publication version must match the selected product pubspec', () async {
    final result = await runRequest(
      product: 'pokemap',
      action: 'publish',
      pokeMapVersion: '0.3.4',
      confirmation: 'RELEASE',
    );

    expect(result.exitCode, isNot(0));
    expect(
      result.stderr,
      contains('PokeMap version 0.3.4 does not match pubspec version 0.3.3.'),
    );
  });

  test('PokeMap publication uses only its own pubspec', () async {
    final result = await runRequest(
      product: 'pokemap',
      action: 'publish',
      pokeMapVersion: '0.3.3',
      confirmation: 'RELEASE',
    );

    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(result.stdout, contains('Validated PokeMap publish request.'));
  });
}
