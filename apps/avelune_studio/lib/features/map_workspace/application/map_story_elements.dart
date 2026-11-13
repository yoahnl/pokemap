import 'package:map_core/map_core.dart';

import '../../events/domain/event_record_view.dart';

enum MapStoryElementKind { character, interactive, zone, map }

enum MapStoryElementTarget { entity, model, trigger, map }

const mapStoryZoneTypes = {
  TriggerType.event,
  TriggerType.message,
  TriggerType.interaction,
};

final class MapStoryElement {
  const MapStoryElement({
    required this.kind,
    required this.target,
    required this.id,
    required this.name,
    required this.behaviours,
    required this.configured,
    this.position,
    this.area,
  });

  final MapStoryElementKind kind;
  final MapStoryElementTarget target;
  final String id;
  final String name;
  final List<NarrativeEventRecord> behaviours;
  final bool configured;
  final GridPos? position;
  final MapRect? area;

  String get key => '${target.name}:$id';
}

final class MapStoryElements {
  MapStoryElements(MapData map, ProjectManifest? project)
    : elements = _read(map, project);

  final List<MapStoryElement> elements;

  MapStoryElement? byKey(String? key) =>
      elements.where((element) => element.key == key).firstOrNull;

  static List<MapStoryElement> _read(MapData map, ProjectManifest? project) {
    final behaviours = <String, List<NarrativeEventRecord>>{};
    for (final record
        in project?.eventRegistry?.records ?? const <NarrativeEventRecord>[]) {
      final key = record.source?.when(
        entityInteract: (mapId, id) => mapId == map.id ? 'entity:$id' : null,
        entityBump: (mapId, id) => mapId == map.id ? 'entity:$id' : null,
        entityAutorun: (mapId, id) => mapId == map.id ? 'entity:$id' : null,
        modelInteract: (mapId, id) => mapId == map.id ? 'model:$id' : null,
        triggerEnter: (mapId, id) => mapId == map.id ? 'trigger:$id' : null,
        triggerBump: (mapId, id) => mapId == map.id ? 'trigger:$id' : null,
        mapEnter: (mapId) => mapId == map.id ? 'map:${map.id}' : null,
        outcomeReceived: (_) => null,
      );
      if (key != null) behaviours.putIfAbsent(key, () => []).add(record);
    }
    List<NarrativeEventRecord> of(String key) =>
        List.unmodifiable(behaviours[key] ?? const <NarrativeEventRecord>[]);
    final models = {
      for (final model in project?.models3d ?? const <ProjectModel3dEntry>[])
        model.id: model.name,
    };
    return [
      for (final entity in map.entities)
        if (entity.kind == MapEntityKind.npc)
          MapStoryElement(
            kind: MapStoryElementKind.character,
            target: MapStoryElementTarget.entity,
            id: entity.id,
            name: _entityName(entity),
            behaviours: of('entity:${entity.id}'),
            configured:
                behaviours.containsKey('entity:${entity.id}') ||
                entity.npc?.dialogue != null ||
                entity.npc?.conditionalDialogues.isNotEmpty == true ||
                entity.npc?.trainerId != null,
            position: entity.pos,
          ),
      for (final entity in map.entities)
        if (entity.kind == MapEntityKind.sign ||
            entity.kind == MapEntityKind.item)
          MapStoryElement(
            kind: MapStoryElementKind.interactive,
            target: MapStoryElementTarget.entity,
            id: entity.id,
            name: _entityName(entity),
            behaviours: of('entity:${entity.id}'),
            configured:
                behaviours.containsKey('entity:${entity.id}') ||
                entity.sign?.dialogue != null ||
                entity.sign?.plainText.trim().isNotEmpty == true ||
                entity.item != null,
            position: entity.pos,
          ),
      for (final instance
          in map.spatialScene?.instances ?? const <SpatialModelInstance>[])
        if (behaviours.containsKey('model:${instance.id}'))
          MapStoryElement(
            kind: MapStoryElementKind.interactive,
            target: MapStoryElementTarget.model,
            id: instance.id,
            name: models[instance.modelId] ?? instance.id,
            behaviours: of('model:${instance.id}'),
            configured: true,
            position: GridPos(
              x: instance.position.x.floor(),
              y: instance.position.z.floor(),
            ),
          ),
      for (final trigger in map.triggers)
        if (mapStoryZoneTypes.contains(trigger.type))
          MapStoryElement(
            kind: MapStoryElementKind.zone,
            target: MapStoryElementTarget.trigger,
            id: trigger.id,
            name: trigger.name.trim().isNotEmpty
                ? trigger.name.trim()
                : trigger.id,
            behaviours: of('trigger:${trigger.id}'),
            configured: behaviours.containsKey('trigger:${trigger.id}'),
            position: trigger.area.pos,
            area: trigger.area,
          ),
      MapStoryElement(
        kind: MapStoryElementKind.map,
        target: MapStoryElementTarget.map,
        id: map.id,
        name: map.name,
        behaviours: of('map:${map.id}'),
        configured: behaviours.containsKey('map:${map.id}'),
      ),
    ];
  }

  static String _entityName(MapEntity entity) {
    for (final value in [
      entity.name,
      entity.npc?.displayName ?? '',
      entity.sign?.title ?? '',
    ]) {
      if (value.trim().isNotEmpty) return value.trim();
    }
    return entity.id;
  }
}
