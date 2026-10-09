import 'dart:ui';
import 'dart:typed_data';

import 'package:flame_3d/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_picking.dart';
import 'package:map_render_3d/src/adaptive_camera.dart';
import 'package:flame_3d/resources.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart';
import 'package:map_render_3d/src/spatial_cell_overlay.dart';

void main() {
  test(
    'collision and marker overlays follow relief and partition large meshes',
    () {
      final scene = MapSpatialScene(
        width: 80,
        depth: 80,
        heightLevels: List.filled(6400, 2),
      );
      final meshes = spatialCellOverlayMeshes(scene, [
        for (var i = 0; i < 6400; i++)
          SpatialCellOverlay(
            id: '$i',
            cell: (i % 80, i ~/ 80),
            kind: SpatialCellOverlayKind.collision,
            color: const Color(0xffff0000),
          ),
      ]).toList();
      expect(meshes.length, greaterThan(1));
      var vertices = 0;
      for (final mesh in meshes) {
        for (final surface in mesh.surfaces) {
          vertices += surface.vertexCount;
          expect(
            surface.indices.every(
              (index) => index < surface.vertexCount && index < 65536,
            ),
            isTrue,
          );
          expect(
            [
              for (var i = 1; i < surface.positions.length; i += 3)
                surface.positions[i],
            ].every(
              (height) =>
                  (height - (scene.heightAt(0, 0) + .035)).abs() < .00001,
            ),
            isTrue,
          );
        }
      }
      expect(vertices, 6400 * 16);
    },
  );
  test('elevated plateau preserves the camera distance and inclination', () {
    final camera = AdaptiveCamera3D();
    final center = Vector3(6, 512, 5);
    camera.frame(center, pitch: .5, yaw: .3, distance: 42);
    expect((camera.position - camera.target).length, closeTo(42, .0001));
    expect(camera.position.y, greaterThan(512));
    expect(camera.target, center);
  });
  test('far camera keeps its target within clip space at maximum distance', () {
    final camera = AdaptiveCamera3D(fovY: 40)..sceneRadius = 256;
    camera.onGameResize(Vector2(800, 600));
    camera.position.setValues(0, 6000, 8000);
    camera.target.setZero();
    final clip = camera.viewProjectionMatrix.transform(Vector4(0, 0, 0, 1));
    expect(clip.z / clip.w, inInclusiveRange(-1, 1));
  });
  test(
    'painted ground depth is distinct and close scene content stays visible',
    () {
      final camera = AdaptiveCamera3D(fovY: 40)..sceneRadius = 20;
      camera.onGameResize(Vector2(800, 600));
      camera.frame(Vector3.zero(), pitch: .7, yaw: 0, distance: 40);
      double depth(Vector3 point) {
        final clip = camera.viewProjectionMatrix.transform(
          Vector4(point.x, point.y, point.z, 1),
        );
        return (clip.z / clip.w + 1) / 2;
      }

      final base = Float32List.fromList([depth(Vector3.zero())]).single;
      final painted = Float32List.fromList([depth(Vector3(0, .001, 0))]).single;
      final overlay = Float32List.fromList([
        depth(Vector3(0, .0015, 0)),
      ]).single;
      expect(painted, lessThan(base));
      expect(overlay, lessThan(painted));
      camera.frame(Vector3.zero(), pitch: .7, yaw: 0, distance: 5);
      for (final point in [
        Vector3(0, .02, 0),
        Vector3(3, 4, 0),
        Vector3(-3, 0, 2),
      ]) {
        expect(depth(point), inInclusiveRange(0, 1));
      }
    },
  );
  test('terrain carries palette colors in materials used by the shader', () {
    const ground = Color(0xff125588), edge = Color(0xff113344);
    final surfaces = terrainMeshes(
      MapSpatialScene(width: 2, depth: 2),
      ground,
      edge,
    ).expand((mesh) => mesh.surfaces);
    final colors = surfaces
        .map((surface) => (surface.material as UnlitMaterial).albedoColor)
        .toSet();
    expect(colors, containsAll([ground, edge]));
  });
  test('terrain leaves unpainted water cells free of opaque base faces', () {
    final surfaces = terrainMeshes(
      MapSpatialScene(width: 2, depth: 2),
      const Color(0xff125588),
      const Color(0xff113344),
      paintedCells: {(0, 0), (0, 1), (1, 1)},
    ).expand((mesh) => mesh.surfaces);
    final topCells = <(int, int)>{};
    for (final surface in surfaces) {
      for (var i = 0; i < surface.positions.length; i += 12) {
        final points = [
          for (var j = i; j < i + 12; j += 3)
            Vector3.array(surface.positions, j),
        ];
        if (points.every((point) => point.y == 0)) {
          topCells.add((
            (points.map((point) => point.x).reduce((a, b) => a + b) / 4)
                .floor(),
            (points.map((point) => point.z).reduce((a, b) => a + b) / 4)
                .floor(),
          ));
        }
      }
    }
    expect(topCells, {(0, 0), (0, 1), (1, 1)});
  });
  test('painted terrain retains its cliff faces beside empty cells', () {
    final surfaces = terrainMeshes(
      MapSpatialScene(width: 2, depth: 1, heightLevels: [4, 0]),
      const Color(0xff125588),
      const Color(0xff113344),
      paintedCells: {(0, 0)},
    ).expand((mesh) => mesh.surfaces);
    expect(
      surfaces.any((surface) {
        for (var i = 0; i < surface.positions.length; i += 12) {
          final points = [
            for (var j = i; j < i + 12; j += 3)
              Vector3.array(surface.positions, j),
          ];
          if (points.every((point) => point.x == 1) &&
              points.any((point) => point.y == 0) &&
              points.any((point) => point.y > 0)) {
            return true;
          }
        }
        return false;
      }),
      isTrue,
    );
  });
  test('cell picking handles top, cliff faces, empty space and grid edges', () {
    final scene = MapSpatialScene(
      width: 2,
      depth: 2,
      heightLevels: [0, 0, 2, 0],
    );
    expect(pickSpatialCell(scene, Vector3(.5, 10, .5), Vector3(0, -1, 0)), (
      0,
      0,
    ));
    expect(pickSpatialCell(scene, Vector3(.5, 1, 4), Vector3(0, -.1, -1)), (
      0,
      1,
    ));
    expect(pickSpatialCell(scene, Vector3(1, 10, .5), Vector3(0, -1, 0)), (
      1,
      0,
    ));
    expect(
      pickSpatialCell(scene, Vector3(3, 10, .5), Vector3(0, -1, 0)),
      isNull,
    );
    expect(
      pickSpatialCell(scene, Vector3(.5, 10, .5), Vector3(0, 1, 0)),
      isNull,
    );
  });
  test(
    'large terrain partitions indices into supported sixteen bit meshes',
    () {
      final scene = MapSpatialScene(width: 256, depth: 256);
      final meshes = terrainMeshes(
        scene,
        const Color(0xffeeeeee),
        const Color(0xffaaaaaa),
      ).toList();
      expect(meshes.length, greaterThan(1));
      for (final mesh in meshes) {
        for (final surface in mesh.surfaces) {
          expect(surface.vertexCount, lessThanOrEqualTo(65535));
        }
      }
    },
  );
}
