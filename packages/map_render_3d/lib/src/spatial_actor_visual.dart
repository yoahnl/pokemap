import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flame_3d/resources.dart';
import 'package:flame_3d/core.dart';
import 'package:map_core/map_core.dart';

import 'spatial_ground.dart' show applySpatialGroundColorKey;

final class SpatialActorTexture {
  SpatialActorTexture._(this.texture, this._alpha);
  final Texture texture;
  final Uint8List _alpha;
  final _footAnchors = <ui.Rect, ({double x, double y})?>{};

  ({double x, double y})? footAnchor(ui.Rect frame) {
    if (_footAnchors.containsKey(frame)) return _footAnchors[frame];
    return _footAnchors[frame] = spatialActorFrameFootAnchor(
      _alpha,
      width: texture.width,
      height: texture.height,
      frame: frame,
    );
  }

  static Future<SpatialActorTexture> fromImage(
    ui.Image image, {
    TilesetTransparentColor? transparentColor,
  }) async {
    if (transparentColor == null) {
      final data = await image.toByteData();
      if (data == null)
        throw StateError('Actor texture pixels are unavailable.');
      final rgba = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final alpha = Uint8List(image.width * image.height);
      for (var index = 0; index < alpha.length; index++) {
        alpha[index] = rgba[index * 4 + 3];
      }
      return SpatialActorTexture._(
        ImageTexture(data, width: image.width, height: image.height),
        alpha,
      );
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
    final alpha = Uint8List(image.width * image.height);
    for (var index = 0; index < alpha.length; index++) {
      alpha[index] = rgba[index * 4 + 3];
    }
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
      return SpatialActorTexture._(await ImageTexture.create(processed), alpha);
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
    this.groundY,
    required this.texture,
    required this.frame,
    this.width,
    this.height = 1.92,
    this.billboardVerticalOffset = 0,
    this.contactShadow = false,
    this.airborne = false,
    this.landingDust = false,
  }) : assert(width == null || width > 0),
       assert(height > 0);
  final double x, y, z;
  final double? groundY;
  final SpatialActorTexture texture;
  final ui.Rect frame;
  final double? width;
  final double height;
  final double billboardVerticalOffset;
  final bool contactShadow;
  final bool airborne;
  final bool landingDust;
  double get resolvedWidth => width ?? height * frame.width / frame.height;
  ({double x, double y})? get contactShadowFootAnchor =>
      texture.footAnchor(frame);
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

Vector3 spatialActorBillboardOffset({
  required double verticalOffset,
  required Quaternion rotation,
  required Vector3 scale,
}) => Matrix4.compose(
  Vector3.zero(),
  rotation,
  scale,
).transform3(Vector3(0, verticalOffset, 0));

({double x, double y})? spatialActorFrameFootAnchor(
  Uint8List alpha, {
  required int width,
  required int height,
  required ui.Rect frame,
}) {
  if (width <= 0 ||
      height <= 0 ||
      alpha.length != width * height ||
      ![
        frame.left,
        frame.top,
        frame.right,
        frame.bottom,
      ].every((v) => v.isFinite) ||
      frame.left < 0 ||
      frame.top < 0 ||
      frame.right > width ||
      frame.bottom > height ||
      frame.width <= 0 ||
      frame.height <= 0) {
    throw ArgumentError('Invalid actor frame alpha bounds.');
  }
  final left = frame.left.floor(), right = frame.right.ceil();
  final top = frame.top.floor(), bottom = frame.bottom.ceil();
  for (var y = bottom - 1; y >= top; y--) {
    var visible = false;
    for (var x = left; x < right; x++) {
      if (alpha[y * width + x] >= 64) {
        visible = true;
        break;
      }
    }
    if (!visible) continue;
    var sumX = 0.0, count = 0;
    for (var row = math.max(top, y - 2); row <= y; row++) {
      for (var x = left; x < right; x++) {
        if (alpha[row * width + x] >= 64) {
          sumX += x + .5;
          count++;
        }
      }
    }
    return (
      x: (sumX / count - frame.left) / frame.width - .5,
      y: (frame.bottom - math.min(y + 1, frame.bottom)) / frame.height,
    );
  }
  return null;
}
