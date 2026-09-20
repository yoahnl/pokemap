import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../shared/widgets/feedback/studio_badge.dart';

const eventSourceKinds = [
  NarrativeEventSourceKind.entityInteract,
  NarrativeEventSourceKind.triggerEnter,
  NarrativeEventSourceKind.mapEnter,
  NarrativeEventSourceKind.outcomeReceived,
];

StudioTone eventKindTone(NarrativeEventSourceKind? kind) => switch (kind) {
  NarrativeEventSourceKind.entityInteract => StudioTone.info,
  NarrativeEventSourceKind.triggerEnter => StudioTone.success,
  NarrativeEventSourceKind.mapEnter => StudioTone.feature,
  NarrativeEventSourceKind.outcomeReceived => StudioTone.warning,
  null => StudioTone.neutral,
};

StudioTone eventStateTone(NarrativeEventRecord record, {bool dirty = false}) =>
    dirty || record.draftOrNull != null
    ? StudioTone.warning
    : record.enabledOrNull == true
    ? StudioTone.success
    : StudioTone.neutral;

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
  entityInteract: (map, _) => map,
  triggerEnter: (map, _) => map,
  mapEnter: (map) => map,
  outcomeReceived: (_) => null,
);

String? eventTargetId(NarrativeEventSourceRef? source) => source?.when(
  entityInteract: (_, id) => id,
  triggerEnter: (_, id) => id,
  mapEnter: (_) => null,
  outcomeReceived: (_) => null,
);

String eventKindLabel(NarrativeEventSourceKind? kind) => switch (kind) {
  NarrativeEventSourceKind.entityInteract => 'Interaction du joueur',
  NarrativeEventSourceKind.triggerEnter => 'Entrée de zone',
  NarrativeEventSourceKind.mapEnter => 'Entrée sur la carte',
  NarrativeEventSourceKind.outcomeReceived => 'Réception d’un résultat',
  null => 'Source à choisir',
};

IconData eventKindIcon(NarrativeEventSourceKind? kind) => switch (kind) {
  NarrativeEventSourceKind.entityInteract => Icons.forum_outlined,
  NarrativeEventSourceKind.triggerEnter => Icons.crop_free,
  NarrativeEventSourceKind.mapEnter => Icons.login,
  NarrativeEventSourceKind.outcomeReceived => Icons.flag_outlined,
  null => Icons.add_location_alt_outlined,
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
