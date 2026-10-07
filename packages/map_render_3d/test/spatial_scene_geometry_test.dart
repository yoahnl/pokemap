import 'dart:ui';

import 'package:flame_3d/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_picking.dart';
import 'package:map_render_3d/src/adaptive_camera.dart';
import 'package:flame_3d/resources.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart';

void main() {
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
