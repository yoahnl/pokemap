import 'dart:math' as math;

import 'package:flame_3d/camera.dart';

void applySpatialCameraMagnification(
  CameraComponent3D camera, {
  required double baseFieldOfViewDegrees,
  required double magnification,
}) {
  if (!baseFieldOfViewDegrees.isFinite ||
      baseFieldOfViewDegrees <= 0 ||
      baseFieldOfViewDegrees >= 180) {
    throw ArgumentError.value(baseFieldOfViewDegrees, 'baseFieldOfViewDegrees');
  }
  if (!magnification.isFinite || magnification <= 0) {
    throw ArgumentError.value(magnification, 'magnification');
  }
  final halfField = baseFieldOfViewDegrees * math.pi / 360;
  camera.fovY =
      2 * math.atan(math.tan(halfField) / magnification) * 180 / math.pi;
}
