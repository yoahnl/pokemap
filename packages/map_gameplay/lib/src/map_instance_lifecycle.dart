import 'dart:math' as math;

import 'package:map_core/map_core.dart';

final class MapInstanceMapGeometry {
  MapInstanceMapGeometry({
    required String mapId,
    required this.originTiles,
    required this.sizeTiles,
  }) : mapId = _identity(mapId) {
    _integer(originTiles.x, 'originTiles.x', -2147483648);
    _integer(originTiles.y, 'originTiles.y', -2147483648);
    _integer(sizeTiles.width, 'sizeTiles.width', 1);
    _integer(sizeTiles.height, 'sizeTiles.height', 1);
  }

  final String mapId;
  final GridPos originTiles;
  final GridSize sizeTiles;
}

final class MapInstanceLogicalViewport {
  MapInstanceLogicalViewport({
    required double leftTiles,
    required double topTiles,
  })  : leftTiles = _finite(leftTiles, 'leftTiles'),
        topTiles = _finite(topTiles, 'topTiles');

  final double leftTiles;
  final double topTiles;
}

MapInstanceWorldState setupDifferentMapInstance({
  required MapInstanceWorldState state,
  required String targetMapId,
  required String Function(String mapId) allocateId,
}) {
  _identity(targetMapId);
  final instance =
      _createInstance(targetMapId, allocateId, _instanceIds(state));
  return MapInstanceWorldState(persistentClearedObstacles: state.persistentClearedObstacles, instancesByMapId: {targetMapId: instance});
}

MapInstanceWorldState preserveSameMapInstance({
  required MapInstanceWorldState state,
  required String mapId,
}) {
  if (state.instanceRef(mapId) == null) {
    throw StateError('Map $mapId has no current logical instance.');
  }
  return state;
}

MapInstanceWorldState retainMapInstance({
  required MapInstanceWorldState state,
  required String mapId,
  required String Function(String mapId) allocateId,
}) {
  _identity(mapId);
  if (state.instancesByMapId.containsKey(mapId)) return state;
  final instance = _createInstance(mapId, allocateId, _instanceIds(state));
  return MapInstanceWorldState(persistentClearedObstacles: state.persistentClearedObstacles, instancesByMapId: {
    ...state.instancesByMapId,
    mapId: instance,
  });
}

MapInstanceLogicalViewport resolveMapInstanceLogicalViewport({
  required double playerAnchorX,
  required double playerAnchorY,
  required MapInstanceMapGeometry activeMap,
  required MapInstanceRetentionPolicy policy,
}) {
  final left = _finite(playerAnchorX, 'playerAnchorX') -
      (policy.viewportWidthTiles - 1) / 2;
  final top = _finite(playerAnchorY, 'playerAnchorY') -
      (policy.viewportHeightTiles - 1) / 2;
  final display = _display(left, top, activeMap, policy);
  return MapInstanceLogicalViewport(
    leftTiles: activeMap.originTiles.x + display.$1,
    topTiles: activeMap.originTiles.y + display.$2,
  );
}

MapInstanceWorldState updateMapInstanceRetention({
  required MapInstanceWorldState state,
  required MapInstanceMapGeometry activeMap,
  required Iterable<MapInstanceMapGeometry> directConnectedMaps,
  required MapInstanceLogicalViewport logicalViewport,
  required MapInstanceRetentionPolicy policy,
  required bool settled,
  required String Function(String mapId) allocateId,
}) {
  preserveSameMapInstance(state: state, mapId: activeMap.mapId);
  final neighbors = <String, MapInstanceMapGeometry>{};
  for (final geometry in directConnectedMaps) {
    if (geometry.mapId == activeMap.mapId ||
        neighbors.containsKey(geometry.mapId)) {
      throw ArgumentError(
          'Connected map geometry must have unique identities.');
    }
    neighbors[geometry.mapId] = geometry;
  }
  if (!settled) return state;
  final instanceIds = _instanceIds(state);
  final result = <String, MapInstanceRuntimeState>{
    activeMap.mapId: state.instancesByMapId[activeMap.mapId]!,
  };
  final neighborIds = neighbors.keys.toList()..sort();
  for (final mapId in neighborIds) {
    final geometry = neighbors[mapId]!;
    final left = logicalViewport.leftTiles - geometry.originTiles.x;
    final top = logicalViewport.topTiles - geometry.originTiles.y;
    final existing = state.instancesByMapId[mapId];
    if (existing == null && !_inRange(left, top, geometry, policy)) {
      continue;
    }
    final instance =
        existing ?? _createInstance(mapId, allocateId, instanceIds);
    final display = _display(left, top, geometry, policy);
    if (_inRange(display.$1, display.$2, geometry, policy)) {
      result[mapId] = instance;
    }
  }
  if (result.length == state.instancesByMapId.length &&
      result.entries.every((entry) =>
          identical(entry.value, state.instancesByMapId[entry.key]))) {
    return state;
  }
  return MapInstanceWorldState(persistentClearedObstacles: state.persistentClearedObstacles, instancesByMapId: result);
}

Set<String> _instanceIds(MapInstanceWorldState state) => {
      for (final instance in state.instancesByMapId.values) instance.instanceId,
    };

MapInstanceRuntimeState _createInstance(
  String mapId,
  String Function(String mapId) allocateId,
  Set<String> reservedInstanceIds,
) {
  final instanceId = _identity(allocateId(mapId));
  if (!reservedInstanceIds.add(instanceId)) {
    throw ArgumentError('A new map instance requires a fresh identity.');
  }
  return MapInstanceRuntimeState(instanceId: instanceId);
}

(double, double) _display(
  double left,
  double top,
  MapInstanceMapGeometry geometry,
  MapInstanceRetentionPolicy policy,
) {
  if (!policy.clampViewportToMapIds.contains(geometry.mapId)) {
    return (left, top);
  }
  return (
    math.max(
        0.0,
        math.min(left,
            (geometry.sizeTiles.width - policy.viewportWidthTiles).toDouble())),
    math.max(
        0.0,
        math.min(
            top,
            (geometry.sizeTiles.height - policy.viewportHeightTiles)
                .toDouble())),
  );
}

bool _inRange(
  double left,
  double top,
  MapInstanceMapGeometry geometry,
  MapInstanceRetentionPolicy policy,
) =>
    left < geometry.sizeTiles.width + policy.marginTiles &&
    top < geometry.sizeTiles.height + policy.marginTiles &&
    left > -(policy.viewportWidthTiles + policy.marginTiles) &&
    top > -(policy.viewportHeightTiles + policy.marginTiles);

String _identity(String value) {
  if (value.isEmpty || value.trim() != value) {
    throw ArgumentError.value(
        value, 'identity', 'must be a canonical identity');
  }
  return value;
}

void _integer(int value, String field, int minimum) {
  if (value < minimum || value > 2147483647) {
    throw ArgumentError.value(value, field, 'outside native geometry bounds');
  }
}

double _finite(double value, String field) {
  if (!value.isFinite) {
    throw ArgumentError.value(value, field, 'must be finite');
  }
  return value;
}
