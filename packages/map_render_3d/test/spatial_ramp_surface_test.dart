import 'package:flame_3d/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_ground.dart';
import 'package:map_render_3d/src/spatial_picking.dart';
import 'package:map_render_3d/src/spatial_terrain_geometry.dart';

void main() {
  test('flat clipped ground stays horizontal across logical and model ramps', () {
    final geometry = resolveSmartTileSpriteGeometry(
      cellX: 1, cellY: 1, destinationCellWidth: 1, destinationCellHeight: 1,
      sourceCellWidth: 32, sourceCellHeight: 32, offsetUnit: SmartTileOffsetUnit.pixel,
      offsetX: 0, offsetY: 0, atlasPixelOffsetX: 0, atlasPixelOffsetY: 0,
      footprintWidth: 2, footprintHeight: 2, anchorX: 0, anchorY: 0,
      transform: const SmartTileSpriteTransform(),
    );
    for (final modelSurface in [false, true]) {
      final scene = surfaceScene(modelSurface: modelSurface);
      final before = scene.toJson();
      final vertices = spatialGroundVertices(geometry, scene: scene, height: .25,
        followTerrain: false, excludedCells: {(2, 2)},
        spatialClip: SmartTileSpatialClip(left: .25, top: 0, right: .75, bottom: 1));
      expect(vertices, isNotEmpty);
      var area = 0.0;
      for (var offset = 0; offset < vertices.length; offset += 4) {
        final quad = vertices.sublist(offset, offset + 4);
        final points = quad.map((vertex) => Vector3(vertex.position.x, vertex.position.y, vertex.position.z)).toList();
        area += List.generate(4, (index) {
          final a = points[index], b = points[(index + 1) % 4];
          return a.x * b.z - b.x * a.z;
        }).reduce((a, b) => a + b).abs() / 2;
        final center = points.reduce((a, b) => a + b) / 4.0;
        expect((center.x.floor(), center.z.floor()), isNot((2, 2)));
        for (final vertex in quad) {
          expect(vertex.position.y, .25);
          expect(vertex.position.x, inInclusiveRange(1.5, 2.5));
          expect(vertex.texCoord.x, closeTo((vertex.position.x - 1) / 2, 1e-6));
          expect(vertex.texCoord.y, closeTo((vertex.position.z - 1) / 2, 1e-6));
        }
      }
      expect(area, closeTo(1.5, 1e-12));
      expect(scene.toJson(), before);
    }
  });
  test(
    'a stair surface removes only its exact fractional terrain footprint',
    () {
      final scene = surfaceScene();
      final tops = spatialTerrainFaces(scene)
          .where((face) => face.isTop)
          .toList();
      expect(
        tops.fold(0.0, (area, face) => area + quadArea(face.positions)),
        closeTo(24 - 2.75 * 1.5, 1e-12),
      );
      for (final face in tops) {
        final center =
            face.positions.reduce((a, b) => a + b) /
            face.positions.length.toDouble();
        expect(
          scene.navigation.ramps.single.contains(center.x, center.z),
          isFalse,
        );
      }
      expect(
        spatialSurfacePatches(scene).where((patch) => patch.ramp != null),
        isNotEmpty,
      );
      expect(
        spatialTerrainFaces(scene).where((face) => !face.isTop),
        isNotEmpty,
      );
    },
  );

  test('painted ground retains UVs and height outside the stair footprint', () {
    final scene = surfaceScene();
    final geometry = resolveSmartTileSpriteGeometry(
      cellX: 0,
      cellY: 0,
      destinationCellWidth: 1,
      destinationCellHeight: 1,
      sourceCellWidth: 32,
      sourceCellHeight: 32,
      offsetUnit: SmartTileOffsetUnit.pixel,
      offsetX: 0,
      offsetY: 0,
      atlasPixelOffsetX: 0,
      atlasPixelOffsetY: 0,
      footprintWidth: 6,
      footprintHeight: 4,
      anchorX: 0,
      anchorY: 0,
      transform: const SmartTileSpriteTransform(),
    );
    final vertices = spatialGroundVertices(
      geometry,
      scene: scene,
      height: .003,
    );
    var area = 0.0;
    for (var i = 0; i < vertices.length; i += 4) {
      final quad = vertices.sublist(i, i + 4);
      final points = quad
          .map((v) => Vector3(v.position.x, v.position.y, v.position.z))
          .toList();
      area += quadArea(points);
      final center = points.reduce((a, b) => a + b) / 4.0;
      expect(
        scene.navigation.ramps.single.contains(center.x, center.z),
        isFalse,
      );
      for (final vertex in quad) {
        expect(vertex.texCoord.x, closeTo(vertex.position.x / 6, 1e-6));
        expect(vertex.texCoord.y, closeTo(vertex.position.z / 4, 1e-6));
      }
      expect(
        quad.map((v) => v.position.y),
        everyElement(
          closeTo(
            scene.heightAt(center.x.floor(), center.z.floor()) + .003,
            1e-6,
          ),
        ),
      );
    }
    expect(area, closeTo(24 - 2.75 * 1.5, 1e-12));
  });

  test('a model surface keeps analytic ramp picking and movement heights', () {
    final scene = surfaceScene();
    final hit = pickSpatialSurface(
      scene,
      Vector3(2.625, 5, 2),
      Vector3(0, -1, 0),
    );
    expect(hit, isNotNull);
    expect(hit!.cell, (2, 2));
    expect(hit.position.y, closeTo(.5, 1e-12));
    expect(scene.worldHeightAt(2.625, 2), closeTo(.5, 1e-12));
  });

  test('an ordinary terrain ramp continues to render its whole surface', () {
    final scene = surfaceScene(modelSurface: false);
    final tops = spatialTerrainFaces(scene).where((face) => face.isTop);
    expect(
      tops.fold(0.0, (area, face) => area + quadArea(face.positions)),
      closeTo(24, 1e-12),
    );
  });
}

double quadArea(List<Vector3> points) =>
    (points[3].x - points[0].x).abs() * (points[1].z - points[0].z).abs();

MapSpatialScene surfaceScene({bool modelSurface = true}) => MapSpatialScene(
  width: 6,
  depth: 4,
  levelHeight: .25,
  heightLevels: List.generate(24, (index) => index % 6 >= 4 ? 4 : 0),
  navigation: SpatialNavigationProfile(
    ramps: [
      SpatialRamp.fromJson({
        'id': 'slope',
        'x': 1.25,
        'z': 1.25,
        'width': 2.75,
        'depth': 1.5,
        'lowLevel': 0,
        'highLevel': 4,
        'direction': 'east',
        if (modelSurface) 'surfaceInstanceId': 'stairs',
      }),
    ],
  ),
  instances: [
    SpatialModelInstance(
      id: 'stairs',
      modelId: 'stair-model',
      position: Model3dVector3(x: 2.625, y: 0, z: 2),
      blocksMovement: false,
    ),
  ],
);
