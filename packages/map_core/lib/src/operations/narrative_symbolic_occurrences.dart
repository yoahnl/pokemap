part of 'narrative_symbolic_reachability_solver.dart';

const _playerMapFootprintKey = 'player:map';

typedef _SymbolicOccurrence = ({
  Object? sourceKey,
  List<List<NarrativeEventDefinition>> entries,
});

typedef _SymbolicZoneFront = ({String mapId, MapRect area});

bool _isSymbolicNarrativeZone(MapTrigger trigger) =>
    trigger.id.isNotEmpty &&
    trigger.id.trim() == trigger.id &&
    (trigger.type == TriggerType.event || trigger.type == TriggerType.custom);

Map<NarrativeEventSourceRef, _SymbolicZoneFront> _symbolicZoneFronts(
  List<MapData> maps,
) => {
  for (final map in maps)
    if (map.id.isNotEmpty && map.id == map.id.trim())
      for (final trigger in map.triggers)
        if (_isSymbolicNarrativeZone(trigger))
          NarrativeEventSourceRef.triggerEnter(map.id, trigger.id): (
            mapId: map.id,
            area: trigger.area,
          ),
};

Map<String, Set<String>> _symbolicMapTransitions(Map<String, MapData> maps) => {
  for (final map in maps.values)
    map.id: {
      for (final connection in map.connections)
        if (maps.containsKey(connection.targetMapId)) connection.targetMapId,
      for (final warp in map.warps)
        if (warp.triggerMode != MapWarpTriggerMode.sceneOnly &&
            maps.containsKey(warp.targetMapId))
          warp.targetMapId,
    },
};

String? _symbolicSceneWarpDestination(
  SceneNode node,
  Map<String, MapData> maps,
) {
  if (node.payload case SceneActionPayload(
    interactiveCommand: SceneWarpInteractiveCommand(
      :final destinationMapId,
      :final warpId,
    ),
  )) {
    final map = maps[destinationMapId];
    if (map != null && map.warps.any((warp) => warp.id == warpId)) {
      return map.id;
    }
  }
  return null;
}

Object? _playerOccurrenceKey(
  NarrativeEventSourceRef source,
  Map<NarrativeEventSourceRef, _SymbolicZoneFront> zoneFronts,
) => zoneFronts[source] ?? (_isPlayerControlledSource(source) ? source : null);

Map<Object, List<List<NarrativeEventDefinition>>> _symbolicPlayerOccurrences(
  List<NarrativeEventDefinition> batch,
  Map<NarrativeEventSourceRef, _SymbolicZoneFront> zoneFronts,
) {
  final byOccurrence =
      <Object, Map<NarrativeEventSourceRef, List<NarrativeEventDefinition>>>{};
  for (final definition in batch) {
    final key = _playerOccurrenceKey(definition.source, zoneFronts);
    if (key == null) continue;
    byOccurrence
        .putIfAbsent(key, () => {})
        .putIfAbsent(definition.source, () => [])
        .add(definition);
  }
  return {
    for (final entry in byOccurrence.entries)
      entry.key: entry.value.values.toList()
        ..sort(
          (left, right) => compareNarrativeEventUtf16(
            left.first.source.toJson()['triggerId'] as String,
            right.first.source.toJson()['triggerId'] as String,
          ),
        ),
  };
}
