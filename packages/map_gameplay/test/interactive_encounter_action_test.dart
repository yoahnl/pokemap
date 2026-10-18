import 'dart:math';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  test(
    'Headbutt objects block grid navigation without collision overrides',
    () {
      final fixture = encounterFixture();
      final world = fixture.world(fixture.state);
      expect(fixture.entity.properties, isEmpty);
      expect(fixture.entity.fieldObstacle, isNull);
      expect(
        world.isCellCenterBlockedLegacyForGridIndexedSystems(3, 2),
        isTrue,
      );
      final result = stepGameplayWorld(
        world,
        const MoveIntent(Direction.east, pixelsPerStep: 16),
      );
      expect(result, isA<Blocked>());
      expect(
        result.world.player.playerPositionPx,
        world.player.playerPositionPx,
      );
    },
  );
  test('Headbutt objects stop pixel movement at their collision boundary', () {
    final fixture = encounterFixture();
    var world = fixture.world(fixture.state);
    expect(
      world.mapEntitiesCollidePixelRect(
        const PixelRect(leftPx: 48, topPx: 32, widthPx: 16, heightPx: 16),
      ),
      isTrue,
    );
    GameplayStepResult? stopped;
    for (var step = 0; step < 16; step++) {
      final result = stepGameplayWorld(
        world,
        const MoveIntent(Direction.east, pixelsPerStep: 1),
      );
      if (result is Blocked) {
        stopped = result;
        expect(
          result.world.player.playerPositionPx,
          world.player.playerPositionPx,
        );
        break;
      }
      world = result.world;
    }
    expect(stopped, isA<Blocked>());
    expect(world.player.pos, fixture.state.playerPosition);
  });
  test('custom object collision still respects blocking and map presence', () {
    final fixture = encounterFixture();
    for (final entity in [
      fixture.entity.copyWith(interactiveEncounter: null),
      fixture.entity.copyWith(blocksMovement: false),
    ]) {
      final world = GameplayWorldState.initial(
        map: fixture.map.copyWith(entities: [entity]),
        playerPos: fixture.state.playerPosition,
      );
      expect(
        world.isCellCenterBlockedLegacyForGridIndexedSystems(3, 2),
        isFalse,
      );
      expect(
        stepGameplayWorld(
          world,
          const MoveIntent(Direction.east, pixelsPerStep: 16),
        ),
        isA<Moved>(),
      );
    }
    final hidden = GameplayWorldState.initial(
      map: fixture.map,
      playerPos: fixture.state.playerPosition,
      mapEntityPresencePredicate: (mapId, entity) => false,
    );
    expect(
      hidden.isCellCenterBlockedLegacyForGridIndexedSystems(3, 2),
      isFalse,
    );
    expect(
      stepGameplayWorld(
        hidden,
        const MoveIntent(Direction.east, pixelsPerStep: 16),
      ),
      isA<Moved>(),
    );
  });

  test('Headbutt validates the usable move before RNG and preserves repel', () {
    final fixture = encounterFixture();
    final missing = fixture.state.copyWith(party: const PlayerParty());
    final random = CountingRandom();
    expect(
        evaluateInteractiveEncounter(
                world: fixture.world(missing),
                project: fixture.project,
                gameState: missing,
                entity: fixture.entity)
            .reason,
        InteractiveEncounterBlockReason.missingMove);
    final ticket = InteractiveEncounterTicket(
        attemptId: 'a',
        map: fixture.map,
        project: fixture.project,
        gameState: fixture.state,
        entity: fixture.entity,
        playerPixelPosition: _pixel(fixture.world(fixture.state)),
        issuedAtStateRevision: 1,
        mapActivationId: 'activation');
    final result = resolveInteractiveEncounter(
        ticket: ticket,
        world: fixture.world(fixture.state),
        project: fixture.project,
        gameState: fixture.state,
        currentStateRevision: 1,
        mapActivationId: 'activation',
        random: random);
    expect(result.encounterCheck?.triggered, isTrue);
    expect(result.encounterCheck?.encounter?.sourceKind,
        EncounterSourceKind.interactiveObject);
    expect(result.encounterCheck?.encounter?.playerPos,
        fixture.state.playerPosition);
    expect(random.doubleCalls, 1);
    expect(fixture.state.repelState.remainingSteps, 8);
    expect(
        fixture.state.mapInstanceWorldState.isInteractiveEncounterConsumed(
            fixture.state.mapInstanceWorldState.instanceRef('route')!, 'tree'),
        isFalse);
  });
  test(
      'optional Smash uses captured source after clearing without requiring a Headbutt move',
      () {
    final fixture = encounterFixture();
    final rock = fixture.entity.copyWith(
        fieldObstacle: const MapEntityFieldObstacleData(
            kind: FieldObstacleKind.rockSmashRock),
        interactiveEncounter: MapEntityInteractiveEncounterData(
            trigger: InteractiveEncounterTrigger.afterRockSmash,
            encounterTableId: 'rocks'));
    final map = fixture.map.copyWith(entities: []);
    final scope = fixture.state.mapInstanceWorldState.instanceRef('route')!;
    final state = fixture.state.copyWith(
        party: const PlayerParty(),
        mapInstanceWorldState: fixture.state.mapInstanceWorldState
            .clearFieldObstacle(scope, 'tree'));
    final project = fixture.project.copyWith(encounterTables: [
      fixture.project.encounterTables.single
          .copyWith(id: 'rocks', encounterKind: EncounterKind.special)
    ]);
    final world = GameplayWorldState.initial(
        map: map,
        playerPos: state.playerPosition,
        playerFacing: state.playerFacing.asDirection);
    final ticket = InteractiveEncounterTicket(
        attemptId: 'smash',
        map: map,
        project: project,
        gameState: state,
        entity: rock,
        playerPixelPosition: _pixel(world),
        issuedAtStateRevision: 2,
        mapActivationId: 'activation');
    final random = CountingRandom();
    final result = resolveInteractiveEncounter(
        ticket: ticket,
        world: world,
        project: project,
        gameState: state,
        currentStateRevision: 2,
        mapActivationId: 'activation',
        random: random);
    expect(result.encounterCheck?.triggered, isTrue);
    expect(
        result.encounterCheck?.encounter?.encounterKind, EncounterKind.special);
    expect(random.doubleCalls, 1);
    expect(state.mapInstanceWorldState.isFieldObstacleCleared(scope, 'tree'),
        isTrue);
  });
  test(
      'conditions, fainted partner, wrong mode and consumed entity reject before randomness',
      () {
    final fixture = encounterFixture();
    for (final state in [
      fixture.state.copyWith(
          party: PlayerParty(members: [
        fixture.state.party.members.single.copyWith(currentHp: 0)
      ])),
      fixture.state.copyWith(playerMovementMode: MovementMode.bicycle),
      fixture.state.copyWith(playerFacing: EntityFacing.west)
    ]) {
      final ticket = InteractiveEncounterTicket(
          attemptId: 'invalid',
          map: fixture.map,
          project: fixture.project,
          gameState: state,
          entity: fixture.entity,
          playerPixelPosition: _pixel(fixture.world(state)),
          issuedAtStateRevision: 2,
          mapActivationId: 'activation');
      final random = CountingRandom();
      final result = resolveInteractiveEncounter(
          ticket: ticket,
          world: fixture.world(state),
          project: fixture.project,
          gameState: state,
          currentStateRevision: 2,
          mapActivationId: 'activation',
          random: random);
      expect(result.reason, isNotNull);
      expect(random.doubleCalls, 0);
    }
    final entity = fixture.entity.copyWith(
        interactiveEncounter: MapEntityInteractiveEncounterData(
            trigger: InteractiveEncounterTrigger.headbutt,
            encounterTableId: 'trees',
            conditions: [
          ScriptConditionFactory.itemQuantityAtLeast('key', 1)
        ]));
    final map = fixture.map.copyWith(entities: [entity]);
    final world = GameplayWorldState.initial(
        map: map,
        playerPos: fixture.state.playerPosition,
        playerFacing: Direction.east);
    expect(
        evaluateInteractiveEncounter(
                world: world,
                project: fixture.project,
                gameState: fixture.state,
                entity: entity)
            .reason,
        InteractiveEncounterBlockReason.conditionsNotMet);
  });
  test(
      'consumption survives all other logical state setters and save roundtrip',
      () {
    final fixture = encounterFixture();
    final scope = fixture.state.mapInstanceWorldState.instanceRef('route')!;
    final state = fixture.state.mapInstanceWorldState
        .consumeInteractiveEncounter(scope, 'tree')
        .setEventBoolean(scope, 'event', 'A', true)
        .clearFieldObstacle(scope, 'rock')
        .illuminateZone(scope, 'cave')
        .activateStrength(scope)
        .moveFieldObstacle(scope, 'boulder', const GridPos(x: 4, y: 4))
        .setNpcPoses(scope, _npcPoses(const {'npc': GridPos(x: 5, y: 5)}));
    final restored = MapInstanceWorldState.fromJson(state.toJson());
    expect(restored.isInteractiveEncounterConsumed(scope, 'tree'), isTrue);
    expect(
        restored.isInteractiveEncounterConsumed(scope, 'other-tree'), isFalse);
    final consumed = fixture.state.copyWith(mapInstanceWorldState: restored);
    expect(
        evaluateInteractiveEncounter(
                world: fixture.world(consumed),
                project: fixture.project,
                gameState: consumed,
                entity: fixture.entity)
            .reason,
        InteractiveEncounterBlockReason.alreadyConsumed);
  });
  test('subcell movement refuses an issued interaction before RNG', () {
    final fixture = encounterFixture();
    final original = fixture.world(fixture.state);
    final ticket = InteractiveEncounterTicket(
        attemptId: 'pixel',
        map: fixture.map,
        project: fixture.project,
        gameState: fixture.state,
        entity: fixture.entity,
        playerPixelPosition: _pixel(original),
        issuedAtStateRevision: 1,
        mapActivationId: 'activation');
    final moved = original.withPlayer(original.player.copyWith(
        playerPositionPx: PixelPosition(
            leftPx: original.player.playerPositionPx.leftPx + 1,
            topPx: original.player.playerPositionPx.topPx)));
    final random = CountingRandom();
    expect(
        resolveInteractiveEncounter(
                ticket: ticket,
                world: moved,
                project: fixture.project,
                gameState: fixture.state,
                currentStateRevision: 1,
                mapActivationId: 'activation',
                random: random)
            .reason,
        InteractiveEncounterBlockReason.staleAttempt);
    expect(random.doubleCalls, 0);
  });
  test('stale activation and removed target refuse without RNG', () {
    final fixture = encounterFixture();
    final random = CountingRandom();
    final ticket = InteractiveEncounterTicket(
        attemptId: 'a',
        map: fixture.map,
        project: fixture.project,
        gameState: fixture.state,
        entity: fixture.entity,
        playerPixelPosition: _pixel(fixture.world(fixture.state)),
        issuedAtStateRevision: 1,
        mapActivationId: 'activation');
    final result = resolveInteractiveEncounter(
        ticket: ticket,
        world: fixture.world(fixture.state),
        project: fixture.project,
        gameState: fixture.state,
        currentStateRevision: 1,
        mapActivationId: 'other',
        random: random);
    expect(result.reason, InteractiveEncounterBlockReason.staleAttempt);
    expect(random.doubleCalls, 0);
    expect(
        resolveEncounterSourceAtPosition(fixture.map,
                position: fixture.entity.pos,
                encounterKind: EncounterKind.headbutt)
            .status,
        EncounterSourceResolutionStatus.noSource);
  });
}

({
  MapData map,
  MapEntity entity,
  ProjectManifest project,
  GameState state,
  GameplayWorldState Function(GameState) world
}) encounterFixture() {
  final entity = MapEntity(
      id: 'tree',
      kind: MapEntityKind.custom,
      pos: const GridPos(x: 3, y: 2),
      interactiveEncounter: MapEntityInteractiveEncounterData(
          trigger: InteractiveEncounterTrigger.headbutt,
          encounterTableId: 'trees',
          reusePolicy: InteractiveEncounterReusePolicy.oncePerMapInstance));
  final map = MapData(
      id: 'route',
      name: 'Route',
      size: const GridSize(width: 8, height: 8),
      entities: [entity]);
  final project =
      ProjectManifest(name: 'Test', maps: [], tilesets: [], encounterTables: [
    const ProjectEncounterTable(
        id: 'trees',
        name: 'Trees',
        encounterKind: EncounterKind.headbutt,
        chancePerStep: 1,
        entries: [
          ProjectEncounterEntry(
              speciesId: 'test', minLevel: 2, maxLevel: 2, weight: 1)
        ])
  ]);
  final state = GameState(
      saveId: 'test',
      currentMapId: 'route',
      playerPosition: const GridPos(x: 2, y: 2),
      playerFacing: EntityFacing.east,
      repelState: RepelState.active(itemId: 'repel', steps: 8),
      party: const PlayerParty(members: [
        PlayerPokemon(
            individualId: 'partner',
            speciesId: 'test',
            natureId: 'hardy',
            abilityId: 'test',
            level: 30,
            currentHp: 10,
            knownMoveIds: ['headbutt'],
            currentPpByMoveId: {'headbutt': 0})
      ]),
      mapInstanceWorldState: MapInstanceWorldState(instancesByMapId: {
        'route': MapInstanceRuntimeState(instanceId: 'route-1')
      }));
  return (
    map: map,
    entity: entity,
    project: project,
    state: state,
    world: (current) => GameplayWorldState.initial(
        map: map,
        playerPos: current.playerPosition,
        playerFacing: current.playerFacing.asDirection,
        playerMovementMode: current.playerMovementMode)
  );
}

class CountingRandom implements Random {
  int doubleCalls = 0;
  @override
  double nextDouble() {
    doubleCalls++;
    return 0;
  }

  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
}

PixelOffset _pixel(GameplayWorldState world) => PixelOffset(
    x: world.player.playerPositionPx.leftPx,
    y: world.player.playerPositionPx.topPx);

Map<String, MapInstanceNpcPose> _npcPoses(Map<String, GridPos> positions) => {
  for (final entry in positions.entries)
    entry.key: MapInstanceNpcPose(position: entry.value, facing: EntityFacing.south),
};
