import 'dart:ui';

final class SurfaceStudioAtlasViewGeometry {
  const SurfaceStudioAtlasViewGeometry({
    required this.viewportSize,
    required this.imagePixelSize,
    required this.fittedImageRect,
    required this.tileWidth,
    required this.tileHeight,
    required this.columnCount,
    required this.frameCount,
  });

  factory SurfaceStudioAtlasViewGeometry.fromContain({
    required Size viewportSize,
    required Size imagePixelSize,
    required int tileWidth,
    required int tileHeight,
    required int columnCount,
    required int frameCount,
  }) {
    return SurfaceStudioAtlasViewGeometry(
      viewportSize: viewportSize,
      imagePixelSize: imagePixelSize,
      fittedImageRect: computeSurfaceStudioContainedImageRect(
        viewportSize: viewportSize,
        imagePixelSize: imagePixelSize,
      ),
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      columnCount: columnCount,
      frameCount: frameCount,
    );
  }

  final Size viewportSize;
  final Size imagePixelSize;
  final Rect fittedImageRect;
  final int tileWidth;
  final int tileHeight;
  final int columnCount;
  final int frameCount;
}

Rect computeSurfaceStudioContainedImageRect({
  required Size viewportSize,
  required Size imagePixelSize,
}) {
  if (viewportSize.width <= 0 ||
      viewportSize.height <= 0 ||
      imagePixelSize.width <= 0 ||
      imagePixelSize.height <= 0) {
    return Offset.zero & Size.zero;
  }
  final scale = (viewportSize.width / imagePixelSize.width) <
          (viewportSize.height / imagePixelSize.height)
      ? viewportSize.width / imagePixelSize.width
      : viewportSize.height / imagePixelSize.height;
  final fittedSize = Size(
    imagePixelSize.width * scale,
    imagePixelSize.height * scale,
  );
  return Rect.fromLTWH(
    (viewportSize.width - fittedSize.width) / 2,
    (viewportSize.height - fittedSize.height) / 2,
    fittedSize.width,
    fittedSize.height,
  );
}

int? surfaceStudioColumnAtViewportOffset({
  required Offset localPosition,
  required SurfaceStudioAtlasViewGeometry geometry,
}) {
  final rect = geometry.fittedImageRect;
  if (!rect.contains(localPosition) || geometry.columnCount <= 0) {
    return null;
  }
  final localX = localPosition.dx - rect.left;
  final normalized = (localX / rect.width).clamp(0, 0.999999);
  return (normalized * geometry.columnCount).floor() + 1;
}

int? surfaceStudioFrameAtViewportOffset({
  required Offset localPosition,
  required SurfaceStudioAtlasViewGeometry geometry,
}) {
  final rect = geometry.fittedImageRect;
  if (!rect.contains(localPosition) || geometry.frameCount <= 0) {
    return null;
  }
  final localY = localPosition.dy - rect.top;
  final normalized = (localY / rect.height).clamp(0, 0.999999);
  return (normalized * geometry.frameCount).floor() + 1;
}

Rect surfaceStudioColumnViewportRect({
  required int uiColumn,
  required SurfaceStudioAtlasViewGeometry geometry,
}) {
  final safeColumnCount = geometry.columnCount < 1 ? 1 : geometry.columnCount;
  final column = uiColumn.clamp(1, safeColumnCount).toInt();
  final width = geometry.fittedImageRect.width / safeColumnCount;
  return Rect.fromLTWH(
    geometry.fittedImageRect.left + (column - 1) * width,
    geometry.fittedImageRect.top,
    width,
    geometry.fittedImageRect.height,
  );
}

Rect surfaceStudioTileSourceRect({
  required int uiColumn,
  required int frameIndex,
  required int tileWidth,
  required int tileHeight,
  required int columnCount,
  required int frameCount,
}) {
  final safeColumnCount = columnCount < 1 ? 1 : columnCount;
  final safeFrameCount = frameCount < 1 ? 1 : frameCount;
  final column = uiColumn.clamp(1, safeColumnCount).toInt();
  final frame = frameIndex.clamp(0, safeFrameCount - 1).toInt();
  return Rect.fromLTWH(
    (column - 1) * tileWidth.toDouble(),
    frame * tileHeight.toDouble(),
    tileWidth.toDouble(),
    tileHeight.toDouble(),
  );
}
