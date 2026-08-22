import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// BETA-CIN-085 — the CLI stamps a journey with what makes it reproducible.
///
/// The journey observes and measures; this turns those measurements into a
/// receipt carrying the exact commit, a clean tree, the platform and the
/// commands that produced the run, which is what the ticket's fifth criterion
/// asks for by name. These tests drive it as a subprocess against a throwaway
/// git repository, because the behaviours worth pinning — refusing a dirty
/// tree, writing nothing when it refuses, exiting non-zero on a violation —
/// only exist at that boundary.
void main() {
  test('certifies a measured journey and records its commands', () async {
    final fixture = await _Fixture.create(_validMeasurements());
    addTearDown(fixture.dispose);

    final result = await fixture.run();

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    final receipt = jsonDecode(await fixture.output.readAsString())
        as Map<String, Object?>;
    expect(receipt['benchmark'], 'installed_hub_journey_cin_085');
    expect(receipt['verdict'], 'passed');
    final provenance = receipt['provenance']! as Map<String, Object?>;
    expect(provenance['treeState'], 'clean');
    expect(
      provenance['commit'],
      matches(RegExp(r'^[0-9a-f]{40}$')),
      reason: 'the receipt names the exact commit the journey ran against',
    );
    expect(
      provenance['commands'],
      contains(
        'flutter test test/installed_hub_journey_test.dart',
      ),
      reason: 'the command that produced the run travels with the verdict',
    );
    expect(
      receipt['uncertifiedLimits'],
      isNotEmpty,
      reason: 'what the run did NOT prove is part of the receipt',
    );
  });

  test('refuses a dirty repository without writing a receipt', () async {
    final fixture = await _Fixture.create(_validMeasurements());
    addTearDown(fixture.dispose);
    File(p.join(fixture.repository.path, 'untracked.txt'))
        .writeAsStringSync('dirty\n');

    final result = await fixture.run();

    expect(result.exitCode, 2);
    expect('${result.stderr}', contains('clean tree'));
    expect(
      fixture.output.existsSync(),
      isFalse,
      reason: 'a refused run must leave nothing that later reads as evidence',
    );
  });

  test('exits non-zero and still writes the failed receipt', () async {
    // A violation is a result, not an error: the receipt is the evidence of
    // which exit leaked, so it has to survive.
    final measurements = _validMeasurements();
    final cancel = (measurements['paths']! as Map<String, Object?>)['cancel']!
        as Map<String, Object?>;
    (cancel['residual']! as Map<String, Object?>)['activeTimers'] = 1;
    final fixture = await _Fixture.create(measurements);
    addTearDown(fixture.dispose);

    final result = await fixture.run();

    expect(result.exitCode, 1, reason: '${result.stdout}\n${result.stderr}');
    final receipt = jsonDecode(await fixture.output.readAsString())
        as Map<String, Object?>;
    expect(receipt['verdict'], 'failed');
    expect(
      receipt['violations'],
      contains('paths.cancel.residual.activeTimers'),
    );
  });

  test('refuses an unknown option rather than ignoring it', () async {
    final fixture = await _Fixture.create(_validMeasurements());
    addTearDown(fixture.dispose);

    final result = await fixture.run(extra: <String>['--force', 'yes']);

    expect(result.exitCode, 2);
    expect('${result.stderr}', contains('Unsupported CIN-085 option'));
  });

  test('refuses a journey whose dialogue was outside the Presentation',
      () async {
    final measurements = _validMeasurements();
    final nominal = (measurements['paths']! as Map<String, Object?>)['nominal']!
        as Map<String, Object?>;
    ((nominal['interactions']! as List<Object?>).first
        as Map<String, Object?>)['presentationState'] = 'playing';
    final fixture = await _Fixture.create(measurements);
    addTearDown(fixture.dispose);

    final result = await fixture.run();

    expect(result.exitCode, 2);
    expect('${result.stderr}', contains('old canary'));
    expect(fixture.output.existsSync(), isFalse);
  });
}

final class _Fixture {
  _Fixture._(this.root, this.repository, this.measurements, this.output);

  static Future<_Fixture> create(Map<String, Object?> measurements) async {
    final root = await Directory.systemTemp.createTemp('pokemap-cin-085-cli-');
    final repository = Directory(p.join(root.path, 'repository'))
      ..createSync(recursive: true);
    await _git(repository, <String>['init', '-q']);
    await _git(repository, <String>['config', 'user.email', 'cin085@test']);
    await _git(repository, <String>['config', 'user.name', 'CIN-085']);
    File(p.join(repository.path, 'tracked.txt')).writeAsStringSync('tracked\n');
    await _git(repository, <String>['add', 'tracked.txt']);
    await _git(repository, <String>['commit', '-q', '-m', 'fixture']);
    final payload = File(p.join(root.path, 'measurements.json'))
      ..writeAsStringSync(jsonEncode(measurements));
    return _Fixture._(
      root,
      repository,
      payload,
      File(p.join(root.path, 'receipt.json')),
    );
  }

  final Directory root;
  final Directory repository;
  final File measurements;
  final File output;

  Future<ProcessResult> run({List<String> extra = const <String>[]}) =>
      Process.run(
        'dart',
        <String>[
          'run',
          'bin/certify_installed_hub_journey.dart',
          '--repository-root',
          repository.path,
          '--measurements',
          measurements.path,
          '--journey-command',
          'flutter test test/installed_hub_journey_test.dart',
          '--output',
          output.path,
          ...extra,
        ],
      );

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

Future<void> _git(Directory repository, List<String> arguments) async {
  final result = await Process.run(
    'git',
    arguments,
    workingDirectory: repository.path,
  );
  if (result.exitCode != 0) {
    throw StateError('git ${arguments.join(' ')} failed: ${result.stderr}');
  }
}

Map<String, Object?> _validMeasurements() {
  Map<String, Object?> path(String name) => <String, Object?>{
        'outcome': name == 'nominal'
            ? 'ready'
            : name == 'error'
                ? 'failed'
                : 'cancelled',
        'terminalCommits': 1,
        'interactions': name == 'error'
            ? <Object?>[]
            : <Object?>[
                <String, Object?>{
                  'markerId': 'cue_player_name',
                  'kind': 'SceneTextInteractionRequest',
                  'presentationState': 'interactionHold',
                  'presentationNodeId': 'opening',
                },
              ],
        'residual': <String, Object?>{
          'activeDecoders': 0,
          'activeAudioHandles': 0,
          'activeTimers': 0,
          'activeSubscriptions': 0,
        },
      };

  return <String, Object?>{
    'schemaVersion': 1,
    'benchmark': 'installed_hub_journey_cin_085',
    'installedPackage': <String, Object?>{
      'gameId': 'games.pokemap.certification.neutral',
      'gameVersion': '1.0.0',
      'treeSha256':
          '680d93dc156b2ff23b3e555cf356addbbe71466ba8874836963d95e5c730d3e5',
      'packageSha256':
          '1c373f632aaa2fd98e3f1694946b635cb7fe831a8492f71612a4104a5d68f197',
      'installedVersionRoot': '/tmp/support/games/'
          'games.pokemap.certification.neutral/versions/1.0.0',
    },
    'paths': <String, Object?>{
      for (final name in const <String>['nominal', 'cancel', 'skip', 'error'])
        name: path(name),
    },
    'persistence': <String, Object?>{
      'committedDraftFields': const <String>[
        'playerName',
        'avatarCharacterId',
        'starterOptionId',
      ],
      'visibleAfterHandoff': true,
      'survivedReload': true,
      'projectConfigUnchanged': true,
    },
    'uncertifiedLimits': const <String>[
      "The Hub's own UI was not driven; BETA-CIN-086 owns the visual recette.",
      'Only macOS was exercised.',
    ],
  };
}
