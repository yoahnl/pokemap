import 'package:map_core/map_core.dart';

class AddEntityToMapUseCase {
  MapData execute(
    MapData map, {
    required MapEntity entity,
  }) {
    final updated = addEntityToMap(
      map,
      entity: entity,
    );
    MapValidator.validate(updated);
    return updated;
  }
}

class UpdateEntityOnMapUseCase {
  MapData execute(
    MapData map, {
    required String entityId,
    String? id,
    String? name,
    MapEntityKind? kind,
    GridPos? pos,
    GridSize? size,
    Map<String, String>? properties,
    MapEntityNpcData? npc,
    MapEntitySignData? sign,
    MapEntityItemData? item,
    MapEntitySpawnData? spawn,
  }) {
    final updated = updateEntityOnMap(
      map,
      entityId: entityId,
      id: id,
      name: name,
      kind: kind,
      pos: pos,
      size: size,
      properties: properties,
      npc: npc ?? mapEntityTypedPayloadUnset,
      sign: sign ?? mapEntityTypedPayloadUnset,
      item: item ?? mapEntityTypedPayloadUnset,
      spawn: spawn ?? mapEntityTypedPayloadUnset,
    );
    MapValidator.validate(updated);
    return updated;
  }
}

class DeleteEntityFromMapUseCase {
  MapData execute(
    MapData map, {
    required String entityId,
  }) {
    final updated = removeEntityFromMap(
      map,
      entityId: entityId,
    );
    MapValidator.validate(updated);
    return updated;
  }
}
