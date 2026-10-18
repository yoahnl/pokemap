import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/runtime_smoke_profile_fixture.dart';

void main() {
  test('round-trips a versioned release receipt', () {
    final receipt = NarrativeRuntimeSmokeReceipt(
      projectFingerprint: 'sha256:${'c' * 64}',
      validatorVersion: 'narrative-validator-v1',
      profileId: runtimeSmokeProfileFixture.id,
      profileVersion: runtimeSmokeProfileFixture.version,
      suiteIds: runtimeSmokeProfileFixture.requiredSuiteIds.reversed.toList(),
      fixtureId: 'selbrume',
      result: NarrativeRuntimeSmokeResult.pass,
      completedAt: DateTime.parse('2026-07-20T10:00:00+02:00'),
    );

    final decoded = NarrativeRuntimeSmokeReceipt.fromJson(receipt.toJson());
    expect(decoded.suiteIds, runtimeSmokeProfileFixture.requiredSuiteIds);
    expect(decoded.completedAt.isUtc, isTrue);
    expect(runtimeSmokeProfileFixture.acceptsSuites(decoded.suiteIds), isTrue);
  });

  test('release profile refuses a partial suite', () {
    expect(
        runtimeSmokeProfileFixture.acceptsSuites(['test-retry']),
        isFalse);
  });
}
