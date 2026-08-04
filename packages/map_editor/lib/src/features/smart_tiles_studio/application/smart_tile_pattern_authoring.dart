import 'dart:math' as math;

import 'package:map_core/map_core.dart';

final class SmartTilePatternAuthoringException implements Exception {
  const SmartTilePatternAuthoringException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'SmartTilePatternAuthoringException($code): $message';
}

final class SmartTilePatternAtlasSelection {
  const SmartTilePatternAtlasSelection({
    required this.startColumn,
    required this.startRow,
    required this.endColumn,
    required this.endRow,
  });

  final int startColumn;
  final int startRow;
  final int endColumn;
  final int endRow;

  int get left => math.min(startColumn, endColumn);
  int get right => math.max(startColumn, endColumn);
  int get top => math.min(startRow, endRow);
  int get bottom => math.max(startRow, endRow);
  int get width => right - left + 1;
  int get height => bottom - top + 1;

  bool contains({required int column, required int row}) =>
      column >= left && column <= right && row >= top && row <= bottom;
}

final class SmartTilePatternAtlasProjection {
  const SmartTilePatternAtlasProjection({
    required this.atlasId,
    required this.selection,
    required this.anchorColumn,
    required this.anchorRow,
  });

  final String atlasId;
  final SmartTilePatternAtlasSelection selection;
  final int anchorColumn;
  final int anchorRow;
}

ProjectSmartTilePattern compileSmartTileAtlasPattern({
  required String id,
  required String name,
  required SmartTileUsage usage,
  required ProjectSmartTileAtlas atlas,
  required SmartTilePatternAtlasSelection selection,
  required int anchorColumn,
  required int anchorRow,
  required SmartTilePatternRepeatMode repeatMode,
  String categoryId = '',
  int drawOrder = 0,
  List<String> tags = const <String>[],
  int sortOrder = 0,
}) {
  final normalizedId = id.trim();
  final normalizedName = name.trim();
  if (normalizedId.isEmpty) {
    throw const SmartTilePatternAuthoringException(
      'smart_tile.pattern.id_blank',
      'Le motif doit posséder un identifiant interne.',
    );
  }
  if (normalizedName.isEmpty) {
    throw const SmartTilePatternAuthoringException(
      'smart_tile.pattern.name_blank',
      'Donnez un nom au motif.',
    );
  }
  if (selection.left < 0 ||
      selection.top < 0 ||
      selection.right >= atlas.columns ||
      selection.bottom >= atlas.rows) {
    throw const SmartTilePatternAuthoringException(
      'smart_tile.pattern.selection_outside_atlas',
      'La zone sélectionnée dépasse les limites de l’atlas.',
    );
  }
  if (selection.width > 64 || selection.height > 64) {
    throw const SmartTilePatternAuthoringException(
      'smart_tile.pattern.selection_too_large',
      'Un motif ne peut pas dépasser 64 × 64 cellules.',
    );
  }
  if (!selection.contains(column: anchorColumn, row: anchorRow)) {
    throw const SmartTilePatternAuthoringException(
      'smart_tile.pattern.anchor_outside_selection',
      'L’ancrage doit se trouver dans la zone sélectionnée.',
    );
  }

  return ProjectSmartTilePattern(
    id: normalizedId,
    name: normalizedName,
    categoryId: categoryId,
    usage: usage,
    width: selection.width,
    height: selection.height,
    anchorX: anchorColumn - selection.left,
    anchorY: anchorRow - selection.top,
    repeatMode: repeatMode,
    drawOrder: drawOrder,
    tags: List<String>.unmodifiable(tags),
    sortOrder: sortOrder,
    cells: <SmartTilePatternCell>[
      for (var row = selection.top; row <= selection.bottom; row++)
        for (var column = selection.left; column <= selection.right; column++)
          SmartTilePatternCell(
            x: column - selection.left,
            y: row - selection.top,
            parts: <SmartTileVisualPart>[
              SmartTileVisualPart(
                source: SmartTileVisualSource.frame(
                  frame: SmartTileFrameRef(
                    atlasId: atlas.id,
                    column: column,
                    row: row,
                  ),
                ),
              ),
            ],
          ),
    ],
  );
}

SmartTilePatternAtlasProjection? projectSmartTilePatternAtlasSelection(
  ProjectSmartTilePattern pattern,
) {
  if (pattern.cells.length != pattern.width * pattern.height) return null;
  String? atlasId;
  int? left;
  int? top;
  for (final cell in pattern.cells) {
    if (cell.eraseMaterial ||
        cell.collision != SmartTilePatternCollision.inherit ||
        cell.parts.length != 1) {
      return null;
    }
    final part = cell.parts.single;
    if (part.channel != SmartTileRenderChannel.ground ||
        part.transform != const SmartTileSpriteTransform() ||
        part.offsetX != 0 ||
        part.offsetY != 0 ||
        part.footprintWidth != 1 ||
        part.footprintHeight != 1 ||
        part.anchorX != 0 ||
        part.anchorY != 0 ||
        part.drawOrder != 0 ||
        part.source is! SmartTileFrameSource) {
      return null;
    }
    final frame = (part.source as SmartTileFrameSource).frame;
    if (frame.columnSpan != 1 || frame.rowSpan != 1) return null;
    atlasId ??= frame.atlasId;
    if (atlasId != frame.atlasId) return null;
    left ??= frame.column - cell.x;
    top ??= frame.row - cell.y;
    if (frame.column != left + cell.x || frame.row != top + cell.y) {
      return null;
    }
  }
  if (atlasId == null || left == null || top == null) return null;
  return SmartTilePatternAtlasProjection(
    atlasId: atlasId,
    selection: SmartTilePatternAtlasSelection(
      startColumn: left,
      startRow: top,
      endColumn: left + pattern.width - 1,
      endRow: top + pattern.height - 1,
    ),
    anchorColumn: left + pattern.anchorX,
    anchorRow: top + pattern.anchorY,
  );
}
