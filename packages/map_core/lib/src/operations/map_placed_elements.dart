import '../exceptions/map_exceptions.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';

String buildMapPlacedElementId({
  required String layerId,
  required String elementId,
  required GridPos pos,
}) {
  return '${Uri.encodeComponent(layerId)}::${pos.x}::${pos.y}';
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

MapData setMapPlacedElementAnimation(
  MapData map, {
  required String instanceId,
  required MapPlacedElementAnimation? animation,
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
  next[index] = next[index].copyWith(animation: animation);
  return map.copyWith(placedElements: next);
}

MapData resetMapPlacedElementAnimation(
  MapData map, {
  required String instanceId,
}) {
  return setMapPlacedElementAnimation(
    map,
    instanceId: instanceId,
    animation: null,
  );
}

MapData setMapPlacedElementAnimationEnabled(
  MapData map, {
  required String instanceId,
  required bool enabled,
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
  final current = map.placedElements[index];
  final currentAnim = current.animation ?? const MapPlacedElementAnimation();
  final nextAnim = currentAnim.copyWith(enabled: enabled);
  return setMapPlacedElementAnimation(
    map,
    instanceId: normalizedId,
    animation: nextAnim,
  );
}

MapData setMapPlacedElementBehaviors(
  MapData map, {
  required String instanceId,
  required List<MapPlacedElementBehavior> behaviors,
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
  final normalizedBehaviors =
      behaviors.map(_normalizePlacedElementBehavior).toList(growable: false);
  final next = List<MapPlacedElement>.from(map.placedElements, growable: true);
  next[index] = next[index].copyWith(behaviors: normalizedBehaviors);
  return map.copyWith(placedElements: next);
}

MapData resetMapPlacedElementBehaviors(
  MapData map, {
  required String instanceId,
}) {
  return setMapPlacedElementBehaviors(
    map,
    instanceId: instanceId,
    behaviors: const <MapPlacedElementBehavior>[],
  );
}

MapData addMapPlacedElementBehavior(
  MapData map, {
  required String instanceId,
  required MapPlacedElementBehavior behavior,
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
  final current = map.placedElements[index].behaviors;
  final nextBehaviors = List<MapPlacedElementBehavior>.from(
    current,
    growable: true,
  )..add(_normalizePlacedElementBehavior(behavior));
  return setMapPlacedElementBehaviors(
    map,
    instanceId: normalizedId,
    behaviors: nextBehaviors,
  );
}

MapData updateMapPlacedElementBehaviorAt(
  MapData map, {
  required String instanceId,
  required int behaviorIndex,
  required MapPlacedElementBehavior behavior,
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
  final nextBehaviors = List<MapPlacedElementBehavior>.from(
    map.placedElements[index].behaviors,
    growable: true,
  );
  if (behaviorIndex < 0 || behaviorIndex >= nextBehaviors.length) {
    throw ValidationException(
      'Placed element behavior index out of range: $behaviorIndex',
    );
  }
  nextBehaviors[behaviorIndex] = _normalizePlacedElementBehavior(behavior);
  return setMapPlacedElementBehaviors(
    map,
    instanceId: normalizedId,
    behaviors: nextBehaviors,
  );
}

MapData removeMapPlacedElementBehaviorAt(
  MapData map, {
  required String instanceId,
  required int behaviorIndex,
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
  final nextBehaviors = List<MapPlacedElementBehavior>.from(
    map.placedElements[index].behaviors,
    growable: true,
  );
  if (behaviorIndex < 0 || behaviorIndex >= nextBehaviors.length) {
    throw ValidationException(
      'Placed element behavior index out of range: $behaviorIndex',
    );
  }
  nextBehaviors.removeAt(behaviorIndex);
  return setMapPlacedElementBehaviors(
    map,
    instanceId: normalizedId,
    behaviors: nextBehaviors,
  );
}

MapData setMapPlacedElementBehaviorEnabledAt(
  MapData map, {
  required String instanceId,
  required int behaviorIndex,
  required bool enabled,
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
  final nextBehaviors = List<MapPlacedElementBehavior>.from(
    map.placedElements[index].behaviors,
    growable: true,
  );
  if (behaviorIndex < 0 || behaviorIndex >= nextBehaviors.length) {
    throw ValidationException(
      'Placed element behavior index out of range: $behaviorIndex',
    );
  }
  nextBehaviors[behaviorIndex] =
      nextBehaviors[behaviorIndex].copyWith(enabled: enabled);
  return setMapPlacedElementBehaviors(
    map,
    instanceId: normalizedId,
    behaviors: nextBehaviors,
  );
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
    behaviors: instance.behaviors
        .map(_normalizePlacedElementBehavior)
        .toList(growable: false),
    properties: {
      for (final entry in instance.properties.entries)
        entry.key.trim(): entry.value.trim(),
    },
  );
}

MapPlacedElementBehavior _normalizePlacedElementBehavior(
  MapPlacedElementBehavior behavior,
) {
  return behavior.copyWith(
    effect: _normalizePlacedElementEffect(behavior.effect),
  );
}

MapPlacedElementEffect _normalizePlacedElementEffect(
  MapPlacedElementEffect effect,
) {
  final message = effect.message?.trim();
  final dialogue = effect.dialogue;
  final trimmedDialogue = dialogue == null
      ? null
      : dialogue.copyWith(
          dialogueId: dialogue.dialogueId.trim(),
          scriptPathRelative: dialogue.scriptPathRelative.trim(),
          startNode: dialogue.startNode?.trim().isEmpty == true
              ? null
              : dialogue.startNode?.trim(),
        );
  return effect.copyWith(
    message: message == null || message.isEmpty ? null : message,
    dialogue: trimmedDialogue,
  );
}
