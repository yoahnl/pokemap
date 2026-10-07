import 'dart:ui';
import 'dart:typed_data';
import 'package:map_render_3d/src/spatial_pixel_material.dart';
import 'package:map_render_3d/src/spatial_terrain_geometry.dart';

import 'package:flame_3d/core.dart';
import 'package:flame_3d/resources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_ground.dart';
import 'package:map_render_3d/src/spatial_picking.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart';

MapSpatialScene rampScene() => MapSpatialScene(
  width: 3,
  depth: 4,
  heightLevels: [0, 2, 0, 0, 2, 0, 0, 2, 0, 0, 0, 0],
  navigation: SpatialNavigationProfile(
    ramps: [
      SpatialRamp(
        id: 'ramp',
        x: 1,
        z: 1,
        width: 1,
        depth: 2,
        lowLevel: 0,
        highLevel: 2,
        direction: SpatialRampDirection.north,
      ),
    ],
  ),
);

void main() {
  test('separated fractional ramps only subdivide nearby terrain cells', () {
    final levels = [
      for (var z = 0; z < 64; z++)
        for (var x = 0; x < 64; x++) z % 3 == 0 ? 1 : 0,
    ];
    final ramps = <SpatialRamp>[];
    for (var z = 0; z < 16; z++) {
      for (var x = 0; x < 16; x++) {
        ramps.add(
          SpatialRamp(
            id: 'ramp-$z-$x',
            x: x * 3 + .1 + z * .001,
            z: z * 3 + .1 + x * .001,
            width: .2,
            depth: 1,
            lowLevel: 0,
            highLevel: 1,
            direction: SpatialRampDirection.north,
          ),
        );
      }
    }
    final scene = MapSpatialScene(
      width: 64,
      depth: 64,
      heightLevels: levels,
      navigation: SpatialNavigationProfile(ramps: ramps),
    );
    final patches = spatialSurfacePatches(scene).toList();
    expect(patches.length, lessThanOrEqualTo(64 * 64 + 12 * ramps.length));
    expect(patches.where((patch) => patch.cell == (63, 63)), hasLength(1));
    expect(
      patches.fold<double>(
        0,
        (area, patch) =>
            area + (patch.right - patch.left) * (patch.bottom - patch.top),
      ),
      closeTo(64 * 64, .000001),
    );
    final faces = spatialTerrainFaces(scene).toList();
    expect(faces.length, lessThanOrEqualTo(64 * 64 + 40 * ramps.length));
    for (final patch in patches.where((patch) => patch.ramp != null)) {
      for (final corner in patch.corners) {
        expect(
          corner.y,
          closeTo(patch.ramp!.levelAt(corner.x, corner.z), .00001),
        );
      }
    }
  });

  test('neighbor cliffs clip their edges at fractional ramp boundaries', () {
    final ramp = SpatialRamp(
      id: 'ramp',
      x: 1,
      z: 1.25,
      width: .5,
      depth: 1,
      lowLevel: 0,
      highLevel: 2,
      direction: SpatialRampDirection.north,
    );
    final scene = MapSpatialScene(
      width: 3,
      depth: 4,
      heightLevels: [3, 0, 0, 3, 2, 0, 3, 0, 0, 3, 0, 0],
      navigation: SpatialNavigationProfile(ramps: [ramp]),
    );
    final faces =
        spatialTerrainFaces(
          scene,
          left: 0,
          top: 1.1,
          right: 1,
          bottom: 2.6,
          repeatWalls: false,
        ).where(
          (face) =>
              !face.isTop && face.positions.every((point) => point.x == 1),
        );
    expect(faces, hasLength(4));
    for (final face in faces) {
      final midpoint =
          face.positions.map((point) => point.z).reduce((a, b) => a + b) /
          face.positions.length;
      for (final point in face.positions) {
        if ((point.y - 3).abs() < .000001) continue;
        final expected = ramp.contains(1, midpoint)
            ? ramp.levelAt(1, point.z)
            : scene.heightAt(1, midpoint.floor());
        expect(point.y, closeTo(expected, .000001));
      }
    }
  });

  test('fractional ramp side walls stay exposed at large map coordinates', () {
    final levels = List.filled(132 * 3, 0)..[129] = 2;
    final scene = MapSpatialScene(
      width: 132,
      depth: 3,
      heightLevels: levels,
      navigation: SpatialNavigationProfile(
        ramps: [
          SpatialRamp(
            id: 'ramp',
            x: 129.1,
            z: 1,
            width: .6,
            depth: 1,
            lowLevel: 0,
            highLevel: 2,
            direction: SpatialRampDirection.north,
          ),
        ],
      ),
    );
    final walls =
        spatialTerrainFaces(
          scene,
          left: 129,
          top: 1,
          right: 130,
          bottom: 2,
          repeatWalls: false,
        ).where(
          (face) =>
              !face.isTop &&
              face.positions.every((p) => (p.x - 129.1).abs() < .00001),
        );
    expect(walls, isNotEmpty);
    expect(
      walls.expand((face) => face.positions).map((p) => p.y),
      containsAll([0.0, 2.0]),
    );
  });

  test(
    'picking geometry stays local and does not expand cliff texture levels',
    () {
      final scene = MapSpatialScene(
        width: 256,
        depth: 256,
        heightLevels: [
          for (var z = 0; z < 256; z++)
            for (var x = 0; x < 256; x++) (x + z).isEven ? 32 : 0,
        ],
      );
      final faces =
          Function.apply(
                spatialTerrainFaces,
                [scene],
                {
                  #left: 127.0,
                  #top: 127.0,
                  #right: 128.0,
                  #bottom: 128.0,
                  #repeatWalls: false,
                },
              )
              as Iterable<SpatialTerrainFace>;
      expect(faces.toList(), hasLength(5));
      expect(
        pickSpatialCell(scene, Vector3(127.5, 100, 127.5), Vector3(0, -1, 0)),
        (127, 127),
      );
    },
  );

  test('exposed cliffs repeat the texture once per terrain level', () {
    final scene = MapSpatialScene(width: 1, depth: 1, heightLevels: [3]);
    final texture = Texture(ByteData(32 * 32 * 4), width: 32, height: 32);
    final meshes =
        Function.apply(
              terrainMeshes,
              [scene, const Color(0xffeeeeee), const Color(0xffaaaaaa)],
              {
                #cliffTexture: (
                  texture: texture,
                  sourceRect: const SmartTileSourceRect(
                    x: 0,
                    y: 0,
                    width: 32,
                    height: 32,
                  ),
                ),
              },
            )
            as Iterable<Mesh>;
    final walls = meshes
        .expand((mesh) => mesh.surfaces)
        .where((surface) => surface.material is SpatialPixelMaterial)
        .toList();
    expect(walls, hasLength(1));
    expect(walls.single.vertexCount, 4 * 4 * 4);
    expect(
      spatialTerrainFaces(scene)
          .where((face) => !face.isTop)
          .expand((face) => face.uvs)
          .every((uv) => uv.x >= 0 && uv.x <= 1 && uv.y >= 0 && uv.y <= 1),
      isTrue,
    );
    final ys = <double>{
      for (var i = 1; i < walls.single.positions.length; i += 3)
        walls.single.positions[i],
    };
    expect(ys, containsAll([0, 1, 2, 3]));
  });

  test('fractional ramps preserve full block cliff UV coordinates', () {
    final scene = MapSpatialScene(
      width: 3,
      depth: 3,
      heightLevels: [2, 2, 2, 2, 2, 2, 0, 0, 0],
      navigation: SpatialNavigationProfile(
        ramps: [
          SpatialRamp(
            id: 'fractional',
            x: 1.25,
            z: 1,
            width: .5,
            depth: 1,
            lowLevel: 0,
            highLevel: 2,
            direction: SpatialRampDirection.north,
          ),
        ],
      ),
    );
    final back = spatialTerrainFaces(scene).where(
      (face) => !face.isTop && face.positions.every((point) => point.z == 0),
    );
    for (final face in back) {
      for (var i = 0; i < face.positions.length; i++) {
        expect(
          face.uvs[i].x,
          closeTo(face.cell.$1 + 1 - face.positions[i].x, .000001),
        );
      }
    }
  });
  test('terrain ramp replaces block tops with its affine surface', () {
    final scene = rampScene();
    final surfaces = terrainMeshes(
      scene,
      const Color(0xffeeeeee),
      const Color(0xffaaaaaa),
    ).expand((mesh) => mesh.surfaces);
    final heights = <double>[];
    for (final surface in surfaces) {
      for (var i = 0; i < surface.positions.length; i += 3) {
        final x = surface.positions[i],
            y = surface.positions[i + 1],
            z = surface.positions[i + 2];
        if (x == 1 && z == 2 && y > 0) heights.add(y);
      }
    }
    expect(heights, isNotEmpty);
    expect(heights.every((height) => (height - 1).abs() < .00001), isTrue);
  });

  test('ramp picking hits the slope rather than its backing terrain block', () {
    final scene = rampScene();
    expect(
      pickSpatialCell(scene, Vector3(1.5, 1.8, 2.5), Vector3(0, -.2, -1)),
      (1, 1),
    );
  });

  test(
    'ground clips transformed quads on abrupt terrain with continuous UVs',
    () {
      final scene = MapSpatialScene(
        width: 3,
        depth: 3,
        heightLevels: [0, 3, 0, 0, 3, 0, 0, 3, 0],
      );
      for (final transform in smartTileD4Transforms) {
        final geometry = resolveSmartTileSpriteGeometry(
          cellX: 0,
          cellY: 0,
          destinationCellWidth: 1,
          destinationCellHeight: 1,
          sourceCellWidth: 32,
          sourceCellHeight: 32,
          offsetUnit: SmartTileOffsetUnit.pixel,
          offsetX: 16,
          offsetY: 16,
          atlasPixelOffsetX: 0,
          atlasPixelOffsetY: 0,
          footprintWidth: 2,
          footprintHeight: 2,
          anchorX: 0,
          anchorY: 0,
          transform: transform,
        );
        final vertices =
            Function.apply(
                  spatialGroundVertices,
                  [geometry],
                  {#scene: scene, #height: .003},
                )
                as List<Vertex>;
        expect(vertices.length, greaterThan(4));
        for (final corner in spatialGroundVertices(geometry)) {
          final clipped = vertices
              .where(
                (v) =>
                    (v.position.x - corner.position.x).abs() < .000001 &&
                    (v.position.z - corner.position.z).abs() < .000001,
              )
              .first;
          expect(clipped.texCoord.x, closeTo(corner.texCoord.x, .000001));
          expect(clipped.texCoord.y, closeTo(corner.texCoord.y, .000001));
        }
        for (var i = 0; i < vertices.length; i += 4) {
          final quad = vertices.sublist(i, i + 4);
          final x = quad.map((v) => v.position.x).reduce((a, b) => a + b) / 4;
          final z = quad.map((v) => v.position.z).reduce((a, b) => a + b) / 4;
          final expected = scene.heightAt(x.floor(), z.floor()) + .003;
          expect(
            quad.every((v) => (v.position.y - expected).abs() < .00001),
            isTrue,
          );
          expect(
            quad.every(
              (v) =>
                  v.texCoord.x >= 0 &&
                  v.texCoord.x <= 1 &&
                  v.texCoord.y >= 0 &&
                  v.texCoord.y <= 1,
            ),
            isTrue,
          );
        }
      }
    },
  );
}
