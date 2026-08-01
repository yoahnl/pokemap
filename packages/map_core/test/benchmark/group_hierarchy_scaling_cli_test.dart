import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('writes hierarchy validation percentiles and a stable checksum',
      () async {
    final output = await _temporaryOutput('group_hierarchy');
    final result = await _run(<String>[
      '--warmups',
      '0',
      '--samples',
      '1',
      '--sizes',
      '3,8',
      '--output',
      output.path,
    ]);

    expect(result.exitCode, 0, reason: '${result.stderr}');
    final payload =
        jsonDecode(await output.readAsString()) as Map<String, Object?>;
    expect(payload['schemaVersion'], 2);
    expect(payload['benchmark'], 'group_hierarchy_scaling');
    final rows =
        (payload['results']! as List<Object?>).cast<Map<String, Object?>>();
    expect(rows.map((row) => row['groupCount']), <Object?>[3, 8]);
    expect(
        rows.every((row) => '${row['datasetFingerprint']}'.isNotEmpty), isTrue);
    expect(
        rows.every((row) => '${row['validationChecksum']}'.isNotEmpty), isTrue);
  });

  test('rejects zero samples and output paths outside map_core', () async {
    final zero = await _run(const <String>[
      '--samples',
      '0',
      '--output',
      'build/test/group-zero.json',
    ]);
    final escaped = await _run(const <String>[
      '--output',
      '../group-escape.json',
    ]);

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
      <String>['run', 'benchmark/group_hierarchy_scaling.dart', ...arguments],
      workingDirectory: Directory.current.path,
    );
