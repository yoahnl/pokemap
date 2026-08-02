import 'package:map_core/map_core.dart';

import 'map_lifecycle_adapter.dart';
import 'smart_tile_transition_guards.dart';

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
    if (layerKind == MapLayerKind.smartTile) {
      throw nativeSmartTileAuthoringRequiresStn03(
        map: map,
        operation: 'layer.add',
        layerId: layerId,
      );
    }
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
          field: switch (value.field) {
            SmartTileCellField() => SmartTileField.cell(
                semanticCells: List.filled(cellCount, 0),
              ),
            SmartTileCornerField() => SmartTileField.corner(
                semanticCells: List.filled(cellCount, 0),
                corners: List.filled(
                  (map.size.width + 1) * (map.size.height + 1),
                  0,
                ),
              ),
            SmartTileEdgeField() => SmartTileField.edge(
                semanticCells: List.filled(cellCount, 0),
                horizontalEdges: List.filled(
                  map.size.width * (map.size.height + 1),
                  0,
                ),
                verticalEdges: List.filled(
                  (map.size.width + 1) * map.size.height,
                  0,
                ),
              ),
            SmartTileMixedField() => SmartTileField.mixed(
                semanticCells: List.filled(cellCount, 0),
                horizontalEdges: List.filled(
                  map.size.width * (map.size.height + 1),
                  0,
                ),
                verticalEdges: List.filled(
                  (map.size.width + 1) * map.size.height,
                  0,
                ),
                corners: List.filled(
                  (map.size.width + 1) * (map.size.height + 1),
                  0,
                ),
              ),
          },
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
      SmartTileLayer value => smartTileAuthoredValueCount(value),
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
