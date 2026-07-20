import 'package:map_core/map_core.dart';

NarrativeRuntimeSmokeReceipt buildNarrativeRuntimeSmokeEvidence({
  required String projectFingerprint,
  required String validatorVersion,
  required NarrativeRuntimeSmokeProfile profile,
  required List<String> executedSuiteIds,
  required String fixtureId,
  required bool passed,
  required DateTime completedAt,
  List<String> limitations = const <String>[],
}) {
  if (!profile.acceptsSuites(executedSuiteIds)) {
    final missing = profile.requiredSuiteIds
        .where((suiteId) => !executedSuiteIds.contains(suiteId))
        .join(', ');
    throw StateError(
      'Runtime smoke profile ${profile.id} is incomplete. Missing: $missing',
    );
  }
  final normalizedFixtureId = fixtureId.trim();
  if (normalizedFixtureId.isEmpty) {
    throw ArgumentError.value(fixtureId, 'fixtureId', 'must not be empty');
  }
  return NarrativeRuntimeSmokeReceipt(
    projectFingerprint: projectFingerprint,
    validatorVersion: validatorVersion,
    profileId: profile.id,
    profileVersion: profile.version,
    suiteIds: executedSuiteIds,
    fixtureId: normalizedFixtureId,
    result: passed
        ? NarrativeRuntimeSmokeResult.pass
        : NarrativeRuntimeSmokeResult.fail,
    completedAt: completedAt,
    limitations: limitations,
  );
}
