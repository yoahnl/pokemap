import 'package:map_core/map_core.dart';
import 'package:map_gameplay/src/map_instance_lifecycle.dart';
import 'package:test/test.dart';

void main() {
  test(
      'different-map setup clears every previous instance and creates a fresh target',
      () {
    final before = _state();
    final calls = <String>[];
    final after = setupDifferentMapInstance(
        state: before,
        targetMapId: 'neighbor',
        allocateId: (id) {
          calls.add(id);
          return 'new-$id';
        });
    expect(after.instancesByMapId.keys, ['neighbor']);
    expect(after.instanceRef('neighbor')!.instanceId, 'new-neighbor');
    expect(after.eventBoolean(after.instanceRef('neighbor')!, 'door', 'A'),
        isFalse);
    expect(before.eventBoolean(before.instanceRef('active')!, 'door', 'A'),
        isTrue);
    expect(calls, ['neighbor']);
  });

  test('same-map setup preserves the whole store identity and flags', () {
    final before = _state();
    final after = preserveSameMapInstance(state: before, mapId: 'active');
    expect(identical(before, after), isTrue);
    expect(
        after.eventBoolean(after.instanceRef('active')!, 'door', 'A'), isTrue);
    expect(() => preserveSameMapInstance(state: before, mapId: 'absent'),
        throwsStateError);
  });

  test('retain reuses existing instances without invoking the allocator', () {
    final before = _state();
    expect(
        identical(
            retainMapInstance(
                state: before,
                mapId: 'neighbor',
                allocateId: (_) => throw StateError('unexpected allocation')),
            before),
        isTrue);
    final after = retainMapInstance(
        state: before, mapId: 'new', allocateId: (_) => 'fresh');
    expect(after.instanceRef('new')!.instanceId, 'fresh');
    expect(after.instancesByMapId['active'],
        same(before.instancesByMapId['active']));
  });

  test('new instances reject stale reused or noncanonical identities', () {
    final before = _state();
    for (final id in ['active-1', 'neighbor-1', '', ' space']) {
      expect(
          () => setupDifferentMapInstance(
              state: before, targetMapId: 'new', allocateId: (_) => id),
          throwsArgumentError);
      expect(
          () => retainMapInstance(
              state: before, mapId: 'new', allocateId: (_) => id),
          throwsArgumentError);
    }
    expect(
        () => retainMapInstance(
            state: before, mapId: '', allocateId: (_) => 'fresh'),
        throwsArgumentError);
  });

  test(
      'logical viewport uses native configured dimensions and qualified origin',
      () {
    final viewport = resolveMapInstanceLogicalViewport(
        playerAnchorX: 13,
        playerAnchorY: 25,
        activeMap: _geometry('active', x: 80, y: -20),
        policy: _policy());
    expect(viewport.leftTiles, 85.5);
    expect(viewport.topTiles, -0.5);
  });

  test(
      'logical clamp stays on the map and handles maps smaller than the viewport',
      () {
    final policy = _policy(['active']);
    final near = resolveMapInstanceLogicalViewport(
        playerAnchorX: 0,
        playerAnchorY: 0,
        activeMap: _geometry('active', x: 80, y: -20),
        policy: policy);
    expect(near.leftTiles, 80);
    expect(near.topTiles, -20);
    final far = resolveMapInstanceLogicalViewport(
        playerAnchorX: 99,
        playerAnchorY: 99,
        activeMap: _geometry('active', x: 80, y: -20),
        policy: policy);
    expect(far.leftTiles, 104);
    expect(far.topTiles, 8);
    final tiny = resolveMapInstanceLogicalViewport(
        playerAnchorX: 2,
        playerAnchorY: 3,
        activeMap: _geometry('active', width: 4, height: 5),
        policy: policy);
    expect(tiny.leftTiles, 0);
    expect(tiny.topTiles, 0);
  });

  test(
      'retention waits for settled movement and does not allocate while moving',
      () {
    final before = _state();
    final after = updateMapInstanceRetention(
        state: before,
        activeMap: _geometry('active'),
        directConnectedMaps: [],
        logicalViewport: _view(500, 500),
        policy: _policy(),
        settled: false,
        allocateId: (_) => throw StateError('unexpected allocation'));
    expect(identical(before, after), isTrue);
  });

  test(
      'settled retention drops nonadjacent maps and always retains the active one',
      () {
    final before = _state();
    final after = _update(before, neighbors: [], left: 500, top: 500);
    expect(after.instancesByMapId.keys, ['active']);
    expect(after.instanceRef('active'), before.instanceRef('active'));
    expect(
        after.eventBoolean(after.instanceRef('active')!, 'door', 'A'), isTrue);
  });

  test('near connections reuse the exact instance including its flags', () {
    final before = _state();
    final after = _update(before, neighbors: [_geometry('neighbor')]);
    expect(after.instancesByMapId['neighbor'],
        same(before.instancesByMapId['neighbor']));
    expect(after.eventBoolean(after.instanceRef('neighbor')!, 'door', 'A'),
        isTrue);
    expect(after.instancesByMapId.containsKey('unrelated'), isFalse);
  });

  test('eviction and reentry create a new instance without restoring old flags',
      () {
    final before = _state();
    final oldScope = before.instanceRef('neighbor')!;
    final evicted =
        _update(before, neighbors: [_geometry('neighbor')], left: 46);
    expect(evicted.instanceRef('neighbor'), isNull);
    final reentered = _update(evicted, neighbors: [_geometry('neighbor')]);
    expect(reentered.instanceRef('neighbor')!.instanceId, 'new-neighbor');
    expect(
        reentered.eventBoolean(reentered.instanceRef('neighbor')!, 'door', 'A'),
        isFalse);
    expect(
        () => reentered.eventBoolean(oldScope, 'door', 'A'), throwsStateError);
  });

  for (final edge in [(-22.0, 0.0), (46.0, 0.0), (0.0, -18.0), (0.0, 46.0)]) {
    test('retention excludes exact viewport edge $edge', () {
      final after = _update(_state(),
          neighbors: [_geometry('neighbor')], left: edge.$1, top: edge.$2);
      expect(after.instanceRef('neighbor'), isNull);
    });
  }

  for (final edge in [
    (-21.999, 0.0),
    (45.999, 0.0),
    (0.0, -17.999),
    (0.0, 45.999)
  ]) {
    test('retention includes positions strictly inside viewport edge $edge',
        () {
      final after = _update(_state(),
          neighbors: [_geometry('neighbor')], left: edge.$1, top: edge.$2);
      expect(after.instanceRef('neighbor'), isNotNull);
    });
  }

  test('connection origin offsets are applied on both axes', () {
    final after = _update(_state(),
        neighbors: [_geometry('new', x: 100, y: -100)], left: 100, top: -100);
    expect(after.instanceRef('new')!.instanceId, 'new-new');
  });

  test('an existing clamped neighbor is retained even outside its raw range',
      () {
    final after = _update(_state(),
        neighbors: [_geometry('neighbor')],
        left: 500,
        top: 500,
        policy: _policy(['neighbor']));
    expect(after.instanceRef('neighbor')!.instanceId, 'neighbor-1');
    expect(after.eventBoolean(after.instanceRef('neighbor')!, 'door', 'A'),
        isTrue);
  });

  test('an absent clamped neighbor outside raw range is never created', () {
    final after = _update(_state(),
        neighbors: [_geometry('new')],
        left: 500,
        top: 500,
        policy: _policy(['new']),
        allocateId: (_) => throw StateError('unexpected allocation'));
    expect(after.instanceRef('new'), isNull);
  });

  test('retention evaluates raw neighbor range before clamping its display',
      () {
    final after = _update(_state(),
        neighbors: [_geometry('new', width: 4, height: 5)],
        left: -21,
        top: -17,
        policy: _policy(['new']));
    expect(after.instanceRef('new'), isNotNull);
  });

  test('retention ordering is canonical and duplicate geometry is rejected',
      () {
    final before = _state();
    final first = _update(before, neighbors: [_geometry('z'), _geometry('a')]);
    final second = _update(before, neighbors: [_geometry('a'), _geometry('z')]);
    expect(first, second);
    expect(() => _update(before, neighbors: [_geometry('a'), _geometry('a')]),
        throwsArgumentError);
    expect(() => _update(before, neighbors: [_geometry('active')]),
        throwsArgumentError);
  });

  test('missing active instance and malformed geometry are explicit errors',
      () {
    expect(
        () => _update(const MapInstanceWorldState.empty()), throwsStateError);
    expect(() => _geometry(' active'), throwsArgumentError);
    expect(() => _geometry('active', width: 0), throwsArgumentError);
    expect(() => _view(double.nan, 0), throwsArgumentError);
    expect(() => _view(0, double.infinity), throwsArgumentError);
    expect(
        () => resolveMapInstanceLogicalViewport(
            playerAnchorX: double.nan,
            playerAnchorY: 0,
            activeMap: _geometry('active'),
            policy: _policy()),
        throwsArgumentError);
  });

  test('an unchanged neighborhood preserves the world state identity', () {
    final before = MapInstanceWorldState(instancesByMapId: {
      'active': _state().instancesByMapId['active']!,
      'neighbor': _state().instancesByMapId['neighbor']!,
    });
    final after = _update(before,
        neighbors: [_geometry('neighbor')],
        allocateId: (_) => throw StateError('unexpected allocation'));
    expect(identical(before, after), isTrue);
  });

  test('duplicate allocator IDs across newly retained neighbors are rejected',
      () {
    final before = _state();
    expect(
        () => _update(before,
            neighbors: [_geometry('a'), _geometry('b')],
            allocateId: (_) => 'same-new-id'),
        throwsArgumentError);
    expect(before.instancesByMapId.length, 3);
    expect(before.eventBoolean(before.instanceRef('active')!, 'door', 'A'),
        isTrue);
  });

  test('allocator failures propagate without changing the original snapshot',
      () {
    final before = _state();
    expect(
        () => _update(before,
            neighbors: [_geometry('a')],
            allocateId: (_) => throw StateError('allocator failed')),
        throwsStateError);
    expect(before.instanceRef('a'), isNull);
    expect(before.instancesByMapId.length, 3);
  });

  test(
      'configured viewport and margin drive range without hidden source defaults',
      () {
    final policy = MapInstanceRetentionPolicy(
        viewportWidthTiles: 4, viewportHeightTiles: 3, marginTiles: 0);
    final included = _update(_state(),
        neighbors: [_geometry('neighbor')],
        left: -3.99,
        top: -2.99,
        policy: policy);
    final excluded = _update(_state(),
        neighbors: [_geometry('neighbor')], left: -4, top: 0, policy: policy);
    expect(included.instanceRef('neighbor'), isNotNull);
    expect(excluded.instanceRef('neighbor'), isNull);
  });

  test('many connected maps allocate once per map in stable identity order',
      () {
    final calls = <String>[];
    final geometries = [
      for (var index = 0; index < 280; index++) _geometry('map-$index')
    ];
    final after =
        _update(_state(), neighbors: geometries.reversed, allocateId: (mapId) {
      calls.add(mapId);
      return 'instance-$mapId';
    });
    final expected = geometries.map((geometry) => geometry.mapId).toList()
      ..sort();
    expect(calls, expected);
    expect(after.instancesByMapId.length, 281);
    expect(
        after.instancesByMapId.values
            .map((instance) => instance.instanceId)
            .toSet()
            .length,
        281);
  });

  test('a connected-map activation preserves both retained instance references',
      () {
    final before = _state();
    final after = updateMapInstanceRetention(
        state: before,
        activeMap: _geometry('neighbor'),
        directConnectedMaps: [_geometry('active')],
        logicalViewport: _view(0, 0),
        policy: _policy(),
        settled: true,
        allocateId: (_) => throw StateError('unexpected allocation'));
    expect(after.instanceRef('neighbor'), before.instanceRef('neighbor'));
    expect(after.instanceRef('active'), before.instanceRef('active'));
    expect(after.eventBoolean(after.instanceRef('neighbor')!, 'door', 'A'),
        isTrue);
    expect(
        after.eventBoolean(after.instanceRef('active')!, 'door', 'A'), isTrue);
    expect(after.instanceRef('unrelated'), isNull);
  });

  test('save restoration preserves IDs and flags without a lifecycle reset',
      () {
    final before = _state();
    final restored = MapInstanceWorldState.fromJson(before.toJson());
    final preserved = preserveSameMapInstance(state: restored, mapId: 'active');
    expect(preserved, before);
    expect(preserved.instanceRef('neighbor'), before.instanceRef('neighbor'));
  });

  test(
      'failed staged transfer can roll back to the unchanged original snapshot',
      () {
    final before = _state();
    final captured = before.instanceRef('active')!;
    final staged = setupDifferentMapInstance(
        state: before,
        targetMapId: 'neighbor',
        allocateId: (_) => 'new-neighbor');
    expect(() => staged.eventBoolean(captured, 'door', 'A'), throwsStateError);
    expect(before.eventBoolean(captured, 'door', 'A'), isTrue);
    expect(before.instanceRef('neighbor')!.instanceId, 'neighbor-1');
  });
}

MapInstanceWorldState _state() => MapInstanceWorldState(instancesByMapId: {
      'active': MapInstanceRuntimeState(instanceId: 'active-1', eventBooleans: {
        'door': {'A': true}
      }),
      'neighbor':
          MapInstanceRuntimeState(instanceId: 'neighbor-1', eventBooleans: {
        'door': {'A': true}
      }),
      'unrelated': MapInstanceRuntimeState(instanceId: 'unrelated-1'),
    });
MapInstanceMapGeometry _geometry(String id,
        {int x = 0, int y = 0, int width = 40, int height = 40}) =>
    MapInstanceMapGeometry(
        mapId: id,
        originTiles: GridPos(x: x, y: y),
        sizeTiles: GridSize(width: width, height: height));
MapInstanceLogicalViewport _view(double left, double top) =>
    MapInstanceLogicalViewport(leftTiles: left, topTiles: top);
MapInstanceRetentionPolicy _policy([Iterable<String> clamp = const []]) =>
    MapInstanceRetentionPolicy(
        viewportWidthTiles: 16,
        viewportHeightTiles: 12,
        marginTiles: 6,
        clampViewportToMapIds: clamp);
MapInstanceWorldState _update(MapInstanceWorldState state,
        {Iterable<MapInstanceMapGeometry> neighbors = const [],
        double left = 0,
        double top = 0,
        MapInstanceRetentionPolicy? policy,
        String Function(String)? allocateId}) =>
    updateMapInstanceRetention(
        state: state,
        activeMap: _geometry('active'),
        directConnectedMaps: neighbors,
        logicalViewport: _view(left, top),
        policy: policy ?? _policy(),
        settled: true,
        allocateId: allocateId ?? (id) => 'new-$id');
