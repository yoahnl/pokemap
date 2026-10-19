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
  }) : kind = SmartTilePatternSelectionKind.line,
       _end = end;

  const SmartTilePatternSelection.rectangle({
    required this.start,
    required GridPos end,
  }) : kind = SmartTilePatternSelectionKind.rectangle,
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
  String? materialId,
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
  if (materialId != null &&
      (materialId.isEmpty || materialId != materialId.trim())) {
    throw const ValidationException(
      'The pattern material must have a canonical non-empty id.',
      code: 'smart_tile.pattern.material_not_allowed',
    );
  }
  validateSmartTilePatternConstruction(pattern);
  if (pattern.construction != null && (phaseX != 0 || phaseY != 0)) {
    throw const ValidationException(
      'Native construction phases are anchored to the complete selection.',
      code: 'smart_tile.pattern.construction_phase_invalid',
    );
  }
  if (pattern.repeatMode == SmartTilePatternRepeatMode.stamp &&
      selection.kind != SmartTilePatternSelectionKind.stamp) {
    throw const ValidationException(
      'This Smart Tile pattern supports stamp placement only.',
      code: 'smart_tile.pattern.stamp_only',
    );
  }
  final construction = pattern.construction == null
      ? null
      : _compileConstructionSelection(
          pattern: pattern,
          mapSize: mapSize,
          selection: selection,
          maximumCellCount: maximumCellCount,
        );
  final compiled =
      construction?.$1 ??
      _compileSelection(
        layer,
        pattern: pattern,
        mapSize: mapSize,
        selection: selection,
        maximumCellCount: maximumCellCount,
      );
  final resolvedPhaseX = construction != null
      ? 0
      : selection.kind == SmartTilePatternSelectionKind.stamp
      ? pattern.anchorX - selection.start.x + phaseX
      : phaseX;
  final resolvedPhaseY = construction != null
      ? 0
      : selection.kind == SmartTilePatternSelectionKind.stamp
      ? pattern.anchorY - selection.start.y + phaseY
      : phaseY;
  final stroke = SmartTilePatternStroke(
    id: strokeId,
    patternId: pattern.id,
    cells: compiled,
    phaseX: resolvedPhaseX,
    phaseY: resolvedPhaseY,
    constructionBounds: construction?.$2,
  );
  SmartTileLayer next = layer.copyWith(
    patternStrokes: <SmartTilePatternStroke>[
      for (final existing in layer.patternStrokes)
        if (existing.id != strokeId) existing,
      stroke,
    ],
  );
  final eraseCells = <GridPos>[];
  final materialCells = <GridPos>[];
  final collisions = <SmartTilePatternCollisionUpdate>[];
  for (final cell in compiled) {
    final patternCell = smartTilePatternCellAt(
      pattern: pattern,
      stroke: stroke,
      cell: cell,
    );
    if (patternCell == null) continue;
    if (patternCell.eraseMaterial) eraseCells.add(cell);
    if (materialId != null &&
        patternCell.parts.isNotEmpty &&
        !patternCell.eraseMaterial) {
      materialCells.add(cell);
    }
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
  if (materialCells.isNotEmpty) {
    next = applySmartTileMaterialGesture(
      next,
      mapSize: mapSize,
      cells: materialCells,
      materialId: materialId,
    );
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
    collisionUpdates: List<SmartTilePatternCollisionUpdate>.unmodifiable(
      collisions,
    ),
  );
}

SmartTileLayer eraseSmartTilePatternCells(
  SmartTileLayer layer, {
  required GridSize mapSize,
  required Iterable<GridPos> cells,
  Iterable<String>? strokeIds,
  bool clearMaterial = false,
}) {
  Set<String>? selectedIds;
  if (strokeIds != null) {
    selectedIds = <String>{};
    final existingIds = layer.patternStrokes.map((stroke) => stroke.id).toSet();
    for (final id in strokeIds) {
      if (id.isEmpty ||
          id.trim() != id ||
          !selectedIds.add(id) ||
          !existingIds.contains(id)) {
        throw const ValidationException(
          'Smart Tile pattern stroke IDs must be unique existing identities.',
        );
      }
    }
    if (selectedIds.isEmpty) {
      throw const ValidationException(
        'Smart Tile pattern stroke IDs cannot be empty.',
      );
    }
  }
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
    if (selectedIds != null && !selectedIds.contains(stroke.id)) {
      strokes.add(stroke);
      continue;
    }
    final remaining = <GridPos>[
      for (final cell in stroke.cells)
        if (!removed.contains(cell)) cell,
    ];
    if (remaining.length != stroke.cells.length) changed = true;
    if (remaining.isNotEmpty) {
      strokes.add(stroke.copyWith(cells: remaining));
    }
  }
  final next = changed ? layer.copyWith(patternStrokes: strokes) : layer;
  if (!clearMaterial) return next;
  final retained = {for (final stroke in next.patternStrokes) ...stroke.cells};
  return applySmartTileMaterialGesture(
    next,
    mapSize: mapSize,
    cells: removed.where((cell) => !retained.contains(cell)),
    materialId: null,
  );
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
  final construction = pattern.construction;
  final bounds = stroke.constructionBounds;
  if (construction != null && bounds == null) {
    throw const ValidationException(
      'Native construction requires its original rectangle.',
      code: 'smart_tile.pattern.construction_bounds_missing',
    );
  }
  final x = construction == null
      ? _positiveModulo(cell.x + stroke.phaseX, pattern.width)
      : construction.x?.sourceIndex(
              position: cell.x - bounds!.pos.x,
              sourceLength: pattern.width,
              outputLength: bounds.size.width,
            ) ??
            cell.x - bounds!.pos.x;
  final y = construction == null
      ? _positiveModulo(cell.y + stroke.phaseY, pattern.height)
      : construction.y?.sourceIndex(
              position: cell.y - bounds!.pos.y,
              sourceLength: pattern.height,
              outputLength: bounds.size.height,
            ) ??
            cell.y - bounds!.pos.y;
  for (final candidate in pattern.cells) {
    if (candidate.x == x && candidate.y == y) return candidate;
  }
  return null;
}

void validateSmartTilePatternConstruction(ProjectSmartTilePattern pattern) {
  final construction = pattern.construction;
  if (construction == null) return;
  construction.validateSource(width: pattern.width, height: pattern.height);
  if (pattern.repeatMode != SmartTilePatternRepeatMode.tiled ||
      pattern.cells.any(
        (cell) =>
            cell.parts.any((part) => part.source is SmartTileModel3dSource),
      )) {
    throw const ValidationException(
      'Native constructions require tiled 2D source patterns.',
      code: 'smart_tile.pattern.construction_definition_invalid',
    );
  }
}

void validateSmartTilePatternConstructionStroke({
  required ProjectSmartTilePattern pattern,
  required SmartTilePatternStroke stroke,
}) {
  validateSmartTilePatternConstruction(pattern);
  final construction = pattern.construction;
  final bounds = stroke.constructionBounds;
  if (construction == null) {
    if (bounds != null) {
      throw const ValidationException(
        'Ordinary pattern strokes cannot carry construction bounds.',
        code: 'smart_tile.pattern.construction_bounds_unexpected',
      );
    }
    return;
  }
  if (bounds == null) {
    throw const ValidationException(
      'Native construction requires its original rectangle.',
      code: 'smart_tile.pattern.construction_bounds_missing',
    );
  }
  construction.validateSize(
    sourceWidth: pattern.width,
    sourceHeight: pattern.height,
    width: bounds.size.width,
    height: bounds.size.height,
  );
  if (stroke.phaseX != 0 ||
      stroke.phaseY != 0 ||
      stroke.cells.any(
        (cell) =>
            cell.x < bounds.pos.x ||
            cell.y < bounds.pos.y ||
            cell.x >= bounds.pos.x + bounds.size.width ||
            cell.y >= bounds.pos.y + bounds.size.height,
      )) {
    throw const ValidationException(
      'Native construction ownership and phase must remain inside its original rectangle.',
      code: 'smart_tile.pattern.construction_bounds_invalid',
    );
  }
}

(List<GridPos>, MapRect) _compileConstructionSelection({
  required ProjectSmartTilePattern pattern,
  required GridSize mapSize,
  required SmartTilePatternSelection selection,
  required int maximumCellCount,
}) {
  final construction = pattern.construction!;
  final start = selection.start;
  final end = selection.end ?? start;
  var left = start.x < end.x ? start.x : end.x;
  var top = start.y < end.y ? start.y : end.y;
  var width = (start.x - end.x).abs() + 1;
  var height = (start.y - end.y).abs() + 1;
  switch (selection.kind) {
    case SmartTilePatternSelectionKind.rectangle:
      break;
    case SmartTilePatternSelectionKind.stamp:
      left -= pattern.anchorX;
      top -= pattern.anchorY;
      width = construction.x?.minimumLength(pattern.width) ?? pattern.width;
      height = construction.y?.minimumLength(pattern.height) ?? pattern.height;
      break;
    case SmartTilePatternSelectionKind.line:
      if (construction.x == null && start.x == end.x) {
        left -= pattern.anchorX;
        width = pattern.width;
      } else if (construction.y == null && start.y == end.y) {
        top -= pattern.anchorY;
        height = pattern.height;
      } else {
        throw const ValidationException(
          'Native construction lines must follow the repeated axis with a fixed complete cross-section.',
          code: 'smart_tile.pattern.construction_line_invalid',
        );
      }
      break;
  }
  construction.validateSize(
    sourceWidth: pattern.width,
    sourceHeight: pattern.height,
    width: width,
    height: height,
  );
  if (maximumCellCount <= 0) {
    throw const ValidationException(
      'Smart Tile pattern maximumCellCount must be positive.',
    );
  }
  if (width * height > maximumCellCount) {
    throw SmartTileGestureLimitException(maximumCellCount: maximumCellCount);
  }
  if (left < 0 ||
      top < 0 ||
      left + width > mapSize.width ||
      top + height > mapSize.height) {
    throw const ValidationException(
      'The complete native construction must fit inside the map.',
      code: 'smart_tile.pattern.construction_out_of_bounds',
    );
  }
  return (
    List<GridPos>.unmodifiable([
      for (var y = top; y < top + height; y++)
        for (var x = left; x < left + width; x++) GridPos(x: x, y: y),
    ]),
    MapRect(
      pos: GridPos(x: left, y: top),
      size: GridSize(width: width, height: height),
    ),
  );
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
  if (pattern.clippingPolicy == SmartTilePatternClippingPolicy.reject &&
      (selection.start.x - pattern.anchorX < 0 ||
          selection.start.y - pattern.anchorY < 0 ||
          selection.start.x - pattern.anchorX + pattern.width > mapSize.width ||
          selection.start.y - pattern.anchorY + pattern.height >
              mapSize.height)) {
    throw const ValidationException(
      'The entire anchored pattern must fit inside the map.',
      code: 'smart_tile.pattern.stamp_out_of_bounds',
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
