import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';
import '../models/geometry.dart';
import '../models/map_layer.dart';
import '../models/smart_tile.dart';
import 'smart_tile_layer_operations.dart';

enum SmartTilePatternSelectionKind { stamp, line, rectangle }

@immutable
final class SmartTilePatternSelection {
  const SmartTilePatternSelection.stamp({required GridPos anchor})
      : kind = SmartTilePatternSelectionKind.stamp,
        start = anchor,
        _end = null;

  const SmartTilePatternSelection.line({
    required this.start,
    required GridPos end,
  })  : kind = SmartTilePatternSelectionKind.line,
        _end = end;

  const SmartTilePatternSelection.rectangle({
    required this.start,
    required GridPos end,
  })  : kind = SmartTilePatternSelectionKind.rectangle,
        _end = end;

  final SmartTilePatternSelectionKind kind;
  final GridPos start;
  final GridPos? _end;

  GridPos? get end => _end;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmartTilePatternSelection &&
          other.kind == kind &&
          other.start == start &&
          other.end == end;

  @override
  int get hashCode => Object.hash(kind, start, end);
}

@immutable
final class SmartTilePatternCollisionUpdate {
  const SmartTilePatternCollisionUpdate({
    required this.cell,
    required this.blocked,
  });

  final GridPos cell;
  final bool blocked;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmartTilePatternCollisionUpdate &&
          other.cell == cell &&
          other.blocked == blocked;

  @override
  int get hashCode => Object.hash(cell, blocked);
}

@immutable
final class SmartTilePatternApplication {
  const SmartTilePatternApplication({
    required this.layer,
    required this.affectedCells,
    required this.collisionUpdates,
  });

  final SmartTileLayer layer;
  final List<GridPos> affectedCells;
  final List<SmartTilePatternCollisionUpdate> collisionUpdates;
}

/// Applies one reusable visual pattern as one ordered, atomic layer stroke.
///
/// Line and rectangle gestures repeat in map space. A stamp expands the whole
/// pattern footprint and aligns its authored anchor with the clicked cell.
SmartTilePatternApplication applySmartTilePatternGesture(
  SmartTileLayer layer, {
  required ProjectSmartTilePattern pattern,
  required GridSize mapSize,
  required SmartTilePatternSelection selection,
  required String strokeId,
  int phaseX = 0,
  int phaseY = 0,
  int maximumCellCount = smartTileMaximumCellsPerGesture,
}) {
  if (strokeId.trim().isEmpty || strokeId != strokeId.trim()) {
    throw const ValidationException(
      'Smart Tile pattern stroke id must be canonical.',
      code: 'smart_tile.pattern.stroke_id_invalid',
    );
  }
  if (pattern.usage != layer.usage) {
    throw const ValidationException(
      'Smart Tile pattern usage must match the target layer.',
      code: 'smart_tile.pattern.usage_mismatch',
    );
  }
  if (pattern.repeatMode == SmartTilePatternRepeatMode.stamp &&
      selection.kind != SmartTilePatternSelectionKind.stamp) {
    throw const ValidationException(
      'This Smart Tile pattern supports stamp placement only.',
      code: 'smart_tile.pattern.stamp_only',
    );
  }
  final compiled = _compileSelection(
    layer,
    pattern: pattern,
    mapSize: mapSize,
    selection: selection,
    maximumCellCount: maximumCellCount,
  );
  final resolvedPhaseX = selection.kind == SmartTilePatternSelectionKind.stamp
      ? pattern.anchorX - selection.start.x + phaseX
      : phaseX;
  final resolvedPhaseY = selection.kind == SmartTilePatternSelectionKind.stamp
      ? pattern.anchorY - selection.start.y + phaseY
      : phaseY;
  final stroke = SmartTilePatternStroke(
    id: strokeId,
    patternId: pattern.id,
    cells: compiled,
    phaseX: resolvedPhaseX,
    phaseY: resolvedPhaseY,
  );
  SmartTileLayer next = layer.copyWith(
    patternStrokes: <SmartTilePatternStroke>[
      for (final existing in layer.patternStrokes)
        if (existing.id != strokeId) existing,
      stroke,
    ],
  );
  final eraseCells = <GridPos>[];
  final collisions = <SmartTilePatternCollisionUpdate>[];
  for (final cell in compiled) {
    final patternCell = smartTilePatternCellAt(
      pattern: pattern,
      stroke: stroke,
      cell: cell,
    );
    if (patternCell == null) continue;
    if (patternCell.eraseMaterial) eraseCells.add(cell);
    switch (patternCell.collision) {
      case SmartTilePatternCollision.inherit:
        break;
      case SmartTilePatternCollision.passable:
        collisions.add(
          SmartTilePatternCollisionUpdate(cell: cell, blocked: false),
        );
      case SmartTilePatternCollision.blocked:
        collisions.add(
          SmartTilePatternCollisionUpdate(cell: cell, blocked: true),
        );
    }
  }
  if (eraseCells.isNotEmpty) {
    next = applySmartTileMaterialGesture(
      next,
      mapSize: mapSize,
      cells: eraseCells,
      materialId: null,
    );
  }
  return SmartTilePatternApplication(
    layer: next,
    affectedCells: compiled,
    collisionUpdates:
        List<SmartTilePatternCollisionUpdate>.unmodifiable(collisions),
  );
}

/// Removes pattern ownership from selected cells without changing materials.
SmartTileLayer eraseSmartTilePatternCells(
  SmartTileLayer layer, {
  required GridSize mapSize,
  required Iterable<GridPos> cells,
}) {
  final removed = <GridPos>{};
  for (final cell in cells) {
    _checkMapCell(cell, mapSize);
    removed.add(cell);
    if (removed.length > smartTileMaximumCellsPerGesture) {
      throw const SmartTileGestureLimitException(
        maximumCellCount: smartTileMaximumCellsPerGesture,
      );
    }
  }
  if (removed.isEmpty) return layer;
  var changed = false;
  final strokes = <SmartTilePatternStroke>[];
  for (final stroke in layer.patternStrokes) {
    final remaining = <GridPos>[
      for (final cell in stroke.cells)
        if (!removed.contains(cell)) cell,
    ];
    if (remaining.length != stroke.cells.length) changed = true;
    if (remaining.isNotEmpty) {
      strokes.add(stroke.copyWith(cells: remaining));
    }
  }
  return changed ? layer.copyWith(patternStrokes: strokes) : layer;
}

/// Resolves the authored pattern cell used by one map cell in a stroke.
SmartTilePatternCell? smartTilePatternCellAt({
  required ProjectSmartTilePattern pattern,
  required SmartTilePatternStroke stroke,
  required GridPos cell,
}) {
  if (stroke.patternId != pattern.id || !stroke.cells.contains(cell)) {
    return null;
  }
  final x = _positiveModulo(cell.x + stroke.phaseX, pattern.width);
  final y = _positiveModulo(cell.y + stroke.phaseY, pattern.height);
  for (final candidate in pattern.cells) {
    if (candidate.x == x && candidate.y == y) return candidate;
  }
  return null;
}

List<GridPos> _compileSelection(
  SmartTileLayer layer, {
  required ProjectSmartTilePattern pattern,
  required GridSize mapSize,
  required SmartTilePatternSelection selection,
  required int maximumCellCount,
}) {
  if (maximumCellCount <= 0) {
    throw const ValidationException(
      'Smart Tile pattern maximumCellCount must be positive.',
    );
  }
  if (selection.kind != SmartTilePatternSelectionKind.stamp) {
    final geometric = switch (selection.kind) {
      SmartTilePatternSelectionKind.line => SmartTileGestureSelection.line(
          start: selection.start,
          end: selection.end!,
        ),
      SmartTilePatternSelectionKind.rectangle =>
        SmartTileGestureSelection.rectangle(
          start: selection.start,
          end: selection.end!,
        ),
      SmartTilePatternSelectionKind.stamp => throw StateError('unreachable'),
    };
    return compileSmartTileGestureSelection(
      layer,
      mapSize: mapSize,
      selection: geometric,
      maximumCellCount: maximumCellCount,
    );
  }
  _checkMapCell(selection.start, mapSize);
  final cells = <GridPos>[];
  for (var patternY = 0; patternY < pattern.height; patternY += 1) {
    for (var patternX = 0; patternX < pattern.width; patternX += 1) {
      final cell = GridPos(
        x: selection.start.x + patternX - pattern.anchorX,
        y: selection.start.y + patternY - pattern.anchorY,
      );
      if (cell.x < 0 ||
          cell.y < 0 ||
          cell.x >= mapSize.width ||
          cell.y >= mapSize.height) {
        continue;
      }
      if (cells.length >= maximumCellCount) {
        throw SmartTileGestureLimitException(
          maximumCellCount: maximumCellCount,
        );
      }
      cells.add(cell);
    }
  }
  return List<GridPos>.unmodifiable(cells);
}

void _checkMapCell(GridPos cell, GridSize size) {
  if (cell.x < 0 ||
      cell.y < 0 ||
      cell.x >= size.width ||
      cell.y >= size.height) {
    throw RangeError('Smart Tile pattern cell is outside the map.');
  }
}

int _positiveModulo(int value, int modulus) {
  final result = value % modulus;
  return result < 0 ? result + modulus : result;
}
