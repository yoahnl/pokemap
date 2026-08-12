import 'package:map_core/map_core.dart';

import '../services/editor_performance_telemetry.dart';

class PaintCollisionOnMapUseCase {
  MapData execute(
    MapData map, {
    required String layerId,
    required GridPos pos,
  }) {
    final painted = paintCollisionOnLayer(map, layerId: layerId, pos: pos);
    _validateCollisionDelta(
      before: map,
      after: painted,
      layerId: layerId,
      pos: pos,
      patternSize: const GridSize(width: 1, height: 1),
    );
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
    _validateCollisionDelta(
      before: map,
      after: painted,
      layerId: layerId,
      pos: pos,
      patternSize: patternSize,
    );
    return painted;
  }
}

class EraseCollisionOnMapUseCase {
  MapData execute(
    MapData map, {
    required String layerId,
    required GridPos pos,
  }) {
    final erased = eraseCollisionOnLayer(map, layerId: layerId, pos: pos);
    _validateCollisionDelta(
      before: map,
      after: erased,
      layerId: layerId,
      pos: pos,
      patternSize: const GridSize(width: 1, height: 1),
    );
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
    _validateCollisionDelta(
      before: map,
      after: erased,
      layerId: layerId,
      pos: pos,
      patternSize: patternSize,
    );
    return erased;
  }
}

void _validateCollisionDelta({
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
      delta: MapMutationDelta.collisionCells(
        layerId: layerId,
        cellIndices: cellIndices,
      ),
    ),
  );
}
