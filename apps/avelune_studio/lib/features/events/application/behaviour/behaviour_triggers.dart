import 'package:map_core/map_core_domain.dart';

enum BehaviourOwner { entity, model, trigger, map }

List<NarrativeEventSourceRef> behaviourTriggerSources({
  required ProjectManifest project,
  required MapData map,
  required BehaviourOwner owner,
  String? ownerId,
}) {
  final candidates = switch (owner) {
    BehaviourOwner.entity => [
      NarrativeEventSourceRef.entityInteract(map.id, ownerId!),
      NarrativeEventSourceRef.entityBump(map.id, ownerId),
      NarrativeEventSourceRef.entityAutorun(map.id, ownerId),
    ],
    BehaviourOwner.model => [
      NarrativeEventSourceRef.modelInteract(map.id, ownerId!),
    ],
    BehaviourOwner.trigger => [
      NarrativeEventSourceRef.triggerEnter(map.id, ownerId!),
      NarrativeEventSourceRef.triggerBump(map.id, ownerId),
    ],
    BehaviourOwner.map => [NarrativeEventSourceRef.mapEnter(map.id)],
  };
  return [
    for (final source in candidates)
      if (_accepted(source, project, map)) source,
  ];
}

List<NarrativeEventSourceKind> behaviourTriggerKinds({
  required ProjectManifest project,
  required MapData map,
  required BehaviourOwner owner,
  String? ownerId,
}) => [
  for (final source in behaviourTriggerSources(
    project: project,
    map: map,
    owner: owner,
    ownerId: ownerId,
  ))
    source.kind,
];

bool _accepted(
  NarrativeEventSourceRef source,
  ProjectManifest project,
  MapData map,
) => source.when(
  entityInteract: (_, entityId) =>
      map.entities.any((entity) => entity.id == entityId),
  entityBump: (_, entityId) => isNarrativeEntityBumpSourceAvailable(
    project: project,
    map: map,
    entityId: entityId,
  ),
  entityAutorun: (_, entityId) => isNarrativeEntityAutorunSourceAvailable(
    project: project,
    map: map,
    entityId: entityId,
  ),
  modelInteract: (_, instanceId) =>
      map.spatialScene?.instances.any(
        (instance) => instance.id == instanceId,
      ) ??
      false,
  triggerEnter: (_, triggerId) =>
      map.triggers.any((trigger) => trigger.id == triggerId),
  triggerBump: (_, triggerId) => isNarrativeTriggerBumpSourceAvailable(
    project: project,
    map: map,
    triggerId: triggerId,
  ),
  mapEnter: (_) => true,
  outcomeReceived: (_) => false,
);
