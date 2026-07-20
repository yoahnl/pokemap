import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('round-trips a versioned release receipt', () {
    final receipt = NarrativeRuntimeSmokeReceipt(
      projectFingerprint: 'sha256:${'c' * 64}',
      validatorVersion: 'narrative-validator-v1',
      profileId: selbrumeReleaseV1Profile.id,
      profileVersion: selbrumeReleaseV1Profile.version,
      suiteIds: selbrumeReleaseV1Profile.requiredSuiteIds.reversed.toList(),
      fixtureId: 'selbrume',
      result: NarrativeRuntimeSmokeResult.pass,
      completedAt: DateTime.parse('2026-07-20T10:00:00+02:00'),
    );

    final decoded = NarrativeRuntimeSmokeReceipt.fromJson(receipt.toJson());
    expect(decoded.suiteIds, selbrumeReleaseV1Profile.requiredSuiteIds);
    expect(decoded.completedAt.isUtc, isTrue);
    expect(selbrumeReleaseV1Profile.acceptsSuites(decoded.suiteIds), isTrue);
  });

  test('release profile refuses a partial suite', () {
    expect(
        selbrumeReleaseV1Profile.acceptsSuites(['selbrume-lighthouse-retry']),
        isFalse);
  });
}
