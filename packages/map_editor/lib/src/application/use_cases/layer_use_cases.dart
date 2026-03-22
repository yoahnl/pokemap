part of 'project_use_cases.dart';

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
      throw Exception('Layer name cannot be empty');
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

  String _generateUniqueLayerId(
    MapData map, {
    required MapLayerKind kind,
    required String name,
  }) {
    final existing = map.layers.map((layer) => layer.id).toSet();
    final kindPrefix = switch (kind) {
      MapLayerKind.tile => 'l_tile',
      MapLayerKind.collision => 'l_collision',
      MapLayerKind.object => 'l_object',
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
