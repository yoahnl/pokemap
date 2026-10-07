import 'dart:math' as math;

import 'package:flame_3d/camera.dart';
import 'package:flame_3d/core.dart';

class AdaptiveCamera3D extends CameraComponent3D {
  AdaptiveCamera3D({super.fovY});
  double sceneRadius = 1;
  final _projection = Matrix4.zero();

  void frame(
    Vector3 center, {
    required double pitch,
    required double yaw,
    required double distance,
  }) {
    target.setFrom(center);
    position.setValues(
      center.x + distance * math.cos(pitch) * math.sin(yaw),
      center.y + distance * math.sin(pitch),
      center.z + distance * math.cos(pitch) * math.cos(yaw),
    );
  }

  @override
  Matrix4 get projectionMatrix {
    final distance = (position - target).length;
    final far = math.max(1000.0, distance + sceneRadius * 4);
    final near = math.max(0.001, math.min(0.01, sceneRadius / 100));
    final size = viewport.virtualSize;
    final aspect = size.y > 0 ? size.x / size.y : 1.0;
    return _projection..setAsPerspective(fovY, aspect, near, far);
  }
}
