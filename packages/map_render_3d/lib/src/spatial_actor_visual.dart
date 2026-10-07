import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flame_3d/resources.dart';
import 'package:flame_3d/core.dart';
import 'package:map_core/map_core.dart';

final class SpatialActorTexture {
  SpatialActorTexture._(this.texture);
  final Texture texture;
  static Future<SpatialActorTexture> fromImage(ui.Image image) async =>
      SpatialActorTexture._(await ImageTexture.create(image));
}

final class SpatialActorVisual {
  const SpatialActorVisual({
    required this.x,
    required this.y,
    required this.z,
    required this.texture,
    required this.frame,
  });
  final double x, y, z;
  final SpatialActorTexture texture;
  final ui.Rect frame;
}

({Quaternion rotation, Vector3 scale}) spatialActorTransform(
  SpatialCameraProfile camera,
) => (
  rotation: Quaternion.axisAngle(
    Vector3(0, 1, 0),
    camera.yawDegrees * math.pi / 180,
  ),
  scale: Vector3(1, 1 / math.cos(camera.pitchDegrees * math.pi / 180), 1),
);
