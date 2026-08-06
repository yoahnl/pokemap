import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:map_core/map_core.dart';

/// Draws one resolved Smart Tile visual with its D4 transform applied.
///
/// The source-space order is flipX, then clockwise rotation. Asymmetric-quadrant
/// tests pin that order against accidental reversal, so every surface that shows
/// Smart Tiles — the map canvas and the Studio laboratory alike — must go
/// through this function instead of re-deriving the maths.
void drawSmartTileVisual(
  ui.Canvas canvas, {
  required ui.Image image,
  required ui.Rect sourceRect,
  required SmartTileLayerVisual visual,
  required ui.Paint paint,
}) {
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
    canvas.drawImageRect(
      image,
      sourceRect,
      ui.Rect.fromLTWH(0, 0, destination.width, destination.height),
      paint,
    );
  } finally {
    canvas.restore();
  }
}

/// Draws a whole batch of resolved visuals, skipping any whose tileset is not
/// decoded yet or whose source rectangle falls outside its image.
void paintSmartTileVisuals(
  ui.Canvas canvas, {
  required Iterable<SmartTileLayerVisual> visuals,
  required Map<String, ui.Image?> tilesetImagesById,
  required ui.Paint paint,
}) {
  for (final visual in visuals) {
    final image = tilesetImagesById[visual.tilesetId];
    if (image == null) continue;
    final source = visual.sourceRect;
    if (source.x < 0 ||
        source.y < 0 ||
        source.x + source.width > image.width ||
        source.y + source.height > image.height) {
      continue;
    }
    drawSmartTileVisual(
      canvas,
      image: image,
      sourceRect: Rect.fromLTWH(
        source.x.toDouble(),
        source.y.toDouble(),
        source.width.toDouble(),
        source.height.toDouble(),
      ),
      visual: visual,
      paint: paint,
    );
  }
}
