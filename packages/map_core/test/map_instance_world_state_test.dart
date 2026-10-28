import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('existing schema 6 and 7 save bytes remain exact after typed reading', () {
    final base = _state();
    final scope = base.instanceRef('source')!;
    for (final old in [base, base.clearFieldObstacle(scope, 'tree', resetPolicy: FieldObstacleResetPolicy.persistent)]) {
      final encoded = jsonEncode(old.toJson());
      expect(jsonEncode(MapInstanceWorldState.fromJson(jsonDecode(encoded) as Map<String, dynamic>).toJson()), encoded);
      expect(old.toJson().containsKey('persistentFieldObstaclePositions'), isFalse);
    }
  });

  test('persistent positions have one immutable authority and stale scopes fail', () {
    final positions = <String, GridPos>{'boulder': const GridPos(x: 4, y: 2)};
    final maps = <String, Map<String, GridPos>>{'source': positions};
    final original = _state();
    final scope = original.instanceRef('source')!;
    final retained = MapInstanceWorldState(instancesByMapId: original.instancesByMapId,
      persistentFieldObstaclePositions: maps);
    positions.clear();
    maps.clear();
    expect(retained.fieldObstaclePosition(scope, 'boulder'), const GridPos(x: 4, y: 2));
    expect(() => retained.persistentFieldObstaclePositions.clear(), throwsUnsupportedError);
    expect(() => retained.persistentFieldObstaclePositions['source']!.clear(), throwsUnsupportedError);
    final moved = retained.moveFieldObstacle(scope, 'boulder', const GridPos(x: 5, y: 2),
      resetPolicy: FieldObstacleResetPolicy.persistent);
    expect(moved.instancesByMapId['source']!.fieldObstaclePositions, isEmpty);
    expect(moved.fieldObstaclePositionForMap('source', 'boulder'), const GridPos(x: 5, y: 2));
    final temporary = moved.moveFieldObstacle(scope, 'boulder', const GridPos(x: 6, y: 2));
    expect(temporary.persistentFieldObstaclePositions, isEmpty);
    expect(temporary.fieldObstaclePosition(scope, 'boulder'), const GridPos(x: 6, y: 2));
    expect(() => moved.fieldObstaclePosition(MapInstanceRef(mapId: 'source', instanceId: 'stale'), 'boulder'), throwsStateError);
    final mutations = [
      moved.setEventBoolean(scope, 'door', 'A', true),
      moved.clearFieldObstacle(scope, 'tree'),
      moved.clearFieldObstacle(scope, 'tree', resetPolicy: FieldObstacleResetPolicy.persistent),
      moved.consumeInteractiveEncounter(scope, 'encounter'),
      moved.illuminateZone(scope, 'room'),
      moved.activateStrength(scope),
      moved.moveFieldObstacle(scope, 'other', const GridPos(x: 6, y: 2)),
      moved.setNpcPoses(scope, {'npc': MapInstanceNpcPose(position: const GridPos(x: 1, y: 1), facing: EntityFacing.south)}),
    ];
    for (final mutation in mutations) {
      expect(mutation.persistentFieldObstaclePositions, moved.persistentFieldObstaclePositions);
      expect(MapInstanceWorldState.fromJson(mutation.toJson()), mutation);
    }
  });

  test('schema 8 rejects corrupt positions, duplicate authorities and cells', () {
    for (final raw in [
      null, <String, dynamic>{}, {'source': <String, dynamic>{}},
      {' source': {'rock': {'x': 1, 'y': 1}}},
      {'source': {' rock': {'x': 1, 'y': 1}}},
      {'source': {'rock': {'x': -1, 'y': 1}}},
      {'source': {'rock': {'x': 1.0, 'y': 1}}},
      {'source': {'rock': {'x': 1, 'y': 1, 'z': 0}}},
      {'source': {'rock': {'x': 1, 'y': 1}, 'other': {'x': 1, 'y': 1}}},
    ]) {
      expect(() => MapInstanceWorldState.fromJson({'schemaVersion': 8,
        'instancesByMapId': <String, dynamic>{}, 'persistentClearedObstacles': <String, dynamic>{},
        'persistentFieldObstaclePositions': raw}), throwsFormatException);
    }
    for (final transient in [
      {'rock': const GridPos(x: 2, y: 1)},
      {'other': const GridPos(x: 1, y: 1)},
    ]) {
      expect(() => MapInstanceWorldState(instancesByMapId: {'source': MapInstanceRuntimeState(instanceId: 'one',
        fieldObstaclePositions: transient)}, persistentFieldObstaclePositions: {'source': {'rock': const GridPos(x: 1, y: 1)}}), throwsArgumentError);
    }
  });

  test('schema 8 restores persistent obstacle positions and exact old wire', () {
    final raw = <String, dynamic>{
      'schemaVersion': 8,
      'persistentClearedObstacles': <String, dynamic>{},
      'persistentFieldObstaclePositions': {'source': {'boulder': {'x': 4, 'y': 2}}},
      'instancesByMapId': <String, dynamic>{},
    };
    final restored = MapInstanceWorldState.fromJson(raw);
    expect(restored.toJson(), raw);
    for (final old in [
      <String, dynamic>{'schemaVersion': 6, 'instancesByMapId': <String, dynamic>{}},
      <String, dynamic>{'schemaVersion': 7, 'persistentClearedObstacles': {'source': ['tree']}, 'instancesByMapId': <String, dynamic>{}},
    ]) {
      expect(MapInstanceWorldState.fromJson(old).toJson(), old);
    }
  });

  test(
    'round-trips the empty typed instance state with its explicit schema',
    () {
      const state = MapInstanceWorldState.empty();
      expect(state.toJson(), {'schemaVersion': 6, 'instancesByMapId': {}});
      expect(MapInstanceWorldState.fromJson(state.toJson()), state);
    },
  );

  test('deep copies constructor maps and rejects mutation of exposed maps', () {
    final booleans = <String, bool>{'A': true};
    final events = <String, Map<String, bool>>{'door': booleans};
    final maps = <String, MapInstanceRuntimeState>{
      'source': MapInstanceRuntimeState(
        instanceId: 'source-instance-1',
        eventBooleans: events,
      ),
    };
    final state = MapInstanceWorldState(instancesByMapId: maps);
    booleans['A'] = false;
    events.clear();
    maps.clear();
    final scope = state.instanceRef('source')!;
    expect(state.eventBoolean(scope, 'door', 'A'), isTrue);
    expect(() => state.instancesByMapId.clear(), throwsUnsupportedError);
    expect(
      () => state.instancesByMapId['source']!.eventBooleans.clear(),
      throwsUnsupportedError,
    );
    expect(
      () => state.instancesByMapId['source']!.eventBooleans['door']!.clear(),
      throwsUnsupportedError,
    );
  });

  test('boolean mutations isolate maps events and case-sensitive keys', () {
    final before = _state();
    final source = before.instanceRef('source')!;
    final neighbor = before.instanceRef('neighbor')!;
    final after = before.setEventBoolean(source, 'door', 'A', true);
    expect(after.eventBoolean(source, 'door', 'A'), isTrue);
    expect(before.eventBoolean(source, 'door', 'A'), isFalse);
    expect(after.eventBoolean(source, 'door', 'a'), isFalse);
    expect(after.eventBoolean(source, 'door', 'B'), isFalse);
    expect(after.eventBoolean(source, 'other-door', 'A'), isFalse);
    expect(after.eventBoolean(neighbor, 'door', 'A'), isFalse);
    final disabled = after.setEventBoolean(source, 'door', 'A', false);
    expect(disabled.eventBoolean(source, 'door', 'A'), isFalse);
    expect(after.eventBoolean(source, 'door', 'A'), isTrue);
  });

  test('a missing key defaults false only inside a known instance', () {
    final state = _state();
    expect(
      state.eventBoolean(state.instanceRef('source')!, 'door', 'A'),
      isFalse,
    );
    expect(state.instanceRef('missing'), isNull);
    final missing = MapInstanceRef(mapId: 'missing', instanceId: 'missing-1');
    expect(() => state.eventBoolean(missing, 'door', 'A'), throwsStateError);
    expect(
      () => state.setEventBoolean(missing, 'door', 'A', true),
      throwsStateError,
    );
  });

  test('replacing an instance never revives the previous instance boolean', () {
    final before = _state();
    final oldScope = before.instanceRef('source')!;
    final old = before.setEventBoolean(oldScope, 'door', 'A', true);
    final replaced = MapInstanceWorldState(
      instancesByMapId: {
        ...old.instancesByMapId,
        'source': MapInstanceRuntimeState(instanceId: 'source-instance-2'),
      },
    );
    final newScope = replaced.instanceRef('source')!;
    expect(newScope, isNot(oldScope));
    expect(replaced.eventBoolean(newScope, 'door', 'A'), isFalse);
    expect(
      () => replaced.eventBoolean(oldScope, 'door', 'A'),
      throwsStateError,
    );
    expect(
      () => replaced.setEventBoolean(oldScope, 'door', 'A', false),
      throwsStateError,
    );
    expect(old.eventBoolean(oldScope, 'door', 'A'), isTrue);
  });

  test(
    'preserves exact identities and explicit false through JSON restore',
    () {
      final scope = _state().instanceRef('source')!;
      final state = _state().setEventBoolean(scope, 'door', 'A', false);
      final restored = MapInstanceWorldState.fromJson(state.toJson());
      expect(restored, state);
      expect(restored.instanceRef('source'), scope);
      expect(restored.instancesByMapId['source']!.eventBooleans['door'], {
        'A': false,
      });
    },
  );

  test('rejects a reused identity between simultaneously retained maps', () {
    expect(
      () => MapInstanceWorldState(
        instancesByMapId: {
          'source': MapInstanceRuntimeState(instanceId: 'same'),
          'neighbor': MapInstanceRuntimeState(instanceId: 'same'),
        },
      ),
      throwsArgumentError,
    );
    expect(
      () => MapInstanceWorldState.fromJson({
        'schemaVersion': 6,
        'instancesByMapId': {
          'source': {
            'instanceId': 'same',
            'consumedInteractiveEncounterEntityIds': <String>[],
            'clearedFieldObstacleIds': <String>[],
            'fieldObstaclePositions': {},
            'npcPoses': {},
            'strengthActive': false,
            'illuminatedZoneIds': <String>[],
            'eventBooleans': {},
          },
          'neighbor': {
            'instanceId': 'same',
            'consumedInteractiveEncounterEntityIds': <String>[],
            'clearedFieldObstacleIds': <String>[],
            'fieldObstaclePositions': {},
            'npcPoses': {},
            'strengthActive': false,
            'illuminatedZoneIds': <String>[],
            'eventBooleans': {},
          },
        },
      }),
      throwsFormatException,
    );
  });

  for (final json in <Map<String, dynamic>>[
    {},
    {'schemaVersion': 6},
    {'schemaVersion': 6.0, 'instancesByMapId': {}},
    {'schemaVersion': 3, 'instancesByMapId': {}},
    {'schemaVersion': 5, 'instancesByMapId': {}},
    {'schemaVersion': 6, 'instancesByMapId': null},
    {'schemaVersion': 6, 'instancesByMapId': {}, 'unknown': true},
    {
      'schemaVersion': 6,
      'instancesByMapId': {
        'source': {'instanceId': 'source-1'},
      },
    },
    {
      'schemaVersion': 6,
      'instancesByMapId': {
        'source': {
          'instanceId': 'source-1',
          'consumedInteractiveEncounterEntityIds': <String>[],
          'clearedFieldObstacleIds': <String>[],
          'fieldObstaclePositions': {},
          'npcPoses': {},
          'strengthActive': false,
          'illuminatedZoneIds': <String>[],
          'eventBooleans': {},
          'unknown': true,
        },
      },
    },
    {
      'schemaVersion': 6,
      'instancesByMapId': {
        'source': {
          'instanceId': 'source-1',
          'consumedInteractiveEncounterEntityIds': <String>[],
          'clearedFieldObstacleIds': <String>[],
          'fieldObstaclePositions': {},
          'npcPoses': {},
          'strengthActive': false,
          'illuminatedZoneIds': <String>[],
          'eventBooleans': {
            'door': {'A': 1},
          },
        },
      },
    },
    {
      'schemaVersion': 6,
      'instancesByMapId': {
        'source': {
          'instanceId': 'source-1',
          'consumedInteractiveEncounterEntityIds': <String>[],
          'clearedFieldObstacleIds': <String>[],
          'fieldObstaclePositions': {},
          'npcPoses': {},
          'strengthActive': false,
          'illuminatedZoneIds': <String>[],
          'eventBooleans': {
            'door': {'A': 'true'},
          },
        },
      },
    },
    {
      'schemaVersion': 6,
      'instancesByMapId': {
        'source': {
          'instanceId': ' source-1',
          'consumedInteractiveEncounterEntityIds': <String>[],
          'clearedFieldObstacleIds': <String>[],
          'fieldObstaclePositions': {},
          'npcPoses': {},
          'strengthActive': false,
          'illuminatedZoneIds': <String>[],
          'eventBooleans': {},
        },
      },
    },
  ]) {
    test('rejects invalid instance state JSON $json', () {
      expect(() => MapInstanceWorldState.fromJson(json), throwsFormatException);
    });
  }

  for (final bad in ['', ' ', ' padded', 'padded ']) {
    test('rejects noncanonical identities $bad', () {
      expect(
        () => MapInstanceRef(mapId: bad, instanceId: 'source-1'),
        throwsArgumentError,
      );
      expect(
        () => MapInstanceRuntimeState(instanceId: bad),
        throwsArgumentError,
      );
      expect(
        () => _state().eventBoolean(_state().instanceRef('source')!, bad, 'A'),
        throwsArgumentError,
      );
      expect(
        () => _state().setEventBoolean(
          _state().instanceRef('source')!,
          'door',
          bad,
          true,
        ),
        throwsArgumentError,
      );
    });
  }
}

MapInstanceWorldState _state() => MapInstanceWorldState(
  instancesByMapId: {
    'source': MapInstanceRuntimeState(instanceId: 'source-instance-1'),
    'neighbor': MapInstanceRuntimeState(instanceId: 'neighbor-instance-1'),
  },
);
