import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';

import 'tileset_transparent_color_processor.dart';

Uint8List renderPathCenterPatternStaticPreviewPng({
  required Uint8List tilesetPngBytes,
  required PathCenterPattern pattern,
  required int tileWidthPx,
  required int tileHeightPx,
  TilesetTransparentColor? transparentColor,
}) {
  if (tileWidthPx <= 0) {
    throw ArgumentError.value(
      tileWidthPx,
      'tileWidthPx',
      'Path center pattern static preview tileWidthPx must be positive.',
    );
  }
  if (tileHeightPx <= 0) {
    throw ArgumentError.value(
      tileHeightPx,
      'tileHeightPx',
      'Path center pattern static preview tileHeightPx must be positive.',
    );
  }

  final processedTilesetBytes = transparentColor == null
      ? tilesetPngBytes
      : applyTilesetTransparentColorToPngBytes(
          imageBytes: tilesetPngBytes,
          transparentColor: transparentColor,
        );
  final tileset = img.decodePng(processedTilesetBytes);
  if (tileset == null) {
    throw ArgumentError.value(
      tilesetPngBytes,
      'tilesetPngBytes',
      'Path center pattern static preview expected valid PNG bytes.',
    );
  }

  final preview = img.Image(
    width: pattern.size.width * tileWidthPx,
    height: pattern.size.height * tileHeightPx,
    numChannels: 4,
  );

  for (final cell in pattern.cells) {
    if (cell.frames.isEmpty) {
      throw ArgumentError.value(
        cell,
        'pattern',
        'Path center pattern static preview cell must contain at least one frame.',
      );
    }
    final source = cell.frames.first.source;
    if (source.width != 1 || source.height != 1) {
      throw ArgumentError.value(
        source,
        'source',
        'Path center pattern static preview only supports 1x1 source rects in V0.',
      );
    }

    final sourceX = source.x * tileWidthPx;
    final sourceY = source.y * tileHeightPx;
    final sourceRight = sourceX + tileWidthPx;
    final sourceBottom = sourceY + tileHeightPx;
    if (sourceX < 0 ||
        sourceY < 0 ||
        sourceRight > tileset.width ||
        sourceBottom > tileset.height) {
      throw ArgumentError.value(
        source,
        'source',
        'Path center pattern static preview source rect is outside tileset image.',
      );
    }

    final destX = cell.localX * tileWidthPx;
    final destY = cell.localY * tileHeightPx;
    for (var y = 0; y < tileHeightPx; y += 1) {
      for (var x = 0; x < tileWidthPx; x += 1) {
        final pixel = tileset.getPixel(sourceX + x, sourceY + y);
        preview.setPixelRgba(
          destX + x,
          destY + y,
          pixel.r.toInt(),
          pixel.g.toInt(),
          pixel.b.toInt(),
          pixel.a.toInt(),
        );
      }
    }
  }

  return img.encodePng(preview);
}
