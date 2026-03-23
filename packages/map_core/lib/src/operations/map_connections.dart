import 'dart:math' as math;

import '../exceptions/map_exceptions.dart';
import '../models/enums.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';

MapConnection? findMapConnection(
  MapData map,
  MapConnectionDirection direction,
) {
  for (final connection in map.connections) {
    if (connection.direction == direction) {
      return connection;
    }
  }
  return null;
}

MapData upsertMapConnectionOnMap(
  MapData map, {
  required MapConnection connection,
}) {
  _validateMapConnection(map, connection);
  final updatedConnections = List<MapConnection>.from(
    map.connections,
    growable: true,
  );
  final existingIndex = updatedConnections.indexWhere(
    (entry) => entry.direction == connection.direction,
  );
  if (existingIndex >= 0) {
    updatedConnections[existingIndex] = connection;
  } else {
    updatedConnections.add(connection);
  }
  updatedConnections.sort(
    (left, right) => left.direction.index.compareTo(right.direction.index),
  );
  return map.copyWith(connections: updatedConnections);
}

MapData removeMapConnectionFromMap(
  MapData map, {
  required MapConnectionDirection direction,
}) {
  final existingIndex = map.connections.indexWhere(
    (entry) => entry.direction == direction,
  );
  if (existingIndex < 0) {
    throw ValidationException(
      'Map connection not found for direction: ${direction.name}',
    );
  }
  final updatedConnections = List<MapConnection>.from(
    map.connections,
    growable: true,
  )..removeAt(existingIndex);
  return map.copyWith(connections: updatedConnections);
}

int computeMapConnectionOverlapLength({
  required GridSize sourceSize,
  required GridSize targetSize,
  required MapConnectionDirection direction,
  required int offset,
}) {
  final sourceLength =
      direction.usesHorizontalOffset ? sourceSize.width : sourceSize.height;
  final targetLength =
      direction.usesHorizontalOffset ? targetSize.width : targetSize.height;
  final overlapStart = math.max(0, offset);
  final overlapEnd = math.min(sourceLength, offset + targetLength);
  return math.max(0, overlapEnd - overlapStart);
}

bool hasMapConnectionOverlap({
  required GridSize sourceSize,
  required GridSize targetSize,
  required MapConnectionDirection direction,
  required int offset,
}) {
  return computeMapConnectionOverlapLength(
        sourceSize: sourceSize,
        targetSize: targetSize,
        direction: direction,
        offset: offset,
      ) >
      0;
}

void _validateMapConnection(
  MapData map,
  MapConnection connection,
) {
  final targetMapId = connection.targetMapId.trim();
  if (targetMapId.isEmpty) {
    throw ValidationException(
      'Map connection ${connection.direction.name} has empty targetMapId',
    );
  }
  if (targetMapId == map.id.trim()) {
    throw ValidationException(
      'Map connection ${connection.direction.name} cannot target its own map',
    );
  }
}
