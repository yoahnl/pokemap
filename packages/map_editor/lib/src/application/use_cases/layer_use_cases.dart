import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';

class AddMapLayerResult {
  final MapData map;
  final MapLayer layer;

  AddMapLayerResult(this.map, this.layer);
}

class AddMapLayerUseCase {
  AddMapLayerResult execute(
    MapData map, {
    required MapLayerKind kind,
    required String name,
    String? tileTilesetId,
    int? insertIndex,
  }) {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw const EditorValidationException('Layer name cannot be empty');
    }

    final layerId = _generateUniqueLayerId(
      map,
      kind: kind,
      name: normalizedName,
    );

    final updated = addMapLayer(
      map,
      kind: kind,
      id: layerId,
      name: normalizedName,
      tileTilesetId: tileTilesetId,
      insertIndex: insertIndex,
    );
    MapValidator.validate(updated);

    final created = updated.layers.firstWhere((layer) => layer.id == layerId);
    return AddMapLayerResult(updated, created);
  }

  AddMapLayerResult executeSurface(
    MapData map, {
    String name = 'Surfaces',
    int? insertIndex,
  }) {
    final normalizedName = name.trim().isEmpty ? 'Surfaces' : name.trim();
    final layerId = _generateUniqueSurfaceLayerId(map);
    final layerName = _resolveSurfaceLayerName(map, normalizedName);
    final layer = MapLayer.surface(
      id: layerId,
      name: layerName,
    );

    var targetIndex = insertIndex ?? map.layers.length;
    if (targetIndex < 0) targetIndex = 0;
    if (targetIndex > map.layers.length) targetIndex = map.layers.length;

    final updatedLayers = List<MapLayer>.from(map.layers, growable: true)
      ..insert(targetIndex, layer);
    final updated = map.copyWith(layers: updatedLayers);
    MapValidator.validate(updated);
    return AddMapLayerResult(updated, layer);
  }

  String _generateUniqueLayerId(
    MapData map, {
    required MapLayerKind kind,
    required String name,
  }) {
    final existing = map.layers.map((layer) => layer.id).toSet();
    final kindPrefix = switch (kind) {
      MapLayerKind.tile => 'l_tile',
      MapLayerKind.collision => 'l_collision',
      MapLayerKind.terrain => 'l_terrain',
      MapLayerKind.path => 'l_path',
      MapLayerKind.object => 'l_object',
      MapLayerKind.environment => 'l_environment',
    };
    final slug = _slugifyLayerName(name);
    final base = slug.isEmpty ? kindPrefix : '${kindPrefix}_$slug';
    var candidate = base;
    var suffix = 1;
    while (existing.contains(candidate)) {
      candidate = '${base}_$suffix';
      suffix++;
    }
    return candidate;
  }

  String _generateUniqueSurfaceLayerId(MapData map) {
    final existing = map.layers.map((layer) => layer.id).toSet();
    const base = 'surface-main';
    if (!existing.contains(base)) {
      return base;
    }
    var suffix = 2;
    while (existing.contains('surface-$suffix')) {
      suffix++;
    }
    return 'surface-$suffix';
  }

  String _resolveSurfaceLayerName(MapData map, String requestedName) {
    if (requestedName != 'Surfaces') {
      return requestedName;
    }
    final existing = map.layers.map((layer) => layer.name).toSet();
    const base = 'Surfaces';
    if (!existing.contains(base)) {
      return base;
    }
    var suffix = 2;
    while (existing.contains('$base $suffix')) {
      suffix++;
    }
    return '$base $suffix';
  }

  String _slugifyLayerName(String value) {
    final lowered = value.toLowerCase().trim();
    final replaced = lowered.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final normalized = replaced.replaceAll(RegExp(r'^_+|_+$'), '');
    return normalized;
  }
}

class RenameMapLayerUseCase {
  MapData execute(
    MapData map, {
    required String layerId,
    required String name,
  }) {
    final updated = renameMapLayer(
      map,
      layerId: layerId,
      name: name,
    );
    MapValidator.validate(updated);
    return updated;
  }
}

class DeleteMapLayerUseCase {
  MapData execute(
    MapData map, {
    required String layerId,
  }) {
    final updated = removeMapLayer(map, layerId: layerId);
    MapValidator.validate(updated);
    return updated;
  }
}

class DeleteAllMapLayersUseCase {
  MapData execute(MapData map) {
    final updated = removeAllMapLayers(map);
    MapValidator.validate(updated);
    return updated;
  }
}

class MoveMapLayerUseCase {
  MapData execute(
    MapData map, {
    required String layerId,
    required int direction,
  }) {
    final updated = moveMapLayer(
      map,
      layerId: layerId,
      direction: direction,
    );
    MapValidator.validate(updated);
    return updated;
  }
}

class ReorderMapLayersUseCase {
  MapData execute(
    MapData map, {
    required int oldIndex,
    required int newIndex,
  }) {
    final updated = reorderMapLayers(
      map,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
    MapValidator.validate(updated);
    return updated;
  }
}

class SetMapLayerVisibilityUseCase {
  MapData execute(
    MapData map, {
    required String layerId,
    required bool isVisible,
  }) {
    final updated = setMapLayerVisibility(
      map,
      layerId: layerId,
      isVisible: isVisible,
    );
    MapValidator.validate(updated);
    return updated;
  }
}

class SetMapLayerOpacityUseCase {
  MapData execute(
    MapData map, {
    required String layerId,
    required double opacity,
  }) {
    final updated = setMapLayerOpacity(
      map,
      layerId: layerId,
      opacity: opacity,
    );
    MapValidator.validate(updated);
    return updated;
  }
}
