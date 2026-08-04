import '../exceptions/map_exceptions.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/geometry.dart';

MapData paintTileOnLayer(
  MapData map, {
  required String layerId,
  required GridPos pos,
  required TileLayerPaletteEntry tile,
}) {
  return paintTilePatternOnLayer(
    map,
    layerId: layerId,
    pos: pos,
    patternSize: const GridSize(width: 1, height: 1),
    tiles: [tile],
    clipToMapBounds: false,
  );
}

MapData paintTilePatternOnLayer(
  MapData map, {
  required String layerId,
  required GridPos pos,
  required GridSize patternSize,
  required List<TileLayerPaletteEntry?> tiles,
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
    final tile = tiles[i];
    if (tile != null &&
        (tile.tilesetId.trim().isEmpty ||
            tile.tilesetId != tile.tilesetId.trim() ||
            tile.localTileId < 0)) {
      throw const ValidationException('Pattern tiles must be canonical');
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
  final nextCells = List<int>.filled(expectedLength, 0, growable: false);
  final sourceTiles = target.cells;
  final copyLimit =
      sourceTiles.length < expectedLength ? sourceTiles.length : expectedLength;
  for (var i = 0; i < copyLimit; i++) {
    nextCells[i] = sourceTiles[i];
  }
  final nextPalette = List<TileLayerPaletteEntry>.from(target.palette);
  final paletteCells = <TileLayerPaletteEntry, int>{
    for (var i = 0; i < nextPalette.length; i++) nextPalette[i]: i + 1,
  };

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
      final tile = tiles[patternIndex];
      nextCells[mapIndex] = tile == null
          ? 0
          : paletteCells.putIfAbsent(tile, () {
              nextPalette.add(tile);
              return nextPalette.length;
            });
    }
  }

  final updatedLayers = List<MapLayer>.from(map.layers, growable: false);
  updatedLayers[layerIndex] = target.copyWith(
    palette: nextPalette,
    cells: nextCells,
  );
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
    tiles: List<TileLayerPaletteEntry?>.filled(
      tileCount,
      null,
      growable: false,
    ),
    clipToMapBounds: clipToMapBounds,
  );
}
