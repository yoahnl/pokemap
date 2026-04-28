import 'package:map_core/map_core.dart';

/// Pure runtime draw plan for one placed Surface cell.
///
/// Lot 89 deliberately stops at this data object: it carries enough catalog and
/// atlas coordinates for a future Flame renderer, but it does not load images
/// and does not draw.
final class SurfaceRuntimeRenderInstruction {
  const SurfaceRuntimeRenderInstruction({
    required this.x,
    required this.y,
    required this.surfacePresetId,
    required this.resolvedRole,
    required this.animationId,
    required this.atlasId,
    required this.tilesetId,
    required this.sourceColumn,
    required this.sourceRow,
    required this.sourceTileWidth,
    required this.sourceTileHeight,
  });

  final int x;
  final int y;
  final String surfacePresetId;
  final SurfaceVariantRole resolvedRole;
  final String animationId;
  final String atlasId;
  final String tilesetId;
  final int sourceColumn;
  final int sourceRow;
  final int sourceTileWidth;
  final int sourceTileHeight;

  int get sourceX => sourceColumn * sourceTileWidth;

  int get sourceY => sourceRow * sourceTileHeight;
}
