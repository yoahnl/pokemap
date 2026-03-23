import 'package:map_core/map_core.dart';

import '../use_cases/terrain_use_cases.dart';

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
    return _clearPaintedCellsFromOtherTerrainLayers(
      updatedMap: painted,
      layerId: layerId,
      pos: pos,
      patternSize: patternSize,
      terrains: List<TerrainType>.filled(
        patternSize.width * patternSize.height,
        terrain,
        growable: false,
      ),
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
    return _clearPaintedCellsFromOtherTerrainLayers(
      updatedMap: painted,
      layerId: layerId,
      pos: const GridPos(x: 0, y: 0),
      patternSize: map.size,
      terrains: List<TerrainType>.filled(
        map.size.width * map.size.height,
        terrain,
        growable: false,
      ),
    );
  }

  MapData _clearPaintedCellsFromOtherTerrainLayers({
    required MapData updatedMap,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required List<TerrainType> terrains,
  }) {
    final activeLayerIndex =
        updatedMap.layers.indexWhere((layer) => layer.id == layerId);
    if (activeLayerIndex < 0) {
      return updatedMap;
    }

    final expectedLength = updatedMap.size.width * updatedMap.size.height;
    final updatedLayers =
        List<MapLayer>.from(updatedMap.layers, growable: true);
    var changed = false;

    for (var layerIndex = 0; layerIndex < updatedLayers.length; layerIndex++) {
      if (layerIndex == activeLayerIndex) {
        continue;
      }
      final layer = updatedLayers[layerIndex];
      if (layer is! TerrainLayer) {
        continue;
      }

      final nextTerrains = List<TerrainType>.filled(
        expectedLength,
        TerrainType.none,
        growable: false,
      );
      final sourceTerrains = layer.terrains;
      final copyLength = sourceTerrains.length < expectedLength
          ? sourceTerrains.length
          : expectedLength;
      for (var i = 0; i < copyLength; i++) {
        nextTerrains[i] = sourceTerrains[i];
      }

      var layerChanged = false;
      for (var y = 0; y < patternSize.height; y++) {
        for (var x = 0; x < patternSize.width; x++) {
          final patternIndex = y * patternSize.width + x;
          if (patternIndex < 0 || patternIndex >= terrains.length) {
            continue;
          }
          if (terrains[patternIndex] == TerrainType.none) {
            continue;
          }
          final mapX = pos.x + x;
          final mapY = pos.y + y;
          if (mapX < 0 ||
              mapY < 0 ||
              mapX >= updatedMap.size.width ||
              mapY >= updatedMap.size.height) {
            continue;
          }
          final mapIndex = mapY * updatedMap.size.width + mapX;
          if (nextTerrains[mapIndex] == TerrainType.none) {
            continue;
          }
          nextTerrains[mapIndex] = TerrainType.none;
          layerChanged = true;
        }
      }

      if (!layerChanged) {
        continue;
      }
      updatedLayers[layerIndex] = layer.copyWith(terrains: nextTerrains);
      changed = true;
    }

    if (!changed) {
      return updatedMap;
    }
    return updatedMap.copyWith(layers: updatedLayers);
  }
}
