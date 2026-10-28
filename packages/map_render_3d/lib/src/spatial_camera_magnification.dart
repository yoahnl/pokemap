import 'dart:math' as math;

import 'package:flame_3d/camera.dart';
import 'package:map_core/map_core.dart';

void applySpatialCameraProfile(
  CameraComponent3D camera, {
  required SpatialCameraProfile profile,
  required double magnification,
  double zoom = 1,
  double viewportAspectRatio = 1,
  bool adaptivePlaybackFraming = false,
}) {
  if (!magnification.isFinite ||
      magnification <= 0 ||
      !zoom.isFinite ||
      zoom <= 0 ||
      !viewportAspectRatio.isFinite ||
      viewportAspectRatio <= 0) {
    throw ArgumentError(
      'Camera zoom, magnification and aspect must be positive.',
    );
  }
  final framingAspect = adaptivePlaybackFraming ? 1.0 : viewportAspectRatio;
  final effectiveMagnification =
      magnification *
      (adaptivePlaybackFraming ? math.sqrt(viewportAspectRatio / 1.5) : 1);
  if (profile.projection == SpatialCameraProjection.orthographic) {
    final height =
        profile.orthographicHeight *
        zoom /
        math.min(1.0, framingAspect) /
        effectiveMagnification;
    if (!height.isFinite || height <= 0) {
      throw ArgumentError(
        'Orthographic camera field is outside finite bounds.',
      );
    }
    camera.projection = CameraProjection.orthographic;
    camera.fovY = height;
  } else {
    camera.projection = CameraProjection.perspective;
    applySpatialCameraMagnification(
      camera,
      baseFieldOfViewDegrees: profile.fieldOfViewDegrees,
      magnification: effectiveMagnification,
    );
  }
}

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
