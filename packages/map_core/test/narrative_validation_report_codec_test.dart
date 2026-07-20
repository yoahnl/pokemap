import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('encodes a stable canonical report and keeps verdicts distinct', () {
    final report = _report(NarrativeValidationStatus.indeterminate);

    final first = encodeNarrativeValidationReport(report);
    final second = encodeNarrativeValidationReport(
      decodeNarrativeValidationReport(first),
    );

    expect(second, first);
    expect(
      decodeNarrativeValidationReport(first).overallStatus,
      NarrativeValidationStatus.indeterminate,
    );
    expect(first, contains('"schemaVersion":1'));
  });

  test('diagnostic fingerprint is stable and content-sensitive', () {
    final diagnostic = NarrativeMultidimensionalDiagnostic(
      id: 'event:evt_port',
      code: 'sourceMissing',
      severity: 'warning',
      message: 'Source absente.',
      path: 'events.evt_port.source',
      provenance: const ['map:port', 'entity:rival'],
    );

    expect(
      narrativeValidationDiagnosticFingerprint(diagnostic),
      narrativeValidationDiagnosticFingerprint(
        NarrativeMultidimensionalDiagnostic.fromJson(diagnostic.toJson()),
      ),
    );
    expect(
      narrativeValidationDiagnosticFingerprint(diagnostic),
      isNot(
        narrativeValidationDiagnosticFingerprint(
          NarrativeMultidimensionalDiagnostic(
            id: diagnostic.id,
            code: diagnostic.code,
            severity: diagnostic.severity,
            message: 'Source corrigée.',
            path: diagnostic.path,
            provenance: diagnostic.provenance,
          ),
        ),
      ),
    );
  });

  test('maps all product statuses to their documented CI exit codes', () {
    expect(narrativeValidationExitCode(NarrativeValidationStatus.pass), 0);
    expect(narrativeValidationExitCode(NarrativeValidationStatus.fail), 1);
    expect(
      narrativeValidationExitCode(NarrativeValidationStatus.indeterminate),
      2,
    );
    expect(narrativeValidationExitCode(NarrativeValidationStatus.notRun), 3);
  });

  test('unknown status is rejected instead of degrading to pass', () {
    final encoded = encodeNarrativeValidationReport(
      _report(NarrativeValidationStatus.pass),
    ).replaceFirst('"status":"pass"', '"status":"unknown"');

    expect(
      () => decodeNarrativeValidationReport(encoded),
      throwsFormatException,
    );
  });
}

NarrativeMultidimensionalValidationReport _report(
  NarrativeValidationStatus narrativeStatus,
) {
  NarrativeValidationDimensionResult dimension(
    NarrativeValidationStatus status,
  ) =>
      NarrativeValidationDimensionResult(status: status);
  return NarrativeMultidimensionalValidationReport(
    validatorVersion: 'narrative-validator-v1',
    profileId: 'selbrume-release-v1',
    profileVersion: 1,
    projectFingerprint: 'sha256:${'d' * 64}',
    generatedAt: DateTime.utc(2026, 7, 20),
    structurallyValid: dimension(NarrativeValidationStatus.pass),
    narrativelySolvable: dimension(narrativeStatus),
    physicallyReachable: dimension(NarrativeValidationStatus.pass),
    runtimeSmokeVerified: dimension(NarrativeValidationStatus.pass),
  );
}
