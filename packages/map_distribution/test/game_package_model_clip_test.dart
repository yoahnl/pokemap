import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import 'support/spatial_package_fixture.dart';

void main() {
  test('clipped static instances require and preserve their host capability',
      () {
    final files = spatialPayload();
    final map = MapData.fromJson(
        jsonDecode(utf8.decode(files['project/maps/map.json']!))
            as Map<String, dynamic>);
    final instance = map.spatialScene!.instances.single.copyWith(
      blocksMovement: false,
      clip: SpatialModelClip(left: 0, top: 0, right: .5, bottom: 1),
    );
    files['project/maps/map.json'] = utf8.encode(jsonEncode(map
        .copyWith(
          spatialScene: map.spatialScene!.copyWith(instances: [instance]),
        )
        .toJson()));
    expect(
        () => const GamePackageBuilder()
            .build(manifest: spatialManifest(), payloadFiles: files),
        throwsA(isA<GamePackageFormatException>().having(
            (error) => error.message,
            'message',
            contains('map3d.model-clip@1'))));
    final built = const GamePackageBuilder().build(
        manifest:
            spatialManifest(capabilities: ['map3d@1', 'map3d.model-clip@1']),
        payloadFiles: files);
    expect(
        const GamePackageInspector()
            .inspect(built.packageBytes)
            .manifest
            .compatibility
            .requiredCapabilities,
        contains('map3d.model-clip@1'));
    final host = GamePackageHostCompatibility(
        hubVersion: Version.parse('1.2.0'),
        runtimeApiVersion: Version.parse('1.4.0'),
        capabilities: const {'map3d@1'},
        supportedProjectFormats: const {'v9'},
        currentProjectFormat: 'v9',
        supportedSaveFormats: const {1});
    expect(
        () => GamePackageInspector(hostCompatibility: host)
            .inspect(built.packageBytes),
        throwsA(isA<GamePackageFormatException>()
            .having((error) => error.code, 'code', 'capabilityUnsupported')));
  });
}
