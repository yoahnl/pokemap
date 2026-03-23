import 'package:map_core/map_core.dart';

class PaintPathOnMapUseCase {
  MapData execute(
    MapData map, {
    required String layerId,
    required GridPos pos,
  }) {
    final painted = paintPathOnLayer(
      map,
      layerId: layerId,
      pos: pos,
    );
    MapValidator.validate(painted);
    return painted;
  }
}

class PaintPathPatternOnMapUseCase {
  MapData execute(
    MapData map, {
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required List<bool> cells,
    bool clipToMapBounds = true,
  }) {
    final painted = paintPathPatternOnLayer(
      map,
      layerId: layerId,
      pos: pos,
      patternSize: patternSize,
      cells: cells,
      clipToMapBounds: clipToMapBounds,
    );
    MapValidator.validate(painted);
    return painted;
  }
}

class ErasePathOnMapUseCase {
  MapData execute(
    MapData map, {
    required String layerId,
    required GridPos pos,
  }) {
    final erased = erasePathOnLayer(
      map,
      layerId: layerId,
      pos: pos,
    );
    MapValidator.validate(erased);
    return erased;
  }
}

class ErasePathPatternOnMapUseCase {
  MapData execute(
    MapData map, {
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    bool clipToMapBounds = true,
  }) {
    final erased = erasePathPatternOnLayer(
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

class AssignPathPresetToLayerUseCase {
  MapData execute(
    MapData map, {
    required String layerId,
    required String presetId,
  }) {
    final updated = assignPathPresetToLayer(
      map,
      layerId: layerId,
      presetId: presetId,
    );
    MapValidator.validate(updated);
    return updated;
  }
}

class SetPathLayerPropertiesUseCase {
  MapData execute(
    MapData map, {
    required String layerId,
    required Map<String, String> properties,
  }) {
    final updated = setPathLayerProperties(
      map,
      layerId: layerId,
      properties: properties,
    );
    MapValidator.validate(updated);
    return updated;
  }
}
