import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

MapData _map() => const MapData(
        id: 'route',
        name: 'Route',
        size: GridSize(width: 5, height: 4),
        entities: [
          MapEntity(
              id: 'tree',
              kind: MapEntityKind.custom,
              pos: GridPos(x: 2, y: 1),
              fieldObstacle: MapEntityFieldObstacleData()),
        ]);
GameState _ready() => GameState(
    saveId: 'cut',
    currentMapId: 'route',
    playerPosition: const GridPos(x: 1, y: 1),
    playerFacing: EntityFacing.east,
    party: const PlayerParty(members: [
      PlayerPokemon(
          speciesId: 'scyther',
          natureId: 'hardy',
          abilityId: 'swarm',
          level: 20,
          currentHp: 30,
          knownMoveIds: ['cut'])
    ]),
    progression:
        const PlayerProgression(unlockedFieldAbilities: [FieldAbility.cut]),
    mapInstanceWorldState: MapInstanceWorldState(instancesByMapId: {
      'route': MapInstanceRuntimeState(instanceId: 'route-1'),
    }));
CutObstacleTicket _ticket(GameState state,
        {int revision = 4}) =>
    CutObstacleTicket(
        fieldAction: FieldActionTicket(
            ability: FieldAbility.cut,
            targetCell: const GridPos(x: 2, y: 1),
            issuedAtStateRevision: revision),
        instance: state.mapInstanceWorldState.instanceRef('route')!,
        entityId: 'tree',
        playerPosition: state.playerPosition,
        playerFacing: state.playerFacing);

void main() {
  test('Cut selects the first usable member and preserves zero PP at commit',
      () {
    final ready = _ready();
    final cutter = ready.party.members.single;
    final state = ready.copyWith(
        party: PlayerParty(members: [
      cutter.copyWith(currentHp: 0),
      cutter.copyWith(knownMoveIds: ['tackle']),
      cutter.copyWith(currentPpByMoveId: {'cut': 0}),
      cutter,
    ]));
    final before = state.toJson();
    final evaluation = evaluateCutObstacleAttempt(
        map: _map(), gameState: state, entityId: 'tree');

    expect(evaluation, isA<CanPromptCutObstacle>());
    expect((evaluation as CanPromptCutObstacle).partyIndex, 2);
    final result = commitCutObstacleAction(
        ticket: _ticket(state),
        map: _map(),
        gameState: state,
        currentStateRevision: 4,
        confirmedEntityId: 'tree') as CutObstacleApplied;
    expect(result.gameState.party, state.party);
    expect(state.toJson(), before);
  });

  test('Cut keeps missing move ahead of a missing unlock', () {
    final state = _ready().copyWith(
        party: const PlayerParty(), progression: const PlayerProgression());
    final evaluation = evaluateCutObstacleAttempt(
        map: _map(), gameState: state, entityId: 'tree');

    expect((evaluation as CutObstacleUnavailable).reason,
        CutObstacleBlockReason.missingMove);
  });

  test('a typed Cut obstacle blocks without untyped collision properties', () {
    final map = _map();
    final state = _ready();
    expect(map.entities.single.properties, isEmpty);
    final world = GameplayWorldState.initial(
      map: map,
      playerPos: state.playerPosition,
      playerFacing: Direction.east,
    );
    expect(world.isCellCenterBlockedLegacyForGridIndexedSystems(2, 1), isTrue);
    final occupied = GameplayWorldState.initial(
      map: map,
      playerPos: const GridPos(x: 2, y: 1),
    );
    expect(occupied.worldStaticObstaclesCollidePlayerCollisionRect(), isTrue);
    final ordinary = GameplayWorldState.initial(
      map: map.copyWith(
          entities: [map.entities.single.copyWith(fieldObstacle: null)]),
      playerPos: const GridPos(x: 2, y: 1),
    );
    expect(ordinary.worldStaticObstaclesCollidePlayerCollisionRect(), isFalse);
  });
  test(
      'a usable Cut party and native unlock can prompt the real front obstacle',
      () {
    final result = evaluateCutObstacleAttempt(
        map: _map(), gameState: _ready(), entityId: 'tree');
    expect(result, isA<CanPromptCutObstacle>());
    expect((result as CanPromptCutObstacle).partyIndex, 0);
  });
  test('accepted Cut writes only its typed map instance obstacle state', () {
    final before = _ready();
    final result = commitCutObstacleAction(
        ticket: _ticket(before),
        map: _map(),
        gameState: before,
        currentStateRevision: 4,
        confirmedEntityId: 'tree');
    expect(result, isA<CutObstacleApplied>());
    final after = (result as CutObstacleApplied).gameState;
    final scope = after.mapInstanceWorldState.instanceRef('route')!;
    expect(after.mapInstanceWorldState.isFieldObstacleCleared(scope, 'tree'),
        isTrue);
    expect(before.mapInstanceWorldState.isFieldObstacleCleared(scope, 'tree'),
        isFalse);
    expect(after.party, before.party);
    expect(after.progression, before.progression);
    expect(after.storyFlags, before.storyFlags);
    expect(after.consumedEventIds, before.consumedEventIds);
  });
  test(
      'typed state projection removes collision and interaction without altering authored map',
      () {
    final authored = _map(), state = _ready();
    final scope = state.mapInstanceWorldState.instanceRef('route')!;
    final instances =
        state.mapInstanceWorldState.clearFieldObstacle(scope, 'tree');
    final projected = applyFieldObstacleWorldStateToMap(
        map: authored, instances: instances, instance: scope);
    final world = GameplayWorldState.initial(
        map: projected,
        playerPos: state.playerPosition,
        playerFacing: Direction.east);
    expect(authored.entities, hasLength(1));
    expect(projected.entities, isEmpty);
    expect(stepGameplayWorld(world, const InteractIntent()),
        isA<NothingToInteract>());
    expect(stepGameplayWorld(world, const MoveIntent(Direction.east)),
        isA<Moved>());
  });
  test('Surf keeps its signed beta gate independently from Cut objects', () {
    expect(betaSignedFieldAbilities, {FieldAbility.surf});
    expect(
        evaluateFieldAction(
            ability: FieldAbility.cut,
            gameState: _ready(),
            isTargetWater: true),
        isA<FieldActionUnsupported>());
  });
  for (final mode in [
    'noMove',
    'fainted',
    'locked',
    'cleared',
    'wrongFacing',
    'wrongMap',
    'missingInstance',
    'spatial'
  ]) {
    test('Cut evaluation refuses $mode without changing state', () {
      var state = _ready();
      var map = _map();
      final reason = switch (mode) {
        'noMove' || 'fainted' => CutObstacleBlockReason.missingMove,
        'locked' => CutObstacleBlockReason.locked,
        'cleared' => CutObstacleBlockReason.alreadyCleared,
        'missingInstance' => CutObstacleBlockReason.missingMapInstance,
        'spatial' => CutObstacleBlockReason.unsupportedMap,
        _ => CutObstacleBlockReason.invalidTarget,
      };
      if (mode == 'noMove') state = state.copyWith(party: const PlayerParty());
      if (mode == 'fainted') {
        state = state.copyWith(
            party: PlayerParty(
                members: [state.party.members.single.copyWith(currentHp: 0)]));
      }
      if (mode == 'locked') {
        state = state.copyWith(progression: const PlayerProgression());
      }
      if (mode == 'cleared') {
        state = state.copyWith(
            mapInstanceWorldState: state.mapInstanceWorldState
                .clearFieldObstacle(
                    state.mapInstanceWorldState.instanceRef('route')!, 'tree'));
      }
      if (mode == 'wrongFacing') {
        state = state.copyWith(playerFacing: EntityFacing.north);
      }
      if (mode == 'wrongMap') state = state.copyWith(currentMapId: 'other');
      if (mode == 'missingInstance') {
        state = state.copyWith(
            mapInstanceWorldState: const MapInstanceWorldState.empty());
      }
      if (mode == 'spatial') map = map.copyWith(version: ProjectVersion.v9);
      final before = state.toJson();
      final result = evaluateCutObstacleAttempt(
          map: map, gameState: state, entityId: 'tree');
      expect(result, isA<CutObstacleUnavailable>());
      expect((result as CutObstacleUnavailable).reason, reason);
      expect(state.toJson(), before);
    });
  }
  for (final mode in [
    'staleRevision',
    'otherEntity',
    'otherInstance',
    'movedPlayer',
    'turnedPlayer',
    'missingTree',
    'movedTree',
    'duplicateTree',
    'fainted',
    'locked',
    'cleared'
  ]) {
    test('Cut commit rechecks $mode rather than trusting the pending prompt',
        () {
      final before = _ready(), ticket = _ticket(_ready());
      var state = before;
      var map = _map();
      if (mode == 'otherInstance') {
        state = state.copyWith(
            mapInstanceWorldState: MapInstanceWorldState(instancesByMapId: {
          'route': MapInstanceRuntimeState(instanceId: 'route-2')
        }));
      }
      if (mode == 'movedPlayer') {
        state = state.copyWith(playerPosition: const GridPos(x: 0, y: 1));
      }
      if (mode == 'turnedPlayer') {
        state = state.copyWith(playerFacing: EntityFacing.north);
      }
      if (mode == 'missingTree') map = map.copyWith(entities: []);
      if (mode == 'movedTree') {
        map = map.copyWith(entities: [
          map.entities.single.copyWith(pos: const GridPos(x: 3, y: 1))
        ]);
      }
      if (mode == 'duplicateTree') {
        map = map.copyWith(entities: [...map.entities, map.entities.single]);
      }
      if (mode == 'fainted') {
        state = state.copyWith(
            party: PlayerParty(
                members: [state.party.members.single.copyWith(currentHp: 0)]));
      }
      if (mode == 'locked') {
        state = state.copyWith(progression: const PlayerProgression());
      }
      if (mode == 'cleared') {
        state = state.copyWith(
            mapInstanceWorldState: state.mapInstanceWorldState
                .clearFieldObstacle(ticket.instance, 'tree'));
      }
      final frozen = state.toJson();
      final result = commitCutObstacleAction(
          ticket: ticket,
          map: map,
          gameState: state,
          currentStateRevision: mode == 'staleRevision' ? 5 : 4,
          confirmedEntityId: mode == 'otherEntity' ? 'other' : 'tree');
      expect(result, isA<CutObstacleRefused>());
      final expected = mode == 'staleRevision'
          ? FieldActionRefusal.staleStateRevision
          : ['fainted', 'locked', 'cleared', 'duplicateTree'].contains(mode)
              ? FieldActionRefusal.noLongerAvailable
              : FieldActionRefusal.targetChanged;
      expect((result as CutObstacleRefused).refusal, expected);
      expect(state.toJson(), frozen);
    });
  }
  test(
      'save and retained instance preserve Cut while a newly allocated instance resets it',
      () {
    final state = _ready(), authored = _map();
    final scope = state.mapInstanceWorldState.instanceRef('route')!;
    final cut = state.copyWith(
        mapInstanceWorldState:
            state.mapInstanceWorldState.clearFieldObstacle(scope, 'tree'));
    final restored = GameState.fromJson(cut.toJson());
    final retained = retainMapInstance(
        state: restored.mapInstanceWorldState,
        mapId: 'other',
        allocateId: (_) => 'other-1');
    expect(
        applyFieldObstacleWorldStateToMap(
                map: authored, instances: retained, instance: scope)
            .entities,
        isEmpty);
    final reset = setupDifferentMapInstance(
        state: retained, targetMapId: 'route', allocateId: (_) => 'route-2');
    final resetMap = applyFieldObstacleWorldStateToMap(
        map: authored, instances: reset, instance: reset.instanceRef('route')!);
    expect(resetMap.entities, authored.entities);
    expect(
        stepGameplayWorld(
            GameplayWorldState.initial(
                map: resetMap,
                playerPos: state.playerPosition,
                playerFacing: Direction.east),
            const InteractIntent()),
        isA<EntityInteracted>());
    expect(
        () => applyFieldObstacleWorldStateToMap(
            map: authored, instances: reset, instance: scope),
        throwsStateError);
  });
  test(
      'Cut projection preserves unrelated entities and authored floor collision',
      () {
    final state = _ready();
    final scope = state.mapInstanceWorldState.instanceRef('route')!;
    final instances = state.mapInstanceWorldState
        .clearFieldObstacle(scope, 'tree');
    final authored = _map().copyWith(entities: [
      ..._map().entities,
      const MapEntity(
          id: 'marker', kind: MapEntityKind.custom, pos: GridPos(x: 4, y: 2))
    ], layers: [
      MapLayer.collision(
          id: 'wall',
          name: 'Wall',
          collisions: List.generate(20, (index) => index == 7))
    ]);
    final projected = applyFieldObstacleWorldStateToMap(
        map: authored, instances: instances, instance: scope);
    expect(projected.entities.map((entity) => entity.id), ['marker']);
    expect(projected.layers, authored.layers);
    expect(
        stepGameplayWorld(
            GameplayWorldState.initial(
                map: projected,
                playerPos: state.playerPosition,
                playerFacing: Direction.east),
            const MoveIntent(Direction.east)),
        isA<Blocked>());
  });

  for (final entry in const [
    (GridPos(x: 2, y: 0), EntityFacing.south),
    (GridPos(x: 2, y: 2), EntityFacing.north),
    (GridPos(x: 1, y: 1), EntityFacing.east),
    (GridPos(x: 3, y: 1), EntityFacing.west),
  ]) {
    test('Cut uses the real front cell facing ${entry.$2.name}', () {
      final state =
          _ready().copyWith(playerPosition: entry.$1, playerFacing: entry.$2);
      expect(
          evaluateCutObstacleAttempt(
              map: _map(), gameState: state, entityId: 'tree'),
          isA<CanPromptCutObstacle>());
      expect(
          commitCutObstacleAction(
              ticket: _ticket(state),
              map: _map(),
              gameState: state,
              currentStateRevision: 4,
              confirmedEntityId: 'tree'),
          isA<CutObstacleApplied>());
    });
  }
  for (final action in [
    const FieldActionTicket(
        ability: FieldAbility.surf,
        targetCell: GridPos(x: 2, y: 1),
        issuedAtStateRevision: 4),
    const FieldActionTicket(
        ability: FieldAbility.cut,
        targetCell: GridPos(x: 3, y: 1),
        issuedAtStateRevision: 4),
  ]) {
    test(
        'Cut refuses a ticket with a different ability or cell ${action.ability.name}/${action.targetCell}',
        () {
      final state = _ready();
      final original = _ticket(state);
      final ticket = CutObstacleTicket(
          fieldAction: action,
          instance: original.instance,
          entityId: 'tree',
          playerPosition: state.playerPosition,
          playerFacing: state.playerFacing);
      final result = commitCutObstacleAction(
          ticket: ticket,
          map: _map(),
          gameState: state,
          currentStateRevision: 4,
          confirmedEntityId: 'tree');
      expect(result, isA<CutObstacleRefused>());
      expect((result as CutObstacleRefused).refusal,
          FieldActionRefusal.targetChanged);
    });
  }
  test('typed Cut projection refuses spatial obstacle data', () {
    final state = _ready();
    final scope = state.mapInstanceWorldState.instanceRef('route')!;
    final instances =
        state.mapInstanceWorldState.clearFieldObstacle(scope, 'tree');
    expect(
        () => applyFieldObstacleWorldStateToMap(
            map: _map().copyWith(version: ProjectVersion.v9),
            instances: instances,
            instance: scope),
        throwsStateError);
  });
  test(
      'Cut entity collision remains one cell despite metadata and a wider visual profile',
      () {
    const project =
        ProjectManifest(name: 'Cut visual collision', maps: [], tilesets: [
      ProjectTilesetEntry(id: 'trees', name: 'Trees', relativePath: 'trees.png')
    ], elements: [
      ProjectElementEntry(
          id: 'tree-visual',
          name: 'Tree',
          tilesetId: 'trees',
          categoryId: 'props',
          frames: [
            TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 1))
          ],
          collisionProfile: ElementCollisionProfile(
              cells: [GridPos(x: 0, y: 0), GridPos(x: 1, y: 0)]))
    ]);
    final map = _map().copyWith(entities: [
      _map().entities.single.copyWith(
          editorVisual: const MapEntityEditorVisual(elementId: 'tree-visual'),
          properties: const {'collision.width': '2', 'collision.offsetX': '1'})
    ], layers: [
      MapLayer.tile(id: 'props', name: 'Props', cells: List.filled(20, -1))
    ]);
    final state = _ready();
    final world = GameplayWorldState.initial(
        map: map,
        project: project,
        playerPos: state.playerPosition,
        playerFacing: Direction.east);
    expect(resolveEntityCollisionCells(map.entities.single),
        [map.entities.single.pos]);
    expect(world.isCellCenterBlockedLegacyForGridIndexedSystems(2, 1), isTrue);
    expect(world.isCellCenterBlockedLegacyForGridIndexedSystems(3, 1), isFalse);
    expect(
        evaluateCutObstacleAttempt(
            map: map, gameState: state, entityId: 'tree'),
        isA<CanPromptCutObstacle>());
    final applied = commitCutObstacleAction(
        ticket: _ticket(state),
        map: map,
        gameState: state,
        currentStateRevision: 4,
        confirmedEntityId: 'tree') as CutObstacleApplied;
    final projected = applyFieldObstacleWorldStateToMap(
        map: map,
        instances: applied.gameState.mapInstanceWorldState,
        instance: _ticket(state).instance);
    final clearedWorld = GameplayWorldState.initial(
        map: projected,
        project: project,
        playerPos: state.playerPosition,
        playerFacing: Direction.east);
    expect(clearedWorld.isCellCenterBlockedLegacyForGridIndexedSystems(2, 1),
        isFalse);
    expect(clearedWorld.isCellCenterBlockedLegacyForGridIndexedSystems(3, 1),
        isFalse);
    expect(stepGameplayWorld(clearedWorld, const MoveIntent(Direction.east)),
        isA<Moved>());
    final placed = map.copyWith(entities: [], placedElements: const [
      MapPlacedElement(
          id: 'decor',
          elementId: 'tree-visual',
          layerId: 'props',
          pos: GridPos(x: 2, y: 1))
    ]);
    final placedWorld = GameplayWorldState.initial(
        map: placed,
        project: project,
        playerPos: state.playerPosition,
        playerFacing: Direction.east);
    expect(placedWorld.isCellCenterBlockedLegacyForGridIndexedSystems(2, 1),
        isTrue);
    expect(placedWorld.isCellCenterBlockedLegacyForGridIndexedSystems(3, 1),
        isTrue);
  });
}
