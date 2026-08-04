import 'package:map_core/map_core.dart';

class PaintTileOnMapUseCase {
  MapData execute(
    MapData map, {
    required String layerId,
    required GridPos pos,
    required TileLayerPaletteEntry tile,
  }) {
    final painted = paintTileOnLayer(
      map,
      layerId: layerId,
      pos: pos,
      tile: tile,
    );
    MapValidator.validate(painted);
    return painted;
  }
}

class PaintTilePatternOnMapUseCase {
  MapData execute(
    MapData map, {
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required List<TileLayerPaletteEntry?> tiles,
    bool clipToMapBounds = true,
  }) {
    final painted = paintTilePatternOnLayer(
      map,
      layerId: layerId,
      pos: pos,
      patternSize: patternSize,
      tiles: tiles,
      clipToMapBounds: clipToMapBounds,
    );
    MapValidator.validate(painted);
    return painted;
  }
}

class EraseTileOnMapUseCase {
  MapData execute(
    MapData map, {
    required String layerId,
    required GridPos pos,
  }) {
    final erased = eraseTileOnLayer(
      map,
      layerId: layerId,
      pos: pos,
    );
    MapValidator.validate(erased);
    return erased;
  }
}

class EraseTilePatternOnMapUseCase {
  MapData execute(
    MapData map, {
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    bool clipToMapBounds = true,
  }) {
    final erased = eraseTilePatternOnLayer(
      map,
      layerId: layerId,
      pos: pos,
      patternSize: patternSize,
      clipToMapBounds: clipToMapBounds,
    );
    MapValidator.validate(erased);
    return erased;
  }
}
