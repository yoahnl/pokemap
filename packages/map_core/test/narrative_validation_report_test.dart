import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('round-trips four independent statuses and requires four passes', () {
    NarrativeValidationDimensionResult dimension(
            NarrativeValidationStatus status) =>
        NarrativeValidationDimensionResult(status: status);
    final report = NarrativeMultidimensionalValidationReport(
      validatorVersion: 'narrative-validator-v1',
      profileId: 'selbrume-release-v1',
      profileVersion: 1,
      projectFingerprint: 'sha256:${'a' * 64}',
      generatedAt: DateTime.utc(2026, 7, 20),
      structurallyValid: dimension(NarrativeValidationStatus.pass),
      narrativelySolvable: dimension(NarrativeValidationStatus.pass),
      physicallyReachable: dimension(NarrativeValidationStatus.pass),
      runtimeSmokeVerified: dimension(NarrativeValidationStatus.notRun),
    );

    final decoded =
        NarrativeMultidimensionalValidationReport.fromJson(report.toJson());
    expect(
        decoded.runtimeSmokeVerified.status, NarrativeValidationStatus.notRun);
    expect(decoded.overallStatus, NarrativeValidationStatus.notRun);
    expect(decoded.isPlayable, isFalse);
  });

  test('fail dominates indeterminate and notRun', () {
    final pass = NarrativeValidationDimensionResult(
        status: NarrativeValidationStatus.pass);
    final report = NarrativeMultidimensionalValidationReport(
      validatorVersion: 'v1',
      profileId: 'profile',
      profileVersion: 1,
      projectFingerprint: 'sha256:${'b' * 64}',
      generatedAt: DateTime.utc(2026),
      structurallyValid: NarrativeValidationDimensionResult(
          status: NarrativeValidationStatus.fail),
      narrativelySolvable: NarrativeValidationDimensionResult(
          status: NarrativeValidationStatus.indeterminate),
      physicallyReachable: pass,
      runtimeSmokeVerified: NarrativeValidationDimensionResult(
          status: NarrativeValidationStatus.notRun),
    );
    expect(report.overallStatus, NarrativeValidationStatus.fail);
  });
}
