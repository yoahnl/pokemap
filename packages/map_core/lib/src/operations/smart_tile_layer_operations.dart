import '../exceptions/map_exceptions.dart';
import '../models/enums.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/smart_tile.dart';
import '../models/smart_tile_field.dart';

/// Map-only creation cannot atomically update the v5 manifest catalog.
MapData addSmartTileLayer(
  MapData map, {
  required String id,
  required String name,
  required String presetId,
  required SmartTileUsage usage,
  required String defaultMaterialId,
  int layerSeed = 0,
  int? insertIndex,
}) {
  throw const ValidationException(
    'Use the canonical smart_tile.layer.create authoring action',
    code: 'smart_tile_canonical_layer_action_required',
  );
}

List<int> smartTileSemanticCells(SmartTileLayer layer) => switch (layer.field) {
  SmartTileCellField(:final semanticCells) => semanticCells,
  SmartTileCornerField(:final semanticCells) => semanticCells,
  SmartTileEdgeField(:final semanticCells) => semanticCells,
  SmartTileMixedField(:final semanticCells) => semanticCells,
};

List<int> smartTileHorizontalEdges(SmartTileLayer layer) =>
    switch (layer.field) {
      SmartTileEdgeField(:final horizontalEdges) => horizontalEdges,
      SmartTileMixedField(:final horizontalEdges) => horizontalEdges,
      SmartTileCellField() || SmartTileCornerField() => const <int>[],
    };

List<int> smartTileVerticalEdges(SmartTileLayer layer) => switch (layer.field) {
  SmartTileEdgeField(:final verticalEdges) => verticalEdges,
  SmartTileMixedField(:final verticalEdges) => verticalEdges,
  SmartTileCellField() || SmartTileCornerField() => const <int>[],
};

List<int> smartTileCorners(SmartTileLayer layer) => switch (layer.field) {
  SmartTileCornerField(:final corners) => corners,
  SmartTileMixedField(:final corners) => corners,
  SmartTileCellField() || SmartTileEdgeField() => const <int>[],
};

/// Safety boundary for one explicit or persisted Smart Tile cell list.
const int smartTileMaximumCellsPerGesture = 4096;

enum SmartTileGestureSelectionKind { line, rectangle, floodFill }

/// A no-code geometric selection compiled to canonical Smart Tile cells.
final class SmartTileGestureSelection {
  const SmartTileGestureSelection.line({
    required this.start,
    required GridPos end,
  }) : kind = SmartTileGestureSelectionKind.line,
       // Keep the public constructor non-nullable while floodFill owns null.
       // ignore: prefer_initializing_formals
       end = end;

  const SmartTileGestureSelection.rectangle({
    required this.start,
    required GridPos end,
  }) : kind = SmartTileGestureSelectionKind.rectangle,
       // Keep the public constructor non-nullable while floodFill owns null.
       // ignore: prefer_initializing_formals
       end = end;

  const SmartTileGestureSelection.floodFill({required GridPos seed})
    : kind = SmartTileGestureSelectionKind.floodFill,
      start = seed,
      end = null;

  final SmartTileGestureSelectionKind kind;
  final GridPos start;
  final GridPos? end;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmartTileGestureSelection &&
          kind == other.kind &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => Object.hash(kind, start, end);
}

/// Raised before a geometric gesture can exceed its atomic safety boundary.
final class SmartTileGestureLimitException implements Exception {
  const SmartTileGestureLimitException({required this.maximumCellCount});

  final int maximumCellCount;

  @override
  String toString() => 'Smart Tile gesture exceeds $maximumCellCount cells.';
}

/// Compiles a line, filled rectangle, or semantic flood fill to map cells.
///
/// Results are unique and sorted in row-major order so direct Dart, JSONL,
/// editor, and MCP callers all submit the same deterministic gesture.
List<GridPos> compileSmartTileGestureSelection(
  SmartTileLayer layer, {
  required GridSize mapSize,
  required SmartTileGestureSelection selection,
  int? maximumCellCount,
}) {
  final resolvedMaximumCellCount =
      maximumCellCount ?? mapSize.width * mapSize.height;
  if (resolvedMaximumCellCount <= 0) {
    throw const ValidationException(
      'Smart Tile gesture maximumCellCount must be positive',
    );
  }
  _checkCoordinate(
    selection.start.x,
    selection.start.y,
    mapSize.width,
    mapSize.height,
    'gesture start',
  );
  final end = selection.end;
  if (end != null) {
    _checkCoordinate(
      end.x,
      end.y,
      mapSize.width,
      mapSize.height,
      'gesture end',
    );
  }

  final cells = switch (selection.kind) {
    SmartTileGestureSelectionKind.line => _smartTileLineCells(
      selection.start,
      end!,
      maximumCellCount: resolvedMaximumCellCount,
    ),
    SmartTileGestureSelectionKind.rectangle => _smartTileRectangleCells(
      selection.start,
      end!,
      maximumCellCount: resolvedMaximumCellCount,
    ),
    SmartTileGestureSelectionKind.floodFill => _smartTileFloodFillCells(
      layer,
      mapSize: mapSize,
      seed: selection.start,
      maximumCellCount: resolvedMaximumCellCount,
    ),
  };
  cells.sort(_compareGridPositions);
  return List<GridPos>.unmodifiable(cells);
}

List<GridPos> _smartTileLineCells(
  GridPos start,
  GridPos end, {
  required int maximumCellCount,
}) {
  // Canonical endpoint ordering removes Bresenham tie ambiguity: dragging the
  // same segment in the opposite direction must select the exact same cells.
  final lineStart = _compareGridPositions(start, end) <= 0 ? start : end;
  final lineEnd = identical(lineStart, start) ? end : start;
  var x = lineStart.x;
  var y = lineStart.y;
  final dx = (lineEnd.x - lineStart.x).abs();
  final dy = (lineEnd.y - lineStart.y).abs();
  final stepX = lineStart.x < lineEnd.x ? 1 : -1;
  final stepY = lineStart.y < lineEnd.y ? 1 : -1;
  final cells = <GridPos>[];

  if (dx >= dy) {
    var error = dx ~/ 2;
    while (true) {
      _addBoundedGestureCell(cells, GridPos(x: x, y: y), maximumCellCount);
      if (x == lineEnd.x) break;
      x += stepX;
      error -= dy;
      if (error < 0) {
        y += stepY;
        error += dx;
      }
    }
  } else {
    var error = dy ~/ 2;
    while (true) {
      _addBoundedGestureCell(cells, GridPos(x: x, y: y), maximumCellCount);
      if (y == lineEnd.y) break;
      y += stepY;
      error -= dx;
      if (error < 0) {
        x += stepX;
        error += dy;
      }
    }
  }
  return cells;
}

List<GridPos> _smartTileRectangleCells(
  GridPos start,
  GridPos end, {
  required int maximumCellCount,
}) {
  final left = start.x < end.x ? start.x : end.x;
  final right = start.x > end.x ? start.x : end.x;
  final top = start.y < end.y ? start.y : end.y;
  final bottom = start.y > end.y ? start.y : end.y;
  final cellCount = (right - left + 1) * (bottom - top + 1);
  if (cellCount > maximumCellCount) {
    throw SmartTileGestureLimitException(maximumCellCount: maximumCellCount);
  }
  return <GridPos>[
    for (var y = top; y <= bottom; y++)
      for (var x = left; x <= right; x++) GridPos(x: x, y: y),
  ];
}

List<GridPos> _smartTileFloodFillCells(
  SmartTileLayer layer, {
  required GridSize mapSize,
  required GridPos seed,
  required int maximumCellCount,
}) {
  final semanticCells = smartTileSemanticCells(layer);
  final seedIndex = seed.y * mapSize.width + seed.x;
  final targetMaterialIndex = semanticCells[seedIndex];
  final visited = List<bool>.filled(semanticCells.length, false);
  final queue = <int>[seedIndex];
  visited[seedIndex] = true;
  final cells = <GridPos>[];
  var cursor = 0;

  void enqueue(int x, int y) {
    if (x < 0 || y < 0 || x >= mapSize.width || y >= mapSize.height) return;
    final index = y * mapSize.width + x;
    if (visited[index] || semanticCells[index] != targetMaterialIndex) return;
    visited[index] = true;
    queue.add(index);
  }

  while (cursor < queue.length) {
    final index = queue[cursor++];
    final x = index % mapSize.width;
    final y = index ~/ mapSize.width;
    _addBoundedGestureCell(cells, GridPos(x: x, y: y), maximumCellCount);
    enqueue(x, y - 1);
    enqueue(x + 1, y);
    enqueue(x, y + 1);
    enqueue(x - 1, y);
  }
  return cells;
}

void _addBoundedGestureCell(
  List<GridPos> cells,
  GridPos cell,
  int maximumCellCount,
) {
  if (cells.length >= maximumCellCount) {
    throw SmartTileGestureLimitException(maximumCellCount: maximumCellCount);
  }
  cells.add(cell);
}

int _compareGridPositions(GridPos left, GridPos right) {
  final byY = left.y.compareTo(right.y);
  return byY != 0 ? byY : left.x.compareTo(right.x);
}

/// Counts authored palette references across every active native lattice.
int smartTileAuthoredValueCount(SmartTileLayer layer) =>
    <List<int>>[
      smartTileSemanticCells(layer),
      smartTileHorizontalEdges(layer),
      smartTileVerticalEdges(layer),
      smartTileCorners(layer),
    ].fold<int>(
      0,
      (total, values) =>
          total + values.where((materialIndex) => materialIndex != 0).length,
    );

/// Whether a map cell is touched by semantic, edge, or corner authored data.
///
/// Edge and corner fields live between cells. A cell therefore owns the two
/// horizontal edges, two vertical edges, and four corners surrounding it.
bool smartTileCellHasAuthoredValue(
  SmartTileLayer layer, {
  required GridSize mapSize,
  required int x,
  required int y,
}) {
  _checkCoordinate(x, y, mapSize.width, mapSize.height, 'cell');
  final semantic = smartTileSemanticCells(layer);
  if (_isAuthoredAt(semantic, y * mapSize.width + x)) return true;

  final horizontal = smartTileHorizontalEdges(layer);
  if (_isAuthoredAt(horizontal, y * mapSize.width + x) ||
      _isAuthoredAt(horizontal, (y + 1) * mapSize.width + x)) {
    return true;
  }

  final vertical = smartTileVerticalEdges(layer);
  final verticalStride = mapSize.width + 1;
  if (_isAuthoredAt(vertical, y * verticalStride + x) ||
      _isAuthoredAt(vertical, y * verticalStride + x + 1)) {
    return true;
  }

  final corners = smartTileCorners(layer);
  final cornerStride = mapSize.width + 1;
  return _isAuthoredAt(corners, y * cornerStride + x) ||
      _isAuthoredAt(corners, y * cornerStride + x + 1) ||
      _isAuthoredAt(corners, (y + 1) * cornerStride + x) ||
      _isAuthoredAt(corners, (y + 1) * cornerStride + x + 1);
}

bool _isAuthoredAt(List<int> values, int index) =>
    index >= 0 && index < values.length && values[index] != 0;

String? smartTileMaterialIdAt(
  SmartTileLayer layer, {
  required GridSize mapSize,
  required int x,
  required int y,
}) {
  _checkCoordinate(x, y, mapSize.width, mapSize.height, 'cell');
  return _materialIdForIndex(
    layer,
    smartTileSemanticCells(layer)[y * mapSize.width + x],
  );
}

String? smartTileHorizontalEdgeMaterialIdAt(
  SmartTileLayer layer, {
  required GridSize mapSize,
  required int x,
  required int y,
}) {
  _checkCoordinate(x, y, mapSize.width, mapSize.height + 1, 'horizontal edge');
  return _materialIdForIndex(
    layer,
    smartTileHorizontalEdges(layer)[y * mapSize.width + x],
  );
}

String? smartTileVerticalEdgeMaterialIdAt(
  SmartTileLayer layer, {
  required GridSize mapSize,
  required int x,
  required int y,
}) {
  _checkCoordinate(x, y, mapSize.width + 1, mapSize.height, 'vertical edge');
  return _materialIdForIndex(
    layer,
    smartTileVerticalEdges(layer)[y * (mapSize.width + 1) + x],
  );
}

String? smartTileCornerMaterialIdAt(
  SmartTileLayer layer, {
  required GridSize mapSize,
  required int x,
  required int y,
}) {
  _checkCoordinate(x, y, mapSize.width + 1, mapSize.height + 1, 'corner');
  return _materialIdForIndex(
    layer,
    smartTileCorners(layer)[y * (mapSize.width + 1) + x],
  );
}

SmartTileLayer setSmartTileCellMaterial(
  SmartTileLayer layer, {
  required GridSize mapSize,
  required int x,
  required int y,
  required String? materialId,
}) {
  _checkCoordinate(x, y, mapSize.width, mapSize.height, 'cell');
  final interned = _internMaterial(layer, materialId);
  final values = List<int>.of(smartTileSemanticCells(layer));
  values[y * mapSize.width + x] = interned.index;
  return layer.copyWith(
    materialPalette: interned.palette,
    field: _withSemanticCells(layer.field, values),
  );
}

SmartTileLayer setSmartTileHorizontalEdgeMaterial(
  SmartTileLayer layer, {
  required GridSize mapSize,
  required int x,
  required int y,
  required String? materialId,
}) {
  _checkCoordinate(x, y, mapSize.width, mapSize.height + 1, 'horizontal edge');
  final interned = _internMaterial(layer, materialId);
  final values = List<int>.of(smartTileHorizontalEdges(layer));
  if (values.isEmpty) {
    throw const ValidationException(
      'Smart Tile field has no horizontal edge lattice',
    );
  }
  values[y * mapSize.width + x] = interned.index;
  return layer.copyWith(
    materialPalette: interned.palette,
    field: _withHorizontalEdges(layer.field, values),
  );
}

SmartTileLayer setSmartTileVerticalEdgeMaterial(
  SmartTileLayer layer, {
  required GridSize mapSize,
  required int x,
  required int y,
  required String? materialId,
}) {
  _checkCoordinate(x, y, mapSize.width + 1, mapSize.height, 'vertical edge');
  final interned = _internMaterial(layer, materialId);
  final values = List<int>.of(smartTileVerticalEdges(layer));
  if (values.isEmpty) {
    throw const ValidationException(
      'Smart Tile field has no vertical edge lattice',
    );
  }
  values[y * (mapSize.width + 1) + x] = interned.index;
  return layer.copyWith(
    materialPalette: interned.palette,
    field: _withVerticalEdges(layer.field, values),
  );
}

SmartTileLayer setSmartTileCornerMaterial(
  SmartTileLayer layer, {
  required GridSize mapSize,
  required int x,
  required int y,
  required String? materialId,
}) {
  _checkCoordinate(x, y, mapSize.width + 1, mapSize.height + 1, 'corner');
  final interned = _internMaterial(layer, materialId);
  final values = List<int>.of(smartTileCorners(layer));
  if (values.isEmpty) {
    throw const ValidationException('Smart Tile field has no corner lattice');
  }
  values[y * (mapSize.width + 1) + x] = interned.index;
  return layer.copyWith(
    materialPalette: interned.palette,
    field: _withCorners(layer.field, values),
  );
}

/// Projects one map-cell brush gesture onto every lattice owned by the field.
///
/// Each touched cell receives the material in `semanticCells`. Edge fields also
/// receive it on the north, east, south, and west edges; corner fields receive
/// it on their four corners; mixed fields receive all eight Wang slots. Shared
/// slots and duplicate cells are written once, making a gesture independent of
/// input order. Passing `null` or an empty material erases the same footprint.
SmartTileLayer applySmartTileMaterialGesture(
  SmartTileLayer layer, {
  required GridSize mapSize,
  required Iterable<GridPos> cells,
  required String? materialId,
}) {
  final cellIndices = <int>{};
  final horizontalEdgeIndices = <int>{};
  final verticalEdgeIndices = <int>{};
  final cornerIndices = <int>{};
  final hasEdges =
      layer.field is SmartTileEdgeField || layer.field is SmartTileMixedField;
  final hasCorners =
      layer.field is SmartTileCornerField || layer.field is SmartTileMixedField;
  final verticalStride = mapSize.width + 1;

  for (final cell in cells) {
    _checkCoordinate(cell.x, cell.y, mapSize.width, mapSize.height, 'cell');
    cellIndices.add(cell.y * mapSize.width + cell.x);
    if (hasEdges) {
      horizontalEdgeIndices
        ..add(cell.y * mapSize.width + cell.x)
        ..add((cell.y + 1) * mapSize.width + cell.x);
      verticalEdgeIndices
        ..add(cell.y * verticalStride + cell.x)
        ..add(cell.y * verticalStride + cell.x + 1);
    }
    if (hasCorners) {
      cornerIndices
        ..add(cell.y * verticalStride + cell.x)
        ..add(cell.y * verticalStride + cell.x + 1)
        ..add((cell.y + 1) * verticalStride + cell.x)
        ..add((cell.y + 1) * verticalStride + cell.x + 1);
    }
  }
  if (cellIndices.isEmpty) return layer;

  final interned = _internMaterial(layer, materialId);
  final semanticCells = List<int>.of(smartTileSemanticCells(layer));
  for (final index in cellIndices) {
    semanticCells[index] = interned.index;
  }

  final field = switch (layer.field) {
    SmartTileCellField() => SmartTileField.cell(semanticCells: semanticCells),
    SmartTileEdgeField(:final horizontalEdges, :final verticalEdges) => () {
      final nextHorizontalEdges = List<int>.of(horizontalEdges);
      final nextVerticalEdges = List<int>.of(verticalEdges);
      for (final index in horizontalEdgeIndices) {
        nextHorizontalEdges[index] = interned.index;
      }
      for (final index in verticalEdgeIndices) {
        nextVerticalEdges[index] = interned.index;
      }
      return SmartTileField.edge(
        semanticCells: semanticCells,
        horizontalEdges: nextHorizontalEdges,
        verticalEdges: nextVerticalEdges,
      );
    }(),
    SmartTileCornerField(:final corners) => () {
      final nextCorners = List<int>.of(corners);
      for (final index in cornerIndices) {
        nextCorners[index] = interned.index;
      }
      return SmartTileField.corner(
        semanticCells: semanticCells,
        corners: nextCorners,
      );
    }(),
    SmartTileMixedField(
      :final horizontalEdges,
      :final verticalEdges,
      :final corners,
    ) =>
      () {
        final nextHorizontalEdges = List<int>.of(horizontalEdges);
        final nextVerticalEdges = List<int>.of(verticalEdges);
        final nextCorners = List<int>.of(corners);
        for (final index in horizontalEdgeIndices) {
          nextHorizontalEdges[index] = interned.index;
        }
        for (final index in verticalEdgeIndices) {
          nextVerticalEdges[index] = interned.index;
        }
        for (final index in cornerIndices) {
          nextCorners[index] = interned.index;
        }
        return SmartTileField.mixed(
          semanticCells: semanticCells,
          horizontalEdges: nextHorizontalEdges,
          verticalEdges: nextVerticalEdges,
          corners: nextCorners,
        );
      }(),
  };

  return layer.copyWith(materialPalette: interned.palette, field: field);
}

MapData replaceSmartTileLayer(MapData map, {required SmartTileLayer layer}) {
  // Replacement is deliberately map-only: it may maintain an already-native
  // v6 layer, but it must never manufacture the project-wide v6 transition
  // owned by the canonical authoring action together with the manifest.
  if (map.version != ProjectVersion.v6) {
    throw const ValidationException(
      'Native Smart Tile replacement requires a ProjectVersion.v6 map',
      code: 'smart_tile_native_project_version_required',
    );
  }
  final index = map.layers.indexWhere((candidate) => candidate.id == layer.id);
  if (index < 0) {
    throw ValidationException('Layer not found: ${layer.id}');
  }
  if (map.layers[index] is! SmartTileLayer) {
    throw ValidationException('Layer is not a Smart Tile layer: ${layer.id}');
  }
  final layers = List<MapLayer>.of(map.layers)..[index] = layer;
  return map.copyWith(layers: layers);
}

final class SmartTileRemovedPaletteEntry {
  const SmartTileRemovedPaletteEntry({
    required this.materialId,
    required this.oldIndex,
  });

  final String materialId;
  final int oldIndex;

  Map<String, Object?> toJson() => <String, Object?>{
    'materialId': materialId,
    'oldIndex': oldIndex,
  };
}

final class SmartTileLayerNormalizationResult {
  SmartTileLayerNormalizationResult({
    required this.layer,
    required Iterable<SmartTileRemovedPaletteEntry> removedPaletteEntries,
    required Map<String, int> reindexedEntryCounts,
  }) : removedPaletteEntries = List.unmodifiable(removedPaletteEntries),
       reindexedEntryCounts = Map.unmodifiable(reindexedEntryCounts);

  final SmartTileLayer layer;
  final List<SmartTileRemovedPaletteEntry> removedPaletteEntries;
  final Map<String, int> reindexedEntryCounts;

  int get reindexedEntryCount =>
      reindexedEntryCounts.values.fold(0, (sum, value) => sum + value);
}

final class SmartTileLayerUnionResult {
  SmartTileLayerUnionResult({
    required this.layer,
    required Map<String, int> mergedEntryCounts,
  }) : mergedEntryCounts = Map.unmodifiable(mergedEntryCounts);

  final SmartTileLayer layer;
  final Map<String, int> mergedEntryCounts;

  int get mergedEntryCount =>
      mergedEntryCounts.values.fold(0, (sum, value) => sum + value);
}

SmartTileLayerNormalizationResult normalizeSmartTileLayer(
  SmartTileLayer layer,
) {
  final palette = layer.materialPalette;
  if (palette.isEmpty || palette.first.isNotEmpty) {
    throw const ValidationException(
      'Smart Tile materialPalette must start with the empty material',
    );
  }
  final lattices = _activeLattices(layer);
  final usedIndices = <int>{0};
  for (final entry in lattices.entries) {
    for (var offset = 0; offset < entry.value.length; offset++) {
      final index = entry.value[offset];
      if (index < 0 || index >= palette.length) {
        throw ValidationException(
          'Smart Tile ${entry.key}[$offset] references invalid material '
          'palette index $index',
        );
      }
      usedIndices.add(index);
    }
  }
  final behaviorMaterialId = layer.encounterBehavior?.materialId.trim();
  if (behaviorMaterialId != null && behaviorMaterialId.isNotEmpty) {
    final behaviorPaletteIndex = palette.indexOf(behaviorMaterialId);
    if (behaviorPaletteIndex <= 0) {
      throw ValidationException(
        'Smart Tile encounter behavior references unknown material '
        '"$behaviorMaterialId"',
        code: 'smart_tile_encounter_material_unknown',
      );
    }
    usedIndices.add(behaviorPaletteIndex);
  }

  final normalizedPalette = <String>[''];
  final normalizedIndexByMaterial = <String, int>{};
  final oldToNew = <int, int>{0: 0};
  final retainedOldIndices = <int>{0};
  for (var oldIndex = 1; oldIndex < palette.length; oldIndex++) {
    if (!usedIndices.contains(oldIndex)) continue;
    final materialId = palette[oldIndex];
    if (materialId.trim().isEmpty) {
      throw ValidationException(
        'Smart Tile palette index $oldIndex resolves to an empty material',
      );
    }
    final existing = normalizedIndexByMaterial[materialId];
    if (existing != null) {
      oldToNew[oldIndex] = existing;
      continue;
    }
    final newIndex = normalizedPalette.length;
    normalizedPalette.add(materialId);
    normalizedIndexByMaterial[materialId] = newIndex;
    oldToNew[oldIndex] = newIndex;
    retainedOldIndices.add(oldIndex);
  }

  final reindexed = <String, List<int>>{
    for (final entry in lattices.entries)
      entry.key: <int>[for (final index in entry.value) oldToNew[index]!],
  };
  int changedCount(List<int> before, List<int> after) {
    var count = 0;
    for (var index = 0; index < before.length; index++) {
      if (before[index] != after[index]) count++;
    }
    return count;
  }

  return SmartTileLayerNormalizationResult(
    layer: layer.copyWith(
      materialPalette: List.unmodifiable(normalizedPalette),
      field: _fieldFromLattices(layer.field, reindexed),
    ),
    removedPaletteEntries: <SmartTileRemovedPaletteEntry>[
      for (var oldIndex = 1; oldIndex < palette.length; oldIndex++)
        if (!retainedOldIndices.contains(oldIndex))
          SmartTileRemovedPaletteEntry(
            materialId: palette[oldIndex],
            oldIndex: oldIndex,
          ),
    ],
    reindexedEntryCounts: <String, int>{
      for (final entry in lattices.entries)
        entry.key: changedCount(entry.value, reindexed[entry.key]!),
    },
  );
}

SmartTileLayerUnionResult unionSmartTileLayers({
  required SmartTileLayer target,
  required Iterable<SmartTileLayer> sources,
  Map<String, Map<String, String>> materialMappings = const {},
}) {
  final normalizedTarget = normalizeSmartTileLayer(target).layer;
  final normalizedSources = <SmartTileLayer>[
    for (final source in sources) normalizeSmartTileLayer(source).layer,
  ];
  final targetLattices = _activeLattices(normalizedTarget);
  for (final source in normalizedSources) {
    if (source.encounterBehavior != normalizedTarget.encounterBehavior) {
      throw ValidationException(
        'Smart Tile source ${source.id} has an incompatible encounter '
        'behavior',
        code: 'smart_tile.layer_merge_encounter_behavior_conflict',
        details: <String, Object?>{
          'targetLayerId': normalizedTarget.id,
          'sourceLayerId': source.id,
        },
      );
    }
    if (source.usage != normalizedTarget.usage) {
      throw ValidationException(
        'Smart Tile source ${source.id} usage does not match target '
        '${normalizedTarget.id}',
      );
    }
    final sourceLattices = _activeLattices(source);
    if (source.field.runtimeType != normalizedTarget.field.runtimeType ||
        sourceLattices.keys
            .toSet()
            .difference(targetLattices.keys.toSet())
            .isNotEmpty ||
        targetLattices.keys
            .toSet()
            .difference(sourceLattices.keys.toSet())
            .isNotEmpty) {
      throw ValidationException(
        'Smart Tile source ${source.id} has an incompatible field kind',
      );
    }
    for (final entry in targetLattices.entries) {
      if (sourceLattices[entry.key]!.length != entry.value.length) {
        throw ValidationException(
          'Smart Tile source ${source.id} has incompatible ${entry.key} length',
        );
      }
    }
  }

  final mergedMaterials = <String, List<String?>>{
    for (final entry in targetLattices.entries)
      entry.key: _resolvedSmartTileMaterials(
        normalizedTarget,
        entry.value,
        entry.key,
      ),
  };
  final mergedEntryCounts = <String, int>{
    for (final label in targetLattices.keys) label: 0,
  };

  for (final source in normalizedSources) {
    final mapping = materialMappings[source.id] ?? const <String, String>{};
    for (final entry in _activeLattices(source).entries) {
      final sourceMaterials = _resolvedSmartTileMaterials(
        source,
        entry.value,
        entry.key,
      );
      final targetMaterials = mergedMaterials[entry.key]!;
      for (var offset = 0; offset < sourceMaterials.length; offset++) {
        final rawSourceMaterial = sourceMaterials[offset];
        if (rawSourceMaterial == null) continue;
        final sourceMaterial = mapping[rawSourceMaterial] ?? rawSourceMaterial;
        if (sourceMaterial.trim().isEmpty) {
          throw ValidationException(
            'Smart Tile source ${source.id} maps material '
            '$rawSourceMaterial to an empty material',
          );
        }
        final targetMaterial = targetMaterials[offset];
        if (targetMaterial == null) {
          targetMaterials[offset] = sourceMaterial;
          mergedEntryCounts[entry.key] = mergedEntryCounts[entry.key]! + 1;
        } else if (targetMaterial != sourceMaterial) {
          throw ValidationException(
            'Smart Tile ${entry.key}[$offset] has an ambiguous material '
            'conflict between target ${normalizedTarget.id} '
            '($targetMaterial) and source ${source.id} ($sourceMaterial)',
            code: 'smart_tile.layer_merge_conflict',
            details: <String, Object?>{
              'lattice': entry.key,
              'offset': offset,
              'targetLayerId': normalizedTarget.id,
              'targetMaterialId': targetMaterial,
              'sourceLayerId': source.id,
              'sourceMaterialId': sourceMaterial,
            },
          );
        }
      }
    }
  }

  final palette = <String>[''];
  final paletteIndex = <String, int>{};
  void retain(String materialId) {
    if (paletteIndex.containsKey(materialId)) return;
    paletteIndex[materialId] = palette.length;
    palette.add(materialId);
  }

  for (final materialId in normalizedTarget.materialPalette.skip(1)) {
    retain(materialId);
  }
  for (final values in mergedMaterials.values) {
    for (final materialId in values) {
      if (materialId != null) retain(materialId);
    }
  }
  final encoded = <String, List<int>>{
    for (final entry in mergedMaterials.entries)
      entry.key: <int>[
        for (final materialId in entry.value)
          materialId == null ? 0 : paletteIndex[materialId]!,
      ],
  };

  return SmartTileLayerUnionResult(
    layer: normalizedTarget.copyWith(
      materialPalette: List.unmodifiable(palette),
      field: _fieldFromLattices(normalizedTarget.field, encoded),
      patternStrokes: _unionSmartTilePatternStrokes(
        normalizedTarget,
        normalizedSources,
      ),
    ),
    mergedEntryCounts: mergedEntryCounts,
  );
}

List<SmartTilePatternStroke> _unionSmartTilePatternStrokes(
  SmartTileLayer target,
  List<SmartTileLayer> sources,
) {
  final result = <SmartTilePatternStroke>[...target.patternStrokes];
  final usedIds = <String>{for (final stroke in result) stroke.id};
  for (final source in sources) {
    for (final stroke in source.patternStrokes) {
      var id = stroke.id;
      if (!usedIds.add(id)) {
        final base = '${source.id}__${stroke.id}';
        id = base;
        var suffix = 2;
        while (!usedIds.add(id)) {
          id = '${base}__$suffix';
          suffix += 1;
        }
      }
      result.add(id == stroke.id ? stroke : stroke.copyWith(id: id));
    }
  }
  return List<SmartTilePatternStroke>.unmodifiable(result);
}

Map<String, List<int>> _activeLattices(SmartTileLayer layer) =>
    switch (layer.field) {
      SmartTileCellField(:final semanticCells) => <String, List<int>>{
        'semanticCells': semanticCells,
      },
      SmartTileCornerField(:final semanticCells, :final corners) =>
        <String, List<int>>{'semanticCells': semanticCells, 'corners': corners},
      SmartTileEdgeField(
        :final semanticCells,
        :final horizontalEdges,
        :final verticalEdges,
      ) =>
        <String, List<int>>{
          'semanticCells': semanticCells,
          'horizontalEdges': horizontalEdges,
          'verticalEdges': verticalEdges,
        },
      SmartTileMixedField(
        :final semanticCells,
        :final horizontalEdges,
        :final verticalEdges,
        :final corners,
      ) =>
        <String, List<int>>{
          'semanticCells': semanticCells,
          'horizontalEdges': horizontalEdges,
          'verticalEdges': verticalEdges,
          'corners': corners,
        },
    };

SmartTileField _fieldFromLattices(
  SmartTileField field,
  Map<String, List<int>> lattices,
) => switch (field) {
  SmartTileCellField() => SmartTileField.cell(
    semanticCells: lattices['semanticCells']!,
  ),
  SmartTileCornerField() => SmartTileField.corner(
    semanticCells: lattices['semanticCells']!,
    corners: lattices['corners']!,
  ),
  SmartTileEdgeField() => SmartTileField.edge(
    semanticCells: lattices['semanticCells']!,
    horizontalEdges: lattices['horizontalEdges']!,
    verticalEdges: lattices['verticalEdges']!,
  ),
  SmartTileMixedField() => SmartTileField.mixed(
    semanticCells: lattices['semanticCells']!,
    horizontalEdges: lattices['horizontalEdges']!,
    verticalEdges: lattices['verticalEdges']!,
    corners: lattices['corners']!,
  ),
};

SmartTileField _withSemanticCells(SmartTileField field, List<int> values) =>
    switch (field) {
      SmartTileCellField() => SmartTileField.cell(semanticCells: values),
      SmartTileCornerField(:final corners) => SmartTileField.corner(
        semanticCells: values,
        corners: corners,
      ),
      SmartTileEdgeField(:final horizontalEdges, :final verticalEdges) =>
        SmartTileField.edge(
          semanticCells: values,
          horizontalEdges: horizontalEdges,
          verticalEdges: verticalEdges,
        ),
      SmartTileMixedField(
        :final horizontalEdges,
        :final verticalEdges,
        :final corners,
      ) =>
        SmartTileField.mixed(
          semanticCells: values,
          horizontalEdges: horizontalEdges,
          verticalEdges: verticalEdges,
          corners: corners,
        ),
    };

SmartTileField _withHorizontalEdges(SmartTileField field, List<int> values) =>
    switch (field) {
      SmartTileEdgeField(:final semanticCells, :final verticalEdges) =>
        SmartTileField.edge(
          semanticCells: semanticCells,
          horizontalEdges: values,
          verticalEdges: verticalEdges,
        ),
      SmartTileMixedField(
        :final semanticCells,
        :final verticalEdges,
        :final corners,
      ) =>
        SmartTileField.mixed(
          semanticCells: semanticCells,
          horizontalEdges: values,
          verticalEdges: verticalEdges,
          corners: corners,
        ),
      SmartTileCellField() ||
      SmartTileCornerField() => throw const ValidationException(
        'Smart Tile field has no horizontal edge lattice',
      ),
    };

SmartTileField _withVerticalEdges(SmartTileField field, List<int> values) =>
    switch (field) {
      SmartTileEdgeField(:final semanticCells, :final horizontalEdges) =>
        SmartTileField.edge(
          semanticCells: semanticCells,
          horizontalEdges: horizontalEdges,
          verticalEdges: values,
        ),
      SmartTileMixedField(
        :final semanticCells,
        :final horizontalEdges,
        :final corners,
      ) =>
        SmartTileField.mixed(
          semanticCells: semanticCells,
          horizontalEdges: horizontalEdges,
          verticalEdges: values,
          corners: corners,
        ),
      SmartTileCellField() ||
      SmartTileCornerField() => throw const ValidationException(
        'Smart Tile field has no vertical edge lattice',
      ),
    };

SmartTileField _withCorners(SmartTileField field, List<int> values) =>
    switch (field) {
      SmartTileCornerField(:final semanticCells) => SmartTileField.corner(
        semanticCells: semanticCells,
        corners: values,
      ),
      SmartTileMixedField(
        :final semanticCells,
        :final horizontalEdges,
        :final verticalEdges,
      ) =>
        SmartTileField.mixed(
          semanticCells: semanticCells,
          horizontalEdges: horizontalEdges,
          verticalEdges: verticalEdges,
          corners: values,
        ),
      SmartTileCellField() ||
      SmartTileEdgeField() => throw const ValidationException(
        'Smart Tile field has no corner lattice',
      ),
    };

List<String?> _resolvedSmartTileMaterials(
  SmartTileLayer layer,
  List<int> values,
  String label,
) => List<String?>.generate(values.length, (offset) {
  final index = values[offset];
  if (index < 0 || index >= layer.materialPalette.length) {
    throw ValidationException(
      'Smart Tile $label[$offset] references invalid material palette '
      'index $index in layer ${layer.id}',
    );
  }
  return index == 0 ? null : layer.materialPalette[index];
}, growable: false);

({List<String> palette, int index}) _internMaterial(
  SmartTileLayer layer,
  String? materialId,
) {
  final normalized = materialId?.trim() ?? '';
  if (normalized.isEmpty) {
    return (palette: layer.materialPalette, index: 0);
  }
  final existing = layer.materialPalette.indexOf(normalized);
  if (existing >= 0) {
    return (palette: layer.materialPalette, index: existing);
  }
  return (
    palette: List<String>.unmodifiable(<String>[
      ...layer.materialPalette,
      normalized,
    ]),
    index: layer.materialPalette.length,
  );
}

String? _materialIdForIndex(SmartTileLayer layer, int index) {
  if (index == 0) return null;
  if (index < 0 || index >= layer.materialPalette.length) {
    throw RangeError.index(index, layer.materialPalette, 'materialIndex');
  }
  return layer.materialPalette[index];
}

void _checkCoordinate(int x, int y, int width, int height, String label) {
  if (x < 0 || y < 0 || x >= width || y >= height) {
    throw RangeError('$label coordinate is outside its Smart Tile lattice');
  }
}
