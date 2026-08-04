import 'dart:collection';

import 'package:map_core/map_core.dart';

import 'layer_actions.dart';
import 'map_lifecycle_adapter.dart';
import 'smart_tile_transition_guards.dart';

/// Request-local clipboard used by copy/cut/paste operations in one batch.
final class MapRegionClipboard {
  final Map<String, _ClipboardEntry> _entries = {};

  bool contains(String id) => _entries.containsKey(id);

  void _write(String id, _ClipboardEntry entry) {
    _entries[id] = entry;
  }

  _ClipboardEntry _read(String id) {
    final entry = _entries[id];
    if (entry == null) {
      throw _failure(
        'map.clipboard_missing',
        'The requested batch-local clipboard does not exist.',
        details: {'clipboardId': id},
      );
    }
    return entry;
  }
}

/// Pure bounded grid and shape operations for cell-addressable map layers.
final class MapRegionOperations {
  const MapRegionOperations();

  static const Set<String> supportedKinds = {
    'region.copy',
    'region.cut',
    'region.erase',
    'region.fill',
    'region.flip',
    'region.flood_fill',
    'region.move',
    'region.paint',
    'region.paste',
    'region.replace',
    'region.rotate',
    'region.stamp',
    'shape.line',
    'shape.polygon',
    'shape.polyline',
    'shape.rectangle',
  };

  MapOperationStepResult apply(
    MapData map,
    Map<String, Object?> operation, {
    MapRegionClipboard? clipboard,
  }) {
    final kind = _string(operation, 'kind');
    if (!supportedKinds.contains(kind)) {
      throw _failure(
        'map.region_operation_unsupported',
        'The requested region operation is unsupported.',
        details: {'kind': kind},
      );
    }
    _rejectNativeSmartTileMutation(map, operation, kind);
    try {
      return switch (kind) {
        'region.copy' =>
          _copy(map, operation, clipboard ?? MapRegionClipboard()),
        'region.cut' => _cut(map, operation, clipboard ?? MapRegionClipboard()),
        'region.erase' => _erase(map, operation),
        'region.fill' => _fill(map, operation),
        'region.flip' => _flip(map, operation),
        'region.flood_fill' => _floodFill(map, operation),
        'region.move' => _move(map, operation),
        'region.paint' => _paint(map, operation),
        'region.paste' =>
          _paste(map, operation, clipboard ?? MapRegionClipboard()),
        'region.replace' => _replace(map, operation),
        'region.rotate' => _rotate(map, operation),
        'region.stamp' => _stamp(map, operation),
        'shape.line' => _line(map, operation),
        'shape.polygon' => _polygon(map, operation),
        'shape.polyline' => _polyline(map, operation),
        'shape.rectangle' => _rectangle(map, operation),
        _ => throw StateError('unreachable region operation'),
      };
    } on MapAuthoringException {
      rethrow;
    } on Object catch (error) {
      throw _failure(
        'map.region_operation_invalid',
        'The region operation is invalid for the current map.',
        details: {'kind': kind, 'validationType': error.runtimeType.toString()},
      );
    }
  }

  void _rejectNativeSmartTileMutation(
    MapData map,
    Map<String, Object?> operation,
    String kind,
  ) {
    if (kind == 'region.copy' || map.version != ProjectVersion.v6) return;
    final layerId = operation['layerId'];
    if (layerId is! String || layerId.trim() != layerId || layerId.isEmpty) {
      return;
    }
    final layer =
        map.layers.where((candidate) => candidate.id == layerId).firstOrNull;
    if (layer is SmartTileLayer && layer.field is! SmartTileCellField) {
      throw smartTileWangGestureActionRequired(
        map: map,
        operation: kind,
        layerId: layerId,
      );
    }
  }

  MapOperationStepResult _paint(
    MapData map,
    Map<String, Object?> operation,
  ) {
    _only(operation, const {'kind', 'layerId', 'x', 'y', 'value'});
    final grid = _grid(map, operation);
    grid.set(
      _int(operation, 'x'),
      _int(operation, 'y'),
      grid.normalize(operation['value'], field: 'value'),
    );
    return _finish(map, grid, const {'effect': 'paint'});
  }

  MapOperationStepResult _erase(
    MapData map,
    Map<String, Object?> operation,
  ) {
    _only(operation, const {'kind', 'layerId', 'x', 'y', 'width', 'height'});
    final grid = _grid(map, operation);
    final rect = _rect(
      operation,
      defaultWidth: 1,
      defaultHeight: 1,
      bounds: map.size,
    );
    grid.fill(rect, grid.emptyValue);
    return _finish(map, grid, const {'effect': 'erase'});
  }

  MapOperationStepResult _stamp(
    MapData map,
    Map<String, Object?> operation,
  ) {
    _only(
      operation,
      const {'kind', 'layerId', 'x', 'y', 'width', 'height', 'values'},
    );
    final grid = _grid(map, operation);
    final rect = _rect(operation, bounds: map.size);
    final rawValues = operation['values'];
    if (rawValues is! List || rawValues.length != rect.width * rect.height) {
      throw _invalid(
        'values',
        'a list with exactly width × height entries',
      );
    }
    var index = 0;
    for (var y = 0; y < rect.height; y++) {
      for (var x = 0; x < rect.width; x++) {
        grid.set(
          rect.x + x,
          rect.y + y,
          grid.normalize(rawValues[index], field: 'values[$index]'),
        );
        index++;
      }
    }
    return _finish(map, grid, const {'effect': 'stamp'});
  }

  MapOperationStepResult _fill(
    MapData map,
    Map<String, Object?> operation,
  ) {
    _only(
      operation,
      const {'kind', 'layerId', 'x', 'y', 'width', 'height', 'value'},
    );
    final grid = _grid(map, operation);
    final rect = _rect(operation, bounds: map.size);
    grid.fill(rect, grid.normalize(operation['value'], field: 'value'));
    return _finish(map, grid, const {'effect': 'fill'});
  }

  MapOperationStepResult _floodFill(
    MapData map,
    Map<String, Object?> operation,
  ) {
    _only(operation, const {'kind', 'layerId', 'x', 'y', 'value'});
    final grid = _grid(map, operation);
    final x = _int(operation, 'x');
    final y = _int(operation, 'y');
    grid.requirePoint(x, y);
    final before = grid.at(x, y);
    final after = grid.normalize(operation['value'], field: 'value');
    if (before != after) {
      final queue = Queue<_Point>()..add(_Point(x, y));
      grid.set(x, y, after);
      while (queue.isNotEmpty) {
        final point = queue.removeFirst();
        for (final neighbor in [
          _Point(point.x - 1, point.y),
          _Point(point.x + 1, point.y),
          _Point(point.x, point.y - 1),
          _Point(point.x, point.y + 1),
        ]) {
          if (!grid.contains(neighbor.x, neighbor.y) ||
              grid.at(neighbor.x, neighbor.y) != before) {
            continue;
          }
          grid.set(neighbor.x, neighbor.y, after);
          queue.add(neighbor);
        }
      }
    }
    return _finish(map, grid, const {'effect': 'flood_fill'});
  }

  MapOperationStepResult _replace(
    MapData map,
    Map<String, Object?> operation,
  ) {
    _only(
      operation,
      const {
        'kind',
        'layerId',
        'from',
        'to',
        'x',
        'y',
        'width',
        'height',
      },
    );
    final grid = _grid(map, operation);
    final from = grid.normalize(operation['from'], field: 'from');
    final to = grid.normalize(operation['to'], field: 'to');
    final coordinateFields = ['x', 'y', 'width', 'height'];
    final provided = coordinateFields.where(operation.containsKey).length;
    if (provided != 0 && provided != coordinateFields.length) {
      throw _invalid(
        'x/y/width/height',
        'either a complete rectangle or no rectangle',
      );
    }
    final rect = provided == 0
        ? _Rect(0, 0, map.size.width, map.size.height)
        : _rect(operation, bounds: map.size);
    for (var y = rect.y; y < rect.bottom; y++) {
      for (var x = rect.x; x < rect.right; x++) {
        if (grid.at(x, y) == from) grid.set(x, y, to);
      }
    }
    return _finish(map, grid, const {'effect': 'replace'});
  }

  MapOperationStepResult _line(
    MapData map,
    Map<String, Object?> operation,
  ) {
    _only(operation, const {'kind', 'layerId', 'from', 'to', 'value'});
    final grid = _grid(map, operation);
    final from = _point(operation['from'], 'from', map.size);
    final to = _point(operation['to'], 'to', map.size);
    final value = grid.normalize(operation['value'], field: 'value');
    _drawLine(grid, from, to, value);
    return _finish(map, grid, const {'effect': 'line'});
  }

  MapOperationStepResult _polyline(
    MapData map,
    Map<String, Object?> operation,
  ) {
    _only(operation, const {'kind', 'layerId', 'points', 'value'});
    final grid = _grid(map, operation);
    final points = _points(operation['points'], map.size, minimum: 2);
    final value = grid.normalize(operation['value'], field: 'value');
    for (var index = 1; index < points.length; index++) {
      _drawLine(grid, points[index - 1], points[index], value);
    }
    return _finish(map, grid, const {'effect': 'polyline'});
  }

  MapOperationStepResult _rectangle(
    MapData map,
    Map<String, Object?> operation,
  ) {
    _only(
      operation,
      const {
        'kind',
        'layerId',
        'x',
        'y',
        'width',
        'height',
        'value',
        'filled',
      },
    );
    final grid = _grid(map, operation);
    final rect = _rect(operation, bounds: map.size);
    final value = grid.normalize(operation['value'], field: 'value');
    final filled = _optionalBool(operation, 'filled') ?? false;
    if (filled) {
      grid.fill(rect, value);
    } else {
      _drawLine(
        grid,
        _Point(rect.x, rect.y),
        _Point(rect.right - 1, rect.y),
        value,
      );
      _drawLine(
        grid,
        _Point(rect.x, rect.bottom - 1),
        _Point(rect.right - 1, rect.bottom - 1),
        value,
      );
      _drawLine(
        grid,
        _Point(rect.x, rect.y),
        _Point(rect.x, rect.bottom - 1),
        value,
      );
      _drawLine(
        grid,
        _Point(rect.right - 1, rect.y),
        _Point(rect.right - 1, rect.bottom - 1),
        value,
      );
    }
    return _finish(map, grid, {'effect': filled ? 'filled_rect' : 'rect'});
  }

  MapOperationStepResult _polygon(
    MapData map,
    Map<String, Object?> operation,
  ) {
    _only(operation, const {'kind', 'layerId', 'points', 'value', 'filled'});
    final grid = _grid(map, operation);
    final points = _points(operation['points'], map.size, minimum: 3);
    final value = grid.normalize(operation['value'], field: 'value');
    final filled = _optionalBool(operation, 'filled') ?? true;
    for (var index = 0; index < points.length; index++) {
      _drawLine(
        grid,
        points[index],
        points[(index + 1) % points.length],
        value,
      );
    }
    if (filled) {
      final minX =
          points.map((point) => point.x).reduce((a, b) => a < b ? a : b);
      final maxX =
          points.map((point) => point.x).reduce((a, b) => a > b ? a : b);
      final minY =
          points.map((point) => point.y).reduce((a, b) => a < b ? a : b);
      final maxY =
          points.map((point) => point.y).reduce((a, b) => a > b ? a : b);
      for (var y = minY; y <= maxY; y++) {
        for (var x = minX; x <= maxX; x++) {
          if (_insidePolygon(x + 0.5, y + 0.5, points)) {
            grid.set(x, y, value);
          }
        }
      }
    }
    return _finish(
        map, grid, {'effect': filled ? 'filled_polygon' : 'polygon'});
  }

  MapOperationStepResult _copy(
    MapData map,
    Map<String, Object?> operation,
    MapRegionClipboard clipboard,
  ) {
    _only(
      operation,
      const {
        'kind',
        'layerId',
        'clipboardId',
        'x',
        'y',
        'width',
        'height',
      },
    );
    final grid = _grid(map, operation);
    final rect = _rect(operation, bounds: map.size);
    final clipboardId = _string(operation, 'clipboardId');
    clipboard._write(clipboardId, grid.capture(rect));
    return MapOperationStepResult(
      map: map,
      changedCells: 0,
      touchedLayerIds: [grid.layer.id],
      metadata: {
        'effect': 'copied',
        'clipboardId': clipboardId,
        'cellCount': rect.width * rect.height,
      },
    );
  }

  MapOperationStepResult _cut(
    MapData map,
    Map<String, Object?> operation,
    MapRegionClipboard clipboard,
  ) {
    _only(
      operation,
      const {
        'kind',
        'layerId',
        'clipboardId',
        'x',
        'y',
        'width',
        'height',
      },
    );
    final grid = _grid(map, operation);
    final rect = _rect(operation, bounds: map.size);
    final clipboardId = _string(operation, 'clipboardId');
    clipboard._write(clipboardId, grid.capture(rect));
    grid.fill(rect, grid.emptyValue);
    return _finish(map, grid, {
      'effect': 'cut',
      'clipboardId': clipboardId,
      'cellCount': rect.width * rect.height,
    });
  }

  MapOperationStepResult _paste(
    MapData map,
    Map<String, Object?> operation,
    MapRegionClipboard clipboard,
  ) {
    _only(
      operation,
      const {'kind', 'layerId', 'clipboardId', 'x', 'y'},
    );
    final grid = _grid(map, operation);
    final clipboardId = _string(operation, 'clipboardId');
    final entry = clipboard._read(clipboardId);
    if (entry.layerKind != grid.layerKind) {
      throw _failure(
        'map.clipboard_layer_incompatible',
        'Clipboard values cannot be pasted into this layer kind.',
        details: {
          'clipboardLayerKind': entry.layerKind,
          'targetLayerKind': grid.layerKind,
        },
      );
    }
    final target = _Rect(
      _int(operation, 'x'),
      _int(operation, 'y'),
      entry.width,
      entry.height,
    );
    _requireRectInBounds(target, map.size);
    grid.write(target.x, target.y, entry.width, entry.height, entry.values);
    return _finish(map, grid, {
      'effect': 'pasted',
      'clipboardId': clipboardId,
      'cellCount': entry.values.length,
    });
  }

  MapOperationStepResult _move(
    MapData map,
    Map<String, Object?> operation,
  ) {
    _only(operation, const {'kind', 'layerId', 'source', 'target'});
    final grid = _grid(map, operation);
    final source = _rectObject(operation['source'], 'source', map.size);
    final targetPoint = _point(operation['target'], 'target', map.size);
    final target = _Rect(
      targetPoint.x,
      targetPoint.y,
      source.width,
      source.height,
    );
    _requireRectInBounds(target, map.size);
    final captured = grid.capture(source);
    grid.fill(source, grid.emptyValue);
    grid.write(
        target.x, target.y, captured.width, captured.height, captured.values);
    return _finish(map, grid, {
      'effect': 'moved',
      'cellCount': captured.values.length,
    });
  }

  MapOperationStepResult _rotate(
    MapData map,
    Map<String, Object?> operation,
  ) {
    _only(
      operation,
      const {
        'kind',
        'layerId',
        'x',
        'y',
        'width',
        'height',
        'quarterTurns',
      },
    );
    final grid = _grid(map, operation);
    final rect = _rect(operation, bounds: map.size);
    final turns = _int(operation, 'quarterTurns') % 4;
    final normalizedTurns = turns < 0 ? turns + 4 : turns;
    if (normalizedTurns.isOdd && rect.width != rect.height) {
      throw _failure(
        'map.rotation_dimensions_invalid',
        'Odd quarter-turn in-place rotations require a square selection.',
        details: {'width': rect.width, 'height': rect.height},
      );
    }
    final captured = grid.capture(rect);
    var width = captured.width;
    var height = captured.height;
    var values = List<Object?>.of(captured.values);
    for (var turn = 0; turn < normalizedTurns; turn++) {
      final rotated = List<Object?>.filled(values.length, null);
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final targetX = height - 1 - y;
          final targetY = x;
          rotated[targetY * height + targetX] = values[y * width + x];
        }
      }
      values = rotated;
      final previousWidth = width;
      width = height;
      height = previousWidth;
    }
    grid.write(rect.x, rect.y, width, height, values);
    return _finish(map, grid, {
      'effect': 'rotated',
      'quarterTurns': normalizedTurns,
      'cellCount': values.length,
    });
  }

  MapOperationStepResult _flip(
    MapData map,
    Map<String, Object?> operation,
  ) {
    _only(
      operation,
      const {
        'kind',
        'layerId',
        'x',
        'y',
        'width',
        'height',
        'axis',
      },
    );
    final grid = _grid(map, operation);
    final rect = _rect(operation, bounds: map.size);
    final axis = _string(operation, 'axis');
    if (axis != 'horizontal' && axis != 'vertical') {
      throw _invalid('axis', 'horizontal or vertical');
    }
    final captured = grid.capture(rect);
    final values = List<Object?>.filled(captured.values.length, null);
    for (var y = 0; y < rect.height; y++) {
      for (var x = 0; x < rect.width; x++) {
        final sourceX = axis == 'horizontal' ? rect.width - 1 - x : x;
        final sourceY = axis == 'vertical' ? rect.height - 1 - y : y;
        values[y * rect.width + x] =
            captured.values[sourceY * rect.width + sourceX];
      }
    }
    grid.write(rect.x, rect.y, rect.width, rect.height, values);
    return _finish(map, grid, {
      'effect': 'flipped',
      'axis': axis,
      'cellCount': values.length,
    });
  }
}

MapOperationStepResult _finish(
  MapData map,
  _DenseLayerGrid grid,
  Map<String, Object?> metadata,
) {
  var changed = 0;
  for (var index = 0; index < grid.values.length; index++) {
    if (grid.values[index] != grid.before[index]) changed++;
  }
  return MapOperationStepResult(
    map: grid.rebuild(map),
    changedCells: changed,
    touchedLayerIds: [grid.layer.id],
    metadata: metadata,
  );
}

_DenseLayerGrid _grid(
  MapData map,
  Map<String, Object?> operation,
) {
  final layerId = _string(operation, 'layerId');
  for (var index = 0; index < map.layers.length; index++) {
    if (map.layers[index].id == layerId) {
      return _DenseLayerGrid.fromMap(map, index);
    }
  }
  throw _failure(
    'map.layer_missing',
    'The requested layer does not exist.',
    details: {'layerId': layerId},
  );
}

final class _DenseLayerGrid {
  _DenseLayerGrid({
    required this.layer,
    required this.layerIndex,
    required this.width,
    required this.height,
    required this.layerKind,
    required this.emptyValue,
    required List<Object?> values,
  })  : before = List.unmodifiable(values),
        values = List.of(values);

  factory _DenseLayerGrid.fromMap(MapData map, int layerIndex) {
    final layer = map.layers[layerIndex];
    final cellCount = map.size.width * map.size.height;
    late final String kind;
    late final Object? empty;
    late final List<Object?> values;
    switch (layer) {
      case TileLayer value:
        kind = 'tile';
        empty = null;
        values = <Object?>[
          for (var index = 0; index < value.cells.length; index++)
            resolveTileLayerCell(value, index),
        ];
      case CollisionLayer value:
        kind = 'collision';
        empty = false;
        values = List<Object?>.from(value.collisions);
      case SmartTileLayer value:
        kind = 'smart_tile';
        empty = null;
        values = [
          for (final materialIndex in smartTileSemanticCells(value))
            _smartMaterial(value, materialIndex),
        ];
      case ObjectLayer() || EnvironmentLayer() || BorderLayer():
        throw _failure(
          'map.layer_not_cell_addressable',
          'This layer kind does not support region operations.',
          details: {'layerId': layer.id},
        );
    }
    if (values.length != cellCount) {
      throw _failure(
        'map.layer_dimensions_invalid',
        'The layer cell count does not match the map dimensions.',
        details: {
          'layerId': layer.id,
          'expectedCellCount': cellCount,
          'actualCellCount': values.length,
        },
      );
    }
    return _DenseLayerGrid(
      layer: layer,
      layerIndex: layerIndex,
      width: map.size.width,
      height: map.size.height,
      layerKind: kind,
      emptyValue: empty,
      values: values,
    );
  }

  final MapLayer layer;
  final int layerIndex;
  final int width;
  final int height;
  final String layerKind;
  final Object? emptyValue;
  final List<Object?> before;
  final List<Object?> values;

  bool contains(int x, int y) => x >= 0 && y >= 0 && x < width && y < height;

  void requirePoint(int x, int y) {
    if (!contains(x, y)) {
      throw _failure(
        'map.operation_out_of_bounds',
        'A region operation coordinate is outside map bounds.',
        details: {'x': x, 'y': y, 'width': width, 'height': height},
      );
    }
  }

  Object? at(int x, int y) {
    requirePoint(x, y);
    return values[y * width + x];
  }

  void set(int x, int y, Object? value) {
    requirePoint(x, y);
    values[y * width + x] = value;
  }

  void fill(_Rect rect, Object? value) {
    _requireRectInBounds(rect, GridSize(width: width, height: height));
    for (var y = rect.y; y < rect.bottom; y++) {
      for (var x = rect.x; x < rect.right; x++) {
        set(x, y, value);
      }
    }
  }

  _ClipboardEntry capture(_Rect rect) {
    _requireRectInBounds(rect, GridSize(width: width, height: height));
    final captured = <Object?>[];
    for (var y = rect.y; y < rect.bottom; y++) {
      for (var x = rect.x; x < rect.right; x++) {
        captured.add(at(x, y));
      }
    }
    return _ClipboardEntry(
      layerKind: layerKind,
      width: rect.width,
      height: rect.height,
      values: captured,
    );
  }

  void write(
    int x,
    int y,
    int sourceWidth,
    int sourceHeight,
    List<Object?> source,
  ) {
    final target = _Rect(x, y, sourceWidth, sourceHeight);
    _requireRectInBounds(target, GridSize(width: width, height: height));
    if (source.length != sourceWidth * sourceHeight) {
      throw _failure(
        'map.clipboard_invalid',
        'Clipboard dimensions do not match its cell payload.',
      );
    }
    for (var sourceY = 0; sourceY < sourceHeight; sourceY++) {
      for (var sourceX = 0; sourceX < sourceWidth; sourceX++) {
        set(
          x + sourceX,
          y + sourceY,
          source[sourceY * sourceWidth + sourceX],
        );
      }
    }
  }

  Object? normalize(Object? value, {required String field}) {
    switch (layerKind) {
      case 'tile':
        if (value == null) return null;
        if (value is Map && value.keys.every((key) => key is String)) {
          try {
            final entry = TileLayerPaletteEntry.fromJson(
              Map<String, dynamic>.from(value),
            );
            if (entry.tilesetId.trim() == entry.tilesetId &&
                entry.tilesetId.isNotEmpty &&
                entry.localTileId >= 0) {
              return entry;
            }
          } on Object {
            // Normalized into one stable authoring validation error below.
          }
        }
        throw _invalid(field, 'null or a canonical tile palette entry');
      case 'collision':
        if (value is bool) return value;
        throw _invalid(field, 'a boolean');
      case 'smart_tile':
        if (value == null) return null;
        if (value is String && value.trim() == value && value.isNotEmpty) {
          return value;
        }
        throw _invalid(field, 'null or a nonblank trimmed preset/material ID');
      default:
        throw StateError('unsupported grid layer kind');
    }
  }

  MapData rebuild(MapData map) {
    late final MapLayer updated;
    switch (layer) {
      case TileLayer value:
        final palette = <TileLayerPaletteEntry>[];
        final paletteCells = <TileLayerPaletteEntry, int>{};
        final cells = <int>[];
        for (final raw in values) {
          final entry = raw as TileLayerPaletteEntry?;
          cells.add(
            entry == null
                ? 0
                : paletteCells.putIfAbsent(entry, () {
                    palette.add(entry);
                    return palette.length;
                  }),
          );
        }
        updated = value.copyWith(palette: palette, cells: cells);
      case CollisionLayer value:
        updated = value.copyWith(collisions: values.cast<bool>());
      case SmartTileLayer value:
        final palette = List<String>.of(value.materialPalette);
        if (palette.isEmpty || palette.first != '') {
          throw _failure(
            'map.smart_tile_palette_invalid',
            'Smart Tile material palettes must start with the empty material.',
            details: {'layerId': layer.id},
          );
        }
        final indexes = <int>[];
        for (final material in values) {
          if (material == null) {
            indexes.add(0);
            continue;
          }
          final id = material as String;
          var index = palette.indexOf(id);
          if (index < 0) {
            palette.add(id);
            index = palette.length - 1;
          }
          indexes.add(index);
        }
        updated = value.copyWith(
          materialPalette: palette,
          field: switch (value.field) {
            SmartTileCellField() => SmartTileField.cell(
                semanticCells: indexes,
              ),
            SmartTileCornerField(:final corners) => SmartTileField.corner(
                semanticCells: indexes,
                corners: corners,
              ),
            SmartTileEdgeField(
              :final horizontalEdges,
              :final verticalEdges,
            ) =>
              SmartTileField.edge(
                semanticCells: indexes,
                horizontalEdges: horizontalEdges,
                verticalEdges: verticalEdges,
              ),
            SmartTileMixedField(
              :final horizontalEdges,
              :final verticalEdges,
              :final corners,
            ) =>
              SmartTileField.mixed(
                semanticCells: indexes,
                horizontalEdges: horizontalEdges,
                verticalEdges: verticalEdges,
                corners: corners,
              ),
          },
        );
      case ObjectLayer() || EnvironmentLayer() || BorderLayer():
        throw StateError('non-cell layer cannot be rebuilt as a grid');
    }
    final layers = List<MapLayer>.of(map.layers)..[layerIndex] = updated;
    return map.copyWith(layers: layers);
  }
}

final class _ClipboardEntry {
  _ClipboardEntry({
    required this.layerKind,
    required this.width,
    required this.height,
    required Iterable<Object?> values,
  }) : values = List.unmodifiable(values);

  final String layerKind;
  final int width;
  final int height;
  final List<Object?> values;
}

String? _smartMaterial(SmartTileLayer layer, int index) {
  if (index == 0) return null;
  if (index < 0 || index >= layer.materialPalette.length) {
    throw _failure(
      'map.smart_tile_palette_invalid',
      'A Smart Tile cell references an invalid material palette index.',
      details: {'layerId': layer.id, 'materialIndex': index},
    );
  }
  return layer.materialPalette[index];
}

void _drawLine(
  _DenseLayerGrid grid,
  _Point from,
  _Point to,
  Object? value,
) {
  var x = from.x;
  var y = from.y;
  final deltaX = (to.x - from.x).abs();
  final stepX = from.x < to.x ? 1 : -1;
  final deltaY = -(to.y - from.y).abs();
  final stepY = from.y < to.y ? 1 : -1;
  var error = deltaX + deltaY;
  while (true) {
    grid.set(x, y, value);
    if (x == to.x && y == to.y) break;
    final doubled = 2 * error;
    if (doubled >= deltaY) {
      error += deltaY;
      x += stepX;
    }
    if (doubled <= deltaX) {
      error += deltaX;
      y += stepY;
    }
  }
}

bool _insidePolygon(double x, double y, List<_Point> points) {
  var inside = false;
  for (var current = 0, previous = points.length - 1;
      current < points.length;
      previous = current++) {
    final a = points[current];
    final b = points[previous];
    final crosses = (a.y > y) != (b.y > y);
    if (crosses && x < (b.x - a.x) * (y - a.y) / (b.y - a.y) + a.x) {
      inside = !inside;
    }
  }
  return inside;
}

List<_Point> _points(Object? value, GridSize bounds, {required int minimum}) {
  if (value is! List || value.length < minimum) {
    throw _invalid('points', 'a list containing at least $minimum points');
  }
  return [
    for (var index = 0; index < value.length; index++)
      _point(value[index], 'points[$index]', bounds),
  ];
}

_Point _point(Object? value, String field, GridSize bounds) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw _invalid(field, 'a coordinate object');
  }
  final object = Map<String, Object?>.from(value);
  _only(object, const {'x', 'y'});
  final point = _Point(_int(object, 'x'), _int(object, 'y'));
  if (point.x < 0 ||
      point.y < 0 ||
      point.x >= bounds.width ||
      point.y >= bounds.height) {
    throw _failure(
      'map.operation_out_of_bounds',
      'A region operation coordinate is outside map bounds.',
      details: {'field': field, 'x': point.x, 'y': point.y},
    );
  }
  return point;
}

_Rect _rect(
  Map<String, Object?> values, {
  int? defaultWidth,
  int? defaultHeight,
  required GridSize bounds,
}) {
  final rect = _Rect(
    _int(values, 'x'),
    _int(values, 'y'),
    values['width'] == null
        ? defaultWidth ?? _int(values, 'width')
        : _int(values, 'width'),
    values['height'] == null
        ? defaultHeight ?? _int(values, 'height')
        : _int(values, 'height'),
  );
  _requireRectInBounds(rect, bounds);
  return rect;
}

_Rect _rectObject(Object? value, String field, GridSize bounds) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw _invalid(field, 'a rectangle object');
  }
  final object = Map<String, Object?>.from(value);
  _only(object, const {'x', 'y', 'width', 'height'});
  return _rect(object, bounds: bounds);
}

void _requireRectInBounds(_Rect rect, GridSize bounds) {
  if (rect.x < 0 ||
      rect.y < 0 ||
      rect.width <= 0 ||
      rect.height <= 0 ||
      rect.right > bounds.width ||
      rect.bottom > bounds.height) {
    throw _failure(
      'map.operation_out_of_bounds',
      'A region operation rectangle is outside map bounds.',
      details: {
        'x': rect.x,
        'y': rect.y,
        'width': rect.width,
        'height': rect.height,
        'mapWidth': bounds.width,
        'mapHeight': bounds.height,
      },
    );
  }
}

final class _Point {
  const _Point(this.x, this.y);

  final int x;
  final int y;
}

final class _Rect {
  const _Rect(this.x, this.y, this.width, this.height);

  final int x;
  final int y;
  final int width;
  final int height;

  int get right => x + width;
  int get bottom => y + height;
}

void _only(Map<String, Object?> values, Set<String> allowed) {
  final unknown = values.keys.where((key) => !allowed.contains(key)).toList()
    ..sort();
  if (unknown.isNotEmpty) {
    throw _failure(
      'map.operation_fields_unsupported',
      'The region operation contains unsupported fields.',
      details: {'unknownFields': unknown},
    );
  }
}

String _string(Map<String, Object?> values, String key) {
  final value = values[key];
  if (value is! String || value.trim() != value || value.isEmpty) {
    throw _invalid(key, 'a nonblank trimmed string');
  }
  return value;
}

int _int(Map<String, Object?> values, String key) {
  final value = values[key];
  if (value is! int) throw _invalid(key, 'an integer');
  return value;
}

bool? _optionalBool(Map<String, Object?> values, String key) {
  final value = values[key];
  if (value == null) return null;
  if (value is! bool) throw _invalid(key, 'a boolean');
  return value;
}

MapAuthoringException _invalid(String field, String expected) => _failure(
      'map.operation_field_invalid',
      'Operation field "$field" must be $expected.',
      details: {'field': field, 'expected': expected},
    );

MapAuthoringException _failure(
  String code,
  String message, {
  Map<String, Object?> details = const {},
}) =>
    MapAuthoringException(code: code, message: message, details: details);
