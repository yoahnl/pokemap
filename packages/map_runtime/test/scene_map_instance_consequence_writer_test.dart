import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test(
    'one scoped setter persists without consuming a page or creating a Fact',
    () {
      final state = _state('instance-1');
      final result = _writer(state).applyOne(state, _setter());
      expect(result.success, isTrue);
      final store = result.gameState.mapInstanceWorldState;
      expect(
        store.eventBoolean(store.instanceRef('map')!, 'door', 'A'),
        isTrue,
      );
      expect(
        state.mapInstanceWorldState.eventBoolean(
          state.mapInstanceWorldState.instanceRef('map')!,
          'door',
          'A',
        ),
        isFalse,
      );
      expect(result.gameState.storyFlags, state.storyFlags);
      expect(result.gameState.consumedEventIds, state.consumedEventIds);
      expect(result.gameState.metadata, state.metadata);
    },
  );

  test('resetting the scoped boolean is explicit and idempotent', () {
    final state = _state('instance-1');
    final writer = _writer(state);
    final set = writer.applyOne(state, _setter());
    expect(set.success, isTrue);
    final reset = writer.applyOne(set.gameState, _setter(value: false));
    expect(reset.success, isTrue);
    final repeated = writer.applyOne(reset.gameState, _setter(value: false));
    expect(repeated.success, isTrue);
    expect(repeated.gameState, reset.gameState);
    expect(
      reset.gameState.mapInstanceWorldState.eventBoolean(
        reset.gameState.mapInstanceWorldState.instanceRef('map')!,
        'door',
        'A',
      ),
      isFalse,
    );
  });

  test('a stale captured instance refuses a write to a recreated map', () {
    final old = _state('instance-1');
    final replacement = _state('instance-2');
    final result = _writer(old).applyOne(replacement, _setter());
    expect(result.success, isFalse);
    expect(result.gameState, same(replacement));
    expect(result.appliedConsequences, isEmpty);
  });

  test('an evicted captured instance refuses a write', () {
    final old = _state('instance-1');
    final empty = old.copyWith(
      mapInstanceWorldState: const MapInstanceWorldState.empty(),
    );
    final result = _writer(old).applyOne(empty, _setter());
    expect(result.success, isFalse);
    expect(result.gameState, same(empty));
  });

  test(
    'a missing runtime binding refuses a write instead of creating an instance',
    () {
      final state = _state('instance-1');
      final result = SceneConsequenceRuntimeWriter(
        project: _project(),
        mapsById: {'map': _map()},
      ).applyOne(state, _setter());
      expect(result.success, isFalse);
      expect(result.gameState, same(state));
    },
  );

  test('unknown and ambiguous owner IDs are rejected', () {
    final state = _state('instance-1');
    final unknown = _writer(state).applyOne(state, _setter(owner: 'unknown'));
    expect(unknown.success, isFalse);
    expect(unknown.gameState, same(state));
    final duplicate = _writer(
      state,
      duplicateOwner: true,
    ).applyOne(state, _setter());
    expect(duplicate.success, isFalse);
    expect(duplicate.gameState, same(state));
  });

  test(
    'a failed scoped setter rolls back earlier consequences in the batch',
    () {
      final old = _state('instance-1');
      final replacement = _state('instance-2');
      final result = _writer(old).applyAll(replacement, [
        SceneConsequence.giveMoney(amount: 100),
        _setter(),
      ]);
      expect(result.success, isFalse);
      expect(result.gameState, same(replacement));
      expect(result.appliedConsequences, isEmpty);
    },
  );
}

GameState _state(String instance) => GameState(
  saveId: 'save',
  currentMapId: 'map',
  mapInstanceWorldState: MapInstanceWorldState(
    instancesByMapId: {'map': MapInstanceRuntimeState(instanceId: instance)},
  ),
);

SceneConsequence _setter({String owner = 'door', bool value = true}) =>
    SceneConsequence.setMapEventInstanceBoolean(
      mapId: 'map',
      eventId: owner,
      key: 'A',
      value: value,
    );

ProjectManifest _project() => ProjectManifest(
  name: 'Scope',
  maps: const [
    ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
  ],
  tilesets: const [],
);

MapData _map({bool duplicateOwner = false}) {
  const owner = MapEntity(
    id: 'door',
    kind: MapEntityKind.sign,
    pos: GridPos(x: 1, y: 1),
  );
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 4, height: 4),
    layers: const [],
    entities: [owner, if (duplicateOwner) owner],
  );
}

SceneConsequenceRuntimeWriter _writer(
  GameState captured, {
  bool duplicateOwner = false,
}) => SceneConsequenceRuntimeWriter(
  project: _project(),
  mapsById: {'map': _map(duplicateOwner: duplicateOwner)},
  mapInstanceScopes: {
    'map': captured.mapInstanceWorldState.instanceRef('map')!,
  },
);
