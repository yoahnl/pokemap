import 'dart:math' as math;

import 'package:flame_3d/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

void main() {
  test(
    'mid-ramp actor keeps its entire body over the feet and its apparent height',
    () {
      for (final pitch in [30.0, 48.7, 60.0]) {
        for (final yaw in [0.0, 90.0, 180.0, 270.0]) {
          final transform = spatialActorTransform(
            SpatialCameraProfile(pitchDegrees: pitch, yawDegrees: yaw),
          );
          final feet = Vector3(8, 1.5, 6.5);
          final matrix = Matrix4.compose(
            feet,
            transform.rotation,
            transform.scale,
          );
          final top = matrix.transform3(Vector3(0, 1.92, 0));
          expect(top.x, closeTo(feet.x, .000001));
          expect(top.z, closeTo(feet.z, .000001));
          expect(top.y, greaterThan(feet.y));
          expect(
            (top.y - feet.y) * math.cos(pitch * math.pi / 180),
            closeTo(1.92, .000001),
          );
        }
      }
    },
  );
}
