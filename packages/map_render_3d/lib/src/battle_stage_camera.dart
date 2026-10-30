import 'dart:math' as math;
import 'dart:ui';

import 'package:flame_3d/camera.dart';
import 'package:flame_3d/core.dart';
import 'package:map_core/map_core.dart';

final class BattleStageCamera extends CameraComponent3D {
  final _projection = Matrix4.zero();
  Size frameSize = Size.zero;
  double focal = 1;
  double centerY = .55;
  Offset? principalPoint;

  void setFrame({
    required Model3dVector3 eye,
    required Model3dVector3 aim,
    required Size size,
    required double focalLength,
    Offset? projectionCenter,
  }) {
    position.setValues(eye.x, eye.y, eye.z);
    target.setValues(aim.x, aim.y, aim.z);
    frameSize = size;
    focal = focalLength;
    principalPoint = projectionCenter;
  }

  @override
  Matrix4 get projectionMatrix {
    final height = math.max(1.0, frameSize.height);
    final aspect = math.max(1.0, frameSize.width) / height;
    final fov = 2 * math.atan(height / (2 * focal)) * 180 / math.pi;
    final center =
        principalPoint ?? Offset(frameSize.width / 2, height * centerY);
    return _projection
      ..setAsPerspective(fov, aspect, .01, 1000)
      ..setEntry(0, 2, 1 - center.dx * 2 / math.max(1.0, frameSize.width))
      ..setEntry(1, 2, center.dy * 2 / height - 1);
  }

  Offset? project(Model3dVector3 point) {
    final clip = viewProjectionMatrix.transform(
      Vector4(point.x, point.y, point.z, 1),
    );
    if (clip.w <= .01) return null;
    return Offset(
      (clip.x / clip.w + 1) * frameSize.width / 2,
      (1 - clip.y / clip.w) * frameSize.height / 2,
    );
  }
}
