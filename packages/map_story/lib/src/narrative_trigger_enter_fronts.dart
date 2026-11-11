import 'package:map_core/map_core.dart';

/// Pure resolution of eligible trigger occupancy and newly-entered fronts.
class NarrativeTriggerEnterFrontResolution {
  NarrativeTriggerEnterFrontResolution._({
    required List<String> currentOccupiedTriggerIds,
    required List<String> enteredTriggerIds,
  })  : currentOccupiedTriggerIds = List.unmodifiable(
          currentOccupiedTriggerIds,
        ),
        enteredTriggerIds = List.unmodifiable(enteredTriggerIds);

  /// Eligible trigger IDs covering the current player position.
  final List<String> currentOccupiedTriggerIds;

  /// Eligible trigger IDs absent from the previous occupancy.
  final List<String> enteredTriggerIds;
}

/// Resolves the eligible `MapTrigger` entry fronts at [currentPosition].
///
/// Only `event` and `custom` triggers belong to the narrative source union.
/// Passing `null` for [previousOccupiedTriggerIds] initializes occupancy (for
/// example after spawn, load, or warp) without emitting entry fronts. Passing
/// an empty iterable represents a previous position outside every eligible
/// trigger and therefore emits every currently occupied trigger as an entry.
NarrativeTriggerEnterFrontResolution resolveNarrativeTriggerEnterFronts({
  required MapData map,
  required GridPos currentPosition,
  required Iterable<String>? previousOccupiedTriggerIds,
}) {
  final currentIds = <String>{};
  for (final trigger in map.triggers) {
    if (!_isNarrativeTrigger(trigger) ||
        !_contains(trigger.area, currentPosition)) {
      continue;
    }
    currentIds.add(trigger.id);
  }

  final orderedCurrentIds = currentIds.toList()
    ..sort(compareNarrativeEventUtf16);
  final previousIds = previousOccupiedTriggerIds?.toSet();
  final enteredIds = previousIds == null
      ? <String>[]
      : orderedCurrentIds
          .where((triggerId) => !previousIds.contains(triggerId))
          .toList(growable: false);

  return NarrativeTriggerEnterFrontResolution._(
    currentOccupiedTriggerIds: orderedCurrentIds,
    enteredTriggerIds: enteredIds,
  );
}

bool _isNarrativeTrigger(MapTrigger trigger) {
  final id = trigger.id;
  return id.isNotEmpty &&
      id.trim() == id &&
      (trigger.type == TriggerType.event || trigger.type == TriggerType.custom);
}

bool _contains(MapRect area, GridPos position) {
  return position.x >= area.pos.x &&
      position.y >= area.pos.y &&
      position.x < area.pos.x + area.size.width &&
      position.y < area.pos.y + area.size.height;
}
