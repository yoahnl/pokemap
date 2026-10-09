import 'dart:math' as math;

import 'package:flame_3d/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/src/adaptive_camera.dart';

void main() {
  double frameDistance(
    AdaptiveCamera3D camera,
    double aspect,
    double distance,
  ) {
    camera.frame(
      Vector3(14.5, 2, 14.5),
      pitch: 48.7 * math.pi / 180,
      yaw: 25 * math.pi / 180,
      distance: distance,
      viewportAspectRatio: aspect,
    );
    return (camera.position - camera.target).length;
  }

  test('portrait keeps the square viewport horizontal field visible', () {
    final camera = AdaptiveCamera3D(fovY: 24);
    final square = frameDistance(camera, 1, 42);
    final portrait = frameDistance(camera, 390 / 844, 42);
    final halfField = math.tan(24 * math.pi / 360);
    expect(
      portrait * halfField * (390 / 844),
      closeTo(square * halfField, 1e-5),
    );
    expect(camera.target, Vector3(14.5, 2, 14.5));
    final offset = (camera.position - camera.target).normalized();
    expect(offset.y, closeTo(math.sin(48.7 * math.pi / 180), 1e-6));
    expect(math.atan2(offset.x, offset.z), closeTo(25 * math.pi / 180, 1e-6));
  });

  test('rotation back to landscape restores the authored distance', () {
    final camera = AdaptiveCamera3D();
    frameDistance(camera, 390 / 844, 42);
    expect(frameDistance(camera, 844 / 390, 42), closeTo(42, 1e-5));
    expect(frameDistance(camera, 1, 42), closeTo(42, 1e-5));
  });

  test('cinematic zoom remains proportional after portrait framing', () {
    final camera = AdaptiveCamera3D();
    final normal = frameDistance(camera, .5, 42);
    expect(frameDistance(camera, .5, 42 * .75), closeTo(normal * .75, 1e-5));
  });

  test('unavailable viewport dimensions keep a finite camera', () {
    final camera = AdaptiveCamera3D();
    for (final aspect in [0.0, -1.0, double.infinity, double.nan]) {
      expect(frameDistance(camera, aspect, 42), closeTo(42, 1e-5));
    }
  });
}
