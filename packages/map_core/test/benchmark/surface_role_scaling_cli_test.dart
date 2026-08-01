import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('writes comparable legacy and topology results for one dataset',
      () async {
    await Directory('build/test').create(recursive: true);
    final outputDirectory = await Directory('build/test').createTemp(
      'surface_role_cli_',
    );
    addTearDown(() => outputDirectory.delete(recursive: true));
    final outputPath = '${outputDirectory.path}/result.json';

    final result = await _run(<String>[
      '--warmups',
      '0',
      '--samples',
      '1',
      '--sizes',
      '9',
      '--fixtures',
      'dense',
      '--modes',
      'legacy,topology',
      '--output',
      outputPath,
    ]);

    expect(result.exitCode, 0, reason: '${result.stderr}');
    final payload = jsonDecode(await File(outputPath).readAsString())
        as Map<String, Object?>;
    final results = payload['results']! as List<Object?>;
    expect(payload['schemaVersion'], 2);
    expect(results, hasLength(2));
    final legacy = results.first as Map<String, Object?>;
    final topology = results.last as Map<String, Object?>;
    expect(legacy['mode'], 'legacy');
    expect(topology['mode'], 'topology');
    expect(legacy['datasetFingerprint'], topology['datasetFingerprint']);
    expect(legacy['roleChecksum'], isNotEmpty);
    expect(legacy['roleChecksum'], topology['roleChecksum']);
  });

  test('rejects malformed size tokens and output paths outside the package',
      () async {
    final malformed = await _run(const <String>[
      '--sizes',
      '9,bad',
      '--output',
      'build/test/malformed.json',
    ]);
    final escaped = await _run(const <String>[
      '--sizes',
      '9',
      '--output',
      '../surface-role-escape.json',
    ]);

    expect(malformed.exitCode, 64);
    expect('${malformed.stderr}', contains('invalid size: bad'));
    expect(escaped.exitCode, 64);
    expect('${escaped.stderr}', contains('must stay inside packages/map_core'));
  });
}

Future<ProcessResult> _run(List<String> arguments) {
  return Process.run(
    Platform.resolvedExecutable,
    <String>['run', 'benchmark/surface_role_scaling.dart', ...arguments],
    workingDirectory: Directory.current.path,
  );
}
