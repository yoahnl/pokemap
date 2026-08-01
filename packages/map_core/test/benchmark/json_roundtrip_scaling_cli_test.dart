import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('writes JSON round-trip size and percentile evidence', () async {
    final output = await _temporaryOutput('json_roundtrip');
    final result = await _run(<String>[
      '--warmups',
      '0',
      '--samples',
      '1',
      '--bytes',
      '512,2048',
      '--output',
      output.path,
    ]);

    expect(result.exitCode, 0, reason: '${result.stderr}');
    final payload =
        jsonDecode(await output.readAsString()) as Map<String, Object?>;
    expect(payload['schemaVersion'], 2);
    expect(payload['benchmark'], 'json_roundtrip_scaling');
    final rows =
        (payload['results']! as List<Object?>).cast<Map<String, Object?>>();
    expect(rows.map((row) => row['targetBytes']), <Object?>[512, 2048]);
    expect(rows.every((row) => (row['actualBytes']! as int) >= 512), isTrue);
    expect(
        rows.every((row) => '${row['roundtripChecksum']}'.isNotEmpty), isTrue);
  });

  test('rejects malformed byte sizes, zero samples, and escaped output',
      () async {
    final malformed = await _run(const <String>[
      '--bytes',
      '1024,nope',
      '--output',
      'build/test/json-malformed.json',
    ]);
    final zero = await _run(const <String>[
      '--samples',
      '0',
      '--output',
      'build/test/json-zero.json',
    ]);
    final escaped = await _run(const <String>[
      '--output',
      '../json-escape.json',
    ]);

    expect(malformed.exitCode, 64);
    expect('${malformed.stderr}', contains('invalid byte size: nope'));
    expect(zero.exitCode, 64);
    expect('${zero.stderr}', contains('samples must be positive'));
    expect(escaped.exitCode, 64);
    expect('${escaped.stderr}', contains('must stay inside packages/map_core'));
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
      <String>['run', 'benchmark/json_roundtrip_scaling.dart', ...arguments],
      workingDirectory: Directory.current.path,
    );
