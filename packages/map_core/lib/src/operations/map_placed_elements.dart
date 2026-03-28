import '../exceptions/map_exceptions.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';

String buildMapPlacedElementId({
  required String layerId,
  required String elementId,
  required GridPos pos,
}) {
  return '${Uri.encodeComponent(layerId)}::${Uri.encodeComponent(elementId)}::${pos.x}::${pos.y}';
}

MapData upsertMapPlacedElement(
  MapData map, {
  required MapPlacedElement instance,
}) {
  final normalized = _normalizePlacedElement(instance);
  final index =
      map.placedElements.indexWhere((entry) => entry.id == normalized.id);
  final next = List<MapPlacedElement>.from(map.placedElements, growable: true);
  if (index < 0) {
    next.add(normalized);
  } else {
    next[index] = normalized;
  }
  return map.copyWith(placedElements: next);
}

MapData removeMapPlacedElement(
  MapData map, {
  required String instanceId,
}) {
  final normalizedId = instanceId.trim();
  if (normalizedId.isEmpty) {
    throw const ValidationException(
        'Placed element instance id cannot be empty');
  }
  final next = map.placedElements
      .where((entry) => entry.id != normalizedId)
      .toList(growable: false);
  if (next.length == map.placedElements.length) {
    throw ValidationException(
        'Placed element instance not found: $normalizedId');
  }
  return map.copyWith(placedElements: next);
}

MapData replaceMapPlacedElementsForLayer(
  MapData map, {
  required String layerId,
  required List<MapPlacedElement> instances,
}) {
  final normalizedLayerId = layerId.trim();
  if (normalizedLayerId.isEmpty) {
    throw const ValidationException('Layer id cannot be empty');
  }
  final normalizedInstances =
      instances.map(_normalizePlacedElement).toList(growable: false);
  final next = <MapPlacedElement>[
    ...map.placedElements.where((entry) => entry.layerId != normalizedLayerId),
    ...normalizedInstances.where((entry) => entry.layerId == normalizedLayerId),
  ];
  return map.copyWith(placedElements: next);
}

MapData setMapPlacedElementCollisionApplied(
  MapData map, {
  required String instanceId,
  required bool applyCollision,
}) {
  final normalizedId = instanceId.trim();
  if (normalizedId.isEmpty) {
    throw const ValidationException(
        'Placed element instance id cannot be empty');
  }
  final index =
      map.placedElements.indexWhere((entry) => entry.id == normalizedId);
  if (index < 0) {
    throw ValidationException(
        'Placed element instance not found: $normalizedId');
  }
  final next = List<MapPlacedElement>.from(map.placedElements, growable: true);
  next[index] = next[index].copyWith(applyCollision: applyCollision);
  return map.copyWith(placedElements: next);
}

MapPlacedElement _normalizePlacedElement(MapPlacedElement instance) {
  final normalizedId = instance.id.trim();
  if (normalizedId.isEmpty) {
    throw const ValidationException(
        'Placed element instance id cannot be empty');
  }
  final normalizedLayerId = instance.layerId.trim();
  if (normalizedLayerId.isEmpty) {
    throw const ValidationException('Placed element layer id cannot be empty');
  }
  final normalizedElementId = instance.elementId.trim();
  if (normalizedElementId.isEmpty) {
    throw const ValidationException(
        'Placed element element id cannot be empty');
  }
  return instance.copyWith(
    id: normalizedId,
    layerId: normalizedLayerId,
    elementId: normalizedElementId,
    properties: {
      for (final entry in instance.properties.entries)
        entry.key.trim(): entry.value.trim(),
    },
  );
}
