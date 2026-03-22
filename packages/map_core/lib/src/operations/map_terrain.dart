import '../exceptions/map_exceptions.dart';
import '../models/enums.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';

MapData paintTerrainOnLayer(
  MapData map, {
  required String layerId,
  required GridPos pos,
  required TerrainType terrain,
}) {
  return paintTerrainPatternOnLayer(
    map,
    layerId: layerId,
    pos: pos,
    patternSize: const GridSize(width: 1, height: 1),
    terrains: [terrain],
    clipToMapBounds: false,
  );
}

MapData paintTerrainPatternOnLayer(
  MapData map, {
  required String layerId,
  required GridPos pos,
  required GridSize patternSize,
  required List<TerrainType> terrains,
  bool clipToMapBounds = true,
}) {
  if (patternSize.width <= 0 || patternSize.height <= 0) {
    throw const ValidationException('Pattern size must be positive');
  }
  final patternLength = patternSize.width * patternSize.height;
  if (terrains.length < patternLength) {
    throw const ValidationException('Pattern terrain data is incomplete');
  }

  final layerIndex = map.layers.indexWhere((layer) => layer.id == layerId);
  if (layerIndex < 0) {
    throw ValidationException('Layer not found: $layerId');
  }

  final target = map.layers[layerIndex];
  if (target is! TerrainLayer) {
    throw ValidationException('Active layer is not a terrain layer: $layerId');
  }

  final expectedLength = map.size.width * map.size.height;
  final nextTerrains = List<TerrainType>.filled(
      expectedLength, TerrainType.none,
      growable: false);
  final sourceTerrains = target.terrains;
  final copyLimit = sourceTerrains.length < expectedLength
      ? sourceTerrains.length
      : expectedLength;
  for (var i = 0; i < copyLimit; i++) {
    nextTerrains[i] = sourceTerrains[i];
  }

  for (var y = 0; y < patternSize.height; y++) {
    for (var x = 0; x < patternSize.width; x++) {
      final mapX = pos.x + x;
      final mapY = pos.y + y;
      if (mapX < 0 ||
          mapY < 0 ||
          mapX >= map.size.width ||
          mapY >= map.size.height) {
        if (clipToMapBounds) {
          continue;
        }
        throw const ValidationException('Paint position is outside map bounds');
      }

      final patternIndex = y * patternSize.width + x;
      final mapIndex = mapY * map.size.width + mapX;
      nextTerrains[mapIndex] = terrains[patternIndex];
    }
  }

  final updatedLayers = List<MapLayer>.from(map.layers, growable: false);
  updatedLayers[layerIndex] = target.copyWith(terrains: nextTerrains);
  return map.copyWith(layers: updatedLayers);
}

MapData eraseTerrainOnLayer(
  MapData map, {
  required String layerId,
  required GridPos pos,
}) {
  return eraseTerrainPatternOnLayer(
    map,
    layerId: layerId,
    pos: pos,
    patternSize: const GridSize(width: 1, height: 1),
    clipToMapBounds: false,
  );
}

MapData eraseTerrainPatternOnLayer(
  MapData map, {
  required String layerId,
  required GridPos pos,
  required GridSize patternSize,
  bool clipToMapBounds = true,
}) {
  if (patternSize.width <= 0 || patternSize.height <= 0) {
    throw const ValidationException('Pattern size must be positive');
  }
  final length = patternSize.width * patternSize.height;
  return paintTerrainPatternOnLayer(
    map,
    layerId: layerId,
    pos: pos,
    patternSize: patternSize,
    terrains:
        List<TerrainType>.filled(length, TerrainType.none, growable: false),
    clipToMapBounds: clipToMapBounds,
  );
}
