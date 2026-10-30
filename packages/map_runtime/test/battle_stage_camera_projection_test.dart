import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/battle_stage_camera.dart';
import 'package:map_runtime/src/presentation/flame/battle_perspective_camera.dart';

void main() {
  test(
    'billboard keeps its world size and GPU corners follow the FX rectangle',
    () {
      final presentation = BattlePerspectiveCamera(
        viewport: const Rect.fromLTWH(12, 24, 390, 430),
      );
      final gpu = BattleStageCamera();
      const foot = Offset(120, 390);
      const neutral = Rect.fromLTWH(58.8, 290, 90, 100);
      final initial = presentation.billboardWorldGeometry(foot, neutral);
      presentation.focus(foot, playerSide: true, durationSeconds: .4);
      for (var i = 0; i < 24; i++) {
        presentation.update(1 / 60);
        gpu.setFrame(
          eye: Model3dVector3(
            x: presentation.eye.x,
            y: presentation.eye.y,
            z: presentation.eye.z,
          ),
          aim: Model3dVector3(
            x: presentation.aim.x,
            y: presentation.aim.y,
            z: presentation.aim.z,
          ),
          size: presentation.viewport.size,
          focalLength: presentation.focal,
        );
        final world = presentation.billboardWorldGeometry(foot, neutral);
        expect(world.width, closeTo(initial.width, .00001));
        expect(world.height, closeTo(initial.height, .00001));
        final right = gpu.right.normalized();
        final up = right.cross(gpu.forward.normalized()).normalized();
        final billboard = presentation.billboardAt(foot);
        final expected = Rect.fromLTWH(
          billboard.position.dx + (neutral.left - foot.dx) * billboard.scale,
          billboard.position.dy + (neutral.top - foot.dy) * billboard.scale,
          neutral.width * billboard.scale,
          neutral.height * billboard.scale,
        );
        for (final corner in [const Offset(0, 0), const Offset(1, 1)]) {
          final projected =
              gpu.project(
                Model3dVector3(
                  x:
                      world.position.x +
                      right.x * world.width * (corner.dx - .5) +
                      up.x * world.height * (1 - corner.dy),
                  y:
                      world.position.y +
                      right.y * world.width * (corner.dx - .5) +
                      up.y * world.height * (1 - corner.dy),
                  z:
                      world.position.z +
                      right.z * world.width * (corner.dx - .5) +
                      up.z * world.height * (1 - corner.dy),
                ),
              )! +
              presentation.viewport.topLeft;
          final target = corner == Offset.zero
              ? expected.topLeft
              : expected.bottomRight;
          expect(projected.dx, closeTo(target.dx, .001));
          expect(projected.dy, closeTo(target.dy, .001));
        }
      }
    },
  );
  for (final viewport in [
    const Rect.fromLTWH(0, 24, 390, 430),
    const Rect.fromLTWH(12, 0, 540, 390),
  ]) {
    test(
      'GPU and FX share projection before, during and after camera travel $viewport',
      () {
        final presentation = BattlePerspectiveCamera(viewport: viewport);
        final gpu = BattleStageCamera();
        final foot = Offset(
          viewport.left + viewport.width * .72,
          viewport.top + viewport.height * .66,
        );
        final ground = presentation.groundAt(foot);
        final points = [ground, ground + const BattleCameraPoint(0, 2, 0)];
        void checkProjection() {
          final surface = Rect.fromLTRB(
            0,
            0,
            viewport.right + 18,
            viewport.bottom + 42,
          );
          gpu.setFrame(
            eye: Model3dVector3(
              x: presentation.eye.x,
              y: presentation.eye.y,
              z: presentation.eye.z,
            ),
            aim: Model3dVector3(
              x: presentation.aim.x,
              y: presentation.aim.y,
              z: presentation.aim.z,
            ),
            size: surface.size,
            focalLength: presentation.focal,
            projectionCenter: Offset(
              viewport.center.dx,
              viewport.top + viewport.height * .55,
            ),
          );
          for (final point in points) {
            final actual =
                gpu.project(
                  Model3dVector3(x: point.x, y: point.y, z: point.z),
                )! +
                surface.topLeft;
            final expected = presentation.project(point).position;
            expect(actual.dx, closeTo(expected.dx, .001));
            expect(actual.dy, closeTo(expected.dy, .001));
          }
        }

        checkProjection();
        presentation.focus(foot, playerSide: false, durationSeconds: .4);
        for (var i = 0; i < 24; i++) {
          presentation.update(1 / 60);
          checkProjection();
        }
        presentation.reset(durationSeconds: .3);
        presentation.update(.3);
        checkProjection();
      },
    );
  }
}
