import 'package:map_core/map_core_domain.dart';

String? storyZoneEventMoment(
  NarrativeEventRecord record,
  String mapId,
  String id,
) {
  final source = record.definitionOrNull?.source ?? record.draftOrNull?.source;
  return source?.when(
    entityAutorun: (_, _) => null,
    entityBump: (_, _) => null,
    entityInteract: (_, _) => null,
    modelInteract: (_, _) => null,
    triggerBump: (map, trigger) =>
        map == mapId && trigger == id ? 'en touchant la zone' : null,
    triggerEnter: (map, trigger) =>
        map == mapId && trigger == id ? 'en entrant dans la zone' : null,
    mapEnter: (_) => null,
    outcomeReceived: (_) => null,
  );
}

List<(String, String?)> storyZoneAdmissibleSources({
  required ProjectManifest project,
  required MapData map,
  required MapTrigger trigger,
}) {
  final area = trigger.area;
  final withinMap =
      area.pos.x >= 0 &&
      area.pos.y >= 0 &&
      area.size.width > 0 &&
      area.size.height > 0 &&
      area.pos.x + area.size.width <= map.size.width &&
      area.pos.y + area.size.height <= map.size.height;
  final enterReason =
      trigger.type != TriggerType.event && trigger.type != TriggerType.custom
      ? 'zone système réglée par ses outils dédiés'
      : !withinMap
      ? 'surface hors de la carte'
      : null;
  final bumpReason =
      isNarrativeTriggerBumpSourceAvailable(
        project: project,
        map: map,
        triggerId: trigger.id,
      )
      ? null
      : map.spatialScene != null ||
            project.settings.dimension != ProjectDimension.twoD
      ? 'réservé aux cartes 2D'
      : trigger.type != TriggerType.event
      ? 'réservé aux zones d’événement'
      : 'zone dupliquée ou hors de la carte';
  return [
    ('En entrant dans la zone', enterReason),
    ('En touchant la zone', bumpReason),
  ];
}
