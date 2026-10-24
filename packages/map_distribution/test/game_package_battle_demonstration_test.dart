import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';
import 'support/battle_demonstration_fixture.dart';
import 'support/spatial_package_fixture.dart';

void main() {
  for (final enabled in [false, true]) {
    test('demonstration packages require their explicit capability: $enabled',
        () {
      GamePackageBuildResult operation() => const GamePackageBuilder().build(
          manifest: spatialManifest(capabilities: [
            'map3d@1',
            'map3d.gameplay@1',
            'map3d.story@1',
            if (enabled) SceneBattleDemonstration.capabilityId
          ]),
          payloadFiles: battleDemonstrationPayload());
      if (enabled) {
        expect(operation, returnsNormally);
      } else {
        expect(operation, throwsA(isA<GamePackageFormatException>()));
      }
    });
  }
}
