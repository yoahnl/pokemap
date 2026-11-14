import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import 'support/spatial_package_fixture.dart';

Map<String, List<int>> _closedSlopePayload() {
  final files = spatialPayload();
  final map = MapData.fromJson(
      jsonDecode(utf8.decode(files['project/maps/map.json']!))
          as Map<String, dynamic>);
  final slope = SpatialTerrainSurface(
    id: 'slope',
    x: 1,
    z: 1,
    height: 2,
    gradientZ: -.5,
    closedFlanks: true,
    footprints: [
      BorderGroundFootprint(points: [
        BorderGroundPoint(x: 0, z: 0),
        BorderGroundPoint(x: 1, z: 0),
        BorderGroundPoint(x: 1, z: 2),
        BorderGroundPoint(x: 0, z: 2),
      ])
    ],
  );
  files['project/maps/map.json'] = utf8.encode(jsonEncode(map
      .copyWith(
          spatialScene: map.spatialScene!.copyWith(
              terrainSurfaces: SpatialTerrainSurfaceSet(surfaces: [slope])))
      .toJson()));
  return files;
}

void main() {
  test('slopes with closed flanks require their capability', () {
    expect(
        () => const GamePackageBuilder().build(
              manifest: spatialManifest(
                  capabilities: ['map3d@1', 'map3d.terrain-surfaces@1']),
              payloadFiles: _closedSlopePayload(),
            ),
        throwsA(isA<GamePackageFormatException>().having(
            (error) => error.message,
            'message',
            contains('map3d.closed-slope-flanks@1'))));
    final built = const GamePackageBuilder().build(
      manifest: spatialManifest(capabilities: [
        'map3d@1',
        'map3d.terrain-surfaces@1',
        'map3d.closed-slope-flanks@1',
      ]),
      payloadFiles: _closedSlopePayload(),
    );
    expect(
        const GamePackageInspector()
            .inspect(built.packageBytes)
            .manifest
            .compatibility
            .requiredCapabilities,
        contains('map3d.closed-slope-flanks@1'));
    expect(AveluneRuntimeCompatibility.host().capabilities,
        contains('map3d.closed-slope-flanks@1'));
  });
}
