import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'round-trips the empty typed instance state with its explicit schema',
    () {
      const state = MapInstanceWorldState.empty();
      expect(state.toJson(), {'schemaVersion': 2, 'instancesByMapId': {}});
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
        'schemaVersion': 2,
        'instancesByMapId': {
          'source': {
            'instanceId': 'same',
            'clearedFieldObstacleIds': <String>[],
            'eventBooleans': {},
          },
          'neighbor': {
            'instanceId': 'same',
            'clearedFieldObstacleIds': <String>[],
            'eventBooleans': {},
          },
        },
      }),
      throwsFormatException,
    );
  });

  for (final json in <Map<String, dynamic>>[
    {},
    {'schemaVersion': 2},
    {'schemaVersion': 2.0, 'instancesByMapId': {}},
    {'schemaVersion': 3, 'instancesByMapId': {}},
    {'schemaVersion': 2, 'instancesByMapId': null},
    {'schemaVersion': 2, 'instancesByMapId': {}, 'unknown': true},
    {
      'schemaVersion': 2,
      'instancesByMapId': {
        'source': {'instanceId': 'source-1'},
      },
    },
    {
      'schemaVersion': 2,
      'instancesByMapId': {
        'source': {
          'instanceId': 'source-1',
          'clearedFieldObstacleIds': <String>[],
          'eventBooleans': {},
          'unknown': true,
        },
      },
    },
    {
      'schemaVersion': 2,
      'instancesByMapId': {
        'source': {
          'instanceId': 'source-1',
          'clearedFieldObstacleIds': <String>[],
          'eventBooleans': {
            'door': {'A': 1},
          },
        },
      },
    },
    {
      'schemaVersion': 2,
      'instancesByMapId': {
        'source': {
          'instanceId': 'source-1',
          'clearedFieldObstacleIds': <String>[],
          'eventBooleans': {
            'door': {'A': 'true'},
          },
        },
      },
    },
    {
      'schemaVersion': 2,
      'instancesByMapId': {
        'source': {
          'instanceId': ' source-1',
          'clearedFieldObstacleIds': <String>[],
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
