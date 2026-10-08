import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flame_3d/resources.dart';
import 'package:flame_3d/core.dart';
import 'package:map_core/map_core.dart';

import 'spatial_ground.dart' show applySpatialGroundColorKey;

final class SpatialActorTexture {
  SpatialActorTexture._(this.texture);
  final Texture texture;
  static Future<SpatialActorTexture> fromImage(
    ui.Image image, {
    TilesetTransparentColor? transparentColor,
  }) async {
    if (transparentColor == null) {
      return SpatialActorTexture._(await ImageTexture.create(image));
    }
    final data = await image.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    );
    if (data == null) {
      throw StateError('Actor texture pixels are unavailable.');
    }
    final rgba = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    applySpatialGroundColorKey(rgba, transparentColor);
    final decoded = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      rgba,
      image.width,
      image.height,
      ui.PixelFormat.rgba8888,
      decoded.complete,
    );
    final processed = await decoded.future;
    try {
      return SpatialActorTexture._(await ImageTexture.create(processed));
    } finally {
      processed.dispose();
    }
  }
}

final class SpatialActorVisual {
  const SpatialActorVisual({
    required this.x,
    required this.y,
    required this.z,
    required this.texture,
    required this.frame,
    this.width,
    this.height = 1.92,
  }) : assert(width == null || width > 0),
       assert(height > 0);
  final double x, y, z;
  final SpatialActorTexture texture;
  final ui.Rect frame;
  final double? width;
  final double height;
  double get resolvedWidth => width ?? height * frame.width / frame.height;
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
