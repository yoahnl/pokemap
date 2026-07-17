import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  group('resolveNarrativeTriggerEnterFronts', () {
    test('initializes inside eligible triggers without emitting an entry', () {
      final map = _mapWithTriggers([
        _trigger('zone_event', TriggerType.event),
        _trigger('zone_custom', TriggerType.custom),
        for (final type in const [
          TriggerType.warp,
          TriggerType.message,
          TriggerType.interaction,
          TriggerType.spawn,
          TriggerType.camera,
        ])
          _trigger('system_${type.name}', type),
      ]);

      final resolution = resolveNarrativeTriggerEnterFronts(
        map: map,
        currentPosition: const GridPos(x: 2, y: 2),
        previousOccupiedTriggerIds: null,
      );

      expect(
        resolution.currentOccupiedTriggerIds,
        ['zone_custom', 'zone_event'],
      );
      expect(resolution.enteredTriggerIds, isEmpty);
    });

    test('does not emit while staying inside the same eligible trigger', () {
      final map = _mapWithTriggers([
        _trigger('zone_event', TriggerType.event),
      ]);
      final initialized = resolveNarrativeTriggerEnterFronts(
        map: map,
        currentPosition: const GridPos(x: 2, y: 2),
        previousOccupiedTriggerIds: null,
      );

      final maintained = resolveNarrativeTriggerEnterFronts(
        map: map,
        currentPosition: const GridPos(x: 3, y: 3),
        previousOccupiedTriggerIds: initialized.currentOccupiedTriggerIds,
      );

      expect(maintained.currentOccupiedTriggerIds, ['zone_event']);
      expect(maintained.enteredTriggerIds, isEmpty);
    });

    test('rearams after exit and emits once on re-entry', () {
      final map = _mapWithTriggers([
        _trigger('zone_event', TriggerType.event),
      ]);
      final initialized = resolveNarrativeTriggerEnterFronts(
        map: map,
        currentPosition: const GridPos(x: 2, y: 2),
        previousOccupiedTriggerIds: null,
      );
      final exited = resolveNarrativeTriggerEnterFronts(
        map: map,
        currentPosition: const GridPos(x: 8, y: 8),
        previousOccupiedTriggerIds: initialized.currentOccupiedTriggerIds,
      );

      final reentered = resolveNarrativeTriggerEnterFronts(
        map: map,
        currentPosition: const GridPos(x: 2, y: 2),
        previousOccupiedTriggerIds: exited.currentOccupiedTriggerIds,
      );

      expect(exited.currentOccupiedTriggerIds, isEmpty);
      expect(exited.enteredTriggerIds, isEmpty);
      expect(reentered.currentOccupiedTriggerIds, ['zone_event']);
      expect(reentered.enteredTriggerIds, ['zone_event']);
    });

    test('keeps overlapping fronts in canonical UTF-16 order', () {
      final map = _mapWithTriggers([
        _trigger('zone_\uE000', TriggerType.event),
        _trigger('zone_\u{10000}', TriggerType.custom),
        _trigger('zone_a', TriggerType.event),
      ]);

      final resolution = resolveNarrativeTriggerEnterFronts(
        map: map,
        currentPosition: const GridPos(x: 2, y: 2),
        previousOccupiedTriggerIds: const <String>[],
      );

      expect(
        resolution.enteredTriggerIds,
        ['zone_a', 'zone_\u{10000}', 'zone_\uE000'],
      );
      expect(
        resolution.currentOccupiedTriggerIds,
        resolution.enteredTriggerIds,
      );
    });
  });
}

MapData _mapWithTriggers(List<MapTrigger> triggers) {
  return MapData(
    id: 'map_test',
    name: 'Map test',
    size: const GridSize(width: 10, height: 10),
    triggers: triggers,
  );
}

MapTrigger _trigger(String id, TriggerType type) {
  return MapTrigger(
    id: id,
    type: type,
    area: const MapRect(
      pos: GridPos(x: 1, y: 1),
      size: GridSize(width: 4, height: 4),
    ),
  );
}
