import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'spatial_terrain_surface_test.dart' show sceneJson, surfaceJson;

void main() {
  test('a slope with closed flanks keeps the flag through JSON and copies', () {
    final json = surfaceJson()..['closedFlanks'] = true;
    final scene = MapSpatialScene.fromJson(sceneJson([json]));
    final surface = scene.terrainSurfaces.surfaces.single;
    expect(surface.closedFlanks, isTrue);
    expect(surface.toJson()['closedFlanks'], isTrue);
    expect(surface.copyWith(height: 3).closedFlanks, isTrue);
    expect(surface.copyWith(closedFlanks: false).closedFlanks, isFalse);
    final encoded =
        jsonDecode(jsonEncode(scene.toJson())) as Map<String, dynamic>;
    expect(MapSpatialScene.fromJson(encoded), scene);
  });

  test('surfaces without the flag keep their exact legacy JSON', () {
    final legacy = surfaceJson();
    final surface = SpatialTerrainSurface.fromJson(legacy);
    expect(surface.closedFlanks, isFalse);
    expect(surface.toJson(), legacy);
    expect(surface.toJson().containsKey('closedFlanks'), isFalse);
  });

  test('the flag distinguishes surfaces and must be a boolean', () {
    final open = SpatialTerrainSurface.fromJson(surfaceJson());
    final closed = open.copyWith(closedFlanks: true);
    expect(closed, isNot(open));
    expect(closed.hashCode, isNot(open.hashCode));
    expect(
      () => SpatialTerrainSurface.fromJson(
        surfaceJson()..['closedFlanks'] = 'yes',
      ),
      throwsFormatException,
    );
  });
}
