import 'package:map_core/map_core.dart';

class PaintTerrainOnMapUseCase {
  MapData execute(
    MapData map, {
    required String layerId,
    required GridPos pos,
    required TerrainType terrain,
  }) {
    final painted = paintTerrainOnLayer(
      map,
      layerId: layerId,
      pos: pos,
      terrain: terrain,
    );
    MapValidator.validate(painted);
    return painted;
  }
}

class PaintTerrainPatternOnMapUseCase {
  MapData execute(
    MapData map, {
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required List<TerrainType> terrains,
    bool clipToMapBounds = true,
  }) {
    final painted = paintTerrainPatternOnLayer(
      map,
      layerId: layerId,
      pos: pos,
      patternSize: patternSize,
      terrains: terrains,
      clipToMapBounds: clipToMapBounds,
    );
    MapValidator.validate(painted);
    return painted;
  }
}

class EraseTerrainOnMapUseCase {
  MapData execute(
    MapData map, {
    required String layerId,
    required GridPos pos,
  }) {
    final erased = eraseTerrainOnLayer(
      map,
      layerId: layerId,
      pos: pos,
    );
    MapValidator.validate(erased);
    return erased;
  }
}

class EraseTerrainPatternOnMapUseCase {
  MapData execute(
    MapData map, {
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    bool clipToMapBounds = true,
  }) {
    final erased = eraseTerrainPatternOnLayer(
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
