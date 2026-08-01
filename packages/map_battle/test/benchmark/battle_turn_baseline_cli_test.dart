import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('writes deterministic battle turn percentile evidence', () async {
    final output = await _temporaryOutput('battle_turn');
    final result = await _run(<String>[
      '--warmups',
      '0',
      '--samples',
      '1',
      '--turns',
      '2,5',
      '--output',
      output.path,
    ]);

    expect(result.exitCode, 0, reason: '${result.stderr}');
    final payload =
        jsonDecode(await output.readAsString()) as Map<String, Object?>;
    expect(payload['schemaVersion'], 2);
    expect(payload['benchmark'], 'battle_turn_baseline');
    final rows =
        (payload['results']! as List<Object?>).cast<Map<String, Object?>>();
    expect(rows.map((row) => row['turnCount']), <Object?>[2, 5]);
    expect(
        rows.every((row) => '${row['datasetFingerprint']}'.isNotEmpty), isTrue);
    expect(rows.every((row) => '${row['battleChecksum']}'.isNotEmpty), isTrue);
  });

  test('rejects malformed turn counts, zero samples, and escaped output',
      () async {
    final malformed = await _run(const <String>[
      '--turns',
      '100,bad',
      '--output',
      'build/test/battle-malformed.json',
    ]);
    final zero = await _run(const <String>[
      '--samples',
      '0',
      '--output',
      'build/test/battle-zero.json',
    ]);
    final escaped = await _run(const <String>[
      '--output',
      '../battle-escape.json',
    ]);

    expect(malformed.exitCode, 64);
    expect('${malformed.stderr}', contains('invalid turn count: bad'));
    expect(zero.exitCode, 64);
    expect('${zero.stderr}', contains('samples must be positive'));
    expect(escaped.exitCode, 64);
    expect(
        '${escaped.stderr}', contains('must stay inside packages/map_battle'));
  });
}

Future<File> _temporaryOutput(String prefix) async {
  await Directory('build/test').create(recursive: true);
  final directory = await Directory('build/test').createTemp('${prefix}_cli_');
  addTearDown(() => directory.delete(recursive: true));
  return File('${directory.path}/result.json');
}

Future<ProcessResult> _run(List<String> arguments) => Process.run(
      Platform.resolvedExecutable,
      <String>['run', 'benchmark/battle_turn_baseline.dart', ...arguments],
      workingDirectory: Directory.current.path,
    );
