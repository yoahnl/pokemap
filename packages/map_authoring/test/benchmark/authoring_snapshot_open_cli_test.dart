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
      '--modes',
      'cold,warm',
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
    expect(rows, hasLength(4));
    expect(rows.map((row) => row['mode']).toSet(), {'cold', 'warm'});
    expect(rows.map((row) => row['rootCount']).toSet(), <Object?>{1, 3});
    expect(rows.every((row) => row['fixture'] == 'small'), isTrue);
    expect(
        rows.every((row) => '${row['snapshotChecksum']}'.isNotEmpty), isTrue);
    expect(
      rows.where((row) => row['mode'] == 'warm').every(
            (row) => (row['snapshotCacheHits']! as int) > 0,
          ),
      isTrue,
    );
  });

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
