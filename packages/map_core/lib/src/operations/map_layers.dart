import '../exceptions/map_exceptions.dart';
import '../models/enums.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';

MapData addMapLayer(
  MapData map, {
  required MapLayerKind kind,
  required String id,
  required String name,
  String? tileTilesetId,
  int? insertIndex,
}) {
  final normalizedId = id.trim();
  if (normalizedId.isEmpty) {
    throw const ValidationException('Layer ID cannot be empty');
  }
  final normalizedName = name.trim();
  if (normalizedName.isEmpty) {
    throw const ValidationException('Layer name cannot be empty');
  }
  if (map.layers.any((layer) => layer.id == normalizedId)) {
    throw ValidationException('Layer ID already exists: $normalizedId');
  }
  final normalizedTileTilesetId = tileTilesetId?.trim();
  if (normalizedTileTilesetId != null && normalizedTileTilesetId.isEmpty) {
    throw const ValidationException('Tile layer tilesetId cannot be empty');
  }

  final cellCount = map.size.width * map.size.height;
  final newLayer = switch (kind) {
    MapLayerKind.tile => MapLayer.tile(
        id: normalizedId,
        name: normalizedName,
        tilesetId: normalizedTileTilesetId,
        tiles: List<int>.filled(cellCount, 0, growable: false),
      ),
    MapLayerKind.collision => MapLayer.collision(
        id: normalizedId,
        name: normalizedName,
        collisions: List<bool>.filled(cellCount, false, growable: false),
      ),
    MapLayerKind.object => MapLayer.object(
        id: normalizedId,
        name: normalizedName,
      ),
  };

  var targetIndex = insertIndex ?? map.layers.length;
  if (targetIndex < 0) targetIndex = 0;
  if (targetIndex > map.layers.length) targetIndex = map.layers.length;

  final updatedLayers = List<MapLayer>.from(map.layers, growable: true);
  updatedLayers.insert(targetIndex, newLayer);
  return map.copyWith(layers: updatedLayers);
}

MapData renameMapLayer(
  MapData map, {
  required String layerId,
  required String name,
}) {
  final normalizedName = name.trim();
  if (normalizedName.isEmpty) {
    throw const ValidationException('Layer name cannot be empty');
  }

  final layerIndex = map.layers.indexWhere((layer) => layer.id == layerId);
  if (layerIndex < 0) {
    throw ValidationException('Layer not found: $layerId');
  }

  final updatedLayers = List<MapLayer>.from(map.layers, growable: false);
  updatedLayers[layerIndex] = _copyLayer(
    updatedLayers[layerIndex],
    name: normalizedName,
  );
  return map.copyWith(layers: updatedLayers);
}

MapData removeMapLayer(
  MapData map, {
  required String layerId,
}) {
  final layerIndex = map.layers.indexWhere((layer) => layer.id == layerId);
  if (layerIndex < 0) {
    throw ValidationException('Layer not found: $layerId');
  }

  final updatedLayers = List<MapLayer>.from(map.layers, growable: true)
    ..removeAt(layerIndex);
  return map.copyWith(layers: updatedLayers);
}

MapData removeAllMapLayers(MapData map) {
  return map.copyWith(layers: const []);
}

MapData moveMapLayer(
  MapData map, {
  required String layerId,
  required int direction,
}) {
  if (direction == 0) return map;

  final layerIndex = map.layers.indexWhere((layer) => layer.id == layerId);
  if (layerIndex < 0) {
    throw ValidationException('Layer not found: $layerId');
  }

  final targetIndex = layerIndex + direction;
  if (targetIndex < 0 || targetIndex >= map.layers.length) {
    return map;
  }

  final updatedLayers = List<MapLayer>.from(map.layers, growable: true);
  final layer = updatedLayers.removeAt(layerIndex);
  updatedLayers.insert(targetIndex, layer);
  return map.copyWith(layers: updatedLayers);
}

MapData setMapLayerVisibility(
  MapData map, {
  required String layerId,
  required bool isVisible,
}) {
  final layerIndex = map.layers.indexWhere((layer) => layer.id == layerId);
  if (layerIndex < 0) {
    throw ValidationException('Layer not found: $layerId');
  }

  final updatedLayers = List<MapLayer>.from(map.layers, growable: false);
  updatedLayers[layerIndex] = _copyLayer(
    updatedLayers[layerIndex],
    isVisible: isVisible,
  );
  return map.copyWith(layers: updatedLayers);
}

MapData setMapLayerOpacity(
  MapData map, {
  required String layerId,
  required double opacity,
}) {
  if (opacity < 0 || opacity > 1) {
    throw ValidationException(
        'Layer opacity must be between 0 and 1: $opacity');
  }

  final layerIndex = map.layers.indexWhere((layer) => layer.id == layerId);
  if (layerIndex < 0) {
    throw ValidationException('Layer not found: $layerId');
  }

  final updatedLayers = List<MapLayer>.from(map.layers, growable: false);
  updatedLayers[layerIndex] = _copyLayer(
    updatedLayers[layerIndex],
    opacity: opacity,
  );
  return map.copyWith(layers: updatedLayers);
}

MapLayer _copyLayer(
  MapLayer layer, {
  String? name,
  bool? isVisible,
  double? opacity,
}) {
  return layer.map(
    tile: (tileLayer) => tileLayer.copyWith(
      name: name ?? tileLayer.name,
      isVisible: isVisible ?? tileLayer.isVisible,
      opacity: opacity ?? tileLayer.opacity,
    ),
    collision: (collisionLayer) => collisionLayer.copyWith(
      name: name ?? collisionLayer.name,
      isVisible: isVisible ?? collisionLayer.isVisible,
      opacity: opacity ?? collisionLayer.opacity,
    ),
    object: (objectLayer) => objectLayer.copyWith(
      name: name ?? objectLayer.name,
      isVisible: isVisible ?? objectLayer.isVisible,
      opacity: opacity ?? objectLayer.opacity,
    ),
  );
}
