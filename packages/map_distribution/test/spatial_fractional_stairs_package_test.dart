import 'package:map_distribution/map_distribution.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import 'support/fractional_stair_fixture.dart';
import 'support/spatial_package_fixture.dart';

void main() {
  test('fractional ramps require their own capability before package delivery',
      () {
    final files = fractionalStairPayload();
    expect(
        () => const GamePackageBuilder().build(
              manifest: spatialManifest(
                  capabilities: ['map3d@1', 'map3d.terrain-surfaces@1']),
              payloadFiles: files,
            ),
        throwsA(isA<GamePackageFormatException>().having(
            (error) => error.message,
            'message',
            contains('map3d.fractional-ramps@1'))));
    final built = const GamePackageBuilder().build(
      manifest: spatialManifest(capabilities: [
        'map3d@1',
        'map3d.terrain-surfaces@1',
        'map3d.fractional-ramps@1'
      ]),
      payloadFiles: files,
    );
    final inspected = const GamePackageInspector().inspect(built.packageBytes);
    expect(inspected.manifest.compatibility.requiredCapabilities,
        contains('map3d.fractional-ramps@1'));
    final olderHost = GamePackageHostCompatibility(
      hubVersion: Version.parse('1.2.0'),
      runtimeApiVersion: Version.parse('1.4.0'),
      capabilities: const {'map3d@1', 'map3d.terrain-surfaces@1'},
      supportedProjectFormats: const {'v9'},
      currentProjectFormat: 'v9',
      supportedSaveFormats: const {1},
    );
    expect(
        () => GamePackageInspector(hostCompatibility: olderHost)
            .inspect(built.packageBytes),
        throwsA(isA<GamePackageFormatException>()
            .having((error) => error.code, 'code', 'capabilityUnsupported')));
  });

  test('integral ramp endpoints do not require the fractional capability', () {
    final built = const GamePackageBuilder().build(
      manifest: spatialManifest(
          capabilities: ['map3d@1', 'map3d.terrain-surfaces@1']),
      payloadFiles: fractionalStairPayload(highLevel: 2),
    );
    expect(
        const GamePackageInspector()
            .inspect(built.packageBytes)
            .manifest
            .compatibility
            .requiredCapabilities,
        isNot(contains('map3d.fractional-ramps@1')));
  });
}
