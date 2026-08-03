import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory temporaryDirectory;
  late File pokeMapPubspec;
  late File avelunePubspec;
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
    avelunePubspec = File(p.join(temporaryDirectory.path, 'avelune.yaml'));
    await pokeMapPubspec.writeAsString(
      'name: map_editor\nversion: 0.3.3+303\n',
    );
    await avelunePubspec.writeAsString(
      'name: pokemap_hub\nversion: 0.1.1+2\n',
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
    String? aveluneVersion,
    String? confirmation,
    File? githubOutput,
  }) {
    return Process.run(
      dartExecutable,
      [
        '../../tool/release_control_center/validate_release_request.dart',
        '--product',
        product,
        '--action',
        action,
        '--ref',
        ref,
        '--pokemap-pubspec',
        pokeMapPubspec.path,
        '--avelune-pubspec',
        avelunePubspec.path,
        if (pokeMapVersion != null) ...[
          '--pokemap-version',
          pokeMapVersion,
        ],
        if (aveluneVersion != null) ...[
          '--avelune-version',
          aveluneVersion,
        ],
        if (confirmation != null) ...['--confirmation', confirmation],
        if (githubOutput != null) ...[
          '--github-output',
          githubOutput.path,
        ],
      ],
    );
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
        'avelune_selected=false',
        'pokemap_version=0.3.3',
        'pokemap_tag=pokemap-v0.3.3',
        'avelune_version=',
        'avelune_tag=',
      ]),
    );
  });

  test('preflight resolves both versions without confirmation', () async {
    final githubOutput = File(
      p.join(temporaryDirectory.path, 'github-output.txt'),
    );
    final result = await runRequest(
      product: 'both',
      action: 'preflight',
      githubOutput: githubOutput,
    );

    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(result.stdout, contains('Validated PokeMap + Avelune preflight'));
    expect(
      await githubOutput.readAsLines(),
      containsAll(<String>[
        'pokemap_selected=true',
        'avelune_selected=true',
        'pokemap_version=0.3.3',
        'avelune_version=0.1.1',
      ]),
    );
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
      product: 'avelune',
      action: 'publish',
      ref: 'refs/heads/feature/test',
      aveluneVersion: '0.1.1',
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
      product: 'both',
      action: 'publish',
      pokeMapVersion: '0.3.4',
      aveluneVersion: '0.1.1',
      confirmation: 'RELEASE',
    );

    expect(result.exitCode, isNot(0));
    expect(
      result.stderr,
      contains('PokeMap version 0.3.4 does not match pubspec version 0.3.3.'),
    );
  });

  test('a selected product does not depend on the other product pubspec',
      () async {
    await avelunePubspec.delete();

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
