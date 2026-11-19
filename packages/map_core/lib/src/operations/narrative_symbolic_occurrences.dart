part of 'narrative_symbolic_reachability_solver.dart';

const _playerMapFootprintKey = 'player:map';

typedef _SymbolicOccurrence = ({
  Object? sourceKey,
  Map<NarrativeEventSourceRef, List<NarrativeEventDefinition>> entries,
});

typedef _SymbolicZoneFront = ({
  String mapId,
  MapRect area,
  _SymbolicZoneWalk? walk,
});

bool _isSymbolicNarrativeZone(MapData map, MapTrigger trigger) =>
    trigger.id.isNotEmpty &&
    trigger.id.trim() == trigger.id &&
    (trigger.type == TriggerType.event || trigger.type == TriggerType.custom) &&
    _zoneHasExteriorCell(map, trigger.area);

Map<NarrativeEventSourceRef, _SymbolicZoneFront> _symbolicZoneFronts(
  List<MapData> maps,
  Set<NarrativeEventSourceRef> activeSources,
) {
  final fronts = <NarrativeEventSourceRef, _SymbolicZoneFront>{};
  for (final map in maps) {
    if (map.id.isEmpty ||
        map.id != map.id.trim() ||
        map.size.width <= 0 ||
        map.size.height <= 0) {
      continue;
    }
    final areas = <NarrativeEventSourceRef, MapRect>{};
    for (final trigger in map.triggers) {
      if (!_isSymbolicNarrativeZone(map, trigger)) continue;
      final source = NarrativeEventSourceRef.triggerEnter(map.id, trigger.id);
      if (activeSources.contains(source)) areas[source] = trigger.area;
    }
    final walks = _symbolicZoneWalks(map, areas);
    for (final entry in areas.entries) {
      fronts[entry.key] = (
        mapId: map.id,
        area: entry.value,
        walk: walks[entry.key],
      );
    }
  }
  return fronts;
}

typedef _SymbolicMapTransition = ({String mapId, GridPos? arrivalCell});

Map<String, Set<_SymbolicMapTransition>> _symbolicMapTransitions(
  Map<String, MapData> maps,
) => {
  for (final map in maps.values)
    map.id: {
      for (final connection in map.connections)
        if (maps.containsKey(connection.targetMapId))
          (mapId: connection.targetMapId, arrivalCell: null),
      for (final warp in map.warps)
        if (warp.triggerMode != MapWarpTriggerMode.sceneOnly &&
            maps.containsKey(warp.targetMapId))
          (mapId: warp.targetMapId, arrivalCell: warp.targetPos),
    },
};

Object? _playerOccurrenceKey(
  NarrativeEventSourceRef source,
  Map<NarrativeEventSourceRef, _SymbolicZoneFront> zoneFronts,
) {
  final front = zoneFronts[source];
  return front?.walk ??
      front ??
      (_isPlayerControlledSource(source) ? source : null);
}

Map<Object, Map<NarrativeEventSourceRef, List<NarrativeEventDefinition>>>
_symbolicPlayerOccurrences(
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
      entry.key: entry.value.length == 1
          ? entry.value
          : Map.fromEntries(
              entry.value.entries.toList()..sort(
                (left, right) => compareNarrativeEventUtf16(
                  _triggerId(left.key),
                  _triggerId(right.key),
                ),
              ),
            ),
  };
}

String _triggerId(NarrativeEventSourceRef source) =>
    source.toJson()['triggerId'] as String;
