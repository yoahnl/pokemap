import 'package:map_core/map_core.dart';

import '../use_cases/project_use_cases.dart';

class TerrainBrushFootprint {
  const TerrainBrushFootprint({
    required this.size,
    required this.failureLabel,
  });

  final GridSize size;
  final String failureLabel;
}

class TerrainPaintingCoordinator {
  const TerrainPaintingCoordinator({
    required PaintTerrainOnMapUseCase paintTerrainOnMapUseCase,
    required PaintTerrainPatternOnMapUseCase paintTerrainPatternOnMapUseCase,
    required EraseTerrainOnMapUseCase eraseTerrainOnMapUseCase,
    required EraseTerrainPatternOnMapUseCase eraseTerrainPatternOnMapUseCase,
  })  : _paintTerrainOnMapUseCase = paintTerrainOnMapUseCase,
        _paintTerrainPatternOnMapUseCase = paintTerrainPatternOnMapUseCase,
        _eraseTerrainOnMapUseCase = eraseTerrainOnMapUseCase,
        _eraseTerrainPatternOnMapUseCase = eraseTerrainPatternOnMapUseCase;

  final PaintTerrainOnMapUseCase _paintTerrainOnMapUseCase;
  final PaintTerrainPatternOnMapUseCase _paintTerrainPatternOnMapUseCase;
  final EraseTerrainOnMapUseCase _eraseTerrainOnMapUseCase;
  final EraseTerrainPatternOnMapUseCase _eraseTerrainPatternOnMapUseCase;

  TerrainBrushFootprint resolveFootprint({
    required TerrainType terrain,
  }) {
    return TerrainBrushFootprint(
      size: const GridSize(width: 1, height: 1),
      failureLabel: terrain == TerrainType.path ? 'path' : 'terrain',
    );
  }

  MapData paint({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required TerrainType terrain,
    required GridSize patternSize,
  }) {
    final painted = patternSize.width == 1 && patternSize.height == 1
        ? _paintTerrainOnMapUseCase.execute(
            map,
            layerId: layerId,
            pos: pos,
            terrain: terrain,
          )
        : _paintTerrainPatternOnMapUseCase.execute(
            map,
            layerId: layerId,
            pos: pos,
            patternSize: patternSize,
            terrains: List<TerrainType>.filled(
              patternSize.width * patternSize.height,
              terrain,
              growable: false,
            ),
            clipToMapBounds: true,
          );
    if (terrain == TerrainType.path) {
      return painted;
    }
    return _preserveExistingPathCellsOnTerrainLayer(
      previousMap: map,
      updatedMap: painted,
      layerId: layerId,
    );
  }

  MapData erase({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
  }) {
    if (patternSize.width == 1 && patternSize.height == 1) {
      return _eraseTerrainOnMapUseCase.execute(
        map,
        layerId: layerId,
        pos: pos,
      );
    }
    return _eraseTerrainPatternOnMapUseCase.execute(
      map,
      layerId: layerId,
      pos: pos,
      patternSize: patternSize,
      clipToMapBounds: true,
    );
  }

  MapData fill({
    required MapData map,
    required String layerId,
    required TerrainType terrain,
  }) {
    final painted = _paintTerrainPatternOnMapUseCase.execute(
      map,
      layerId: layerId,
      pos: const GridPos(x: 0, y: 0),
      patternSize: map.size,
      terrains: List<TerrainType>.filled(
        map.size.width * map.size.height,
        terrain,
        growable: false,
      ),
      clipToMapBounds: true,
    );
    if (terrain == TerrainType.path) {
      return painted;
    }
    return _preserveExistingPathCellsOnTerrainLayer(
      previousMap: map,
      updatedMap: painted,
      layerId: layerId,
    );
  }

  MapData _preserveExistingPathCellsOnTerrainLayer({
    required MapData previousMap,
    required MapData updatedMap,
    required String layerId,
  }) {
    final previousLayer = _findLayerById(previousMap, layerId);
    final updatedLayer = _findLayerById(updatedMap, layerId);
    if (previousLayer is! TerrainLayer || updatedLayer is! TerrainLayer) {
      return updatedMap;
    }

    final expectedLength = updatedMap.size.width * updatedMap.size.height;
    final nextTerrains = List<TerrainType>.filled(
      expectedLength,
      TerrainType.none,
      growable: false,
    );
    final updatedSource = updatedLayer.terrains;
    final updatedCopyLength = updatedSource.length < expectedLength
        ? updatedSource.length
        : expectedLength;
    for (var i = 0; i < updatedCopyLength; i++) {
      nextTerrains[i] = updatedSource[i];
    }

    var changed = false;
    final previousSource = previousLayer.terrains;
    final previousCopyLength = previousSource.length < expectedLength
        ? previousSource.length
        : expectedLength;
    for (var i = 0; i < previousCopyLength; i++) {
      if (previousSource[i] != TerrainType.path) continue;
      if (nextTerrains[i] == TerrainType.path) continue;
      nextTerrains[i] = TerrainType.path;
      changed = true;
    }
    if (!changed) {
      return updatedMap;
    }

    final layerIndex =
        updatedMap.layers.indexWhere((layer) => layer.id == layerId);
    if (layerIndex < 0) {
      return updatedMap;
    }
    final updatedLayers =
        List<MapLayer>.from(updatedMap.layers, growable: false);
    final layer = updatedLayers[layerIndex];
    if (layer is! TerrainLayer) {
      return updatedMap;
    }
    updatedLayers[layerIndex] = layer.copyWith(terrains: nextTerrains);
    return updatedMap.copyWith(layers: updatedLayers);
  }

  MapLayer? _findLayerById(MapData map, String layerId) {
    for (final layer in map.layers) {
      if (layer.id == layerId) {
        return layer;
      }
    }
    return null;
  }
}
