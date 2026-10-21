import 'package:map_core/map_core.dart';

import 'gameplay_world_state.dart';

bool evaluateScenePlayerAtEntityAnchor({
  required SceneConditionSource source,
  required GameplayWorldState world,
  required String currentMapId,
}) {
  if (source.sourceKind != SceneConditionSourceKind.playerAtEntityAnchor) {
    throw ArgumentError('An entity anchor condition is required.');
  }
  if (world.map.id != currentMapId || world.map.spatialScene != null) {
    throw StateError('The entity anchor requires the current 2D world.');
  }
  if (source.mapId != currentMapId) return _matched(source, false);
  final entities =
      world.map.entities.where((entity) => entity.id == source.sourceId);
  if (entities.length != 1) {
    throw StateError('The entity anchor must resolve exactly one entity.');
  }
  final anchor = entities.single.pos;
  if (anchor.x < 0 ||
      anchor.y < 0 ||
      anchor.x >= world.map.size.width ||
      anchor.y >= world.map.size.height) {
    throw StateError('The entity anchor is outside its map.');
  }
  return _matched(source, world.player.pos == anchor);
}

bool evaluateSceneMapEventInstanceBoolean({
  required SceneConditionSource source,
  required GameState gameState,
  required NarrativeMapView map,
  required MapInstanceRef scope,
}) {
  if (source.sourceKind != SceneConditionSourceKind.mapEventInstanceBoolean) {
    throw ArgumentError('A map instance boolean condition is required.');
  }
  _validateOwner(map, source.mapId!, source.sourceId, scope);
  final value = gameState.mapInstanceWorldState.eventBoolean(
    scope,
    source.sourceId,
    source.key!,
  );
  return _matched(source, value);
}

GameState applySceneMapEventInstanceBoolean({
  required GameState gameState,
  required SceneSetMapEventInstanceBooleanConsequence consequence,
  required NarrativeMapView map,
  required MapInstanceRef expectedInstance,
}) {
  _validateOwner(map, consequence.mapId, consequence.eventId, expectedInstance);
  final instances = gameState.mapInstanceWorldState.setEventBoolean(
    expectedInstance,
    consequence.eventId,
    consequence.key,
    consequence.value,
  );
  return identical(instances, gameState.mapInstanceWorldState)
      ? gameState
      : gameState.copyWith(mapInstanceWorldState: instances);
}

void _validateOwner(
  NarrativeMapView map,
  String mapId,
  String eventId,
  MapInstanceRef scope,
) {
  if (map.id != mapId ||
      scope.mapId != mapId ||
      map.entities.where((entity) => entity.id == eventId).length != 1) {
    throw StateError(
        'The instance boolean requires its declared unique map owner.');
  }
}

bool _matched(SceneConditionSource source, bool value) =>
    switch (source.operator) {
      SceneConditionOperator.isTrue => value,
      SceneConditionOperator.isFalse => !value,
      SceneConditionOperator.equals =>
        throw ArgumentError('A boolean operator is required.'),
    };
