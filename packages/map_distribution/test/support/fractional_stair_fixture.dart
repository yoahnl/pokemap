import 'dart:convert';

import 'package:map_core/map_core.dart';

import 'spatial_package_fixture.dart';

Map<String, List<int>> fractionalStairPayload({double highLevel = 1.5}) {
  final files = spatialPayload();
  final map = MapData.fromJson(
      jsonDecode(utf8.decode(files['project/maps/map.json']!))
          as Map<String, dynamic>);
  final surface = SpatialTerrainSurface(
    id: 'upper',
    x: 1,
    z: 1,
    height: highLevel,
    footprints: [
      BorderGroundFootprint(points: [
        BorderGroundPoint(x: 0, z: 0),
        BorderGroundPoint(x: 4, z: 0),
        BorderGroundPoint(x: 4, z: 1),
        BorderGroundPoint(x: 0, z: 1),
      ])
    ],
  );
  final ramp = SpatialRamp.fromJson({
    'id': 'stairs',
    'x': 2,
    'z': 2,
    'width': 1,
    'depth': 2,
    'lowLevel': 0,
    'highLevel': highLevel,
    'direction': 'north',
  });
  final scene = map.spatialScene!.copyWith(
    terrainSurfaces: SpatialTerrainSurfaceSet(surfaces: [surface]),
    navigation: map.spatialScene!.navigation.copyWith(ramps: [ramp]),
  );
  files['project/maps/map.json'] =
      utf8.encode(jsonEncode(map.copyWith(spatialScene: scene).toJson()));
  return files;
}
