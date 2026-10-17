import 'dart:math' as math;

import '../exceptions/map_exceptions.dart';
import '../models/enums.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';

String mapConnectionResourceId(String mapId, MapConnection connection) =>
    '${Uri.encodeComponent(mapId)}:${connection.direction.name}:${Uri.encodeComponent(connection.targetMapId)}';

bool mapConnectionSpansOverlap({
  required GridSize sourceSize,
  required MapConnection first,
  required GridSize firstTargetSize,
  required MapConnection second,
  required GridSize secondTargetSize,
}) {
  if (first.direction != second.direction) return false;
  final horizontal = first.direction.usesHorizontalOffset;
  final sourceLength = horizontal ? sourceSize.width : sourceSize.height;
  final start = math.max(0, math.max(first.offset, second.offset));
  final end = math.min(
    sourceLength,
    math.min(
      first.offset +
          (horizontal ? firstTargetSize.width : firstTargetSize.height),
      second.offset +
          (horizontal ? secondTargetSize.width : secondTargetSize.height),
    ),
  );
  return start < end;
}

MapConnection? findMapConnection(
  MapData map,
  MapConnectionDirection direction, {
  String? targetMapId,
}) {
  MapConnection? result;
  for (final connection in map.connections) {
    if (connection.direction == direction &&
        (targetMapId == null || connection.targetMapId == targetMapId)) {
      if (result != null) {
        throw ValidationException(
          'Ambiguous map connection: ${direction.name}',
        );
      }
      result = connection;
    }
  }
  return result;
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
    (entry) =>
        entry.direction == connection.direction &&
        entry.targetMapId == connection.targetMapId,
  );
  if (existingIndex >= 0) {
    updatedConnections[existingIndex] = connection;
  } else {
    updatedConnections.add(connection);
  }
  updatedConnections.sort((left, right) {
    final direction = left.direction.index.compareTo(right.direction.index);
    return direction == 0
        ? left.targetMapId.compareTo(right.targetMapId)
        : direction;
  });
  return map.copyWith(connections: updatedConnections);
}

MapData removeMapConnectionFromMap(
  MapData map, {
  required MapConnectionDirection direction,
  String? targetMapId,
}) {
  final connection = findMapConnection(
    map,
    direction,
    targetMapId: targetMapId,
  );
  final existingIndex = map.connections.indexWhere(
    (entry) => identical(entry, connection),
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

void _validateMapConnection(MapData map, MapConnection connection) {
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
