import '../exceptions/map_exceptions.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';

MapData paintPathOnLayer(
  MapData map, {
  required String layerId,
  required GridPos pos,
}) {
  return paintPathPatternOnLayer(
    map,
    layerId: layerId,
    pos: pos,
    patternSize: const GridSize(width: 1, height: 1),
    cells: const [true],
    clipToMapBounds: false,
  );
}

MapData paintPathPatternOnLayer(
  MapData map, {
  required String layerId,
  required GridPos pos,
  required GridSize patternSize,
  required List<bool> cells,
  bool clipToMapBounds = true,
}) {
  if (patternSize.width <= 0 || patternSize.height <= 0) {
    throw const ValidationException('Pattern size must be positive');
  }
  final patternLength = patternSize.width * patternSize.height;
  if (cells.length < patternLength) {
    throw const ValidationException('Pattern path data is incomplete');
  }

  final layerIndex = map.layers.indexWhere((layer) => layer.id == layerId);
  if (layerIndex < 0) {
    throw ValidationException('Layer not found: $layerId');
  }

  final target = map.layers[layerIndex];
  if (target is! PathLayer) {
    throw ValidationException('Active layer is not a path layer: $layerId');
  }

  final expectedLength = map.size.width * map.size.height;
  final nextCells = List<bool>.filled(expectedLength, false, growable: false);
  final sourceCells = target.cells;
  final copyLimit =
      sourceCells.length < expectedLength ? sourceCells.length : expectedLength;
  for (var i = 0; i < copyLimit; i++) {
    nextCells[i] = sourceCells[i];
  }

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
      nextCells[mapIndex] = cells[patternIndex];
    }
  }

  final updatedLayers = List<MapLayer>.from(map.layers, growable: false);
  updatedLayers[layerIndex] = target.copyWith(cells: nextCells);
  return map.copyWith(layers: updatedLayers);
}

MapData erasePathOnLayer(
  MapData map, {
  required String layerId,
  required GridPos pos,
}) {
  return erasePathPatternOnLayer(
    map,
    layerId: layerId,
    pos: pos,
    patternSize: const GridSize(width: 1, height: 1),
    clipToMapBounds: false,
  );
}

MapData erasePathPatternOnLayer(
  MapData map, {
  required String layerId,
  required GridPos pos,
  required GridSize patternSize,
  bool clipToMapBounds = true,
}) {
  if (patternSize.width <= 0 || patternSize.height <= 0) {
    throw const ValidationException('Pattern size must be positive');
  }
  final length = patternSize.width * patternSize.height;
  return paintPathPatternOnLayer(
    map,
    layerId: layerId,
    pos: pos,
    patternSize: patternSize,
    cells: List<bool>.filled(length, false, growable: false),
    clipToMapBounds: clipToMapBounds,
  );
}

MapData assignPathPresetToLayer(
  MapData map, {
  required String layerId,
  required String presetId,
}) {
  final layerIndex = map.layers.indexWhere((layer) => layer.id == layerId);
  if (layerIndex < 0) {
    throw ValidationException('Layer not found: $layerId');
  }

  final target = map.layers[layerIndex];
  if (target is! PathLayer) {
    throw ValidationException('Active layer is not a path layer: $layerId');
  }

  final updatedLayers = List<MapLayer>.from(map.layers, growable: false);
  updatedLayers[layerIndex] = target.copyWith(presetId: presetId.trim());
  return map.copyWith(layers: updatedLayers);
}

MapData setPathLayerProperties(
  MapData map, {
  required String layerId,
  required Map<String, String> properties,
}) {
  final layerIndex = map.layers.indexWhere((layer) => layer.id == layerId);
  if (layerIndex < 0) {
    throw ValidationException('Layer not found: $layerId');
  }

  final target = map.layers[layerIndex];
  if (target is! PathLayer) {
    throw ValidationException('Active layer is not a path layer: $layerId');
  }

  final normalizedProperties = <String, String>{};
  for (final entry in properties.entries) {
    final key = entry.key.trim();
    if (key.isEmpty) {
      throw const ValidationException(
          'Path layer property key cannot be empty');
    }
    normalizedProperties[key] = entry.value;
  }

  final updatedLayers = List<MapLayer>.from(map.layers, growable: false);
  updatedLayers[layerIndex] = target.copyWith(properties: normalizedProperties);
  return map.copyWith(layers: updatedLayers);
}
