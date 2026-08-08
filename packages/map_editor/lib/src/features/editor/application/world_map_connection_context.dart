import 'dart:ui';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

final class WorldMapConnectionNeighbor {
  const WorldMapConnectionNeighbor({
    required this.direction,
    required this.connection,
    required this.entry,
    required this.map,
    required this.tileBounds,
    required this.exactReciprocalPair,
  });

  final MapConnectionDirection direction;
  final MapConnection connection;
  final ProjectMapEntry entry;
  final MapData map;
  final Rect tileBounds;
  final bool exactReciprocalPair;
}

final class WorldMapConnectionContextIssue {
  const WorldMapConnectionContextIssue({
    required this.direction,
    required this.targetMapId,
    required this.code,
    required this.message,
  });

  final MapConnectionDirection direction;
  final String targetMapId;
  final String code;
  final String message;
}

final class WorldMapConnectionContext {
  WorldMapConnectionContext({
    required this.sourceMap,
    required Map<MapConnectionDirection, WorldMapConnectionNeighbor> neighbors,
    required Map<MapConnectionDirection, WorldMapConnectionContextIssue> issues,
  })  : neighbors = Map.unmodifiable(neighbors),
        issues = Map.unmodifiable(issues),
        contentTileBounds = _contentBounds(sourceMap, neighbors.values);

  final MapData sourceMap;
  final Map<MapConnectionDirection, WorldMapConnectionNeighbor> neighbors;
  final Map<MapConnectionDirection, WorldMapConnectionContextIssue> issues;
  final Rect contentTileBounds;

  static Rect _contentBounds(
    MapData sourceMap,
    Iterable<WorldMapConnectionNeighbor> neighbors,
  ) {
    var bounds = Rect.fromLTWH(
      0,
      0,
      sourceMap.size.width.toDouble(),
      sourceMap.size.height.toDouble(),
    );
    for (final neighbor in neighbors) {
      bounds = bounds.expandToInclude(neighbor.tileBounds);
    }
    return bounds;
  }
}

final class WorldMapConnectionProjectionException implements Exception {
  const WorldMapConnectionProjectionException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class WorldMapConnectionContextProjector {
  const WorldMapConnectionContextProjector({
    this.actions = const WarpConnectionActions(),
  });

  final WarpConnectionActions actions;

  WorldMapConnectionNeighbor projectNeighbor({
    required MapData sourceMap,
    required MapConnection connection,
    required ProjectMapEntry entry,
    required MapData targetMap,
  }) {
    final preview = actions.previewAlignment(
      sourceSize: sourceMap.size,
      targetSize: targetMap.size,
      direction: connection.direction,
      offset: connection.offset,
    );
    if (!preview.hasOverlap) {
      throw WorldMapConnectionProjectionException(
        'La connexion ${connection.direction.name} vers ${targetMap.id} '
        'ne possède aucun recouvrement.',
      );
    }
    final along = (preview.sourceStart - preview.targetStart).toDouble();
    final targetWidth = targetMap.size.width.toDouble();
    final targetHeight = targetMap.size.height.toDouble();
    final sourceWidth = sourceMap.size.width.toDouble();
    final sourceHeight = sourceMap.size.height.toDouble();
    final origin = switch (connection.direction) {
      MapConnectionDirection.north => Offset(along, -targetHeight),
      MapConnectionDirection.east => Offset(sourceWidth, along),
      MapConnectionDirection.south => Offset(along, sourceHeight),
      MapConnectionDirection.west => Offset(-targetWidth, along),
    };
    final reciprocal = _connectionFor(
      targetMap,
      connection.direction.opposite,
    );
    return WorldMapConnectionNeighbor(
      direction: connection.direction,
      connection: connection,
      entry: entry,
      map: targetMap,
      tileBounds: Rect.fromLTWH(
        origin.dx,
        origin.dy,
        targetWidth,
        targetHeight,
      ),
      exactReciprocalPair: reciprocal != null &&
          reciprocal.targetMapId == sourceMap.id &&
          reciprocal.offset == -connection.offset,
    );
  }
}

MapConnection? _connectionFor(
  MapData map,
  MapConnectionDirection direction,
) {
  for (final connection in map.connections) {
    if (connection.direction == direction) return connection;
  }
  return null;
}
