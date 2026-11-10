import 'package:map_core/map_core_domain.dart';

import '../domain/event_record_view.dart';

const eventSourceKinds = [
  NarrativeEventSourceKind.entityInteract,
  NarrativeEventSourceKind.entityBump,
  NarrativeEventSourceKind.entityAutorun,
  NarrativeEventSourceKind.modelInteract,
  NarrativeEventSourceKind.triggerBump,
  NarrativeEventSourceKind.triggerEnter,
  NarrativeEventSourceKind.mapEnter,
  NarrativeEventSourceKind.outcomeReceived,
];

String eventName(NarrativeEventRecord record) =>
    record.definitionOrNull?.name ?? record.draftOrNull!.name;

NarrativeEventSourceRef? eventSource(NarrativeEventRecord record) =>
    record.definitionOrNull?.source ?? record.draftOrNull?.source;

String? eventSceneId(NarrativeEventRecord record) =>
    record.definitionOrNull?.sceneId ?? record.draftOrNull?.sceneId;

NarrativeEventConditionExpression eventExpression(
  NarrativeEventRecord record,
) =>
    record.definitionOrNull?.conditionExpression ??
    record.draftOrNull!.conditionExpression;

String? eventMapId(NarrativeEventSourceRef? source) => source?.when(
  entityAutorun: (map, _) => map,
  entityBump: (map, _) => map,
  entityInteract: (map, _) => map,
  modelInteract: (map, _) => map,
  triggerBump: (map, _) => map,
  triggerEnter: (map, _) => map,
  mapEnter: (map) => map,
  outcomeReceived: (_) => null,
);

String? eventTargetId(NarrativeEventSourceRef? source) => source?.when(
  entityAutorun: (_, id) => id,
  entityBump: (_, id) => id,
  entityInteract: (_, id) => id,
  modelInteract: (_, id) => id,
  triggerBump: (_, id) => id,
  triggerEnter: (_, id) => id,
  mapEnter: (_) => null,
  outcomeReceived: (_) => null,
);

String? eventOwnerId(NarrativeEventSourceRef? source) => source?.when(
  entityAutorun: (_, id) => id,
  entityBump: (_, id) => id,
  entityInteract: (_, id) => id,
  modelInteract: (_, _) => null,
  triggerBump: (_, _) => null,
  triggerEnter: (_, _) => null,
  mapEnter: (_) => null,
  outcomeReceived: (_) => null,
);

({String? mapId, String? entityId}) eventConditionOwner(
  NarrativeEventSourceRef? source,
) {
  final owner = eventOwnerId(source);
  return (mapId: owner == null ? null : eventMapId(source), entityId: owner);
}

String eventKindLabel(NarrativeEventSourceKind? kind) => switch (kind) {
  NarrativeEventSourceKind.entityAutorun => 'Automatique',
  NarrativeEventSourceKind.entityBump => 'Contact du joueur',
  NarrativeEventSourceKind.entityInteract => 'Interaction du joueur',
  NarrativeEventSourceKind.modelInteract => 'Interaction avec un décor 3D',
  NarrativeEventSourceKind.triggerBump => 'Contact de zone',
  NarrativeEventSourceKind.triggerEnter => 'Entrée de zone',
  NarrativeEventSourceKind.mapEnter => 'Entrée sur la carte',
  NarrativeEventSourceKind.outcomeReceived => 'Réception d’un résultat',
  null => 'Source à choisir',
};

String eventStateLabel(NarrativeEventRecord record) =>
    record.draftOrNull != null
    ? 'Brouillon enregistré'
    : record.enabledOrNull == true
    ? 'Activé'
    : 'Configuré · désactivé';

String eventMapLabel(ProjectManifest project, String? id) {
  if (id == null) return 'Global / Résultats';
  return project.maps.where((entry) => entry.id == id).firstOrNull?.name ??
      'Carte absente : $id';
}

String eventRepeatEffect(
  NarrativeEventRecord record,
  NarrativeOutcomeEventSourceCatalog outcomes,
) {
  if (record.reusePolicy == null) {
    return 'À définir : choisissez ce qui se passe après une première lecture.';
  }
  if (record.reusePolicy == NarrativeEventReusePolicy.reusable) {
    return 'À chaque déclenchement, tant que ses conditions sont remplies.';
  }
  return switch (record.resetPolicy) {
    NarrativeEventResetNever() => 'Une seule fois dans la partie.',
    NarrativeEventResetOnMapReentry() => 'Une fois par visite : se rejoue après avoir quitté puis retrouvé sa carte.',
    NarrativeEventResetOnOutcomeReceived(:final outcome) =>
      'Une fois, puis à nouveau après le résultat « ${_outcomeLabel(outcome, outcomes)} ».',
  };
}

String _outcomeLabel(
  NarrativeOutcomeRef outcome,
  NarrativeOutcomeEventSourceCatalog outcomes,
) {
  final matches = outcomes.options
      .where((option) => option.outcome == outcome)
      .toList();
  return matches.length == 1 ? matches.single.outcomeLabel : outcome.outcomeId;
}
