import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('writes a versioned deterministic map paint receipt', () async {
    final output = await _temporaryOutput('map_paint');

    final result = await _run(<String>[
      '--warmups',
      '0',
      '--samples',
      '1',
      '--sizes',
      '8',
      '--stroke-lengths',
      '1,4',
      '--output',
      output.path,
    ]);

    expect(result.exitCode, 0, reason: '${result.stderr}');
    final payload =
        jsonDecode(await output.readAsString()) as Map<String, Object?>;
    expect(payload['schemaVersion'], 2);
    expect(payload['benchmark'], 'map_paint_gesture');
    expect(payload['sampleCount'], 1);
    final rows = payload['results']! as List<Object?>;
    expect(rows, hasLength(2));
    for (final row in rows.cast<Map<String, Object?>>()) {
      expect(row['datasetFingerprint'], isNotEmpty);
      expect(row['paintChecksum'], isNotEmpty);
      expect(row['samplesUs'], hasLength(1));
      expect(row['p50Us'], row['p95Us']);
      expect(row['p95Us'], row['p99Us']);
    }
  });

  test('rejects zero samples, malformed strokes, and escaped output', () async {
    final zero = await _run(const <String>[
      '--samples',
      '0',
      '--output',
      'build/test/map-paint-zero.json',
    ]);
    final malformed = await _run(const <String>[
      '--stroke-lengths',
      '1,bad',
      '--output',
      'build/test/map-paint-malformed.json',
    ]);
    final escaped = await _run(const <String>[
      '--output',
      '../map-paint-escape.json',
    ]);

    expect(zero.exitCode, 64);
    expect('${zero.stderr}', contains('samples must be positive'));
    expect(malformed.exitCode, 64);
    expect('${malformed.stderr}', contains('invalid stroke length: bad'));
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
      <String>['run', 'benchmark/map_paint_gesture.dart', ...arguments],
      workingDirectory: Directory.current.path,
    );
