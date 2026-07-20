import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('builds a release receipt only after every required suite ran', () {
    final receipt = buildNarrativeRuntimeSmokeEvidence(
      projectFingerprint: 'sha256:${'f' * 64}',
      validatorVersion: 'narrative-validator-v1',
      profile: selbrumeReleaseV1Profile,
      executedSuiteIds: selbrumeReleaseV1Profile.requiredSuiteIds,
      fixtureId: 'selbrume',
      passed: true,
      completedAt: DateTime.utc(2026, 7, 20),
    );
    expect(receipt.result, NarrativeRuntimeSmokeResult.pass);
    expect(receipt.profileId, 'selbrume-release-v1');
  });

  test('refuses to promote a trivial or partial fixture', () {
    expect(
      () => buildNarrativeRuntimeSmokeEvidence(
        projectFingerprint: 'sha256:${'f' * 64}',
        validatorVersion: 'v1',
        profile: selbrumeReleaseV1Profile,
        executedSuiteIds: const ['selbrume-lighthouse-retry'],
        fixtureId: 'tiny',
        passed: true,
        completedAt: DateTime.utc(2026),
      ),
      throwsStateError,
    );
  });
}
