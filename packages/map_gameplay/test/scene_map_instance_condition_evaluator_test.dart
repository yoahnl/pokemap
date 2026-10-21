import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  test('prepared owners preserve scoped booleans through a save round trip',
      () {
    final map = NarrativeMapProjection.fromMapData(_world().map);
    final before = _state();
    final scope = before.mapInstanceWorldState.instanceRef('source')!;
    final changed = applySceneMapEventInstanceBoolean(
      gameState: before,
      consequence: _setter(true),
      map: map,
      expectedInstance: scope,
    );
    final restored =
        GameState.fromJson(jsonDecode(jsonEncode(changed.toJson())));
    expect(
        evaluateSceneMapEventInstanceBoolean(
          source: _boolean(),
          gameState: restored,
          map: map,
          scope: scope,
        ),
        isTrue);
    expect(
        evaluateSceneMapEventInstanceBoolean(
          source: _boolean(),
          gameState: before,
          map: map,
          scope: scope,
        ),
        isFalse);
    expect(
        () => evaluateSceneMapEventInstanceBoolean(
              source: _boolean(),
              gameState: restored,
              map: map,
              scope:
                  MapInstanceRef(mapId: 'other', instanceId: 'other-instance'),
            ),
        throwsStateError);
  });

  test('matches only the exact logical entity anchor on the current map', () {
    expect(_atAnchor(_world(playerPos: const GridPos(x: 2, y: 2))), isTrue);
    for (final pos in [
      const GridPos(x: 1, y: 2),
      const GridPos(x: 2, y: 1),
      const GridPos(x: 3, y: 2),
      const GridPos(x: 2, y: 3),
      const GridPos(x: 3, y: 3),
    ]) {
      expect(_atAnchor(_world(playerPos: pos)), isFalse);
    }
  });

  test('does not substitute footprint occupancy for anchor equality', () {
    final world = _world(
      playerPos: const GridPos(x: 3, y: 2),
      entities: [_door.copyWith(size: const GridSize(width: 2, height: 2))],
    );
    expect(_atAnchor(world), isFalse);
  });

  test('requires both native map identities and does not cross map coordinates',
      () {
    final world = _world(playerPos: const GridPos(x: 2, y: 2));
    expect(
        evaluateScenePlayerAtEntityAnchor(
          source: _anchor(mapId: 'neighbor'),
          world: world,
          currentMapId: 'source',
        ),
        isFalse);
    expect(
        () => evaluateScenePlayerAtEntityAnchor(
              source: _anchor(),
              world: world,
              currentMapId: 'neighbor',
            ),
        throwsStateError);
  });

  test(
      'presence filters collision and visibility do not change exact occupancy',
      () {
    final world = _world(playerPos: const GridPos(x: 2, y: 2))
        .withNpcMapPresencePredicate((_, __) => false)
        .withMapEntityPresencePredicate((_, __) => false);
    expect(world.entityAt(2, 2), isNull);
    expect(_atAnchor(world), isTrue);
  });

  test(
      'reads the moved authoritative entity anchor rather than its authored pose',
      () {
    final before = _world(playerPos: const GridPos(x: 3, y: 2));
    final moved = before.withEntityPosition('door', const GridPos(x: 3, y: 2));
    expect(_atAnchor(before), isFalse);
    expect(_atAnchor(moved), isTrue);
    expect(before.map.entities.single.pos, const GridPos(x: 2, y: 2));
  });

  for (final entities in <List<MapEntity>>[
    [],
    [_door, _door]
  ]) {
    test(
        'does not turn missing or duplicate anchors into a false branch ${entities.length}',
        () {
      expect(() => _atAnchor(_world(entities: entities)), throwsStateError);
      expect(() => _atAnchor(_world(entities: entities), expected: false),
          throwsStateError);
    });
  }

  test('boolean reads default false and writes only the captured owner scope',
      () {
    final before = _state();
    final scope = before.mapInstanceWorldState.instanceRef('source')!;
    expect(_read(before, scope), isFalse);
    final after = applySceneMapEventInstanceBoolean(
      gameState: before,
      consequence: _setter(true),
      map: _world().map,
      expectedInstance: scope,
    );
    expect(_read(after, scope), isTrue);
    expect(_read(before, scope), isFalse);
    expect(after.storyFlags, before.storyFlags);
    expect(after.narrativeFactRuntimeState, before.narrativeFactRuntimeState);
    expect(after.narrativeEventProgress, before.narrativeEventProgress);
    expect(after.metadata, before.metadata);
    final restored = gameStateFromSaveData(saveDataFromGameState(after));
    expect(_read(restored, scope), isTrue);
    expect(restored.mapInstanceWorldState.instanceRef('source'), scope);
  });

  test('a local boolean write cannot bind to a replacement map instance', () {
    final before = _state();
    final old = before.mapInstanceWorldState.instanceRef('source')!;
    final replaced = before.copyWith(
        mapInstanceWorldState: MapInstanceWorldState(instancesByMapId: {
      'source': MapInstanceRuntimeState(instanceId: 'source-instance-2'),
    }));
    expect(() => _read(replaced, old, expected: false), throwsStateError);
    expect(
        () => applySceneMapEventInstanceBoolean(
              gameState: replaced,
              consequence: _setter(true),
              map: _world().map,
              expectedInstance: old,
            ),
        throwsStateError);
    expect(
        replaced.mapInstanceWorldState.eventBoolean(
          replaced.mapInstanceWorldState.instanceRef('source')!,
          'door',
          'A',
        ),
        isFalse);
  });

  for (final entities in <List<MapEntity>>[
    [],
    [_door, _door]
  ]) {
    test('boolean owner must be declared exactly once ${entities.length}', () {
      final state = _state();
      final scope = state.mapInstanceWorldState.instanceRef('source')!;
      final map = _world(entities: entities).map;
      expect(
          () => evaluateSceneMapEventInstanceBoolean(
                source: _boolean(expected: false),
                gameState: state,
                map: map,
                scope: scope,
              ),
          throwsStateError);
      expect(
          () => applySceneMapEventInstanceBoolean(
                gameState: state,
                consequence: _setter(true),
                map: map,
                expectedInstance: scope,
              ),
          throwsStateError);
    });
  }

  test('a declared non-NPC entity can own its instance boolean', () {
    final state = _state();
    final scope = state.mapInstanceWorldState.instanceRef('source')!;
    final map =
        _world(entities: [_door.copyWith(kind: MapEntityKind.sign)]).map;
    final after = applySceneMapEventInstanceBoolean(
      gameState: state,
      consequence: _setter(true),
      map: map,
      expectedInstance: scope,
    );
    expect(
        evaluateSceneMapEventInstanceBoolean(
          source: _boolean(),
          gameState: after,
          map: map,
          scope: scope,
        ),
        isTrue);
  });
}

SceneConditionSource _anchor({String mapId = 'source', bool expected = true}) =>
    SceneConditionSource.playerAtEntityAnchor(
      mapId: mapId,
      entityId: 'door',
      expected: expected,
    );

SceneConditionSource _boolean({bool expected = true}) =>
    SceneConditionSource.mapEventInstanceBoolean(
      mapId: 'source',
      eventId: 'door',
      key: 'A',
      expected: expected,
    );

SceneSetMapEventInstanceBooleanConsequence _setter(bool value) =>
    SceneSetMapEventInstanceBooleanConsequence(
      mapId: 'source',
      eventId: 'door',
      key: 'A',
      value: value,
    );

bool _atAnchor(GameplayWorldState world, {bool expected = true}) =>
    evaluateScenePlayerAtEntityAnchor(
      source: _anchor(expected: expected),
      world: world,
      currentMapId: 'source',
    );

bool _read(GameState state, MapInstanceRef scope, {bool expected = true}) =>
    evaluateSceneMapEventInstanceBoolean(
      source: _boolean(expected: expected),
      gameState: state,
      map: _world().map,
      scope: scope,
    );

const _door = MapEntity(
  id: 'door',
  kind: MapEntityKind.npc,
  pos: GridPos(x: 2, y: 2),
  npc: MapEntityNpcData(),
);

GameplayWorldState _world({
  GridPos playerPos = const GridPos(x: 2, y: 2),
  List<MapEntity>? entities,
}) =>
    GameplayWorldState.initial(
      map: MapData(
          id: 'source',
          name: 'Source',
          size: const GridSize(width: 6, height: 6),
          entities: entities ?? [_door]),
      project: const ProjectManifest(name: 'Source', maps: [], tilesets: []),
      playerPos: playerPos,
      tileWidth: 16,
      tileHeight: 16,
    );

GameState _state() => GameState(
      saveId: 'instance-save',
      currentMapId: 'source',
      mapInstanceWorldState: MapInstanceWorldState(instancesByMapId: {
        'source': MapInstanceRuntimeState(instanceId: 'source-instance-1'),
      }),
    );
