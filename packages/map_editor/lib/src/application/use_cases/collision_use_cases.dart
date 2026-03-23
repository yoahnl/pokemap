import 'package:map_core/map_core.dart';

class PaintCollisionOnMapUseCase {
  MapData execute(
    MapData map, {
    required String layerId,
    required GridPos pos,
  }) {
    final painted = paintCollisionOnLayer(
      map,
      layerId: layerId,
      pos: pos,
    );
    MapValidator.validate(painted);
    return painted;
  }
}

class PaintCollisionPatternOnMapUseCase {
  MapData execute(
    MapData map, {
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    bool clipToMapBounds = true,
  }) {
    final painted = paintCollisionPatternOnLayer(
      map,
      layerId: layerId,
      pos: pos,
      patternSize: patternSize,
      clipToMapBounds: clipToMapBounds,
    );
    MapValidator.validate(painted);
    return painted;
  }
}

class EraseCollisionOnMapUseCase {
  MapData execute(
    MapData map, {
    required String layerId,
    required GridPos pos,
  }) {
    final erased = eraseCollisionOnLayer(
      map,
      layerId: layerId,
      pos: pos,
    );
    MapValidator.validate(erased);
    return erased;
  }
}

class EraseCollisionPatternOnMapUseCase {
  MapData execute(
    MapData map, {
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    bool clipToMapBounds = true,
  }) {
    final erased = eraseCollisionPatternOnLayer(
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
