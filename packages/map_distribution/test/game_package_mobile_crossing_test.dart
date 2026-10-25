import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';
import 'support/spatial_package_fixture.dart';
import 'support/cinematic_mobile_crossing_fixture.dart';


void main() {
  for (final enabled in [false, true]) {
    test('crossing package requires explicit capability=$enabled', () {
      GamePackageBuildResult operation() => const GamePackageBuilder().build(
          manifest: spatialManifest(capabilities: [
            'map3d@1', 'map3d.gameplay@1', 'map3d.story@1',
            if (enabled) CinematicAsset.mobileActorCrossingCapabilityId
          ]),
          payloadFiles: mobileCrossingPayload());
      if (enabled) {
        expect(operation, returnsNormally);
      } else {
        expect(operation, throwsA(isA<GamePackageFormatException>()));
      }
    });
  }
  test('a reader without crossing capability rejects the package', () {
    final current = AveluneRuntimeCompatibility.host();
    final older = GamePackageHostCompatibility(hubVersion: current.hubVersion, runtimeApiVersion: current.runtimeApiVersion, supportedRuntimeApiVersions: current.supportedRuntimeApiVersions, capabilities: {...current.capabilities}..remove(CinematicAsset.mobileActorCrossingCapabilityId), supportedProjectFormats: current.supportedProjectFormats, currentProjectFormat: current.currentProjectFormat, currentProjectFormats: current.currentProjectFormats, supportedSaveFormats: current.supportedSaveFormats);
    final result = const GamePackageCompatibilityEvaluator().evaluate(spatialManifest(capabilities: ['map3d@1', CinematicAsset.mobileActorCrossingCapabilityId]), older);
    expect(result.decision, GamePackageCompatibilityDecision.reject);
    expect(result.missingCapabilities, contains(CinematicAsset.mobileActorCrossingCapabilityId));
  });

  test('current runtime declares mobile crossing capability', () {
    expect(AveluneRuntimeCompatibility.host().capabilities,
        contains(CinematicAsset.mobileActorCrossingCapabilityId));
  });
}
