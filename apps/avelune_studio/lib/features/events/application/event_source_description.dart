import 'package:map_core/map_core_domain.dart';

import 'event_labels.dart';

typedef EventSourceDescription = ({String title, String? position});

const eventSourceMapToRepair = 'Source indisponible · carte à réparer';

EventSourceDescription describeEventSource({
  required NarrativeEventSourceRef source,
  required MapData map,
  required ProjectManifest? project,
}) {
  if (map.id != eventMapId(source)) {
    return (title: eventSourceMapToRepair, position: null);
  }
  final id = eventTargetId(source);
  if (source.kind == NarrativeEventSourceKind.modelInteract) {
    final instances =
        map.spatialScene?.instances
            .where((instance) => instance.id == id)
            .toList() ??
        [];
    if (instances.length != 1) {
      return (
        title: '${instances.isEmpty ? 'Source absente' : 'Source ambiguë'} · $id',
        position: null,
      );
    }
    final instance = instances.single;
    final model = project?.models3d
        .where((model) => model.id == instance.modelId)
        .firstOrNull;
    return (
      title: model?.name ?? 'Ressource 3D absente',
      position:
          'Position : (${instance.position.x}, ${instance.position.z})',
    );
  }
  if (id == null) return (title: 'Toute la carte · à son entrée', position: null);
  final entitySource =
      source.kind == NarrativeEventSourceKind.entityInteract ||
      source.kind == NarrativeEventSourceKind.entityBump ||
      source.kind == NarrativeEventSourceKind.entityAutorun;
  final entities = map.entities.where((e) => e.id == id).toList();
  final triggers = map.triggers.where((t) => t.id == id).toList();
  final matches = entitySource ? entities.length : triggers.length;
  if (matches != 1) {
    return (
      title: '${matches == 0 ? 'Source absente' : 'Source ambiguë'} · $id',
      position: null,
    );
  }
  if (source.kind == NarrativeEventSourceKind.entityAutorun &&
      (project == null ||
          !isNarrativeEntityAutorunSourceAvailable(
            project: project,
            map: map,
            entityId: id,
          ))) {
    return (
      title: 'Source indisponible · élément source à réparer',
      position: null,
    );
  }
  if (source.kind == NarrativeEventSourceKind.entityBump &&
      (project == null ||
          !isNarrativeEntityBumpSourceAvailable(
            project: project,
            map: map,
            entityId: id,
          ))) {
    return (title: 'Source indisponible · personnage à réparer', position: null);
  }
  if (source.kind == NarrativeEventSourceKind.triggerBump &&
      (project == null ||
          !isNarrativeTriggerBumpSourceAvailable(
            project: project,
            map: map,
            triggerId: id,
          ))) {
    return (title: 'Source indisponible · zone à réparer', position: null);
  }
  final position = entitySource
      ? entities.single.pos
      : triggers.single.area.pos;
  final name = entitySource ? entities.single.name : triggers.single.name;
  return (
    title: name.isEmpty ? eventKindLabel(source.kind) : name,
    position: 'Position : (${position.x}, ${position.y})',
  );
}
