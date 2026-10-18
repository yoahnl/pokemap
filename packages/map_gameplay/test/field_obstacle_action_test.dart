import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'support/moving_platform_fixture.dart';

MapData obstacleMap(FieldObstacleKind kind) => MapData(
      id: 'route',
      name: 'Route',
      size: const GridSize(width: 6, height: 4),
      entities: [
        MapEntity(
            id: 'rock',
            kind: MapEntityKind.custom,
            pos: const GridPos(x: 2, y: 1),
            fieldObstacle: MapEntityFieldObstacleData(kind: kind))
      ],
    );
GameState ready(FieldAbility ability) => GameState(
      saveId: 'obstacles',
      currentMapId: 'route',
      playerPosition: const GridPos(x: 1, y: 1),
      playerFacing: EntityFacing.east,
      party: PlayerParty(members: [
        PlayerPokemon(
            speciesId: 'machop',
            natureId: 'hardy',
            abilityId: 'guts',
            level: 20,
            currentHp: 30,
            knownMoveIds: [ability.moveId],
            currentPpByMoveId: {ability.moveId: 0})
      ]),
      progression: PlayerProgression(unlockedFieldAbilities: [ability]),
      mapInstanceWorldState: MapInstanceWorldState(instancesByMapId: {
        'route': MapInstanceRuntimeState(instanceId: 'route-1'),
      }),
    );
FieldObstacleTicket ticket(GameState state, FieldAbility ability) =>
    FieldObstacleTicket(
      fieldAction: FieldActionTicket(
          ability: ability,
          targetCell: const GridPos(x: 2, y: 1),
          issuedAtStateRevision: 4),
      instance: state.mapInstanceWorldState.instanceRef('route')!,
      entityId: 'rock',
      playerPosition: state.playerPosition,
      playerPixelPosition: state.playerPixelPosition,
      playerFacing: state.playerFacing,
    );
GameplayWorldState world(MapData map, GameState state) =>
    GameplayWorldState.initial(
      map: map,
      playerPos: state.playerPosition,
      playerFacing: Direction.east,
    );
void main() {
  for (final invalid in [
    'missing',
    'wrongKind',
    'bounds',
    'rockOverlap',
    'npcOverlap'
  ]) {
    test('saved NPC positions reject $invalid before composing the map', () {
      final map =
          obstacleMap(FieldObstacleKind.strengthBoulder).copyWith(entities: [
        ...obstacleMap(FieldObstacleKind.strengthBoulder).entities,
        const MapEntity(
            id: 'walker',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 3, y: 1),
            npc: MapEntityNpcData(displayName: 'Walker')),
        const MapEntity(
            id: 'other',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 4, y: 1),
            npc: MapEntityNpcData(displayName: 'Other')),
      ]);
      var state = ready(FieldAbility.strength).mapInstanceWorldState;
      final scope = state.instanceRef('route')!;
      state = state
          .moveFieldObstacle(scope, 'rock', const GridPos(x: 3, y: 1))
          .setNpcPoses(scope, _npcPoses({
        invalid == 'missing'
            ? 'ghost'
            : invalid == 'wrongKind'
                ? 'rock'
                : 'walker': GridPos(
            x: invalid == 'bounds'
                ? 6
                : invalid == 'rockOverlap'
                    ? 3
                    : 4,
            y: invalid == 'rockOverlap' ? 1 : 2),
        if (invalid == 'npcOverlap') 'other': const GridPos(x: 4, y: 2),
      }));
      expect(
          () => applyFieldObstacleWorldStateToMap(
              map: map, instances: state, instance: scope),
          throwsStateError);
    });
  }
  test(
      'NPC positions restore before boulder collision and reset with the same instance policy',
      () {
    final authored =
        obstacleMap(FieldObstacleKind.strengthBoulder).copyWith(entities: [
      ...obstacleMap(FieldObstacleKind.strengthBoulder).entities,
      const MapEntity(
          id: 'walker',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 3, y: 1),
          npc: MapEntityNpcData(displayName: 'Walker')),
    ]);
    var state = ready(FieldAbility.strength).mapInstanceWorldState;
    final scope = state.instanceRef('route')!;
    state = state
        .setNpcPoses(scope, _npcPoses(const {'walker': GridPos(x: 4, y: 2)}))
        .activateStrength(scope)
        .moveFieldObstacle(scope, 'rock', const GridPos(x: 3, y: 1));
    final restored = MapInstanceWorldState.fromJson(state.toJson());
    final map = applyFieldObstacleWorldStateToMap(
        map: authored, instances: restored, instance: scope);
    expect(map.entities.first.pos, const GridPos(x: 3, y: 1));
    expect(map.entities.last.pos, const GridPos(x: 4, y: 2));
    final reset = setupDifferentMapInstance(
        state: restored, targetMapId: 'route', allocateId: (_) => 'route-2');
    expect(
        applyFieldObstacleWorldStateToMap(
            map: authored,
            instances: reset,
            instance: reset.instanceRef('route')!),
        authored);
  });

  test(
      'a push onto moved platform support reprojects and restores its exact composed state',
      () {
    final fixture = MovingPlatformFixture();
    final map = fixture.map.copyWith(layers: [
      MovingPlatformFixture.terrain('magma', blockedIndex: 23)
    ], entities: const [
      MapEntity(
          id: 'rock',
          kind: MapEntityKind.custom,
          pos: GridPos(x: 4, y: 2),
          fieldObstacle: MapEntityFieldObstacleData(
              kind: FieldObstacleKind.strengthBoulder)),
    ]);
    final platform = fixture.state.withPlatform(
        mapId: 'gym',
        platformId: 'bridge',
        pose: MovingPlatformPose(leftPx: 96, topPx: 64, quarterTurns: 0));
    final instances = MapInstanceWorldState(instancesByMapId: {
      'gym': MapInstanceRuntimeState(instanceId: 'gym-1', strengthActive: true)
    });
    final state = ready(FieldAbility.strength).copyWith(
        currentMapId: 'gym',
        playerPosition: const GridPos(x: 5, y: 2),
        playerFacing: EntityFacing.west,
        mapInstanceWorldState: instances,
        movingPlatformWorldState: platform);
    final scope = instances.instanceRef('gym')!;
    final action = FieldObstacleTicket(
        fieldAction: const FieldActionTicket(
            ability: FieldAbility.strength,
            targetCell: GridPos(x: 4, y: 2),
            issuedAtStateRevision: 4),
        instance: scope,
        entityId: 'rock',
        playerPosition: state.playerPosition,
        playerFacing: state.playerFacing);
    final current =
        fixture.world(map: map, state: platform, player: state.playerPosition);
    final result = commitStrengthPush(
        ticket: action,
        world:
            current.withPlayer(current.player.copyWith(facing: Direction.west)),
        gameState: state,
        currentStateRevision: 4,
        authoringMap: map,
        project: fixture.project) as StrengthPushApplied;
    final restored = GameState.fromJson(result.gameState.toJson());
    final projected = applyFieldObstacleWorldStateToMap(
        map: result.movement.world.map,
        authoringMap: map,
        instances: restored.mapInstanceWorldState,
        instance: scope,
        project: fixture.project,
        movingPlatformWorldState: restored.movingPlatformWorldState);
    expect(projected.entities.single.pos, const GridPos(x: 3, y: 2));
    expect(
        applyFieldObstacleWorldStateToMap(
            map: projected,
            authoringMap: map,
            instances: restored.mapInstanceWorldState,
            instance: scope,
            project: fixture.project,
            movingPlatformWorldState: restored.movingPlatformWorldState),
        projected);
    expect(map.entities.single.pos, const GridPos(x: 4, y: 2));
  });

  test(
      'Strength refuses an absent world-rule target instead of moving the hidden entity',
      () {
    final map = obstacleMap(FieldObstacleKind.strengthBoulder);
    var state = ready(FieldAbility.strength);
    state = state.copyWith(
        mapInstanceWorldState: state.mapInstanceWorldState.activateStrength(
            state.mapInstanceWorldState.instanceRef('route')!));
    final hidden = GameplayWorldState.initial(
        map: map,
        playerPos: state.playerPosition,
        playerFacing: Direction.east,
        mapEntityPresencePredicate: (_, entity) => entity.id != 'rock');
    expect(stepGameplayWorld(hidden, const MoveIntent(Direction.east)),
        isA<Moved>());
    expect(
        commitStrengthPush(
            ticket: ticket(state, FieldAbility.strength),
            world: hidden,
            gameState: state,
            currentStateRevision: 4),
        isA<FieldObstacleRefused>());
  });

  test('Strength commit refuses corruption in another saved obstacle', () {
    final map = obstacleMap(FieldObstacleKind.strengthBoulder);
    var state = ready(FieldAbility.strength);
    final scope = state.mapInstanceWorldState.instanceRef('route')!;
    state = state.copyWith(
        mapInstanceWorldState: state.mapInstanceWorldState
            .activateStrength(scope)
            .moveFieldObstacle(scope, 'ghost', const GridPos(x: 4, y: 1)));
    expect(
        commitStrengthPush(
            ticket: ticket(state, FieldAbility.strength),
            world: world(map, state),
            gameState: state,
            currentStateRevision: 4),
        isA<FieldObstacleRefused>());
  });

  test(
      'repeated projection uses the complete authored obstacle set while retaining live NPCs',
      () {
    final authored =
        obstacleMap(FieldObstacleKind.rockSmashRock).copyWith(entities: [
      ...obstacleMap(FieldObstacleKind.rockSmashRock).entities,
      const MapEntity(
          id: 'tree',
          kind: MapEntityKind.custom,
          pos: GridPos(x: 4, y: 1),
          fieldObstacle: MapEntityFieldObstacleData()),
      const MapEntity(
          id: 'npc',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 0, y: 2),
          npc: MapEntityNpcData(displayName: 'Walker')),
    ]);
    var state = ready(FieldAbility.rockSmash).mapInstanceWorldState;
    final scope = state.instanceRef('route')!;
    state = state.clearFieldObstacle(scope, 'tree');
    final first = applyFieldObstacleWorldStateToMap(
        map: authored, instances: state, instance: scope);
    final movedNpc = first.copyWith(
        entities: first.entities
            .map((entity) => entity.id == 'npc'
                ? entity.copyWith(pos: const GridPos(x: 1, y: 2))
                : entity)
            .toList());
    state = state
        .clearFieldObstacle(scope, 'rock')
        .setNpcPoses(scope, _npcPoses(const {'npc': GridPos(x: 1, y: 2)}));
    final second = applyFieldObstacleWorldStateToMap(
        map: movedNpc,
        authoringMap: authored,
        instances: state,
        instance: scope);
    expect(second.entities.map((entity) => entity.id), ['npc']);
    expect(second.entities.single.pos, const GridPos(x: 1, y: 2));
    expect(
        applyFieldObstacleWorldStateToMap(
            map: second,
            authoringMap: authored,
            instances: state,
            instance: scope),
        second);
    expect(authored.entities, hasLength(3));
    expect(
        () => applyFieldObstacleWorldStateToMap(
            map: authored,
            instances: state.clearFieldObstacle(scope, 'missing'),
            instance: scope),
        throwsStateError);
    expect(
        () => applyFieldObstacleWorldStateToMap(
            map: authored,
            instances: state.clearFieldObstacle(scope, 'npc'),
            instance: scope),
        throwsStateError);
  });

  test('Rock Smash revalidates and clears a native rock without spending PP',
      () {
    final map = obstacleMap(FieldObstacleKind.rockSmashRock),
        state = ready(FieldAbility.rockSmash);
    expect(
        evaluateFieldObstacleAttempt(
            map: map, gameState: state, entityId: 'rock'),
        isA<CanUseFieldObstacle>());
    final result = commitDestructibleFieldObstacleAction(
        ticket: ticket(state, FieldAbility.rockSmash),
        map: map,
        gameState: state,
        currentStateRevision: 4,
        confirmedEntityId: 'rock') as FieldObstacleApplied;
    expect(result.gameState.party, state.party);
    expect(
        applyFieldObstacleWorldStateToMap(
                map: map,
                instances: result.gameState.mapInstanceWorldState,
                instance: ticket(state, FieldAbility.rockSmash).instance)
            .entities,
        isEmpty);
  });
  test('Strength activates once and commits player and boulder together', () {
    final map = obstacleMap(FieldObstacleKind.strengthBoulder),
        state = ready(FieldAbility.strength);
    final activated = commitStrengthActivation(
        ticket: ticket(state, FieldAbility.strength),
        map: map,
        gameState: state,
        currentStateRevision: 4,
        confirmedEntityId: 'rock') as FieldObstacleApplied;
    final result = commitStrengthPush(
        ticket: ticket(activated.gameState, FieldAbility.strength),
        world: world(map, state),
        gameState: activated.gameState,
        currentStateRevision: 4) as StrengthPushApplied;
    expect(result.gameState.playerPosition, const GridPos(x: 2, y: 1));
    expect(result.movement.world.player.pos, result.gameState.playerPosition);
    expect(result.movement.world.map.entities.single.pos,
        const GridPos(x: 3, y: 1));
    expect(
        result.gameState.mapInstanceWorldState.fieldObstaclePosition(
            ticket(state, FieldAbility.strength).instance, 'rock'),
        const GridPos(x: 3, y: 1));
    expect(result.gameState.party, state.party);
    expect(map.entities.single.pos, const GridPos(x: 2, y: 1));
  });
  for (final mode in [
    'wall',
    'npc',
    'object',
    'reservation',
    'water',
    'edge',
    'notActive',
    'fainted',
    'locked',
    'stale'
  ]) {
    test('Strength refuses $mode with no partial mutation', () {
      var map = obstacleMap(FieldObstacleKind.strengthBoulder);
      var state = ready(FieldAbility.strength);
      final scope = state.mapInstanceWorldState.instanceRef('route')!;
      if (mode != 'notActive') {
        state = state.copyWith(
            mapInstanceWorldState:
                state.mapInstanceWorldState.activateStrength(scope));
      }
      if (mode == 'wall') {
        map = map.copyWith(layers: [
          MapLayer.collision(
              id: 'wall',
              name: 'Wall',
              collisions: List.generate(24, (index) => index == 9))
        ]);
      }
      if (mode == 'npc' || mode == 'object') {
        map = map.copyWith(entities: [
          ...map.entities,
          MapEntity(
              id: 'blocker',
              properties: const {'collision.width': '1'},
              kind: mode == 'npc' ? MapEntityKind.npc : MapEntityKind.custom,
              pos: const GridPos(x: 3, y: 1),
              npc: mode == 'npc'
                  ? const MapEntityNpcData(displayName: 'Blocker')
                  : null)
        ]);
      }
      if (mode == 'water') {
        map = map.copyWith(gameplayZones: const [
          MapGameplayZone(
              id: 'water',
              kind: GameplayZoneKind.movement,
              area: MapRect(
                  pos: GridPos(x: 3, y: 1),
                  size: GridSize(width: 1, height: 1)),
              movement: MovementZonePayload(requiredMode: MovementMode.surf))
        ]);
      }
      if (mode == 'edge') {
        map = map.copyWith(size: const GridSize(width: 3, height: 4));
      }
      if (mode == 'fainted') {
        state = state.copyWith(
            party: PlayerParty(
                members: [state.party.members.single.copyWith(currentHp: 0)]));
      }
      if (mode == 'locked') {
        state = state.copyWith(progression: const PlayerProgression());
      }
      final before = state.toJson();
      final result = commitStrengthPush(
          ticket: ticket(state, FieldAbility.strength),
          world: world(map, state),
          gameState: state,
          currentStateRevision: mode == 'stale' ? 5 : 4,
          characterReservations: mode == 'reservation'
              ? const [
                  PixelRect(leftPx: 48, topPx: 16, widthPx: 16, heightPx: 16)
                ]
              : const []);
      expect(result, isA<FieldObstacleRefused>());
      expect(state.toJson(), before);
      expect(map.entities.first.pos, const GridPos(x: 2, y: 1));
    });
  }
  for (final mode in [
    'stale',
    'turned',
    'moved',
    'fainted',
    'locked',
    'wrongTarget'
  ]) {
    test('Strength activation revalidates $mode', () {
      final original = ready(FieldAbility.strength);
      var state = original;
      if (mode == 'turned') {
        state = state.copyWith(playerFacing: EntityFacing.north);
      }
      if (mode == 'moved') {
        state = state.copyWith(playerPosition: const GridPos(x: 0, y: 1));
      }
      if (mode == 'fainted') {
        state = state.copyWith(party: const PlayerParty());
      }
      if (mode == 'locked') {
        state = state.copyWith(progression: const PlayerProgression());
      }
      expect(
          commitStrengthActivation(
              ticket: ticket(original, FieldAbility.strength),
              map: obstacleMap(FieldObstacleKind.strengthBoulder),
              gameState: state,
              currentStateRevision: mode == 'stale' ? 5 : 4,
              confirmedEntityId: mode == 'wrongTarget' ? 'other' : 'rock'),
          isA<FieldObstacleRefused>());
      expect(
          state.mapInstanceWorldState.isStrengthActive(
              ticket(original, FieldAbility.strength).instance),
          isFalse);
    });
  }
  for (final mode in [
    'missing',
    'wrongKind',
    'overlap',
    'outOfBounds',
    'water',
    'wall'
  ]) {
    test('saved boulder projection rejects corrupt $mode position', () {
      var map = obstacleMap(FieldObstacleKind.strengthBoulder);
      if (mode == 'missing') {
        map = map.copyWith(entities: []);
      }
      if (mode == 'wrongKind') {
        map = obstacleMap(FieldObstacleKind.cutTree);
      }
      if (mode == 'overlap') {
        map = map.copyWith(entities: [
          ...map.entities,
          const MapEntity(
              id: 'blocker',
              properties: {'collision.width': '1'},
              kind: MapEntityKind.custom,
              pos: GridPos(x: 3, y: 1))
        ]);
      }
      if (mode == 'water') {
        map = map.copyWith(gameplayZones: const [
          MapGameplayZone(
              id: 'water',
              kind: GameplayZoneKind.movement,
              area: MapRect(
                  pos: GridPos(x: 3, y: 1),
                  size: GridSize(width: 1, height: 1)),
              movement: MovementZonePayload(requiredMode: MovementMode.surf))
        ]);
      }
      if (mode == 'wall') {
        map = map.copyWith(layers: [
          MapLayer.collision(
              id: 'wall',
              name: 'Wall',
              collisions: List.generate(24, (index) => index == 9))
        ]);
      }
      final state = ready(FieldAbility.strength).mapInstanceWorldState;
      final scope = state.instanceRef('route')!;
      final changed = state.moveFieldObstacle(
          scope, 'rock', GridPos(x: mode == 'outOfBounds' ? 6 : 3, y: 1));
      expect(
          () => applyFieldObstacleWorldStateToMap(
              map: map, instances: changed, instance: scope),
          throwsStateError);
    });
  }
  test(
      'activation, positions, cleared obstacles and booleans survive all setters and save',
      () {
    var state = ready(FieldAbility.strength).mapInstanceWorldState;
    final scope = state.instanceRef('route')!;
    state = state
        .activateStrength(scope)
        .moveFieldObstacle(scope, 'rock', const GridPos(x: 3, y: 1))
        .clearFieldObstacle(scope, 'tree')
        .setEventBoolean(scope, 'door', 'A', true);
    final restored = MapInstanceWorldState.fromJson(state.toJson());
    expect(restored, state);
    expect(restored.isStrengthActive(scope), isTrue);
    expect(restored.fieldObstaclePosition(scope, 'rock'),
        const GridPos(x: 3, y: 1));
    expect(restored.isFieldObstacleCleared(scope, 'tree'), isTrue);
    expect(restored.eventBoolean(scope, 'door', 'A'), isTrue);
    final reset = setupDifferentMapInstance(
        state: restored, targetMapId: 'route', allocateId: (_) => 'route-2');
    expect(reset.isStrengthActive(reset.instanceRef('route')!), isFalse);
    expect(reset.fieldObstaclePosition(reset.instanceRef('route')!, 'rock'),
        isNull);
  });
}

Map<String, MapInstanceNpcPose> _npcPoses(Map<String, GridPos> positions) => {
  for (final entry in positions.entries)
    entry.key: MapInstanceNpcPose(position: entry.value, facing: EntityFacing.south),
};
