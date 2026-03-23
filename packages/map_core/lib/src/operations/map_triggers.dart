import '../exceptions/map_exceptions.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/enums.dart';

MapTrigger? findTriggerById(
  MapData map,
  String triggerId,
) {
  final normalizedTriggerId = triggerId.trim();
  if (normalizedTriggerId.isEmpty) {
    return null;
  }
  for (final trigger in map.triggers) {
    if (trigger.id == normalizedTriggerId) {
      return trigger;
    }
  }
  return null;
}

MapTrigger? findTriggerAtPos(
  MapData map,
  GridPos pos,
) {
  for (var index = map.triggers.length - 1; index >= 0; index--) {
    final trigger = map.triggers[index];
    if (_containsPos(trigger.area, pos)) {
      return trigger;
    }
  }
  return null;
}

MapData addTriggerToMap(
  MapData map, {
  required MapTrigger trigger,
}) {
  final normalizedTrigger = _normalizeTrigger(trigger);
  _validateTrigger(
    map,
    normalizedTrigger,
    duplicateIdLabel: 'Trigger ID already exists',
  );
  return map.copyWith(
    triggers: [...map.triggers, normalizedTrigger],
  );
}

MapData updateTriggerOnMap(
  MapData map, {
  required String triggerId,
  String? id,
  String? name,
  TriggerType? type,
  MapRect? area,
  Map<String, String>? properties,
}) {
  final index = map.triggers.indexWhere((trigger) => trigger.id == triggerId);
  if (index < 0) {
    throw ValidationException('Trigger not found: $triggerId');
  }
  final current = map.triggers[index];
  final next = _normalizeTrigger(
    current.copyWith(
      id: id?.trim() ?? current.id,
      name: name?.trim() ?? current.name,
      type: type ?? current.type,
      area: area ?? current.area,
      properties: properties == null
          ? current.properties
          : _normalizeProperties(properties),
    ),
  );
  _validateTrigger(
    map,
    next,
    excludedTriggerId: current.id,
    duplicateIdLabel: 'Trigger ID already exists',
  );
  final updated = List<MapTrigger>.from(map.triggers, growable: false);
  updated[index] = next;
  return map.copyWith(triggers: updated);
}

MapData moveTriggerOnMap(
  MapData map, {
  required String triggerId,
  required GridPos pos,
}) {
  final trigger = findTriggerById(map, triggerId);
  if (trigger == null) {
    throw ValidationException('Trigger not found: $triggerId');
  }
  return updateTriggerOnMap(
    map,
    triggerId: triggerId,
    area: trigger.area.copyWith(pos: pos),
  );
}

MapData resizeTriggerOnMap(
  MapData map, {
  required String triggerId,
  required GridSize size,
}) {
  final trigger = findTriggerById(map, triggerId);
  if (trigger == null) {
    throw ValidationException('Trigger not found: $triggerId');
  }
  return updateTriggerOnMap(
    map,
    triggerId: triggerId,
    area: trigger.area.copyWith(size: size),
  );
}

MapData removeTriggerFromMap(
  MapData map, {
  required String triggerId,
}) {
  final index = map.triggers.indexWhere((trigger) => trigger.id == triggerId);
  if (index < 0) {
    throw ValidationException('Trigger not found: $triggerId');
  }
  final updated = List<MapTrigger>.from(map.triggers, growable: true)
    ..removeAt(index);
  return map.copyWith(triggers: updated);
}

MapTrigger _normalizeTrigger(MapTrigger trigger) {
  return trigger.copyWith(
    id: trigger.id.trim(),
    name: trigger.name.trim(),
    properties: _normalizeProperties(trigger.properties),
  );
}

Map<String, String> _normalizeProperties(Map<String, String> properties) {
  return Map<String, String>.unmodifiable({
    for (final entry in properties.entries)
      entry.key.trim(): entry.value.trim(),
  });
}

void _validateTrigger(
  MapData map,
  MapTrigger trigger, {
  String? excludedTriggerId,
  required String duplicateIdLabel,
}) {
  final id = trigger.id.trim();
  if (id.isEmpty) {
    throw const ValidationException('Trigger ID cannot be empty');
  }
  if (map.triggers.any(
    (entry) => entry.id == id && entry.id != excludedTriggerId,
  )) {
    throw ValidationException('$duplicateIdLabel: $id');
  }

  final area = trigger.area;
  if (area.size.width <= 0 || area.size.height <= 0) {
    throw ValidationException(
      'Trigger $id has invalid area size: (${area.size.width}x${area.size.height})',
    );
  }
  if (area.pos.x < 0 ||
      area.pos.y < 0 ||
      area.pos.x + area.size.width > map.size.width ||
      area.pos.y + area.size.height > map.size.height) {
    throw ValidationException(
      'Trigger $id area is out of map bounds at (${area.pos.x}, ${area.pos.y}) with size (${area.size.width}x${area.size.height})',
    );
  }
  for (final key in trigger.properties.keys) {
    if (key.trim().isEmpty) {
      throw ValidationException('Trigger $id has an empty property key');
    }
  }
}

bool _containsPos(
  MapRect rect,
  GridPos pos,
) {
  return pos.x >= rect.pos.x &&
      pos.y >= rect.pos.y &&
      pos.x < rect.pos.x + rect.size.width &&
      pos.y < rect.pos.y + rect.size.height;
}
