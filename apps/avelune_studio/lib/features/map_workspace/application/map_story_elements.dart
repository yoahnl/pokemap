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

typedef MapStoryOrphan = ({
  NarrativeEventRecord behaviour,
  MapStoryElementTarget target,
  String id,
});

typedef MapStoryCarrier = ({
  String name,
  List<NarrativeEventRecord> behaviours,
});

final class MapStoryBehaviourIndex {
  MapStoryBehaviourIndex(this.mapId, Iterable<NarrativeEventRecord> records) {
    for (final record in records) {
      final at = record.source?.when(
        entityInteract: (mapId, id) =>
            (mapId, MapStoryElementTarget.entity, id),
        entityBump: (mapId, id) => (mapId, MapStoryElementTarget.entity, id),
        entityAutorun: (mapId, id) => (mapId, MapStoryElementTarget.entity, id),
        modelInteract: (mapId, id) => (mapId, MapStoryElementTarget.model, id),
        triggerEnter: (mapId, id) => (mapId, MapStoryElementTarget.trigger, id),
        triggerBump: (mapId, id) => (mapId, MapStoryElementTarget.trigger, id),
        mapEnter: (mapId) => (mapId, MapStoryElementTarget.map, mapId),
        outcomeReceived: (_) => null,
      );
      if (at == null || at.$1 != mapId) continue;
      _byTarget
          .putIfAbsent(at.$2, () => {})
          .putIfAbsent(at.$3, () => [])
          .add(record);
    }
    for (final behaviours in _byTarget.values) {
      behaviours.updateAll((_, records) => List.unmodifiable(records));
    }
  }

  final String mapId;
  final _byTarget =
      <MapStoryElementTarget, Map<String, List<NarrativeEventRecord>>>{};

  Map<String, List<NarrativeEventRecord>> on(MapStoryElementTarget target) =>
      _byTarget[target] ?? const {};

  List<NarrativeEventRecord> of(MapStoryElementTarget target, String id) =>
      _byTarget[target]?[id] ?? const [];
}

final class MapStoryElements {
  factory MapStoryElements(
    MapData map,
    ProjectManifest? project, {
    MapStoryBehaviourIndex? behaviours,
  }) {
    final index =
        behaviours ??
        MapStoryBehaviourIndex(
          map.id,
          project?.eventRegistry?.records ?? const [],
        );
    final models = index.on(MapStoryElementTarget.model).isEmpty
        ? const <String, String>{}
        : {
            for (final model
                in project?.models3d ?? const <ProjectModel3dEntry>[])
              model.id: model.name,
          };
    final carriers = _carrierNames(map, index, models);
    return MapStoryElements._(
      _read(map, index, models),
      index,
      carriers,
      List.unmodifiable([
        for (final MapEntry(key: target, value: names) in carriers.entries)
          for (final MapEntry(key: id, value: behaviours)
              in index.on(target).entries)
            if (!names.containsKey(id))
              for (final behaviour in behaviours)
                (behaviour: behaviour, target: target, id: id),
      ]),
    );
  }

  MapStoryElements._(
    this.elements,
    this._behaviours,
    this._carriers,
    this.orphans,
  );

  final List<MapStoryElement> elements;
  final List<MapStoryOrphan> orphans;
  final MapStoryBehaviourIndex _behaviours;
  final Map<MapStoryElementTarget, Map<String, String>> _carriers;

  MapStoryElement? byKey(String? key) =>
      elements.where((element) => element.key == key).firstOrNull;

  MapStoryCarrier? carrier(MapStoryElementTarget target, String id) {
    final name = _carriers[target]?[id];
    return name == null
        ? null
        : (name: name, behaviours: _behaviours.of(target, id));
  }

  static Map<MapStoryElementTarget, Map<String, String>> _carrierNames(
    MapData map,
    MapStoryBehaviourIndex index,
    Map<String, String> models,
  ) {
    final entities = index.on(MapStoryElementTarget.entity);
    final instances = index.on(MapStoryElementTarget.model);
    final triggers = index.on(MapStoryElementTarget.trigger);
    return {
      MapStoryElementTarget.entity: {
        if (entities.isNotEmpty)
          for (final entity in map.entities)
            if (entities.containsKey(entity.id)) entity.id: _entityName(entity),
      },
      MapStoryElementTarget.model: {
        if (instances.isNotEmpty)
          for (final instance
              in map.spatialScene?.instances ?? const <SpatialModelInstance>[])
            if (instances.containsKey(instance.id))
              instance.id: models[instance.modelId] ?? instance.id,
      },
      MapStoryElementTarget.trigger: {
        if (triggers.isNotEmpty)
          for (final trigger in map.triggers)
            if (triggers.containsKey(trigger.id))
              trigger.id: _triggerName(trigger),
      },
    };
  }

  static List<MapStoryElement> _read(
    MapData map,
    MapStoryBehaviourIndex index,
    Map<String, String> models,
  ) {
    List<NarrativeEventRecord> carried(String id) =>
        index.of(MapStoryElementTarget.entity, id);
    final instances = index.on(MapStoryElementTarget.model);
    final arrival = index.of(MapStoryElementTarget.map, map.id);
    return [
      for (final entity in map.entities)
        if (entity.kind == MapEntityKind.npc)
          MapStoryElement(
            kind: MapStoryElementKind.character,
            target: MapStoryElementTarget.entity,
            id: entity.id,
            name: _entityName(entity),
            behaviours: carried(entity.id),
            configured:
                carried(entity.id).isNotEmpty ||
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
            behaviours: carried(entity.id),
            configured:
                carried(entity.id).isNotEmpty ||
                entity.sign?.dialogue != null ||
                entity.sign?.plainText.trim().isNotEmpty == true ||
                entity.item != null,
            position: entity.pos,
          ),
      for (final instance
          in map.spatialScene?.instances ?? const <SpatialModelInstance>[])
        if (instances[instance.id] case final behaviours?)
          MapStoryElement(
            kind: MapStoryElementKind.interactive,
            target: MapStoryElementTarget.model,
            id: instance.id,
            name: models[instance.modelId] ?? instance.id,
            behaviours: behaviours,
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
            name: _triggerName(trigger),
            behaviours: index.of(MapStoryElementTarget.trigger, trigger.id),
            configured: index
                .of(MapStoryElementTarget.trigger, trigger.id)
                .isNotEmpty,
            position: trigger.area.pos,
            area: trigger.area,
          ),
      MapStoryElement(
        kind: MapStoryElementKind.map,
        target: MapStoryElementTarget.map,
        id: map.id,
        name: map.name,
        behaviours: arrival,
        configured: arrival.isNotEmpty,
      ),
    ];
  }

  static String _triggerName(MapTrigger trigger) =>
      trigger.name.trim().isNotEmpty ? trigger.name.trim() : trigger.id;

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
