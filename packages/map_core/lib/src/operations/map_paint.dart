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
  if (pos.x < 0 ||
      pos.y < 0 ||
      pos.x >= map.size.width ||
      pos.y >= map.size.height) {
    throw const ValidationException('Paint position is outside map bounds');
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
  final tiles = List<int>.filled(expectedLength, 0, growable: false);
  final source = target.tiles;
  final limit = source.length < expectedLength ? source.length : expectedLength;
  for (var i = 0; i < limit; i++) {
    tiles[i] = source[i];
  }

  final index = pos.y * map.size.width + pos.x;
  tiles[index] = tileId;

  final updatedLayers = List<MapLayer>.from(map.layers, growable: false);
  updatedLayers[layerIndex] = target.copyWith(tiles: tiles);

  return map.copyWith(layers: updatedLayers);
}
