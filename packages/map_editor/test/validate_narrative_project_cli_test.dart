import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

void main() {
  final dartExecutable = p.join(
    Platform.environment['FLUTTER_ROOT']!,
    'bin',
    'cache',
    'dart-sdk',
    'bin',
    'dart',
  );
  test(
    'project CLI has no default policy and serializes nullable profile metadata',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'unconfigured-runtime-',
      );
      addTearDown(() => root.delete(recursive: true));
      await File('${root.path}/project.json').writeAsString(
        jsonEncode(
          const ProjectManifest(
            name: 'No policy',
            maps: [],
            tilesets: [],
          ).toJson(),
        ),
      );
      final result = await Process.run(dartExecutable, [
        'tool/validate_narrative_project.dart',
        '--project-root',
        root.path,
        '--format',
        'json',
      ], workingDirectory: Directory.current.path);
      expect(result.exitCode, isNot(64), reason: '${result.stderr}');
      final report = decodeNarrativeValidationReport(result.stdout as String);
      expect(report.profileId, isNull);
      expect(report.profileVersion, isNull);
      expect(
        report.runtimeSmokeVerified.status,
        NarrativeValidationStatus.notRun,
      );
      expect(
        report.runtimeSmokeVerified.limitations.join(' '),
        contains('Aucun profil'),
      );
    },
  );

  test(
    'process preserves pass, fail, indeterminate and notRun exit codes',
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

        final result = await Process.run(dartExecutable, [
          'tool/validate_narrative_project.dart',
          '--report-input',
          input.path,
          '--format',
          'json',
          '--output',
          output.path,
        ], workingDirectory: Directory.current.path);

        expect(result.exitCode, entry.value, reason: '${result.stderr}');
        expect(
          decodeNarrativeValidationReport(
            await output.readAsString(),
          ).overallStatus,
          entry.key,
        );
      }
    },
  );

  test('usage errors are code 64 and never become a product verdict', () async {
    final result = await Process.run(dartExecutable, [
      'tool/validate_narrative_project.dart',
      '--format',
      'yaml',
    ], workingDirectory: Directory.current.path);

    expect(result.exitCode, 64);
    expect('${result.stderr}', contains('Only "--format json"'));
  });
}

NarrativeMultidimensionalValidationReport _report(
  NarrativeValidationStatus status,
) {
  NarrativeValidationDimensionResult dimension(
    NarrativeValidationStatus value,
  ) => NarrativeValidationDimensionResult(status: value);
  return NarrativeMultidimensionalValidationReport(
    validatorVersion: 'narrative-validator-v1',
    profileId: 'cli-fixture-v1',
    profileVersion: 1,
    projectFingerprint: 'sha256:${'e' * 64}',
    generatedAt: DateTime.utc(2026, 7, 20),
    structurallyValid: dimension(status),
    narrativelySolvable: dimension(NarrativeValidationStatus.pass),
    physicallyReachable: dimension(NarrativeValidationStatus.pass),
    runtimeSmokeVerified: dimension(NarrativeValidationStatus.pass),
  );
}
