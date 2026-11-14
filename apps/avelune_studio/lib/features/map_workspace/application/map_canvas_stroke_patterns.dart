part of 'map_canvas_stroke.dart';

bool _hasSpatialPatternPartAt({
  required SmartTileLayer layer,
  required ProjectManifest project,
  required GridPos cell,
}) {
  final owner = _spatialPatternOwnerAt(
    layer: layer,
    project: project,
    cell: cell,
  );
  return owner != null &&
      (smartTilePatternCellAt(
            pattern: owner.pattern,
            stroke: owner.stroke,
            cell: cell,
          )?.parts.isNotEmpty ??
          false);
}

({ProjectSmartTilePattern pattern, SmartTilePatternStroke stroke})?
_spatialPatternOwnerAt({
  required SmartTileLayer layer,
  required ProjectManifest project,
  required GridPos cell,
}) {
  for (final stroke in layer.patternStrokes.reversed) {
    if (!stroke.cells.contains(cell)) continue;
    final pattern = project.smartTileCatalog.patterns
        .where((pattern) => pattern.id == stroke.patternId)
        .firstOrNull;
    if (pattern == null || pattern.usage != layer.usage) continue;
    return (pattern: pattern, stroke: stroke);
  }
  return null;
}

bool _isSmallModelStamp(ProjectSmartTilePattern pattern) {
  final parts = pattern.cells.expand((cell) => cell.parts);
  return pattern.repeatMode == SmartTilePatternRepeatMode.stamp &&
      pattern.width <= 8 &&
      pattern.height <= 8 &&
      pattern.width * pattern.height > 1 &&
      parts.isNotEmpty &&
      parts.every((part) => part.source is SmartTileModel3dSource) &&
      !parts.every((part) => part.spatialClip != null);
}

bool _isSmallStampStroke(
  ProjectSmartTilePattern pattern,
  SmartTilePatternStroke stroke,
) {
  if (stroke.cells.isEmpty ||
      stroke.cells.length > pattern.width * pattern.height) {
    return false;
  }
  var minX = stroke.cells.first.x, maxX = minX;
  var minY = stroke.cells.first.y, maxY = minY;
  for (final cell in stroke.cells) {
    if (cell.x < minX) minX = cell.x;
    if (cell.x > maxX) maxX = cell.x;
    if (cell.y < minY) minY = cell.y;
    if (cell.y > maxY) maxY = cell.y;
  }
  return maxX - minX + 1 <= pattern.width && maxY - minY + 1 <= pattern.height;
}

extension _MapCanvasStrokePatternErase on MapCanvasStroke {
  SmartTileLayer _erasePatterns(SmartTileLayer layer) {
    if (!atomicPatternErase) {
      return eraseSmartTilePatternCells(
        layer,
        mapSize: buffer.sourceMap.size,
        cells: _terrainCells,
        clearMaterial:
            layer.usage == SmartTileUsage.path &&
            (layer.encounterBehavior != null ||
                layer.animationActivation ==
                    SmartTileAnimationActivation.onEnter),
      );
    }
    final strokeIds = <String>{};
    final cells = <GridPos>{};
    for (final cell in _terrainCells) {
      final owner = _spatialPatternOwnerAt(
        layer: layer,
        project: project,
        cell: cell,
      );
      if (owner == null ||
          owner.pattern.id != erasePatternId ||
          !_isSmallStampStroke(owner.pattern, owner.stroke)) {
        continue;
      }
      strokeIds.add(owner.stroke.id);
      cells.addAll(owner.stroke.cells);
      if (cells.length > smartTileMaximumCellsPerGesture) {
        throw const SmartTileGestureLimitException(
          maximumCellCount: smartTileMaximumCellsPerGesture,
        );
      }
    }
    if (strokeIds.isEmpty) return layer;
    return eraseSmartTilePatternCells(
      layer,
      mapSize: buffer.sourceMap.size,
      cells: cells,
      strokeIds: strokeIds,
      clearMaterial:
          layer.usage == SmartTileUsage.path &&
          (layer.encounterBehavior != null ||
              layer.animationActivation ==
                  SmartTileAnimationActivation.onEnter),
    );
  }
}
