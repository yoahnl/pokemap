import 'dart:math' as math;
import 'dart:ui';

import 'package:map_core/map_core.dart';

import '../../infrastructure/runtime_tileset_image.dart';

void drawRuntimeSmartTileVisual({
  required Canvas canvas,
  required RuntimeTilesetImage image,
  required SmartTileLayerVisual visual,
  required Paint paint,
}) {
  final source = visual.sourceRect;
  final sourceRect = Rect.fromLTWH(
    source.x.toDouble(),
    source.y.toDouble(),
    source.width.toDouble(),
    source.height.toDouble(),
  );
  if (!image.containsSourceRect(sourceRect)) {
    return;
  }
  final destination = visual.geometry.destinationRect;
  final transform = visual.transform;
  canvas.save();
  try {
    canvas.translate(destination.left, destination.top);
    switch (transform.quarterTurns) {
      case 0:
        break;
      case 1:
        canvas.translate(destination.height, 0);
        canvas.rotate(math.pi / 2);
      case 2:
        canvas.translate(destination.width, destination.height);
        canvas.rotate(math.pi);
      case 3:
        canvas.translate(0, destination.width);
        canvas.rotate(3 * math.pi / 2);
    }
    if (transform.flipX) {
      canvas.translate(destination.width, 0);
      canvas.scale(-1, 1);
    }
    image.drawImageRect(
      canvas,
      sourceRect,
      Rect.fromLTWH(0, 0, destination.width, destination.height),
      paint,
    );
  } finally {
    canvas.restore();
  }
}
