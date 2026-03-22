import '../exceptions/map_exceptions.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';

MapData paintCollisionOnLayer(
  MapData map, {
  required String layerId,
  required GridPos pos,
}) {
  return paintCollisionPatternOnLayer(
    map,
    layerId: layerId,
    pos: pos,
    patternSize: const GridSize(width: 1, height: 1),
    clipToMapBounds: false,
  );
}

MapData paintCollisionPatternOnLayer(
  MapData map, {
  required String layerId,
  required GridPos pos,
  required GridSize patternSize,
  bool clipToMapBounds = true,
}) {
  return _setCollisionPatternOnLayer(
    map,
    layerId: layerId,
    pos: pos,
    patternSize: patternSize,
    value: true,
    clipToMapBounds: clipToMapBounds,
  );
}

MapData eraseCollisionOnLayer(
  MapData map, {
  required String layerId,
  required GridPos pos,
}) {
  return eraseCollisionPatternOnLayer(
    map,
    layerId: layerId,
    pos: pos,
    patternSize: const GridSize(width: 1, height: 1),
    clipToMapBounds: false,
  );
}

MapData eraseCollisionPatternOnLayer(
  MapData map, {
  required String layerId,
  required GridPos pos,
  required GridSize patternSize,
  bool clipToMapBounds = true,
}) {
  return _setCollisionPatternOnLayer(
    map,
    layerId: layerId,
    pos: pos,
    patternSize: patternSize,
    value: false,
    clipToMapBounds: clipToMapBounds,
  );
}

MapData _setCollisionPatternOnLayer(
  MapData map, {
  required String layerId,
  required GridPos pos,
  required GridSize patternSize,
  required bool value,
  required bool clipToMapBounds,
}) {
  if (patternSize.width <= 0 || patternSize.height <= 0) {
    throw const ValidationException('Pattern size must be positive');
  }

  final layerIndex = map.layers.indexWhere((layer) => layer.id == layerId);
  if (layerIndex < 0) {
    throw ValidationException('Layer not found: $layerId');
  }

  final target = map.layers[layerIndex];
  if (target is! CollisionLayer) {
    throw ValidationException(
        'Active layer is not a collision layer: $layerId');
  }

  final expectedLength = map.size.width * map.size.height;
  final nextCollisions =
      List<bool>.filled(expectedLength, false, growable: false);
  final sourceCollisions = target.collisions;
  final copyLimit = sourceCollisions.length < expectedLength
      ? sourceCollisions.length
      : expectedLength;
  for (var i = 0; i < copyLimit; i++) {
    nextCollisions[i] = sourceCollisions[i];
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

      final mapIndex = mapY * map.size.width + mapX;
      nextCollisions[mapIndex] = value;
    }
  }

  final updatedLayers = List<MapLayer>.from(map.layers, growable: false);
  updatedLayers[layerIndex] = target.copyWith(collisions: nextCollisions);
  return map.copyWith(layers: updatedLayers);
}
