import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'support/moving_prop_fixture.dart';

void main() {
  for (final direction in Direction.values) {
    test(
        'a pushed boulder slides ${direction.name} without moving its pusher again',
        () {
      final fixture = _Fixture(direction: direction);
      final started = fixture.push();
      expect(started.slide, isNotNull);
      expect(started.gameState.playerPosition, _Fixture.origin);
      var state = started.gameState;
      var world = started.movement.world;
      var slide = started.slide;
      final visited = <GridPos>[];
      while (slide != null) {
        final result = stepFieldObstacleSlide(
          slide: slide,
          world: world,
          gameState: state,
        );
        if (result is! FieldObstacleSlideMoved) {
          expect(result, isA<FieldObstacleSlideStopped>());
          break;
        }
        expect(result.from, slide.expectedPosition);
        expect(result.to, _offset(result.from, direction));
        expect(result.gameState.playerPosition, _Fixture.origin);
        expect(result.world.player, world.player);
        visited.add(result.to);
        state = result.gameState;
        world = result.world;
        slide = result.slide;
      }
      expect(visited, isNotEmpty);
      expect(
          world.map.entities.single.pos,
          switch (direction) {
            Direction.east => const GridPos(x: 9, y: 4),
            Direction.west => const GridPos(x: 0, y: 4),
            Direction.south => const GridPos(x: 4, y: 9),
            Direction.north => const GridPos(x: 4, y: 0),
          });
      expect(
          state.mapInstanceWorldState
              .fieldObstaclePosition(started.slide!.instance, 'rock'),
          world.map.entities.single.pos);
    });
  }

  test(
      'normal ground remains one Strength step and exiting ice ends continuation',
      () {
    final normal = _Fixture(ice: false).push();
    expect(normal.slide, isNull);
    expect(normal.movement.world.map.entities.single.pos,
        const GridPos(x: 5, y: 4));
    final fixture = _Fixture(zones: [_ice(width: 2, x: 5)]);
    final started = fixture.push();
    final first = stepFieldObstacleSlide(
      slide: started.slide!,
      world: started.movement.world,
      gameState: started.gameState,
    ) as FieldObstacleSlideMoved;
    expect(first.to, const GridPos(x: 6, y: 4));
    expect(first.slide, isNotNull);
    final second = stepFieldObstacleSlide(
      slide: first.slide!,
      world: first.world,
      gameState: first.gameState,
    ) as FieldObstacleSlideMoved;
    expect(second.to, const GridPos(x: 7, y: 4));
    expect(second.slide, isNull);
  });

  for (final blocker in [
    'wall',
    'npc',
    'custom',
    'boulder',
    'water',
    'prop',
    'reservation'
  ]) {
    test('live $blocker stops a sliding boulder without a partial mutation',
        () {
      final fixture = _Fixture();
      final started = fixture.push();
      final target = const GridPos(x: 6, y: 4);
      var map = started.movement.world.map;
      if (blocker == 'wall') {
        map = map.copyWith(layers: [
          MapLayer.collision(
            id: 'wall',
            name: 'Wall',
            collisions: List.generate(100, (index) => index == 46),
          )
        ]);
      }
      if (['npc', 'custom', 'boulder'].contains(blocker)) {
        map = map.copyWith(entities: [
          ...map.entities,
          MapEntity(
            id: 'blocker',
            pos: target,
            properties:
                blocker == 'custom' ? const {'collision.width': '1'} : const {},
            kind: blocker == 'npc' ? MapEntityKind.npc : MapEntityKind.custom,
            npc: blocker == 'npc' ? const MapEntityNpcData() : null,
            fieldObstacle: blocker == 'boulder'
                ? const MapEntityFieldObstacleData(
                    kind: FieldObstacleKind.strengthBoulder)
                : null,
          ),
        ]);
      }
      if (blocker == 'water') {
        map = map.copyWith(gameplayZones: [
          ...map.gameplayZones,
          const MapGameplayZone(
            id: 'water',
            kind: GameplayZoneKind.movement,
            area: MapRect(
                pos: GridPos(x: 6, y: 4), size: GridSize(width: 1, height: 1)),
            movement: MovementZonePayload(requiredMode: MovementMode.surf),
          ),
        ]);
      }
      if (blocker == 'prop') {
        final props = MovingPropFixture(props: [
          MovingPropFixture.prop('gate', 192, 128, 192, 160),
        ]);
        map = map.copyWith(
            movingProps: props.map.movingProps,
            placedElements: props.map.placedElements,
            layers: props.map.layers);
      }
      final world = fixture.world(map, started.gameState);
      final before = started.gameState.toJson();
      final result = stepFieldObstacleSlide(
        slide: started.slide!,
        world: world,
        gameState: started.gameState,
        project: blocker == 'prop' ? MovingPropFixture().project : null,
        characterReservations: blocker == 'reservation'
            ? const [
                PixelRect(leftPx: 192, topPx: 129, widthPx: 1, heightPx: 1)
              ]
            : const [],
      );
      expect(result, isA<FieldObstacleSlideStopped>());
      expect((result as FieldObstacleSlideStopped).reason,
          FieldObstacleBlockReason.blockedDestination);
      expect(started.gameState.toJson(), before);
      expect(world.map.entities.first.pos, const GridPos(x: 5, y: 4));
    });
  }

  for (final blocked in [false, true]) {
    test(
        'live open props preserve their ${blocked ? 'occupied' : 'vacated'} collision throughout the slide',
        () {
      final fixture = _Fixture();
      final started = fixture.push();
      final props = MovingPropFixture(props: [
        MovingPropFixture.prop(
            'gate', 192, 128, blocked ? 224 : 192, blocked ? 128 : 160),
      ]);
      final map = started.movement.world.map.copyWith(
        movingProps: props.map.movingProps,
        placedElements: props.map.placedElements,
        layers: props.map.layers,
      );
      final state = started.gameState.copyWith(
          movingPropWorldState: started.gameState.movingPropWorldState.withProp(
              mapId: 'room', propId: 'gate', state: MovingPropState.open));
      final first = stepFieldObstacleSlide(
          slide: started.slide!,
          world: fixture.world(map, state),
          gameState: state,
          project: props.project) as FieldObstacleSlideMoved;
      expect(first.to, const GridPos(x: 6, y: 4));
      final second = stepFieldObstacleSlide(
          slide: first.slide!,
          world: first.world,
          gameState: first.gameState,
          project: props.project);
      if (blocked) {
        expect(second, isA<FieldObstacleSlideStopped>());
      } else {
        expect(second, isA<FieldObstacleSlideMoved>());
        expect(
            (second as FieldObstacleSlideMoved).to, const GridPos(x: 7, y: 4));
      }
    });
  }

  test(
      'a saved NPC on a vacated prop footprint blocks instead of invalidating the slide',
      () {
    final fixture = _Fixture();
    final started = fixture.push();
    final props = MovingPropFixture(props: [
      MovingPropFixture.prop('gate', 192, 128, 192, 160),
    ]);
    final map = started.movement.world.map.copyWith(
      movingProps: props.map.movingProps,
      placedElements: props.map.placedElements,
      layers: props.map.layers,
      entities: [
        ...started.movement.world.map.entities,
        const MapEntity(
          id: 'walker',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 6, y: 4),
          npc: MapEntityNpcData(),
        )
      ],
    );
    final state = started.gameState.copyWith(
      movingPropWorldState: started.gameState.movingPropWorldState
          .withProp(mapId: 'room', propId: 'gate', state: MovingPropState.open),
      mapInstanceWorldState: started.gameState.mapInstanceWorldState
          .setNpcPoses(started.slide!.instance, {
        'walker': MapInstanceNpcPose(
            position: const GridPos(x: 6, y: 4), facing: EntityFacing.south)
      }),
    );
    expect(
        stepFieldObstacleSlide(
            slide: started.slide!,
            world: fixture.world(map, state),
            gameState: state,
            project: props.project),
        isA<FieldObstacleSlideStopped>());
  });

  for (final invalid in [
    'instance',
    'position',
    'missing',
    'cleared',
    'savedPosition',
    'direction',
    'budget',
    'player'
  ]) {
    test('refuses $invalid continuation instead of reviving stale inertia', () {
      final fixture = _Fixture();
      final started = fixture.push();
      var state = started.gameState;
      var map = started.movement.world.map;
      final source = started.slide!;
      final slide = FieldObstacleSlide(
        instance: invalid == 'instance'
            ? MapInstanceRef(mapId: 'room', instanceId: 'replaced')
            : source.instance,
        entityId: source.entityId,
        direction: invalid == 'direction' ? Direction.west : source.direction,
        expectedPosition: invalid == 'position'
            ? const GridPos(x: 4, y: 4)
            : source.expectedPosition,
        remainingSteps: invalid == 'budget' ? 100 : source.remainingSteps,
      );
      if (invalid == 'missing') {
        map = map.copyWith(entities: []);
      }
      if (invalid == 'cleared') {
        state = state.copyWith(
            mapInstanceWorldState: state.mapInstanceWorldState
                .clearFieldObstacle(source.instance, 'rock'));
      }
      if (invalid == 'savedPosition') {
        state = state.copyWith(
            mapInstanceWorldState: state.mapInstanceWorldState
                .moveFieldObstacle(
                    source.instance, 'rock', const GridPos(x: 8, y: 4)));
      }
      final world = fixture.world(map, started.gameState);
      if (invalid == 'player') {
        state = state.copyWith(playerPosition: const GridPos(x: 1, y: 1));
      }
      expect(
          stepFieldObstacleSlide(slide: slide, world: world, gameState: state),
          isA<FieldObstacleSlideRefused>());
    });
  }

  test(
      'a final block position survives strict save and resets with a new instance',
      () {
    final fixture = _Fixture(zones: [_ice(width: 2, x: 5)]);
    final started = fixture.push();
    var state = started.gameState;
    var world = started.movement.world;
    var slide = started.slide;
    while (slide != null) {
      final moved =
          stepFieldObstacleSlide(slide: slide, world: world, gameState: state)
              as FieldObstacleSlideMoved;
      state = moved.gameState;
      world = moved.world;
      slide = moved.slide;
    }
    final restored =
        gameStateFromStrictSaveJson(strictGameStateSaveJson(state));
    final projected = applyFieldObstacleWorldStateToMap(
        map: fixture.map,
        instances: restored.mapInstanceWorldState,
        instance: restored.mapInstanceWorldState.instanceRef('room')!);
    expect(projected.entities.single.pos, const GridPos(x: 7, y: 4));
    final reset = setupDifferentMapInstance(
        state: restored.mapInstanceWorldState,
        targetMapId: 'room',
        allocateId: (_) => 'room-2');
    expect(
        applyFieldObstacleWorldStateToMap(
            map: fixture.map,
            instances: reset,
            instance: reset.instanceRef('room')!),
        fixture.map);
  });

  test('continuation uses the same winning valid slide zone as player movement',
      () {
    for (final zones in [
      [
        _ice(),
        _ice(id: 'mud', priority: 2).copyWith(
            movementEffect: const MovementEffectZonePayload(
                effectKind: MovementEffectZoneKind.movementCost))
      ],
      [
        _ice().copyWith(cellMask: const [GridPos(x: 1, y: 1)])
      ],
      [
        _ice().copyWith(
            movementEffect: const MovementEffectZonePayload(movementCost: 0))
      ],
    ]) {
      expect(_Fixture(zones: zones).push().slide, isNull);
    }
    final map = _Fixture(zones: [_ice(id: 'first'), _ice(id: 'last')]).map;
    expect(
        resolveGameplaySlideEffectAt(
                map, const GridPos(x: 5, y: 4), Direction.east)!
            .zoneId,
        'last');
  });

  test('a bounded long corridor makes strict progress and cannot loop', () {
    final fixture = _Fixture(width: 2048);
    final started = fixture.push();
    var world = started.movement.world;
    var state = started.gameState;
    var slide = started.slide;
    var steps = 0;
    while (slide != null) {
      final result =
          stepFieldObstacleSlide(slide: slide, world: world, gameState: state);
      if (result is FieldObstacleSlideStopped) break;
      final moved = result as FieldObstacleSlideMoved;
      expect(moved.to.x, slide.expectedPosition.x + 1);
      if (moved.slide != null) {
        expect(moved.slide!.remainingSteps, lessThan(slide.remainingSteps));
      }
      world = moved.world;
      state = moved.gameState;
      slide = moved.slide;
      steps++;
      expect(steps, lessThan(2048));
    }
    expect(world.map.entities.single.pos, const GridPos(x: 2047, y: 4));
  });
}

MapGameplayZone _ice(
        {String id = 'ice', int priority = 1, int x = 0, int width = 2048}) =>
    MapGameplayZone(
      id: id,
      kind: GameplayZoneKind.movementEffect,
      priority: priority,
      area: MapRect(
          pos: GridPos(x: x, y: 0), size: GridSize(width: width, height: 10)),
      movementEffect: const MovementEffectZonePayload(
          effectKind: MovementEffectZoneKind.slide),
    );

GridPos _offset(GridPos value, Direction direction, [int amount = 1]) =>
    GridPos(
        x: value.x + direction.dx * amount, y: value.y + direction.dy * amount);

final class _Fixture {
  _Fixture(
      {this.direction = Direction.east,
      bool ice = true,
      List<MapGameplayZone>? zones,
      int width = 10}) {
    map = MapData(
        id: 'room',
        name: 'Room',
        size: GridSize(width: width, height: 10),
        entities: const [
          MapEntity(
              id: 'rock',
              kind: MapEntityKind.custom,
              pos: origin,
              fieldObstacle: MapEntityFieldObstacleData(
                  kind: FieldObstacleKind.strengthBoulder))
        ],
        gameplayZones: zones ?? (ice ? [_ice(width: width)] : []));
    state = GameState(
        saveId: 'ice',
        currentMapId: 'room',
        playerPosition: _offset(origin, direction, -1),
        playerFacing: direction.asFacing,
        party: PlayerParty(members: [
          PlayerPokemon(
              speciesId: 'machop',
              natureId: 'hardy',
              abilityId: 'guts',
              level: 20,
              currentHp: 30,
              knownMoveIds: const ['strength'],
              currentPpByMoveId: const {'strength': 0})
        ]),
        progression: const PlayerProgression(
            unlockedFieldAbilities: [FieldAbility.strength]),
        mapInstanceWorldState: MapInstanceWorldState(instancesByMapId: {
          'room': MapInstanceRuntimeState(
              instanceId: 'room-1', strengthActive: true),
        }));
  }
  static const origin = GridPos(x: 4, y: 4);
  final Direction direction;
  late final MapData map;
  late final GameState state;

  GameplayWorldState world(MapData map, GameState state) {
    final result = GameplayWorldState.initial(
      map: map,
      playerPos: state.playerPosition,
      playerFacing: direction,
      tileWidth: 32,
      tileHeight: 32,
      project: map.movingProps.isEmpty ? null : MovingPropFixture().project,
      gameState: state,
    );
    return result.withPlayer(result.player.copyWith(
        playerPositionPx: state.playerPixelPosition == null
            ? null
            : PixelPosition(
                leftPx: state.playerPixelPosition!.x,
                topPx: state.playerPixelPosition!.y)));
  }

  StrengthPushApplied push() => commitStrengthPush(
        ticket: FieldObstacleTicket(
            fieldAction: const FieldActionTicket(
                ability: FieldAbility.strength,
                targetCell: origin,
                issuedAtStateRevision: 4),
            instance: state.mapInstanceWorldState.instanceRef('room')!,
            entityId: 'rock',
            playerPosition: state.playerPosition,
            playerFacing: state.playerFacing),
        world: world(map, state),
        gameState: state,
        currentStateRevision: 4,
      ) as StrengthPushApplied;
}
