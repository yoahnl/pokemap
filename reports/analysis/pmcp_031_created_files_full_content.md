# PMCP-031 — Created Files Full Content

This appendix preserves the exact full content of every production and test file created by PMCP-031. The evidence pack and this appendix are excluded to avoid recursive report content.

## `packages/map_authoring/lib/src/domains/maps/layer_actions.dart`

```dart
import 'package:map_core/map_core.dart';

import 'map_lifecycle_adapter.dart';

/// One immutable in-memory map-operation result.
final class MapOperationStepResult {
  MapOperationStepResult({
    required this.map,
    required this.changedCells,
    required Iterable<String> touchedLayerIds,
    Map<String, Object?> metadata = const {},
  })  : touchedLayerIds = Set.unmodifiable(touchedLayerIds),
        metadata = Map.unmodifiable(metadata);

  final MapData map;
  final int changedCells;
  final Set<String> touchedLayerIds;
  final Map<String, Object?> metadata;
}

/// Strict lifecycle operations shared by compact map-operation batches.
final class MapLayerOperations {
  const MapLayerOperations();

  static const Set<String> supportedKinds = {
    'layer.add',
    'layer.clear',
    'layer.delete',
    'layer.move',
    'layer.remove',
    'layer.rename',
    'layer.reorder',
    'layer.set_opacity',
    'layer.set_visibility',
  };

  MapOperationStepResult apply(
    MapData map,
    Map<String, Object?> operation,
  ) {
    final kind = _string(operation, 'kind');
    if (!supportedKinds.contains(kind)) {
      throw _failure(
        'map.layer_operation_unsupported',
        'The requested layer operation is unsupported.',
        details: {'kind': kind},
      );
    }
    try {
      return switch (kind) {
        'layer.add' => _add(map, operation),
        'layer.clear' => _clear(map, operation),
        'layer.delete' || 'layer.remove' => _remove(map, operation),
        'layer.move' => _move(map, operation),
        'layer.rename' => _rename(map, operation),
        'layer.reorder' => _reorder(map, operation),
        'layer.set_opacity' => _setOpacity(map, operation),
        'layer.set_visibility' => _setVisibility(map, operation),
        _ => throw StateError('unreachable layer operation'),
      };
    } on MapAuthoringException {
      rethrow;
    } on Object catch (error) {
      throw _failure(
        'map.layer_operation_invalid',
        'The layer operation is invalid for the current map.',
        details: {'kind': kind, 'validationType': error.runtimeType.toString()},
      );
    }
  }

  MapOperationStepResult _add(
    MapData map,
    Map<String, Object?> operation,
  ) {
    _only(operation, const {
      'kind',
      'layerKind',
      'layerId',
      'name',
      'insertIndex',
      'tilesetId',
      'presetId',
      'usage',
      'defaultMaterialId',
      'layerSeed',
    });
    final layerId = _string(operation, 'layerId');
    final layerKind = _layerKind(_string(operation, 'layerKind'));
    final insertIndex = _optionalInt(operation, 'insertIndex');
    late final MapData updated;
    if (layerKind == MapLayerKind.smartTile) {
      updated = addSmartTileLayer(
        map,
        id: layerId,
        name: _string(operation, 'name'),
        presetId: _string(operation, 'presetId'),
        usage: _smartTileUsage(_string(operation, 'usage')),
        defaultMaterialId: _string(operation, 'defaultMaterialId'),
        layerSeed: _optionalInt(operation, 'layerSeed') ?? 0,
        insertIndex: insertIndex,
      );
    } else {
      updated = addMapLayer(
        map,
        kind: layerKind,
        id: layerId,
        name: _string(operation, 'name'),
        tileTilesetId: _optionalString(operation, 'tilesetId'),
        insertIndex: insertIndex,
      );
    }
    return MapOperationStepResult(
      map: updated,
      changedCells: 0,
      touchedLayerIds: [layerId],
      metadata: {'layerKind': _layerKindName(layerKind), 'effect': 'added'},
    );
  }

  MapOperationStepResult _rename(
    MapData map,
    Map<String, Object?> operation,
  ) {
    _only(operation, const {'kind', 'layerId', 'name'});
    final layerId = _string(operation, 'layerId');
    return MapOperationStepResult(
      map: renameMapLayer(
        map,
        layerId: layerId,
        name: _string(operation, 'name'),
      ),
      changedCells: 0,
      touchedLayerIds: [layerId],
      metadata: const {'effect': 'renamed'},
    );
  }

  MapOperationStepResult _remove(
    MapData map,
    Map<String, Object?> operation,
  ) {
    _only(operation, const {'kind', 'layerId'});
    final layerId = _string(operation, 'layerId');
    final layer = _layer(map, layerId);
    return MapOperationStepResult(
      map: removeMapLayer(map, layerId: layerId),
      changedCells: _authoredCellCount(layer),
      touchedLayerIds: [layerId],
      metadata: const {'effect': 'removed'},
    );
  }

  MapOperationStepResult _move(
    MapData map,
    Map<String, Object?> operation,
  ) {
    _only(operation, const {'kind', 'layerId', 'direction'});
    final layerId = _string(operation, 'layerId');
    return MapOperationStepResult(
      map: moveMapLayer(
        map,
        layerId: layerId,
        direction: _int(operation, 'direction'),
      ),
      changedCells: 0,
      touchedLayerIds: [layerId],
      metadata: const {'effect': 'moved'},
    );
  }

  MapOperationStepResult _reorder(
    MapData map,
    Map<String, Object?> operation,
  ) {
    _only(operation, const {'kind', 'oldIndex', 'newIndex'});
    final oldIndex = _int(operation, 'oldIndex');
    if (oldIndex < 0 || oldIndex >= map.layers.length) {
      throw _invalid('oldIndex', 'an existing layer index');
    }
    final layerId = map.layers[oldIndex].id;
    return MapOperationStepResult(
      map: reorderMapLayers(
        map,
        oldIndex: oldIndex,
        newIndex: _int(operation, 'newIndex'),
      ),
      changedCells: 0,
      touchedLayerIds: [layerId],
      metadata: const {'effect': 'reordered'},
    );
  }

  MapOperationStepResult _setVisibility(
    MapData map,
    Map<String, Object?> operation,
  ) {
    _only(operation, const {'kind', 'layerId', 'isVisible'});
    final layerId = _string(operation, 'layerId');
    return MapOperationStepResult(
      map: setMapLayerVisibility(
        map,
        layerId: layerId,
        isVisible: _bool(operation, 'isVisible'),
      ),
      changedCells: 0,
      touchedLayerIds: [layerId],
      metadata: const {'effect': 'visibility_changed'},
    );
  }

  MapOperationStepResult _setOpacity(
    MapData map,
    Map<String, Object?> operation,
  ) {
    _only(operation, const {'kind', 'layerId', 'opacity'});
    final layerId = _string(operation, 'layerId');
    final value = operation['opacity'];
    if (value is! num || !value.isFinite) {
      throw _invalid('opacity', 'a finite number');
    }
    return MapOperationStepResult(
      map: setMapLayerOpacity(
        map,
        layerId: layerId,
        opacity: value.toDouble(),
      ),
      changedCells: 0,
      touchedLayerIds: [layerId],
      metadata: const {'effect': 'opacity_changed'},
    );
  }

  MapOperationStepResult _clear(
    MapData map,
    Map<String, Object?> operation,
  ) {
    _only(operation, const {'kind', 'layerId'});
    final layerId = _string(operation, 'layerId');
    final index = map.layers.indexWhere((layer) => layer.id == layerId);
    if (index < 0) throw _invalid('layerId', 'an existing layer ID');
    final layer = map.layers[index];
    final cellCount = map.size.width * map.size.height;
    final cleared = switch (layer) {
      TileLayer value => value.copyWith(tiles: List.filled(cellCount, 0)),
      CollisionLayer value =>
        value.copyWith(collisions: List.filled(cellCount, false)),
      TerrainLayer value => value.copyWith(
          terrains: List.filled(cellCount, TerrainType.none),
        ),
      PathLayer value => value.copyWith(cells: List.filled(cellCount, false)),
      SurfaceLayer value => value.copyWith(placements: const []),
      SmartTileLayer value => value.copyWith(
          materialCells: List.filled(cellCount, 0),
          horizontalEdges:
              List.filled(map.size.width * (map.size.height + 1), 0),
          verticalEdges: List.filled((map.size.width + 1) * map.size.height, 0),
          corners: List.filled((map.size.width + 1) * (map.size.height + 1), 0),
        ),
      ObjectLayer value => value,
      EnvironmentLayer value => value.copyWith(
          content: EnvironmentLayerContent.emptyContent,
        ),
      BorderLayer value =>
        value.copyWith(content: BorderLayerContent.emptyContent),
    };
    final layers = List<MapLayer>.of(map.layers)..[index] = cleared;
    final updated = map.copyWith(
      layers: layers,
      placedElements: layer is ObjectLayer
          ? map.placedElements
              .where((element) => element.layerId != layerId)
              .toList(growable: false)
          : map.placedElements,
    );
    return MapOperationStepResult(
      map: updated,
      changedCells: _authoredCellCount(layer),
      touchedLayerIds: [layerId],
      metadata: const {'effect': 'cleared'},
    );
  }
}

MapLayer _layer(MapData map, String layerId) {
  for (final layer in map.layers) {
    if (layer.id == layerId) return layer;
  }
  throw _invalid('layerId', 'an existing layer ID');
}

int _authoredCellCount(MapLayer layer) => switch (layer) {
      TileLayer value => value.tiles.where((cell) => cell != 0).length,
      CollisionLayer value => value.collisions.where((cell) => cell).length,
      TerrainLayer value =>
        value.terrains.where((cell) => cell != TerrainType.none).length,
      PathLayer value => value.cells.where((cell) => cell).length,
      SurfaceLayer value => value.placements.length,
      SmartTileLayer value =>
        value.materialCells.where((cell) => cell != 0).length +
            value.horizontalEdges.where((cell) => cell != 0).length +
            value.verticalEdges.where((cell) => cell != 0).length +
            value.corners.where((cell) => cell != 0).length,
      ObjectLayer() || EnvironmentLayer() || BorderLayer() => 0,
    };

MapLayerKind _layerKind(String value) => switch (value) {
      'tile' => MapLayerKind.tile,
      'collision' => MapLayerKind.collision,
      'terrain' => MapLayerKind.terrain,
      'path' => MapLayerKind.path,
      'surface' => MapLayerKind.surface,
      'smart_tile' => MapLayerKind.smartTile,
      'object' => MapLayerKind.object,
      'environment' => MapLayerKind.environment,
      'border' => MapLayerKind.border,
      _ => throw _invalid('layerKind', 'a supported MapLayer kind'),
    };

String _layerKindName(MapLayerKind value) => switch (value) {
      MapLayerKind.smartTile => 'smart_tile',
      _ => value.name,
    };

SmartTileUsage _smartTileUsage(String value) => switch (value) {
      'terrain' => SmartTileUsage.terrain,
      'path' => SmartTileUsage.path,
      'forest_surface' => SmartTileUsage.forestSurface,
      _ => throw _invalid('usage', 'terrain, path, or forest_surface'),
    };

void _only(Map<String, Object?> values, Set<String> allowed) {
  final unknown = values.keys.where((key) => !allowed.contains(key)).toList()
    ..sort();
  if (unknown.isNotEmpty) {
    throw _failure(
      'map.operation_fields_unsupported',
      'The layer operation contains unsupported fields.',
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

String? _optionalString(Map<String, Object?> values, String key) =>
    values[key] == null ? null : _string(values, key);

int _int(Map<String, Object?> values, String key) {
  final value = values[key];
  if (value is! int) throw _invalid(key, 'an integer');
  return value;
}

int? _optionalInt(Map<String, Object?> values, String key) =>
    values[key] == null ? null : _int(values, key);

bool _bool(Map<String, Object?> values, String key) {
  final value = values[key];
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
```

## `packages/map_authoring/lib/src/domains/maps/region_operations.dart`

```dart
import 'dart:collection';

import 'package:map_core/map_core.dart';

import 'layer_actions.dart';
import 'map_lifecycle_adapter.dart';

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
        empty = 0;
        values = List<Object?>.from(value.tiles);
      case CollisionLayer value:
        kind = 'collision';
        empty = false;
        values = List<Object?>.from(value.collisions);
      case TerrainLayer value:
        kind = 'terrain';
        empty = TerrainType.none;
        values = List<Object?>.from(value.terrains);
      case PathLayer value:
        kind = 'path';
        empty = false;
        values = List<Object?>.from(value.cells);
      case SurfaceLayer value:
        kind = 'surface';
        empty = null;
        values = List<Object?>.filled(cellCount, null);
        for (final placement in value.placements) {
          if (placement.x < 0 ||
              placement.y < 0 ||
              placement.x >= map.size.width ||
              placement.y >= map.size.height) {
            throw _failure(
              'map.layer_dimensions_invalid',
              'A surface placement is outside map bounds.',
              details: {'layerId': layer.id},
            );
          }
          values[placement.y * map.size.width + placement.x] =
              placement.surfacePresetId;
        }
      case SmartTileLayer value:
        kind = 'smart_tile';
        empty = null;
        values = [
          for (final materialIndex in value.materialCells)
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
        if (value is int && value >= 0) return value;
        throw _invalid(field, 'a non-negative tile integer');
      case 'collision':
      case 'path':
        if (value is bool) return value;
        throw _invalid(field, 'a boolean');
      case 'terrain':
        if (value is String) {
          for (final terrain in TerrainType.values) {
            if (terrain.name == value) return terrain;
          }
        }
        throw _invalid(field, 'a supported terrain name');
      case 'surface':
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
        updated = value.copyWith(tiles: values.cast<int>());
      case CollisionLayer value:
        updated = value.copyWith(collisions: values.cast<bool>());
      case TerrainLayer value:
        updated = value.copyWith(terrains: values.cast<TerrainType>());
      case PathLayer value:
        updated = value.copyWith(cells: values.cast<bool>());
      case SurfaceLayer value:
        updated = value.copyWith(placements: [
          for (var index = 0; index < values.length; index++)
            if (values[index] case final String presetId)
              SurfaceCellPlacement(
                x: index % width,
                y: index ~/ width,
                surfacePresetId: presetId,
              ),
        ]);
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
          materialCells: indexes,
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
```

## `packages/map_authoring/lib/src/domains/maps/map_operations_batch.dart`

```dart
import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/resource_ref.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import 'layer_actions.dart';
import 'map_lifecycle_adapter.dart';
import 'region_operations.dart';

/// Canonical compact batch action for layer and bounded region authoring.
final class MapOperationsActions {
  const MapOperationsActions({
    MapLayerOperations layerOperations = const MapLayerOperations(),
    MapRegionOperations regionOperations = const MapRegionOperations(),
  })  : _layerOperations = layerOperations,
        _regionOperations = regionOperations;

  static const int maxOperations = 256;
  static const int maxMapCells = 1000000;
  static const int maxCumulativeChangedCells = 1000000;

  final MapLayerOperations _layerOperations;
  final MapRegionOperations _regionOperations;

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    AuthoringActionDescriptor(
      id: 'map.apply_operations',
      version: 1,
      summary: 'Apply one bounded atomic batch of layer and region operations',
      inputSchemaId: 'schema.map.apply_operations.input.v1',
      outputSchemaId: 'schema.map.mutation.output.v1',
      riskLevel: AuthoringRiskLevel.medium,
      resourceKinds: const ['map'],
      requiredPermissions: const [AuthoringPermission.projectWrite],
      guarantees: const [
        AuthoringGuarantee.dryRun,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.revisionChecked,
        AuthoringGuarantee.undoable,
      ],
      extensions: const {
        'batchAtomicity': 'all_or_nothing',
        'maxOperations': maxOperations,
        'maxMapCells': maxMapCells,
        'receiptPayload': 'bounded_summary',
      },
    ),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    if (context.request.actionId != 'map.apply_operations') {
      throw _failure(
        'map.action_unsupported',
        'The requested map operations action is unsupported.',
        details: {'actionId': context.request.actionId},
      );
    }
    if (context.request.actionVersion != 1) {
      throw _failure(
        'map.action_version_unsupported',
        'The requested map operations action version is unsupported.',
        details: {'actionVersion': context.request.actionVersion},
      );
    }
    final parameters = context.request.parameters;
    _only(parameters, const {'mapId', 'operations'});
    final mapId = _string(parameters, 'mapId');
    final before = context.snapshot.mapById(mapId);
    if (before == null) {
      throw _failure(
        'map.not_found',
        'The requested map does not exist.',
        details: {'mapId': mapId},
      );
    }
    final cellCount = before.size.width * before.size.height;
    if (cellCount > maxMapCells) {
      throw _failure(
        'map.batch_bounds_exceeded',
        'The map is too large for one bounded operation batch.',
        details: {'mapCellCount': cellCount, 'maxMapCells': maxMapCells},
      );
    }
    final rawOperations = parameters['operations'];
    if (rawOperations is! List || rawOperations.isEmpty) {
      throw _invalid('operations', 'a non-empty list');
    }
    if (rawOperations.length > maxOperations) {
      throw _failure(
        'map.batch_bounds_exceeded',
        'The operation batch exceeds the supported operation count.',
        details: {
          'operationCount': rawOperations.length,
          'maxOperations': maxOperations,
        },
      );
    }

    var current = before;
    var changedCells = 0;
    final touchedLayers = <String>{};
    final summaries = <Map<String, Object?>>[];
    final clipboard = MapRegionClipboard();
    for (var index = 0; index < rawOperations.length; index++) {
      final raw = rawOperations[index];
      if (raw is! Map || raw.keys.any((key) => key is! String)) {
        throw _operationFailure(
          index,
          '<invalid>',
          _invalid('operations[$index]', 'a JSON object'),
        );
      }
      final operation = Map<String, Object?>.from(raw);
      final kindValue = operation['kind'];
      final kind = kindValue is String ? kindValue : '<invalid>';
      try {
        late final MapOperationStepResult result;
        if (MapLayerOperations.supportedKinds.contains(kind)) {
          result = _layerOperations.apply(current, operation);
        } else if (MapRegionOperations.supportedKinds.contains(kind)) {
          result = _regionOperations.apply(
            current,
            operation,
            clipboard: clipboard,
          );
        } else {
          throw _failure(
            'map.operation_unsupported',
            'The requested batch operation kind is unsupported.',
            details: {'kind': kind},
          );
        }
        current = result.map;
        changedCells += result.changedCells;
        touchedLayers.addAll(result.touchedLayerIds);
        if (changedCells > maxCumulativeChangedCells) {
          throw _failure(
            'map.batch_bounds_exceeded',
            'The batch exceeds the cumulative changed-cell limit.',
            details: {
              'changedCellCount': changedCells,
              'maxChangedCells': maxCumulativeChangedCells,
            },
          );
        }
        if (summaries.length < 64) {
          summaries.add({
            'index': index,
            'kind': kind,
            'changedCells': result.changedCells,
            'touchedLayerIds': result.touchedLayerIds.toList()..sort(),
            ...result.metadata,
          });
        }
      } on MapAuthoringException catch (error) {
        throw _operationFailure(index, kind, error);
      }
    }

    try {
      MapValidator.validate(
        current,
        projectDialogueContext: context.snapshot.manifest,
      );
    } on Object catch (error) {
      throw _failure(
        'map.batch_projected_state_invalid',
        'The complete operation batch would produce invalid PokeMap data.',
        details: {'validationType': error.runtimeType.toString()},
      );
    }
    final beforeBytes = context.snapshot.resourceBytes('map:$mapId');
    final afterBytes = encodeMapAuthoringDocument(current);
    if (_sameBytes(beforeBytes, afterBytes)) {
      throw _failure('map.no_change', 'The operation batch changes nothing.');
    }
    final entry = context.snapshot.manifest.maps
        .where((candidate) => candidate.id == mapId)
        .firstOrNull;
    if (entry == null) {
      throw _failure(
        'map.manifest_entry_missing',
        'The map has no project manifest storage entry.',
        details: {'mapId': mapId},
      );
    }
    final revision = context.snapshot.resourceFingerprints['map:$mapId'];
    if (revision == null) {
      throw _failure(
        'map.resource_preimage_missing',
        'The map resource revision is unavailable.',
        details: {'mapId': mapId},
      );
    }
    final resource = AuthoringResourceRef(
      kind: 'map',
      id: mapId,
      revision: revision,
    );
    final sortedLayers = touchedLayers.toList()..sort();
    final beforeSummary = _mapLayerSummary(before);
    final afterSummary = _mapLayerSummary(current);
    return AuthoringMutationDraft(
      changeSet: AuthoringChangeSet(
        changes: [
          AuthoringResourceChange(
            resource: resource,
            storageKey: entry.relativePath,
            beforeBytes: beforeBytes,
            afterBytes: afterBytes,
          ),
        ],
        diff: AuthoringDiff([
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.replace,
            resource: resource,
            path: '/layers',
            before: beforeSummary,
            after: afterSummary,
          ),
        ]),
      ),
      preview: {
        'operation': 'apply_operations',
        'mapId': mapId,
        'operationCount': rawOperations.length,
        'changedCellCount': changedCells,
        'touchedLayerCount': sortedLayers.length,
        'touchedLayerIds': sortedLayers.take(64).toList(growable: false),
        'operationSummaries': summaries,
        'summariesTruncated': rawOperations.length > summaries.length,
        'batchAtomicity': 'all_or_nothing',
      },
    );
  }
}

Map<String, Object?> _mapLayerSummary(MapData map) => {
      'mapId': map.id,
      'width': map.size.width,
      'height': map.size.height,
      'layerCount': map.layers.length,
      'layerIds': map.layers.map((layer) => layer.id).take(64).toList(),
      'layerIdsTruncated': map.layers.length > 64,
    };

MapAuthoringException _operationFailure(
  int index,
  String kind,
  MapAuthoringException cause,
) =>
    _failure(
      'map.operation_invalid',
      'The operation batch was rejected without applying any operation.',
      details: {
        'operationIndex': index,
        'operationKind': kind,
        'causeCode': cause.code,
        'causeDetails': cause.details,
      },
      remediation: cause.remediation,
    );

bool _sameBytes(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

void _only(Map<String, Object?> values, Set<String> allowed) {
  final unknown = values.keys.where((key) => !allowed.contains(key)).toList()
    ..sort();
  if (unknown.isNotEmpty) {
    throw _failure(
      'map.request_invalid',
      'The map operations request contains unsupported parameters.',
      details: {'unknownParameters': unknown},
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

MapAuthoringException _invalid(String field, String expected) => _failure(
      'map.request_invalid',
      'Parameter "$field" must be $expected.',
      details: {'parameter': field, 'expected': expected},
    );

MapAuthoringException _failure(
  String code,
  String message, {
  Map<String, Object?> details = const {},
  Iterable<String> remediation = const [],
}) =>
    MapAuthoringException(
      code: code,
      message: message,
      details: details,
      remediation: remediation,
    );
```

## `packages/map_authoring/test/domains/maps/region_operations_test.dart`

```dart
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('MapRegionOperations', () {
    test('supports bounded paint, shapes, flood fill, and replace', () {
      var map = _map(width: 6, height: 5);
      const operations = MapRegionOperations();

      map = operations.apply(map, const {
        'kind': 'region.fill',
        'layerId': 'tiles',
        'x': 0,
        'y': 0,
        'width': 6,
        'height': 5,
        'value': 1,
      }).map;
      map = operations.apply(map, const {
        'kind': 'shape.rectangle',
        'layerId': 'tiles',
        'x': 1,
        'y': 1,
        'width': 4,
        'height': 3,
        'value': 2,
        'filled': false,
      }).map;
      map = operations.apply(map, const {
        'kind': 'region.flood_fill',
        'layerId': 'tiles',
        'x': 2,
        'y': 2,
        'value': 3,
      }).map;
      map = operations.apply(map, const {
        'kind': 'shape.line',
        'layerId': 'tiles',
        'from': {'x': 0, 'y': 4},
        'to': {'x': 5, 'y': 4},
        'value': 4,
      }).map;
      final result = operations.apply(map, const {
        'kind': 'region.replace',
        'layerId': 'tiles',
        'from': 2,
        'to': 5,
      });

      final tiles = (result.map.layers.single as TileLayer).tiles;
      expect(tiles[2 * 6 + 2], 3);
      expect(tiles.sublist(4 * 6), everyElement(4));
      expect(tiles.where((tile) => tile == 5), hasLength(10));
      expect(result.changedCells, 10);
    });

    test('supports polyline, polygon, and exact stamps', () {
      var map = _map(width: 5, height: 5);
      const operations = MapRegionOperations();
      map = operations.apply(map, const {
        'kind': 'region.stamp',
        'layerId': 'tiles',
        'x': 0,
        'y': 0,
        'width': 2,
        'height': 2,
        'values': [1, 2, 3, 4],
      }).map;
      map = operations.apply(map, const {
        'kind': 'shape.polyline',
        'layerId': 'tiles',
        'points': [
          {'x': 0, 'y': 4},
          {'x': 2, 'y': 2},
          {'x': 4, 'y': 4},
        ],
        'value': 8,
      }).map;
      map = operations.apply(map, const {
        'kind': 'shape.polygon',
        'layerId': 'tiles',
        'points': [
          {'x': 1, 'y': 1},
          {'x': 3, 'y': 1},
          {'x': 2, 'y': 3},
        ],
        'value': 9,
        'filled': true,
      }).map;

      final tiles = (map.layers.single as TileLayer).tiles;
      expect(tiles[0], 1);
      expect(tiles[1], 2);
      expect(tiles[5], 3);
      expect(tiles[6], 9);
      expect(tiles[2 * 5 + 2], 9);
      expect(tiles[4 * 5], 8);
      expect(tiles[4 * 5 + 4], 8);
    });

    test('copy, cut, paste, move, rotate, and flip preserve map references',
        () {
      var map = _map(width: 4, height: 4).copyWith(
        layers: [
          MapLayer.tile(
            id: 'tiles',
            name: 'Tiles',
            tiles: const [
              1,
              2,
              0,
              0,
              3,
              4,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
            ],
          ),
        ],
        warps: const [
          MapWarp(
            id: 'warp',
            pos: GridPos(x: 3, y: 3),
            targetMapId: 'other',
            targetPos: GridPos(x: 0, y: 0),
          ),
        ],
      );
      const operations = MapRegionOperations();
      final clipboard = MapRegionClipboard();

      map = operations
          .apply(
              map,
              const {
                'kind': 'region.copy',
                'layerId': 'tiles',
                'clipboardId': 'selection',
                'x': 0,
                'y': 0,
                'width': 2,
                'height': 2,
              },
              clipboard: clipboard)
          .map;
      map = operations
          .apply(
              map,
              const {
                'kind': 'region.paste',
                'layerId': 'tiles',
                'clipboardId': 'selection',
                'x': 2,
                'y': 2,
              },
              clipboard: clipboard)
          .map;
      map = operations
          .apply(
              map,
              const {
                'kind': 'region.rotate',
                'layerId': 'tiles',
                'x': 0,
                'y': 0,
                'width': 2,
                'height': 2,
                'quarterTurns': 1,
              },
              clipboard: clipboard)
          .map;
      map = operations
          .apply(
              map,
              const {
                'kind': 'region.flip',
                'layerId': 'tiles',
                'x': 2,
                'y': 2,
                'width': 2,
                'height': 2,
                'axis': 'horizontal',
              },
              clipboard: clipboard)
          .map;
      map = operations
          .apply(
              map,
              const {
                'kind': 'region.move',
                'layerId': 'tiles',
                'source': {'x': 0, 'y': 0, 'width': 2, 'height': 2},
                'target': {'x': 0, 'y': 2},
              },
              clipboard: clipboard)
          .map;
      map = operations
          .apply(
              map,
              const {
                'kind': 'region.cut',
                'layerId': 'tiles',
                'clipboardId': 'cut',
                'x': 2,
                'y': 2,
                'width': 2,
                'height': 2,
              },
              clipboard: clipboard)
          .map;

      final tiles = (map.layers.single as TileLayer).tiles;
      expect(tiles.sublist(0, 8), everyElement(0));
      expect(tiles.sublist(8, 10), [3, 1]);
      expect(tiles.sublist(12, 14), [4, 2]);
      expect(tiles[10], 0);
      expect(tiles[15], 0);
      expect(map.size, const GridSize(width: 4, height: 4));
      expect(map.warps.single.id, 'warp');
      expect(map.layers.single.id, 'tiles');
      expect(clipboard.contains('cut'), isTrue);
    });

    test('normalizes values for every cell-addressable layer kind', () {
      var map = _map(width: 2, height: 2).copyWith(
        version: ProjectVersion.v4,
        layers: [
          MapLayer.tile(id: 'tile', name: 'Tile', tiles: List.filled(4, 0)),
          MapLayer.collision(
            id: 'collision',
            name: 'Collision',
            collisions: List.filled(4, false),
          ),
          MapLayer.terrain(
            id: 'terrain',
            name: 'Terrain',
            terrains: List.filled(4, TerrainType.none),
          ),
          MapLayer.path(id: 'path', name: 'Path', cells: List.filled(4, false)),
          const MapLayer.surface(id: 'surface', name: 'Surface'),
          const MapLayer.smartTile(
            id: 'smart',
            name: 'Smart',
            presetId: 'preset',
            usage: SmartTileUsage.path,
            materialPalette: ['', 'road'],
            materialCells: [0, 0, 0, 0],
            horizontalEdges: [0, 0, 0, 0, 0, 0],
            verticalEdges: [0, 0, 0, 0, 0, 0],
            corners: [0, 0, 0, 0, 0, 0, 0, 0, 0],
          ),
        ],
      );
      const operations = MapRegionOperations();
      for (final entry in <String, Object?>{
        'tile': 7,
        'collision': true,
        'terrain': 'grass',
        'path': true,
        'surface': 'surface_grass',
        'smart': 'road',
      }.entries) {
        map = operations.apply(map, {
          'kind': 'region.paint',
          'layerId': entry.key,
          'x': 1,
          'y': 1,
          'value': entry.value,
        }).map;
      }

      expect((map.layers[0] as TileLayer).tiles.last, 7);
      expect((map.layers[1] as CollisionLayer).collisions.last, isTrue);
      expect((map.layers[2] as TerrainLayer).terrains.last, TerrainType.grass);
      expect((map.layers[3] as PathLayer).cells.last, isTrue);
      expect((map.layers[4] as SurfaceLayer).placements.single.x, 1);
      expect(
        smartTileMaterialIdAt(
          map.layers[5] as SmartTileLayer,
          mapSize: map.size,
          x: 1,
          y: 1,
        ),
        'road',
      );
    });

    test('rejects out-of-bounds and non-square odd rotations', () {
      const operations = MapRegionOperations();
      final map = _map(width: 4, height: 3);

      for (final operation in [
        const {
          'kind': 'region.paint',
          'layerId': 'tiles',
          'x': 4,
          'y': 0,
          'value': 1,
        },
        const {
          'kind': 'region.rotate',
          'layerId': 'tiles',
          'x': 0,
          'y': 0,
          'width': 2,
          'height': 3,
          'quarterTurns': 1,
        },
      ]) {
        expect(
          () => operations.apply(map, operation),
          throwsA(isA<MapAuthoringException>()),
        );
      }
    });
  });
}

MapData _map({required int width, required int height}) => MapData(
      id: 'fixture',
      name: 'Fixture',
      size: GridSize(width: width, height: height),
      version: ProjectVersion.v3,
      visualStack: MapVisualStackConfig.canonicalV1,
      layers: [
        MapLayer.tile(
          id: 'tiles',
          name: 'Tiles',
          tiles: List<int>.filled(width * height, 0),
        ),
      ],
    );
```

## `packages/map_authoring/test/domains/maps/map_operations_batch_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('MapOperationsActions', () {
    test('advertises one bounded atomic mutation action', () {
      expect(MapOperationsActions.descriptors, hasLength(1));
      final descriptor = MapOperationsActions.descriptors.single;
      expect(descriptor.id, 'map.apply_operations');
      expect(descriptor.guarantees, contains(AuthoringGuarantee.dryRun));
      expect(descriptor.guarantees, contains(AuthoringGuarantee.undoable));
      expect(descriptor.extensions['batchAtomicity'], 'all_or_nothing');
    });

    test('builds a complete map fixture as one compact map change', () {
      final map = _map();
      final snapshot = _snapshot(map);
      final request = _request(snapshot, const [
        {
          'kind': 'layer.add',
          'layerKind': 'collision',
          'layerId': 'collision',
          'name': 'Collision',
        },
        {
          'kind': 'layer.add',
          'layerKind': 'terrain',
          'layerId': 'terrain',
          'name': 'Terrain',
        },
        {
          'kind': 'layer.add',
          'layerKind': 'path',
          'layerId': 'path',
          'name': 'Path',
        },
        {
          'kind': 'layer.add',
          'layerKind': 'surface',
          'layerId': 'surface',
          'name': 'Surface',
        },
        {
          'kind': 'layer.add',
          'layerKind': 'object',
          'layerId': 'objects',
          'name': 'Objects',
        },
        {
          'kind': 'layer.add',
          'layerKind': 'environment',
          'layerId': 'environment',
          'name': 'Environment',
        },
        {
          'kind': 'layer.add',
          'layerKind': 'border',
          'layerId': 'border',
          'name': 'Border',
        },
        {
          'kind': 'layer.add',
          'layerKind': 'smart_tile',
          'layerId': 'smart_path',
          'name': 'Smart Path',
          'presetId': 'smart_path',
          'usage': 'path',
          'defaultMaterialId': 'road',
          'layerSeed': 7,
        },
        {
          'kind': 'region.fill',
          'layerId': 'tiles',
          'x': 0,
          'y': 0,
          'width': 4,
          'height': 3,
          'value': 11,
        },
        {
          'kind': 'shape.line',
          'layerId': 'collision',
          'from': {'x': 0, 'y': 0},
          'to': {'x': 3, 'y': 2},
          'value': true,
        },
      ]);

      final draft = const MapOperationsActions().build(
        _context(snapshot, request),
      );

      expect(draft.changeSet.changes, hasLength(1));
      expect(draft.changeSet.diff.entries, hasLength(1));
      final change = draft.changeSet.changes.single;
      expect(change.storageKey, 'maps/fixture.json');
      expect(change.beforeBytes, snapshot.resourceBytes('map:fixture'));
      final updated = MapData.fromJson(
        jsonDecode(utf8.decode(change.afterBytes!)) as Map<String, dynamic>,
      );
      expect(updated.layers, hasLength(9));
      expect(updated.layers.map((layer) => layer.id), contains('smart_path'));
      expect(updated.version, ProjectVersion.v4);
      expect((updated.layers.first as TileLayer).tiles, everyElement(11));
      expect(draft.preview['operationCount'], 10);
      expect(draft.preview['changedCellCount'], lessThanOrEqualTo(24));
      expect(
        jsonEncode(draft.preview).length,
        lessThan(4096),
        reason: 'receipts/previews must summarize rather than embed cell data',
      );
    });

    test('rejects the complete batch when one operation is invalid', () {
      final map = _map();
      final snapshot = _snapshot(map);
      final request = _request(snapshot, const [
        {
          'kind': 'region.paint',
          'layerId': 'tiles',
          'x': 0,
          'y': 0,
          'value': 9,
        },
        {
          'kind': 'region.paint',
          'layerId': 'tiles',
          'x': 99,
          'y': 0,
          'value': 8,
        },
      ]);

      expect(
        () => const MapOperationsActions().build(_context(snapshot, request)),
        throwsA(
          isA<MapAuthoringException>()
              .having((error) => error.code, 'code', 'map.operation_invalid')
              .having((error) => error.details['operationIndex'], 'index', 1),
        ),
      );
      expect((map.layers.single as TileLayer).tiles, everyElement(0));
      expect(
        snapshot.resourceBytes('map:fixture'),
        _encode(map.toJson()),
      );
    });

    test('layer lifecycle supports all layer kinds and metadata changes', () {
      var map = _map();
      const operations = MapLayerOperations();
      for (final operation in const [
        {
          'kind': 'layer.add',
          'layerKind': 'collision',
          'layerId': 'collision',
          'name': 'Collision',
        },
        {
          'kind': 'layer.add',
          'layerKind': 'terrain',
          'layerId': 'terrain',
          'name': 'Terrain',
        },
        {
          'kind': 'layer.add',
          'layerKind': 'path',
          'layerId': 'path',
          'name': 'Path',
        },
        {
          'kind': 'layer.add',
          'layerKind': 'surface',
          'layerId': 'surface',
          'name': 'Surface',
        },
        {
          'kind': 'layer.add',
          'layerKind': 'smart_tile',
          'layerId': 'smart',
          'name': 'Smart',
          'presetId': 'preset',
          'usage': 'path',
          'defaultMaterialId': 'road',
        },
        {
          'kind': 'layer.add',
          'layerKind': 'object',
          'layerId': 'objects',
          'name': 'Objects',
        },
        {
          'kind': 'layer.add',
          'layerKind': 'environment',
          'layerId': 'environment',
          'name': 'Environment',
        },
        {
          'kind': 'layer.add',
          'layerKind': 'border',
          'layerId': 'border',
          'name': 'Border',
        },
      ]) {
        map = operations.apply(map, operation).map;
      }
      map = operations.apply(map, const {
        'kind': 'layer.rename',
        'layerId': 'collision',
        'name': 'Walls',
      }).map;
      map = operations.apply(map, const {
        'kind': 'layer.set_visibility',
        'layerId': 'collision',
        'isVisible': false,
      }).map;
      map = operations.apply(map, const {
        'kind': 'layer.set_opacity',
        'layerId': 'collision',
        'opacity': 0.5,
      }).map;
      map = operations.apply(map, const {
        'kind': 'layer.reorder',
        'oldIndex': 8,
        'newIndex': 1,
      }).map;

      expect(
          map.layers.map((layer) => layer.runtimeType).toSet(), hasLength(9));
      final collision = map.layers.whereType<CollisionLayer>().single;
      expect(collision.name, 'Walls');
      expect(collision.isVisible, isFalse);
      expect(collision.opacity, 0.5);
      expect(map.version, ProjectVersion.v4);
    });

    test('applies one transaction receipt and undoes the complete batch',
        () async {
      final setup = await _TransactionSetup.create();
      addTearDown(setup.dispose);
      final beforeBytes = await setup.mapFile.readAsBytes();
      final snapshot = await setup.snapshots.load(setup.projectHandle);
      final request = AuthoringRequest(
        requestId: 'request_apply_batch',
        actionId: 'map.apply_operations',
        actionVersion: 1,
        workspaceHandle: setup.workspaceHandle.value,
        parameters: const {
          'mapId': 'fixture',
          'operations': [
            {
              'kind': 'region.fill',
              'layerId': 'tiles',
              'x': 0,
              'y': 0,
              'width': 4,
              'height': 3,
              'value': 6,
            },
            {
              'kind': 'region.erase',
              'layerId': 'tiles',
              'x': 1,
              'y': 1,
            },
          ],
        },
        expectedRevision: snapshot.revision,
        idempotencyKey: 'idem_apply_batch',
        dryRun: false,
      );

      final planned = await setup.mutations.plan(setup.projectHandle, request);
      final applied = await setup.mutations.apply(
        setup.projectHandle,
        planId: planned['planId']! as String,
        operationId: 'operation_apply_batch',
      );

      final receipt = applied['receipt']! as Map<String, Object?>;
      expect(receipt['actionId'], 'map.apply_operations');
      expect(receipt['status'], 'applied');
      final updated = MapData.fromJson(
        jsonDecode(await setup.mapFile.readAsString()) as Map<String, dynamic>,
      );
      expect((updated.layers.single as TileLayer).tiles[0], 6);
      expect((updated.layers.single as TileLayer).tiles[5], 0);

      final undone = await setup.mutations.undo(
        setup.projectHandle,
        entryId: receipt['receiptId']! as String,
        idempotencyKey: 'idem_undo_batch',
      );
      expect(
        (undone['receipt']! as Map<String, Object?>)['actionId'],
        'history.undo',
      );
      expect(await setup.mapFile.readAsBytes(), beforeBytes);
    });

    test('invalid transaction batch never changes the map file', () async {
      final setup = await _TransactionSetup.create();
      addTearDown(setup.dispose);
      final beforeBytes = await setup.mapFile.readAsBytes();
      final snapshot = await setup.snapshots.load(setup.projectHandle);
      final request = AuthoringRequest(
        requestId: 'request_invalid_batch',
        actionId: 'map.apply_operations',
        actionVersion: 1,
        workspaceHandle: setup.workspaceHandle.value,
        parameters: const {
          'mapId': 'fixture',
          'operations': [
            {
              'kind': 'region.paint',
              'layerId': 'tiles',
              'x': 0,
              'y': 0,
              'value': 6,
            },
            {
              'kind': 'region.paint',
              'layerId': 'tiles',
              'x': -1,
              'y': 0,
              'value': 7,
            },
          ],
        },
        expectedRevision: snapshot.revision,
        idempotencyKey: 'idem_invalid_batch',
        dryRun: false,
      );

      await expectLater(
        () => setup.mutations.plan(setup.projectHandle, request),
        throwsA(
          isA<MapAuthoringException>().having(
            (error) => error.code,
            'code',
            'map.operation_invalid',
          ),
        ),
      );
      expect(await setup.mapFile.readAsBytes(), beforeBytes);
    });
  });
}

final class _TransactionSetup {
  _TransactionSetup._({
    required this.root,
    required this.mapFile,
    required this.mutations,
    required this.workspaceHandle,
    required this.projectHandle,
    required this.snapshots,
  });

  static Future<_TransactionSetup> create() async {
    final root = await Directory.systemTemp.createTemp('map-batch-');
    final map = _map();
    final manifest = ProjectManifest(
      name: 'Map Batch Transaction Fixture',
      version: ProjectVersion.v3,
      maps: const [
        ProjectMapEntry(
          id: 'fixture',
          name: 'Fixture',
          relativePath: 'maps/fixture.json',
        ),
      ],
      tilesets: const [],
    );
    await File('${root.path}/project.json').writeAsBytes(
      _encode(manifest.toJson()),
      flush: true,
    );
    await Directory('${root.path}/maps').create();
    final mapFile = File('${root.path}/maps/fixture.json');
    await mapFile.writeAsBytes(_encode(map.toJson()), flush: true);
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore(
      tokenFactory: (prefix) => '${prefix}batchfixture',
    );
    final open = ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
    );
    final opened = await open.openProject(root.path);
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
    );
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    return _TransactionSetup._(
      root: root,
      mapFile: mapFile,
      mutations: mutations,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
      snapshots: snapshots,
    );
  }

  final Directory root;
  final File mapFile;
  final LocalMapAuthoringMutationApi mutations;
  final WorkspaceHandle workspaceHandle;
  final ProjectHandle projectHandle;
  final ProjectSnapshotLoader snapshots;

  Future<void> dispose() async {
    await mutations.detachWorkspace(workspaceHandle);
    if (await root.exists()) await root.delete(recursive: true);
  }
}

AuthoringPlanningContext _context(
  ProjectSnapshot snapshot,
  AuthoringRequest request,
) =>
    AuthoringPlanningContext(
      snapshot: snapshot,
      request: request,
      planId: 'plan_batch',
      seed: 123,
    );

AuthoringRequest _request(
  ProjectSnapshot snapshot,
  List<Map<String, Object?>> operations,
) =>
    AuthoringRequest(
      requestId: 'request_batch',
      actionId: 'map.apply_operations',
      actionVersion: 1,
      workspaceHandle: 'ws_fixture',
      parameters: {'mapId': 'fixture', 'operations': operations},
      expectedRevision: snapshot.revision,
      idempotencyKey: 'idem_batch',
      dryRun: true,
    );

ProjectSnapshot _snapshot(MapData map) {
  final manifest = ProjectManifest(
    name: 'Batch Fixture',
    version: ProjectVersion.v4,
    maps: const [
      ProjectMapEntry(
        id: 'fixture',
        name: 'Fixture',
        relativePath: 'maps/fixture.json',
      ),
    ],
    tilesets: const [],
    smartTileCatalog: ProjectSmartTileCatalog(
      materials: const [
        ProjectSmartTileMaterial(
          id: 'road',
          name: 'Road',
          connectionGroupId: 'road',
        ),
      ],
      presets: const [
        ProjectSmartTilePreset(
          id: 'smart_path',
          name: 'Smart Path',
          usage: SmartTileUsage.path,
          topology: SmartTileTopology.cardinal4,
          defaultMaterialId: 'road',
          allowedMaterialIds: ['road'],
        ),
      ],
    ),
  );
  final manifestBytes = _encode(manifest.toJson());
  final mapBytes = _encode(map.toJson());
  final mapRevision = computeNarrativeProjectFingerprint([
    NarrativeProjectFingerprintEntry(
      relativePath: 'maps/fixture.json',
      bytes: mapBytes,
    ),
  ]);
  final projectRevision = computeNarrativeProjectFingerprint([
    NarrativeProjectFingerprintEntry(
      relativePath: 'project.json',
      bytes: manifestBytes,
    ),
  ]);
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('prj_fixture'),
    revision: computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
        relativePath: 'project.json',
        bytes: manifestBytes,
      ),
      NarrativeProjectFingerprintEntry(
        relativePath: 'maps/fixture.json',
        bytes: mapBytes,
      ),
    ]),
    manifest: manifest,
    maps: [map],
    resourceFingerprints: {
      'project': projectRevision,
      'map:fixture': mapRevision
    },
    resourceBytes: {'project': manifestBytes, 'map:fixture': mapBytes},
  );
}

MapData _map() => MapData(
      id: 'fixture',
      name: 'Fixture',
      size: const GridSize(width: 4, height: 3),
      version: ProjectVersion.v3,
      visualStack: MapVisualStackConfig.canonicalV1,
      layers: [
        MapLayer.tile(
          id: 'tiles',
          name: 'Tiles',
          tiles: List<int>.filled(12, 0),
        ),
      ],
    );

List<int> _encode(Object? value) =>
    utf8.encode(const JsonEncoder.withIndent('  ').convert(value));
```


