import 'package:map_core/map_core_domain.dart';

import 'event_labels.dart';

typedef EventSourceCellTarget = ({
  String label,
  MapRect area,
  NarrativeEventSourceRef source,
});

class EventSourcePicking {
  const EventSourcePicking({
    required this.map,
    required this.project,
    this.source,
    this.chooseKind,
    this.selectableSources,
  });

  final MapData map;
  final ProjectManifest project;
  final NarrativeEventSourceRef? source;
  final NarrativeEventSourceKind? chooseKind;
  final Set<NarrativeEventSourceRef>? selectableSources;

  bool selectable(NarrativeEventSourceRef value) =>
      selectableSources?.contains(value) ?? true;

  NarrativeEventSourceRef? accept(NarrativeEventSourceRef value) =>
      chooseKind == value.kind && selectable(value) ? value : null;

  List<EventSourceCellTarget> get flatTargets {
    final kind =
        chooseKind ?? (eventMapId(source) == map.id ? source?.kind : null);
    NarrativeEventSourceRef entitySource(MapEntity entity) => switch (kind) {
      NarrativeEventSourceKind.entityAutorun =>
        NarrativeEventSourceRef.entityAutorun(map.id, entity.id),
      NarrativeEventSourceKind.entityBump => NarrativeEventSourceRef.entityBump(
        map.id,
        entity.id,
      ),
      NarrativeEventSourceKind.entityInteract =>
        NarrativeEventSourceRef.entityInteract(map.id, entity.id),
      _ => throw StateError('The current source is not an entity source.'),
    };
    NarrativeEventSourceRef triggerSource(MapTrigger trigger) =>
        kind == NarrativeEventSourceKind.triggerBump
        ? NarrativeEventSourceRef.triggerBump(map.id, trigger.id)
        : NarrativeEventSourceRef.triggerEnter(map.id, trigger.id);
    return [
      if (kind == NarrativeEventSourceKind.entityInteract ||
          kind == NarrativeEventSourceKind.entityBump ||
          kind == NarrativeEventSourceKind.entityAutorun)
        for (final entity in map.entities)
          if ((kind != NarrativeEventSourceKind.entityAutorun ||
                  isNarrativeEntityAutorunSourceAvailable(
                    project: project,
                    map: map,
                    entityId: entity.id,
                  )) &&
              (chooseKind != null
                  ? selectable(entitySource(entity)) &&
                        (kind != NarrativeEventSourceKind.entityBump ||
                            isNarrativeEntityBumpSourceAvailable(
                              project: project,
                              map: map,
                              entityId: entity.id,
                            ))
                  : entity.id == eventTargetId(source)))
            (
              label: entity.name,
              area: MapRect(
                pos: entity.pos,
                size: const GridSize(width: 1, height: 1),
              ),
              source: entitySource(entity),
            ),
      if (kind == NarrativeEventSourceKind.triggerEnter ||
          kind == NarrativeEventSourceKind.triggerBump)
        for (final trigger in map.triggers)
          if ((kind != NarrativeEventSourceKind.triggerBump ||
                  isNarrativeTriggerBumpSourceAvailable(
                    project: project,
                    map: map,
                    triggerId: trigger.id,
                  )) &&
              (chooseKind != null
                  ? selectable(triggerSource(trigger))
                  : trigger.id == eventTargetId(source)))
            (
              label: trigger.name,
              area: trigger.area,
              source: triggerSource(trigger),
            ),
    ];
  }

  NarrativeEventSourceRef? modelHit(String id) =>
      accept(NarrativeEventSourceRef.modelInteract(map.id, id));

  NarrativeEventSourceRef? actorHit(String id) => id.startsWith('npc:')
      ? accept(NarrativeEventSourceRef.entityInteract(map.id, id.substring(4)))
      : null;

  NarrativeEventSourceRef? spatialCell(double x, double z) {
    if (chooseKind == NarrativeEventSourceKind.mapEnter) {
      return accept(NarrativeEventSourceRef.mapEnter(map.id));
    }
    if (chooseKind == NarrativeEventSourceKind.entityInteract) {
      for (final entity in map.entities) {
        if (x >= entity.pos.x &&
            z >= entity.pos.y &&
            x < entity.pos.x + entity.size.width &&
            z < entity.pos.y + entity.size.height) {
          return accept(
            NarrativeEventSourceRef.entityInteract(map.id, entity.id),
          );
        }
      }
    }
    if (chooseKind == NarrativeEventSourceKind.triggerEnter) {
      for (final trigger in map.triggers) {
        if (x >= trigger.area.pos.x &&
            z >= trigger.area.pos.y &&
            x < trigger.area.pos.x + trigger.area.size.width &&
            z < trigger.area.pos.y + trigger.area.size.height) {
          return accept(
            NarrativeEventSourceRef.triggerEnter(map.id, trigger.id),
          );
        }
      }
    }
    return null;
  }
}
