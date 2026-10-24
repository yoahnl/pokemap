import 'dart:math' as math;

import 'package:flame_3d/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

void main() {
  test('billboard attachment clears the projected head at real camera pitches', () {
    for (final pitch in [30.0, 55.0, 70.0]) {
      for (final yaw in [0.0, 90.0, 180.0]) {
        final transform = spatialActorTransform(SpatialCameraProfile(pitchDegrees: pitch, yawDegrees: yaw));
        final feet = Vector3(8, 1.5, 6.5);
        final actorTop = Matrix4.compose(feet, transform.rotation, transform.scale)
            .transform3(Vector3(0, 1.92, 0));
        final attachment = feet + spatialActorBillboardOffset(verticalOffset: 1.92 + .15,
            rotation: transform.rotation, scale: transform.scale);
        final angle = pitch * math.pi / 180;
        final yawAngle = yaw * math.pi / 180;
        final screenUp = Vector3(-math.sin(angle) * math.sin(yawAngle), math.cos(angle), -math.sin(angle) * math.cos(yawAngle));
        expect((attachment - actorTop).dot(screenUp), closeTo(.15, .000001));
      }
    }
    final rotation = Quaternion.axisAngle(Vector3(1, 0, 0), -math.pi / 2);
    final scale = Vector3(1, 1, 1);
    final actorTop = Matrix4.compose(Vector3.zero(), rotation, scale).transform3(Vector3(0, 1.92, 0));
    final attachment = spatialActorBillboardOffset(verticalOffset: 1.92 + .15, rotation: rotation, scale: scale);
    expect((attachment - actorTop).dot(Vector3(0, 0, -1)), closeTo(.15, .000001));
  });

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
