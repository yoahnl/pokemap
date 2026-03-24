import '../exceptions/map_exceptions.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/enums.dart';

MapEntity? findEntityById(
  MapData map,
  String entityId,
) {
  final normalizedEntityId = entityId.trim();
  if (normalizedEntityId.isEmpty) {
    return null;
  }
  for (final entity in map.entities) {
    if (entity.id == normalizedEntityId) {
      return entity;
    }
  }
  return null;
}

MapEntity? findEntityAtPos(
  MapData map,
  GridPos pos,
) {
  for (var index = map.entities.length - 1; index >= 0; index--) {
    final entity = map.entities[index];
    if (_containsPos(entity, pos)) {
      return entity;
    }
  }
  return null;
}

MapData addEntityToMap(
  MapData map, {
  required MapEntity entity,
}) {
  final normalizedEntity = _normalizeEntity(entity);
  _validateEntity(
    map,
    normalizedEntity,
    duplicateIdLabel: 'Entity ID already exists',
  );
  return map.copyWith(
    entities: [...map.entities, normalizedEntity],
  );
}

MapData updateEntityOnMap(
  MapData map, {
  required String entityId,
  String? id,
  String? name,
  MapEntityKind? kind,
  GridPos? pos,
  GridSize? size,
  Map<String, String>? properties,
}) {
  final index = map.entities.indexWhere((entity) => entity.id == entityId);
  if (index < 0) {
    throw ValidationException('Entity not found: $entityId');
  }
  final current = map.entities[index];
  final next = _normalizeEntity(
    current.copyWith(
      id: id?.trim() ?? current.id,
      name: name?.trim() ?? current.name,
      kind: kind ?? current.kind,
      pos: pos ?? current.pos,
      size: size ?? current.size,
      properties: properties == null
          ? current.properties
          : _normalizeProperties(properties),
    ),
  );
  _validateEntity(
    map,
    next,
    excludedEntityId: current.id,
    duplicateIdLabel: 'Entity ID already exists',
  );
  final updated = List<MapEntity>.from(map.entities, growable: false);
  updated[index] = next;
  return map.copyWith(entities: updated);
}

MapData moveEntityOnMap(
  MapData map, {
  required String entityId,
  required GridPos pos,
}) {
  final entity = findEntityById(map, entityId);
  if (entity == null) {
    throw ValidationException('Entity not found: $entityId');
  }
  return updateEntityOnMap(
    map,
    entityId: entityId,
    pos: pos,
  );
}

MapData resizeEntityOnMap(
  MapData map, {
  required String entityId,
  required GridSize size,
}) {
  final entity = findEntityById(map, entityId);
  if (entity == null) {
    throw ValidationException('Entity not found: $entityId');
  }
  return updateEntityOnMap(
    map,
    entityId: entityId,
    size: size,
  );
}

MapData removeEntityFromMap(
  MapData map, {
  required String entityId,
}) {
  final index = map.entities.indexWhere((entity) => entity.id == entityId);
  if (index < 0) {
    throw ValidationException('Entity not found: $entityId');
  }
  final updated = List<MapEntity>.from(map.entities, growable: true)
    ..removeAt(index);
  return map.copyWith(entities: updated);
}

MapEntity _normalizeEntity(MapEntity entity) {
  return entity.copyWith(
    id: entity.id.trim(),
    name: entity.name.trim(),
    properties: _normalizeProperties(entity.properties),
  );
}

Map<String, String> _normalizeProperties(Map<String, String> properties) {
  return Map<String, String>.unmodifiable({
    for (final entry in properties.entries)
      entry.key.trim(): entry.value.trim(),
  });
}

void _validateEntity(
  MapData map,
  MapEntity entity, {
  String? excludedEntityId,
  required String duplicateIdLabel,
}) {
  final id = entity.id.trim();
  if (id.isEmpty) {
    throw const ValidationException('Entity ID cannot be empty');
  }
  if (map.entities.any(
    (entry) => entry.id == id && entry.id != excludedEntityId,
  )) {
    throw ValidationException('$duplicateIdLabel: $id');
  }
  if (entity.size.width <= 0 || entity.size.height <= 0) {
    throw ValidationException(
      'Entity $id has invalid size: (${entity.size.width}x${entity.size.height})',
    );
  }
  if (entity.pos.x < 0 ||
      entity.pos.y < 0 ||
      entity.pos.x + entity.size.width > map.size.width ||
      entity.pos.y + entity.size.height > map.size.height) {
    throw ValidationException(
      'Entity $id is out of map bounds at (${entity.pos.x}, ${entity.pos.y}) with size (${entity.size.width}x${entity.size.height})',
    );
  }
  for (final key in entity.properties.keys) {
    if (key.trim().isEmpty) {
      throw ValidationException('Entity $id has an empty property key');
    }
  }
}

bool _containsPos(
  MapEntity entity,
  GridPos pos,
) {
  return pos.x >= entity.pos.x &&
      pos.y >= entity.pos.y &&
      pos.x < entity.pos.x + entity.size.width &&
      pos.y < entity.pos.y + entity.size.height;
}
