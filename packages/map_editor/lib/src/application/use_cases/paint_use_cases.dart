import 'package:map_core/map_core.dart';

import '../services/editor_performance_telemetry.dart';

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
    _validateTileDelta(
      before: map,
      after: painted,
      layerId: layerId,
      pos: pos,
      patternSize: const GridSize(width: 1, height: 1),
    );
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
    _validateTileDelta(
      before: map,
      after: painted,
      layerId: layerId,
      pos: pos,
      patternSize: patternSize,
    );
    return painted;
  }
}

class EraseTileOnMapUseCase {
  MapData execute(
    MapData map, {
    required String layerId,
    required GridPos pos,
  }) {
    final erased = eraseTileOnLayer(map, layerId: layerId, pos: pos);
    _validateTileDelta(
      before: map,
      after: erased,
      layerId: layerId,
      pos: pos,
      patternSize: const GridSize(width: 1, height: 1),
    );
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
    _validateTileDelta(
      before: map,
      after: erased,
      layerId: layerId,
      pos: pos,
      patternSize: patternSize,
    );
    return erased;
  }
}

void _validateTileDelta({
  required MapData before,
  required MapData after,
  required String layerId,
  required GridPos pos,
  required GridSize patternSize,
}) {
  final cellIndices = mapDeltaCellIndicesForRectangle(
    mapSize: before.size,
    origin: pos,
    size: patternSize,
  );
  if (cellIndices.isEmpty) return;
  EditorPerformanceTelemetry.validateMapDelta(
    DeltaValidationContext(
      before: before,
      after: after,
      delta: MapMutationDelta.tileCells(
        layerId: layerId,
        cellIndices: cellIndices,
      ),
    ),
  );
}
