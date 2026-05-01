import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/tileset_transparent_color_processor.dart';

const double pathMappingTilesetMinZoom = 0.5;
const double pathMappingTilesetMaxZoom = 8.0;
const double pathMappingTilesetZoomStep = 1.25;

final class PathMappingAlphaPreviewBytesResult {
  const PathMappingAlphaPreviewBytesResult({
    required this.bytes,
    required this.errorMessage,
  });

  final Uint8List bytes;
  final String? errorMessage;
}

GridPos pathMappingTileFromLocalPosition({
  required ui.Offset localPosition,
  required ui.Size displaySize,
  required int columns,
  required int rows,
}) {
  if (displaySize.width <= 0 ||
      displaySize.height <= 0 ||
      columns <= 0 ||
      rows <= 0) {
    return const GridPos(x: 0, y: 0);
  }
  final maxX = math.max(0.0, displaySize.width - 0.000001);
  final maxY = math.max(0.0, displaySize.height - 0.000001);
  final dx = localPosition.dx.clamp(0.0, maxX).toDouble();
  final dy = localPosition.dy.clamp(0.0, maxY).toDouble();
  return GridPos(
    x: (dx / displaySize.width * columns).floor().clamp(0, columns - 1),
    y: (dy / displaySize.height * rows).floor().clamp(0, rows - 1),
  );
}

double pathMappingClampTilesetZoom(double zoom) {
  final clamped =
      zoom.clamp(pathMappingTilesetMinZoom, pathMappingTilesetMaxZoom);
  return double.parse(clamped.toStringAsFixed(4));
}

double pathMappingTilesetZoomIn(double currentZoom) {
  return pathMappingClampTilesetZoom(currentZoom * pathMappingTilesetZoomStep);
}

double pathMappingTilesetZoomOut(double currentZoom) {
  return pathMappingClampTilesetZoom(currentZoom / pathMappingTilesetZoomStep);
}

PathMappingAlphaPreviewBytesResult createPathMappingAlphaPreviewBytes({
  required Uint8List originalPngBytes,
  required bool enabled,
  required String hexRgb,
}) {
  if (!enabled) {
    return PathMappingAlphaPreviewBytesResult(
      bytes: originalPngBytes,
      errorMessage: null,
    );
  }
  try {
    final transparentColor = TilesetTransparentColor.fromHexRgb(hexRgb.trim());
    return PathMappingAlphaPreviewBytesResult(
      bytes: applyTilesetTransparentColorToPngBytes(
        imageBytes: originalPngBytes,
        transparentColor: transparentColor,
      ),
      errorMessage: null,
    );
  } on ArgumentError {
    return PathMappingAlphaPreviewBytesResult(
      bytes: originalPngBytes,
      errorMessage: 'Couleur hex invalide',
    );
  }
}
