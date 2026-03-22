import '../exceptions/map_exceptions.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/geometry.dart';

MapData paintTileOnLayer(
  MapData map, {
  required String layerId,
  required GridPos pos,
  required int tileId,
}) {
  if (tileId < 0) {
    throw const ValidationException('Tile ID must be >= 0');
  }
  return paintTilePatternOnLayer(
    map,
    layerId: layerId,
    pos: pos,
    patternSize: const GridSize(width: 1, height: 1),
    tiles: [tileId],
    clipToMapBounds: false,
  );
}

MapData paintTilePatternOnLayer(
  MapData map, {
  required String layerId,
  required GridPos pos,
  required GridSize patternSize,
  required List<int> tiles,
  bool clipToMapBounds = true,
}) {
  if (patternSize.width <= 0 || patternSize.height <= 0) {
    throw const ValidationException('Pattern size must be positive');
  }
  final patternLength = patternSize.width * patternSize.height;
  if (tiles.length < patternLength) {
    throw const ValidationException('Pattern tile data is incomplete');
  }
  for (var i = 0; i < patternLength; i++) {
    if (tiles[i] < 0) {
      throw const ValidationException('Pattern tile IDs must be >= 0');
    }
  }

  final layerIndex = map.layers.indexWhere((layer) => layer.id == layerId);
  if (layerIndex < 0) {
    throw ValidationException('Layer not found: $layerId');
  }

  final target = map.layers[layerIndex];
  if (target is! TileLayer) {
    throw ValidationException('Active layer is not a tile layer: $layerId');
  }

  final expectedLength = map.size.width * map.size.height;
  final nextTiles = List<int>.filled(expectedLength, 0, growable: false);
  final sourceTiles = target.tiles;
  final copyLimit =
      sourceTiles.length < expectedLength ? sourceTiles.length : expectedLength;
  for (var i = 0; i < copyLimit; i++) {
    nextTiles[i] = sourceTiles[i];
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
      nextTiles[mapIndex] = tiles[patternIndex];
    }
  }

  final updatedLayers = List<MapLayer>.from(map.layers, growable: false);
  updatedLayers[layerIndex] = target.copyWith(tiles: nextTiles);
  return map.copyWith(layers: updatedLayers);
}

MapData eraseTileOnLayer(
  MapData map, {
  required String layerId,
  required GridPos pos,
}) {
  return eraseTilePatternOnLayer(
    map,
    layerId: layerId,
    pos: pos,
    patternSize: const GridSize(width: 1, height: 1),
    clipToMapBounds: false,
  );
}

MapData eraseTilePatternOnLayer(
  MapData map, {
  required String layerId,
  required GridPos pos,
  required GridSize patternSize,
  bool clipToMapBounds = true,
}) {
  if (patternSize.width <= 0 || patternSize.height <= 0) {
    throw const ValidationException('Pattern size must be positive');
  }
  final tileCount = patternSize.width * patternSize.height;
  return paintTilePatternOnLayer(
    map,
    layerId: layerId,
    pos: pos,
    patternSize: patternSize,
    tiles: List<int>.filled(tileCount, 0, growable: false),
    clipToMapBounds: clipToMapBounds,
  );
}
