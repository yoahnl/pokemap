import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flame_3d/core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/adaptive_camera.dart';
import 'package:map_render_3d/src/spatial_camera_magnification.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('optical magnification scales projection while retaining camera position and target', () {
    final camera = AdaptiveCamera3D(fovY: 35);
    final center = Vector3(25.5, 1, 15.5);
    camera.frame(center, pitch: .7, yaw: .2, distance: 42);
    final position = camera.position.clone();
    final target = camera.target.clone();
    final distance = (position - target).length;
    final before = camera.projectionMatrix.clone();
    const magnification = 1.0801436075517405;
    applySpatialCameraMagnification(
      camera,
      baseFieldOfViewDegrees: 35,
      magnification: magnification,
    );
    final after = camera.projectionMatrix.clone();
    expect(
      camera.fovY,
      closeTo(
        2 *
            math.atan(math.tan(35 * math.pi / 360) / magnification) *
            180 /
            math.pi,
        1e-10,
      ),
    );
    expect(camera.fovY, lessThan(35));
    expect(
      after.entry(0, 0),
      closeTo(before.entry(0, 0) * magnification, 1e-6),
    );
    expect(
      after.entry(1, 1),
      closeTo(before.entry(1, 1) * magnification, 1e-6),
    );
    expect(camera.position, position);
    expect(camera.target, target);
    expect((camera.position - camera.target).length, distance);
  });

  test(
    'magnification is absolute and returns to authored field of view at one',
    () {
      final camera = AdaptiveCamera3D(fovY: 35);
      for (var i = 0; i < 10; i++) {
        applySpatialCameraMagnification(
          camera,
          baseFieldOfViewDegrees: 35,
          magnification: 2,
        );
      }
      expect(
        camera.fovY,
        closeTo(
          2 * math.atan(math.tan(35 * math.pi / 360) / 2) * 180 / math.pi,
          1e-10,
        ),
      );
      applySpatialCameraMagnification(
        camera,
        baseFieldOfViewDegrees: 35,
        magnification: 1,
      );
      expect(camera.fovY, closeTo(35, 1e-10));
      applySpatialCameraMagnification(
        camera,
        baseFieldOfViewDegrees: 35,
        magnification: .8,
      );
      expect(camera.fovY, greaterThan(35));
    },
  );

  test('optical field of view preserves authored distance and existing pose zoom in portrait', () {
    final camera = AdaptiveCamera3D(fovY: 35);
    const authoredDistance = 42.0;
    const controllerZoom = 1.5;
    const poseZoom = .8;
    camera.frame(
      Vector3(4, 2, 6),
      pitch: .6,
      yaw: .3,
      distance: authoredDistance * controllerZoom * poseZoom,
      viewportAspectRatio: .5,
    );
    final before = (camera.position - camera.target).length;
    applySpatialCameraMagnification(
      camera,
      baseFieldOfViewDegrees: 35,
      magnification: 1.08,
    );
    expect((camera.position - camera.target).length, before);
    expect(
      before,
      closeTo(authoredDistance * controllerZoom * poseZoom / .5, 1e-5),
    );
  });

  test('invalid magnification and field of view are rejected without stale camera mutation', () {
    final camera = AdaptiveCamera3D(fovY: 35);
    for (final invalid in [0.0, -1.0, double.nan, double.infinity]) {
      expect(
        () => applySpatialCameraMagnification(
          camera,
          baseFieldOfViewDegrees: 35,
          magnification: invalid,
        ),
        throwsArgumentError,
      );
      expect(camera.fovY, 35);
    }
    for (final invalid in [0.0, -1.0, 180.0, double.nan, double.infinity]) {
      expect(
        () => applySpatialCameraMagnification(
          camera,
          baseFieldOfViewDegrees: invalid,
          magnification: 1,
        ),
        throwsArgumentError,
      );
      expect(camera.fovY, 35);
    }
  });

  test('scene view exposes an optional live optical provider independently of pose zoom', () {
    final controller = SpatialSceneController()
      ..setView(SpatialEditorView.game);
    addTearDown(controller.dispose);
    var magnification = 1.08;
    final view = SpatialSceneView(
      scene: MapSpatialScene(width: 2, depth: 2),
      models: const [],
      loadModel: (_) async => Uint8List(0),
      controller: controller,
      onCell: (_, _) {},
      background: const Color(0xff000000),
      ground: const Color(0xff00ff00),
      edge: const Color(0xff888888),
      errorBuilder: (_, _) => const SizedBox(),
      cameraMagnification: () => magnification,
      cameraPose: () => (x: 1, y: 2, z: 3, zoom: .75),
    );
    expect(view.cameraMagnification!(), 1.08);
    expect(view.cameraPose!()!.zoom, .75);
    magnification = 1;
    expect(view.cameraMagnification!(), 1);
  });
}
