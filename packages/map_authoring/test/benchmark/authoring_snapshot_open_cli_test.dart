import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('opens a deterministic synthetic authoring snapshot', () async {
    final output = await _temporaryOutput('authoring_snapshot');
    final result = await _run(<String>[
      '--warmups',
      '0',
      '--samples',
      '1',
      '--fixtures',
      'small',
      '--roots',
      '1,3',
      '--cycles',
      '1',
      '--output',
      output.path,
    ]);

    expect(result.exitCode, 0, reason: '${result.stderr}');
    final payload =
        jsonDecode(await output.readAsString()) as Map<String, Object?>;
    expect(payload['schemaVersion'], 2);
    expect(payload['benchmark'], 'authoring_snapshot_open');
    final rows =
        (payload['results']! as List<Object?>).cast<Map<String, Object?>>();
    expect(rows.map((row) => row['rootCount']), <Object?>[1, 3]);
    expect(rows.every((row) => row['fixture'] == 'small'), isTrue);
    expect(
        rows.every((row) => '${row['snapshotChecksum']}'.isNotEmpty), isTrue);
  });

  test('measures the canonical Selbrume authoring snapshot', () async {
    final output = await _temporaryOutput('authoring_snapshot_selbrume');
    final result = await _run(<String>[
      '--fixtures',
      'selbrume',
      '--warmups',
      '0',
      '--samples',
      '1',
      '--roots',
      '1',
      '--cycles',
      '1',
      '--output',
      output.path,
    ]);

    expect(result.exitCode, 0, reason: '${result.stderr}');
    final payload =
        jsonDecode(await output.readAsString()) as Map<String, Object?>;
    final rows =
        (payload['results']! as List<Object?>).cast<Map<String, Object?>>();
    expect(rows, hasLength(1));
    expect(rows.single['fixturePath'], 'selbrume');
    expect(rows.single['mapCount'], 10);
    expect(rows.single['resourceCount'], 35);
    expect(rows.single['resourceBytes'], 4753256);
    final profile = Map<String, Object?>.from(
      rows.single['snapshotProfile']! as Map,
    );
    expect(
      profile.keys,
      containsAll(<String>[
        'initialRead',
        'decodeModel',
        'secondObservation',
        'fingerprint',
        'projection',
        'total',
      ]),
    );
    for (final stage in profile.values) {
      final metric = Map<String, Object?>.from(stage! as Map);
      expect(metric['samplesUs'], hasLength(1));
      expect(metric['p50Us'], isA<int>());
      expect(metric['p95Us'], isA<int>());
      expect(metric['p99Us'], isA<int>());
    }
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('rejects promotion checkpoint, zero samples, and escaped output',
      () async {
    final forbidden = await _run(const <String>[
      '--fixtures',
      'promotion_checkpoint',
      '--output',
      'build/test/promotion.json',
    ]);
    final zero = await _run(const <String>[
      '--samples',
      '0',
      '--output',
      'build/test/authoring-zero.json',
    ]);
    final escaped = await _run(const <String>[
      '--output',
      '../authoring-escape.json',
    ]);

    expect(forbidden.exitCode, 64);
    expect('${forbidden.stderr}', contains('snapshot benchmark forbids'));
    expect(zero.exitCode, 64);
    expect('${zero.stderr}', contains('samples must be positive'));
    expect(escaped.exitCode, 64);
    expect('${escaped.stderr}',
        contains('must stay inside packages/map_authoring'));
  }, timeout: const Timeout(Duration(minutes: 2)));
}

Future<File> _temporaryOutput(String prefix) async {
  await Directory('build/test').create(recursive: true);
  final directory = await Directory('build/test').createTemp('${prefix}_cli_');
  addTearDown(() => directory.delete(recursive: true));
  return File('${directory.path}/result.json');
}

Future<ProcessResult> _run(List<String> arguments) => Process.run(
      Platform.resolvedExecutable,
      <String>['run', 'benchmark/authoring_snapshot_open.dart', ...arguments],
      workingDirectory: Directory.current.path,
    );
