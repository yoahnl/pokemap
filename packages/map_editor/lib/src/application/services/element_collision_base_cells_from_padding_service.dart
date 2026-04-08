import 'dart:math' as math;

import 'package:map_core/map_core.dart';

/// Derives the automatic collision shape from the existing padding model.
///
/// This service deliberately stays tile/cell based:
/// - no image inspection
/// - no alpha analysis
/// - no pixel-perfect collision
///
/// The returned cells are the source-grid cells that still intersect the
/// "active" rectangle after padding has trimmed the element bounds.
class ElementCollisionBaseCellsFromPaddingService {
  const ElementCollisionBaseCellsFromPaddingService();

  List<GridPos> derive({
    required TilesetSourceRect source,
    required int tileWidth,
    required int tileHeight,
    required WarpTriggerPadding padding,
  }) {
    if (source.width <= 0 ||
        source.height <= 0 ||
        tileWidth <= 0 ||
        tileHeight <= 0) {
      return const <GridPos>[];
    }

    final sourcePixelWidth = source.width * tileWidth;
    final sourcePixelHeight = source.height * tileHeight;
    final trimmedLeft = padding.left.clamp(0, sourcePixelWidth);
    final trimmedTop = padding.top.clamp(0, sourcePixelHeight);
    final trimmedRight = math.max(
      trimmedLeft,
      sourcePixelWidth - padding.right.clamp(0, sourcePixelWidth),
    );
    final trimmedBottom = math.max(
      trimmedTop,
      sourcePixelHeight - padding.bottom.clamp(0, sourcePixelHeight),
    );

    if (trimmedRight <= trimmedLeft || trimmedBottom <= trimmedTop) {
      return const <GridPos>[];
    }

    final out = <GridPos>[];
    for (var y = 0; y < source.height; y++) {
      final cellTop = y * tileHeight;
      final cellBottom = cellTop + tileHeight;
      final overlapsY = cellBottom > trimmedTop && cellTop < trimmedBottom;
      if (!overlapsY) {
        continue;
      }
      for (var x = 0; x < source.width; x++) {
        final cellLeft = x * tileWidth;
        final cellRight = cellLeft + tileWidth;
        final overlapsX = cellRight > trimmedLeft && cellLeft < trimmedRight;
        if (!overlapsX) {
          continue;
        }
        out.add(GridPos(x: x, y: y));
      }
    }
    return out;
  }
}
