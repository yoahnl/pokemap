import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_gameplay/src/gameplay_world_state.dart';
import 'package:test/test.dart';

import 'support/moving_prop_fixture.dart';
import 'support/moving_platform_fixture.dart';

void main() {
  test('saved props and platforms validate their combined settled poses', () {
    final f = MovingPlatformFixture();
    final map = f.map.copyWith(
      layers: [
        MapLayer.tile(id: 'magma', name: 'Art', cells: List.filled(100, 0))
      ],
      movingProps: [
        MovingPropDefinition(
            id: 'gate',
            placedElementId: 'gate-art',
            closedPositionPx: const PixelOffset(x: 96, y: 64),
            openPositionPx: const PixelOffset(x: 160, y: 64),
            collisionRect:
                const PixelRect(leftPx: 0, topPx: 0, widthPx: 32, heightPx: 32))
      ],
      placedElements: [
        ...f.map.placedElements,
        const MapPlacedElement(
            id: 'gate-art',
            layerId: 'magma',
            elementId: 'platform-0',
            pos: GridPos(x: 3, y: 2),
            applyCollision: false,
            properties: {
              pokemapPlacementOriginProperty: pokemapPlacementOriginAuthored,
            })
      ],
    );
    final platforms = f.state.withPlatform(
        mapId: map.id,
        platformId: 'bridge',
        pose: MovingPlatformPose(leftPx: 96, topPx: 64, quarterTurns: 0));
    final props = const MovingPropWorldState.empty()
        .withProp(mapId: map.id, propId: 'gate', state: MovingPropState.open);
    validateGameplayMovingPlatformWorldState(
        project: f.project,
        maps: [map],
        worldState: platforms,
        movingPropWorldState: props);
    validateGameplayMovingPropWorldState(
        project: f.project,
        maps: [map],
        worldState: props,
        movingPlatformWorldState: platforms);
  });

  test('prop frames retain conditional entity pages and collision storage', () {
    final f = MovingPropFixture(entities: [
      MapEntity(
          id: 'owner',
          kind: MapEntityKind.custom,
          pos: const GridPos(x: 3, y: 2),
          presentation: MapEntityPresentation(variants: [
            MapEntityPresentationVariant(
                id: 'visible',
                blocksMovement: true,
                condition: NarrativeEventConditionExpression.not(
                    NarrativeEventConditionExpression.leaf(
                        NarrativeEventCondition.fact('changed', true)))),
          ])),
    ]);
    final project = f.project.copyWith(facts: [
      NarrativeFactDefinition(id: 'changed', label: 'Changed'),
    ]);
    final world = GameplayWorldState.initial(
        map: f.map,
        project: project,
        playerPos: const GridPos(x: 0, y: 0),
        tileWidth: 32,
        tileHeight: 32,
        gameState: const GameState(saveId: 'save'));
    expect(world.entityAt(3, 2)?.id, 'owner');
    final next = world.withMovingPropState(
        project: project, worldState: const MovingPropWorldState.empty());
    expect(next.entityAt(3, 2)?.id, 'owner');
    expect(next.debugStaticCollisionStorageToken,
        same(world.debugStaticCollisionStorageToken));
    expect(
        moveGameplayProps(
                world: world,
                project: project,
                worldState: const MovingPropWorldState.empty(),
                propIds: ['gate'],
                state: MovingPropState.open)
            .outcome,
        MovingPropMoveOutcome.blocked);
    final overlapping = f.map.copyWith(entities: [
      f.map.entities.single.copyWith(pos: const GridPos(x: 2, y: 2)),
    ]);
    expect(
        () => validateGameplayMovingPropWorldState(
            project: project,
            maps: [overlapping],
            worldState: const MovingPropWorldState.empty(),
            gameState: const GameState(saveId: 'save')),
        throwsFormatException);
  });

  MovingPropMoveResult move(MovingPropFixture f,
          {List<String> ids = const ['gate'],
          MovingPropState target = MovingPropState.open,
          GameplayWorldState? world,
          MovingPropWorldState state = const MovingPropWorldState.empty()}) =>
      moveGameplayProps(
          world: world ?? f.world(state: state),
          project: f.project,
          worldState: state,
          propIds: ids,
          state: target);

  test('moves an autonomous prop without moving the player', () {
    final f = MovingPropFixture();
    final result = move(f);
    expect(result.outcome, MovingPropMoveOutcome.moved);
    expect(result.frames.length, 64);
    expect(
        result.frames.last.positions['gate'], const PixelOffset(x: 128, y: 64));
    expect(result.finalWorldState.prop('room', 'gate'), MovingPropState.open);
    final next = f.world().withMovingPropState(
        project: f.project, worldState: result.finalWorldState);
    expect(next.player.playerPositionPx.leftPx,
        f.world().player.playerPositionPx.leftPx);
    expect(
        next.worldStaticObstaclesCollidePixelRect(
            const PixelRect(leftPx: 65, topPx: 65, widthPx: 1, heightPx: 1)),
        isFalse);
    expect(next.isBlocked(4, 2), isTrue);
    expect(next.withPlayer(next.player).isBlocked(4, 2), isTrue);
    expect(next.withMapEntityPresencePredicate((_, __) => true).isBlocked(4, 2),
        isTrue);
    expect(
        next
            .withMovingPlatformState(
                project: f.project,
                worldState: const MovingPlatformWorldState.empty())
            .isBlocked(4, 2),
        isTrue);
  });

  test('group shares normalized time and commits all states together', () {
    final f = MovingPropFixture(props: [
      MovingPropFixture.prop('a', 64, 64, 128, 64),
      MovingPropFixture.prop('b', 64, 128, 96, 128),
    ]);
    final result = move(f, ids: ['a', 'b']);
    expect(result.outcome, MovingPropMoveOutcome.moved);
    expect(result.frames[31].positions, {
      'a': const PixelOffset(x: 96, y: 64),
      'b': const PixelOffset(x: 80, y: 128),
    });
    expect(result.finalWorldState.propsByMap['room']!.values,
        everyElement(MovingPropState.open));
    expect(() => result.frames.first.positions.clear(), throwsUnsupportedError);
    final closed = move(f,
        ids: ['a', 'b'],
        state: result.finalWorldState,
        target: MovingPropState.closed);
    expect(closed.outcome, MovingPropMoveOutcome.moved);
    expect(closed.finalWorldState.propsByMap['room']!.values,
        everyElement(MovingPropState.closed));
  });

  test('blocks at a wall along the path and returns every group member', () {
    final f = MovingPropFixture(walls: {
      23
    }, props: [
      MovingPropFixture.prop('a', 32, 64, 160, 64),
      MovingPropFixture.prop('b', 32, 128, 160, 128),
    ]);
    final result = move(f, ids: ['a', 'b']);
    expect(result.outcome, MovingPropMoveOutcome.blocked);
    expect(result.finalWorldState.propsByMap['room']!.values,
        everyElement(MovingPropState.closed));
    expect(result.frames.any((frame) => frame.returning), isTrue);
    expect(result.frames.last.positions['a'], const PixelOffset(x: 32, y: 64));
    expect(result.frames.last.positions['b'], const PixelOffset(x: 32, y: 128));
  });

  test('player occupancy and blocking NPC reject the path', () {
    final f = MovingPropFixture();
    expect(move(f, world: f.world(player: const GridPos(x: 3, y: 2))).outcome,
        MovingPropMoveOutcome.blocked);
    final npc = MovingPropFixture(entities: const [
      MapEntity(
          id: 'npc',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 3, y: 2),
          blocksMovement: true),
    ]);
    expect(move(npc).outcome, MovingPropMoveOutcome.blocked);
    expect(
        move(npc,
            world: npc
                .world()
                .withNpcMapPresencePredicate((_, __) => false)).outcome,
        MovingPropMoveOutcome.moved);
  });

  test('stationary props block a moving prop', () {
    final f = MovingPropFixture(props: [
      MovingPropFixture.prop('a', 64, 64, 160, 64),
      MovingPropFixture.prop('b', 128, 64, 192, 64),
    ]);
    expect(move(f, ids: ['a']).outcome, MovingPropMoveOutcome.blocked);
  });

  test('crossing group members cannot pass through each other', () {
    final f = MovingPropFixture(props: [
      MovingPropFixture.prop('a', 64, 64, 65, 64, width: 1, height: 1),
      MovingPropFixture.prop('b', 65, 64, 64, 64, width: 1, height: 1),
    ]);
    expect(move(f, ids: ['a', 'b']).outcome, MovingPropMoveOutcome.blocked);
  });

  test('adjacent props can travel in the same direction together', () {
    final f = MovingPropFixture(props: [
      MovingPropFixture.prop('a', 64, 64, 128, 64),
      MovingPropFixture.prop('b', 96, 64, 160, 64),
    ]);
    expect(move(f, ids: ['a', 'b']).outcome, MovingPropMoveOutcome.moved);
  });

  test('requesting the current state is idempotent without animation', () {
    final f = MovingPropFixture();
    final result = move(f, target: MovingPropState.closed);
    expect(result.outcome, MovingPropMoveOutcome.moved);
    expect(result.frames, isEmpty);
  });

  test('invalid selections are rejected before any frame', () {
    final f = MovingPropFixture();
    for (final ids in <List<String>>[
      [],
      ['missing'],
      ['gate', 'gate'],
      List.generate(33, (i) => '$i')
    ]) {
      expect(() => move(f, ids: ids), throwsFormatException);
    }
  });

  test('mid-motion collision follows the projected footprint', () {
    final f = MovingPropFixture();
    final frame = move(f).frames[31];
    final world = f.world(positions: frame.positions);
    expect(world.isBlocked(3, 2), isTrue);
    expect(world.isBlocked(2, 2), isFalse);
    expect(world.withPlayer(world.player).isBlocked(3, 2), isTrue);
  });

  test('save validation rejects wall and prop overlaps but ignores hidden NPC',
      () {
    final f = MovingPropFixture(walls: {24});
    final open = const MovingPropWorldState.empty()
        .withProp(mapId: 'room', propId: 'gate', state: MovingPropState.open);
    expect(
        () => validateGameplayMovingPropWorldState(
            project: f.project, maps: [f.map], worldState: open),
        throwsFormatException);
    final npc = MovingPropFixture(entities: const [
      MapEntity(
          id: 'npc',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 2, y: 2),
          blocksMovement: true),
    ]);
    expect(
        () => validateGameplayMovingPropWorldState(
            project: npc.project,
            maps: [npc.map],
            worldState: const MovingPropWorldState.empty()),
        throwsFormatException);
    validateGameplayMovingPropWorldState(
        project: npc.project,
        maps: [npc.map],
        worldState: const MovingPropWorldState.empty(),
        npcMapPresencePredicate: (_, __) => false);
  });
}
