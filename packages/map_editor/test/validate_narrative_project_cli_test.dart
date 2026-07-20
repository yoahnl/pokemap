import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

void main() {
  test('process preserves pass, fail, indeterminate and notRun exit codes',
      () async {
    final temporary = await Directory.systemTemp.createTemp(
      'pokemap_narrative_validator_cli_',
    );
    addTearDown(() => temporary.delete(recursive: true));
    final cases = <NarrativeValidationStatus, int>{
      NarrativeValidationStatus.pass: 0,
      NarrativeValidationStatus.fail: 1,
      NarrativeValidationStatus.indeterminate: 2,
      NarrativeValidationStatus.notRun: 3,
    };

    for (final entry in cases.entries) {
      final input = File(p.join(temporary.path, '${entry.key.name}.json'));
      final output = File(
        p.join(temporary.path, '${entry.key.name}.output.json'),
      );
      await input.writeAsString(
        encodeNarrativeValidationReport(_report(entry.key)),
      );

      final result = await Process.run(
        'dart',
        [
          'run',
          'tool/validate_narrative_project.dart',
          '--report-input',
          input.path,
          '--format',
          'json',
          '--output',
          output.path,
        ],
        workingDirectory: Directory.current.path,
      );

      expect(result.exitCode, entry.value, reason: '${result.stderr}');
      expect(
        decodeNarrativeValidationReport(await output.readAsString())
            .overallStatus,
        entry.key,
      );
    }
  });

  test('usage errors are code 64 and never become a product verdict', () async {
    final result = await Process.run(
      'dart',
      [
        'run',
        'tool/validate_narrative_project.dart',
        '--format',
        'yaml',
      ],
      workingDirectory: Directory.current.path,
    );

    expect(result.exitCode, 64);
    expect('${result.stderr}', contains('Only "--format json"'));
  });
}

NarrativeMultidimensionalValidationReport _report(
  NarrativeValidationStatus status,
) {
  NarrativeValidationDimensionResult dimension(
    NarrativeValidationStatus value,
  ) =>
      NarrativeValidationDimensionResult(status: value);
  return NarrativeMultidimensionalValidationReport(
    validatorVersion: 'narrative-validator-v1',
    profileId: 'selbrume-release-v1',
    profileVersion: 1,
    projectFingerprint: 'sha256:${'e' * 64}',
    generatedAt: DateTime.utc(2026, 7, 20),
    structurallyValid: dimension(status),
    narrativelySolvable: dimension(NarrativeValidationStatus.pass),
    physicallyReachable: dimension(NarrativeValidationStatus.pass),
    runtimeSmokeVerified: dimension(NarrativeValidationStatus.pass),
  );
}
