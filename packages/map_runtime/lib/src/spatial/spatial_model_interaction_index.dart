import 'package:map_core/map_core.dart';

typedef SpatialModelInteractionCandidate = ({
  SpatialModelInstance instance,
  MapEntity? owner,
});

final class SpatialModelInteractionIndex {
  SpatialModelInteractionIndex(Iterable<NarrativeEventRecord> records) {
    for (final record in records) {
      if (record.enabledOrNull != true) continue;
      record.definitionOrNull?.source.when<void>(
        modelInteract: (mapId, instanceId) =>
            _instanceIdsByMap.putIfAbsent(mapId, () => {}).add(instanceId),
        entityInteract: (_, _) {},
        entityAutorun: (_, _) {},
        entityBump: (_, _) {},
        triggerBump: (_, _) {},
        triggerEnter: (_, _) {},
        mapEnter: (_) {},
        outcomeReceived: (_) {},
      );
    }
  }

  final _instanceIdsByMap = <String, Set<String>>{};
  MapData? _cachedMap;
  List<SpatialModelInteractionCandidate> _cachedCandidates = const [];

  List<SpatialModelInteractionCandidate> candidatesFor(MapData map) {
    if (identical(map, _cachedMap)) return _cachedCandidates;
    _cachedMap = map;
    final ids = _instanceIdsByMap[map.id];
    if (ids == null) return _cachedCandidates = const [];
    final instances = map.spatialScene!.instances
        .where((instance) => ids.contains(instance.id))
        .toList(growable: false);
    final owners = <String, MapEntity>{};
    if (instances.any((instance) => instance.entityId != null)) {
      for (final entity in map.entities) {
        owners.putIfAbsent(entity.id, () => entity);
      }
    }
    return _cachedCandidates = List.unmodifiable([
      for (final instance in instances)
        if (instance.entityId == null || owners.containsKey(instance.entityId))
          (instance: instance, owner: owners[instance.entityId]),
    ]);
  }
}
