import 'package:map_core/map_core_domain.dart';

final runtimeSmokeProfileFixture =
    NarrativeRuntimeSmokeProfile.fromJson(runtimeSmokeProfileFixtureJson);

const runtimeSmokeProfileFixtureJson = <String, Object?>{
  'id': 'test-release-v1',
  'version': 1,
  'requiredSuiteIds': ['test-journey', 'test-retry'],
};
