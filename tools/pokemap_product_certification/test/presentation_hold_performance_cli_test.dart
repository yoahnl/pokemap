import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// BETA-CIN-084 — the CLI is what makes a hold measurement reproducible.
///
/// The receipt validates a payload; the CLI is what stamps the payload with the
/// commit, the tree state, the device and the Flutter version, so a reader
/// months later can tell which code the numbers describe. These tests drive it
/// as a subprocess against a throwaway git repository, because the parts worth
/// testing — refusing a dirty tree, not writing a receipt when it refuses,
/// exiting non-zero on a violation — only exist at that boundary.
void main() {
  test('certifies a complete hold measurement and stamps its provenance',
      () async {
    final fixture = await _Fixture.create(_validMeasurements());
    addTearDown(fixture.dispose);

    final result = await fixture.run();

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    final receipt = jsonDecode(await fixture.output.readAsString())
        as Map<String, Object?>;
    expect(receipt['benchmark'], 'presentation_hold_cin_084');
    expect(receipt['verdict'], 'passed');
    expect(receipt['platform'], 'macos');
    final provenance = receipt['provenance']! as Map<String, Object?>;
    expect(provenance['treeState'], 'clean');
    expect(provenance['device'], 'macOS desktop');
    expect(provenance['flutterVersion'], '3.46.0-0.3.pre');
    expect(
      provenance['commit'],
      matches(RegExp(r'^[0-9a-f]{40}$')),
      reason: 'the receipt names the exact commit the numbers describe',
    );
    // The budget is in the receipt, so a pass under a loosened budget is
    // distinguishable from a real one after the fact.
    expect(receipt['budgets'], isA<Map<String, Object?>>());
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
    // what was too slow, so it has to survive.
    final measurements = _validMeasurements();
    final landscape = (measurements['orientations']!
        as Map<String, Object?>)['landscape']! as Map<String, Object?>;
    landscape['inputToDisplayUs'] = <int>[
      for (var index = 0; index < 50; index += 1) 400000 + index,
    ];
    final fixture = await _Fixture.create(measurements);
    addTearDown(fixture.dispose);

    final result = await fixture.run();

    expect(result.exitCode, 1, reason: '${result.stdout}\n${result.stderr}');
    final receipt = jsonDecode(await fixture.output.readAsString())
        as Map<String, Object?>;
    expect(receipt['verdict'], 'failed');
    expect(
      receipt['violations'],
      contains('landscape.inputToDisplay.p95'),
    );
  });

  test('refuses an unknown option rather than ignoring it', () async {
    final fixture = await _Fixture.create(_validMeasurements());
    addTearDown(fixture.dispose);

    final result = await fixture.run(extra: <String>['--threshold', '999']);

    expect(result.exitCode, 2);
    expect('${result.stderr}', contains('Unsupported CIN-084 option'));
  });
}

final class _Fixture {
  _Fixture._(this.root, this.repository, this.measurements, this.output);

  static Future<_Fixture> create(Map<String, Object?> measurements) async {
    final root = await Directory.systemTemp.createTemp('pokemap-cin-084-cli-');
    final repository = Directory(p.join(root.path, 'repository'))
      ..createSync(recursive: true);
    await _git(repository, <String>['init', '-q']);
    await _git(repository, <String>['config', 'user.email', 'cin084@test']);
    await _git(repository, <String>['config', 'user.name', 'CIN-084']);
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
          'bin/certify_presentation_hold_performance.dart',
          '--repository-root',
          repository.path,
          '--measurements',
          measurements.path,
          '--device',
          'macOS desktop',
          '--output',
          output.path,
          ...extra,
        ],
        environment: <String, String>{
          ...Platform.environment,
          'FLUTTER_VERSION': '3.46.0-0.3.pre',
        },
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
  Map<String, Object?> orientation() => <String, Object?>{
        'holdCycles': 50,
        'answeredInputs': 50,
        'inputToDisplayUs': <int>[
          for (var index = 0; index < 50; index += 1) 42000 + index,
        ],
        'inputToResumeUs': <int>[
          for (var index = 0; index < 50; index += 1) 61000 + index,
        ],
        'slowFrames': 1,
      };

  return <String, Object?>{
    'schemaVersion': 1,
    'benchmark': 'presentation_hold_cin_084',
    'target':
        'integration_test/presentation_hold_performance_journey_test.dart',
    'executionMode': 'flutter-profile',
    'platform': 'macos',
    'mediaPipeline': <String, Object?>{
      'decoderImplementation': 'AVFoundationVideoDecoder',
      'audioSinkImplementation': 'CoreAudioSink',
      'decodedVideoFrames': 3120,
      'renderedCaptionCues': 100,
    },
    'orientations': <String, Object?>{
      'landscape': orientation(),
      'portrait': orientation(),
    },
    'teardown': <String, Object?>{
      for (final reason in const <String>[
        'stop',
        'skip',
        'background',
        'error',
        'routeClose',
      ])
        reason: <String, Object?>{
          'activeDecoders': 0,
          'activeAudioHandles': 0,
          'activeTimers': 0,
          'activeSubscriptions': 0,
        },
    },
    'memory': <String, Object?>{
      'rssAfterCycle5Bytes': 198 * 1024 * 1024,
      'rssAfterCycle50Bytes': 214 * 1024 * 1024,
    },
  };
}
