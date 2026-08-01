import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('child mode emits a fingerprinted no-mask result', () async {
    final result = await _run(const <String>[
      '--child',
      'true',
      '--warmups',
      '0',
      '--samples',
      '1',
      '--sizes',
      '8',
    ]);

    expect(result.exitCode, 0, reason: '${result.stderr}');
    final payload =
        jsonDecode('${result.stdout}'.trim()) as Map<String, Object?>;
    final measured =
        (payload['results']! as List<Object?>).single as Map<String, Object?>;
    expect(payload['schemaVersion'], 2);
    expect(measured['generatorVersion'], 1);
    expect(measured['datasetFingerprint'], isNotEmpty);
    expect(measured['allocatedPixelMaskChunks'], 0);
    expect(
      (measured['queries1000']! as Map<String, Object?>)['resultChecksum'],
      isNotEmpty,
    );
    final maskMeasured = (payload['maskResults']! as List<Object?>).single
        as Map<String, Object?>;
    expect(maskMeasured['allocatedPixelMaskChunks'], 4);
    expect(
      (maskMeasured['queries']! as Map<String, Object?>)['resultChecksum'],
      isNotEmpty,
    );
  });

  test('rejects a zero isolated run count and output escape', () async {
    final invalidRuns = await _run(const <String>[
      '--sizes',
      '8',
      '--isolated-size',
      '16',
      '--isolated-runs',
      '0',
      '--output',
      'build/test/world-collision.json',
    ]);
    final escaped = await _run(const <String>[
      '--sizes',
      '8',
      '--output',
      '../world-collision-escape.json',
    ]);

    expect(invalidRuns.exitCode, 64);
    expect('${invalidRuns.stderr}', contains('isolated-runs must be positive'));
    expect(escaped.exitCode, 64);
    expect(
      '${escaped.stderr}',
      contains('must stay inside packages/map_gameplay'),
    );
  });
}

Future<ProcessResult> _run(List<String> arguments) {
  return Process.run(
    Platform.resolvedExecutable,
    <String>['run', 'benchmark/world_collision_scaling.dart', ...arguments],
    workingDirectory: Directory.current.path,
  );
}
