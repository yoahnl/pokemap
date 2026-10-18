import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'support/runtime_smoke_profile_fixture.dart';

void main() {
  test('builds a release receipt only after every required suite ran', () {
    final receipt = buildNarrativeRuntimeSmokeEvidence(
      projectFingerprint: 'sha256:${'f' * 64}',
      validatorVersion: 'narrative-validator-v1',
      profile: runtimeSmokeProfileFixture,
      executedSuiteIds: runtimeSmokeProfileFixture.requiredSuiteIds,
      fixtureId: 'selbrume',
      passed: true,
      completedAt: DateTime.utc(2026, 7, 20),
    );
    expect(receipt.result, NarrativeRuntimeSmokeResult.pass);
    expect(receipt.profileId, 'test-release-v1');
  });

  test('refuses to promote a trivial or partial fixture', () {
    expect(
      () => buildNarrativeRuntimeSmokeEvidence(
        projectFingerprint: 'sha256:${'f' * 64}',
        validatorVersion: 'v1',
        profile: runtimeSmokeProfileFixture,
        executedSuiteIds: const ['test-retry'],
        fixtureId: 'tiny',
        passed: true,
        completedAt: DateTime.utc(2026),
      ),
      throwsStateError,
    );
  });
}
