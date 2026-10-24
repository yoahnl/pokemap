import 'dart:convert';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'support/spatial_package_fixture.dart';

void main() {
  test('directional jumps fail closed without capability and on older players',
      () {
    final payload = spatialPayload();
    final map = MapData.fromJson(
        jsonDecode(utf8.decode(payload['project/maps/map.json']!))
            as Map<String, dynamic>);
    payload['project/maps/map.json'] = utf8.encode(jsonEncode(map
        .copyWith(
            spatialScene: map.spatialScene!.copyWith(
                navigation: map.spatialScene!.navigation.copyWith(ledges: [
          SpatialLedge(
              id: 'drop', x: 4, z: 2, direction: SpatialRampDirection.south)
        ])))
        .toJson()));
    expect(
        () => const GamePackageBuilder().build(
            manifest: spatialManifest(capabilities: ['map3d@1']),
            payloadFiles: payload),
        throwsA(isA<GamePackageFormatException>().having(
            (error) => error.message,
            'message',
            contains(SpatialLedge.capabilityId))));
    final built = const GamePackageBuilder().build(
        manifest: spatialManifest(
            capabilities: ['map3d@1', SpatialLedge.capabilityId]),
        payloadFiles: payload);
    expect(
        const GamePackageInspector()
            .inspect(built.packageBytes)
            .manifest
            .compatibility
            .requiredCapabilities,
        contains(SpatialLedge.capabilityId));
    final older = GamePackageHostCompatibility(
        hubVersion: Version.parse('1.2.0'),
        runtimeApiVersion: Version.parse('1.4.0'),
        capabilities: const {'map3d@1'},
        supportedProjectFormats: const {'v9'},
        currentProjectFormat: 'v9',
        supportedSaveFormats: const {1});
    expect(
        () => GamePackageInspector(hostCompatibility: older)
            .inspect(built.packageBytes),
        throwsA(isA<GamePackageFormatException>()
            .having((error) => error.code, 'code', 'capabilityUnsupported')));
  });
}
