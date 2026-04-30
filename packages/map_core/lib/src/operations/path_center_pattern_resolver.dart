import '../models/path_center_pattern.dart';

/// Result of resolving a map coordinate into a local center-pattern cell.
final class PathCenterPatternCellResolution {
  const PathCenterPatternCellResolution({
    required this.mapX,
    required this.mapY,
    required this.localX,
    required this.localY,
    required this.cell,
  });

  final int mapX;
  final int mapY;
  final int localX;
  final int localY;
  final PathCenterPatternCell cell;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PathCenterPatternCellResolution &&
            mapX == other.mapX &&
            mapY == other.mapY &&
            localX == other.localX &&
            localY == other.localY &&
            cell == other.cell;
  }

  @override
  int get hashCode => Object.hash(mapX, mapY, localX, localY, cell);
}

/// Resolves a [PathCenterPattern] cell from absolute map coordinates.
///
/// V0 intentionally rejects negative map coordinates instead of applying
/// positive modulo. Pattern origin is the absolute map origin, not a painted
/// region origin.
PathCenterPatternCellResolution resolvePathCenterPatternCell({
  required PathCenterPattern pattern,
  required int mapX,
  required int mapY,
}) {
  if (mapX < 0) {
    throw ArgumentError.value(
      mapX,
      'mapX',
      'PathCenterPattern mapX must be non-negative.',
    );
  }
  if (mapY < 0) {
    throw ArgumentError.value(
      mapY,
      'mapY',
      'PathCenterPattern mapY must be non-negative.',
    );
  }

  final localX = mapX % pattern.size.width;
  final localY = mapY % pattern.size.height;

  return PathCenterPatternCellResolution(
    mapX: mapX,
    mapY: mapY,
    localX: localX,
    localY: localY,
    cell: pattern.cellAt(localX, localY),
  );
}
