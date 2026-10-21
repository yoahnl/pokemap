import 'dart:math';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  test('random move produces motion while random facing stays in place', () {
    final movement = _movement();
    final controller = _controller(movement, 17);
    final world = _world(movement);
    final attempt = controller.nextStep(const Duration(seconds: 2))!;
    final plan = planNpcFixedRouteStep(world: world, attempt: attempt);
    expect(plan.isBlocked, isFalse);
    expect(plan.motion, isNotNull);
    expect(plan.motion!.from, const GridPos(x: 3, y: 3));
    expect(plan.motion!.to, isNot(plan.motion!.from));
    expect((plan.motion!.to.x - 3).abs() + (plan.motion!.to.y - 3).abs(), 1);
    expect(world.map.entities.single.pos, const GridPos(x: 3, y: 3));
    expect(controller.resolveStep(attempt, NpcFixedRouteStepOutcome.completed),
        isTrue);
    final face = controller.nextStep(const Duration(seconds: 2))!;
    final faced = planNpcFixedRouteStep(world: world, attempt: face);
    expect(faced.motion, isNull);
    expect(faced.isBlocked, isFalse);
  });

  test('seeded directions repeat and cover the four cardinal choices', () {
    List<EntityFacing> sample(int seed) {
      final movement = _movement(onlyRandomMove: true);
      final controller = _controller(movement, seed);
      return [
        for (var i = 0; i < 64; i++)
          (() {
            final step = controller.nextStep(const Duration(seconds: 2))!;
            controller.resolveStep(step, NpcFixedRouteStepOutcome.completed);
            return step.direction;
          })(),
      ];
    }

    expect(sample(31), sample(31));
    expect(sample(31).toSet(), EntityFacing.values.toSet());
    expect(sample(31), isNot(sample(32)));
  });

  for (final obstacle in [
    'terrain',
    'entity',
    'player',
    'dynamic',
    'reservation',
    'bounds'
  ]) {
    test('random move respects $obstacle without choosing a detour', () {
      final movement = _movement(onlyRandomMove: true);
      final controller = _controller(movement, 23);
      final attempt = controller.nextStep(const Duration(seconds: 2))!;
      final delta = switch (attempt.direction) {
        EntityFacing.north => const GridPos(x: 0, y: -1),
        EntityFacing.south => const GridPos(x: 0, y: 1),
        EntityFacing.east => const GridPos(x: 1, y: 0),
        EntityFacing.west => const GridPos(x: -1, y: 0),
      };
      final origin = obstacle == 'bounds'
          ? const GridPos(x: 0, y: 0)
          : const GridPos(x: 3, y: 3);
      final target = GridPos(x: origin.x + delta.x, y: origin.y + delta.y);
      final world = _world(
        movement,
        origin: origin,
        player: obstacle == 'player' ? target : null,
        terrain: obstacle == 'terrain' ? target : null,
        blocker: obstacle == 'entity' ? target : null,
        width: obstacle == 'bounds' ? 1 : 7,
        height: obstacle == 'bounds' ? 1 : 7,
      );
      final plan = planNpcFixedRouteStep(
        world: world,
        attempt: attempt,
        dynamicBlockedCells: obstacle == 'dynamic' ? [target] : const [],
        characterReservations: obstacle == 'reservation'
            ? [
                PixelRect(
                    leftPx: target.x * 32,
                    topPx: target.y * 32,
                    widthPx: 32,
                    heightPx: 32),
              ]
            : const [],
      );
      expect(plan.isBlocked, isTrue);
      expect(plan.motion, isNull);
      expect(plan.world.map.entities.first.pos, origin);
      expect(controller.resolveStep(attempt, NpcFixedRouteStepOutcome.blocked),
          isTrue);
      expect(controller.stepIndex, 0);
    });
  }

  test('pause and interruption invalidate a pending random move', () {
    final movement = _movement(onlyRandomMove: true);
    final controller = _controller(movement, 11);
    expect(
        controller.nextStep(const Duration(seconds: 9), paused: true), isNull);
    final stale = controller.nextStep(const Duration(seconds: 2))!;
    controller.interrupt();
    expect(controller.resolveStep(stale, NpcFixedRouteStepOutcome.completed),
        isFalse);
    expect(() => planNpcFixedRouteStep(world: _world(movement), attempt: stale),
        throwsStateError);
    expect(controller.nextStep(const Duration(milliseconds: 1599)), isNull);
    expect(controller.nextStep(const Duration(milliseconds: 1)), isNotNull);
  });
}

MapEntityNpcMovementConfig _movement({bool onlyRandomMove = false}) =>
    MapEntityNpcMovementConfig.fromJson({
      'mode': 'fixedRoute',
      'routeSteps': [
        {'kind': 'randomMove'},
        if (!onlyRandomMove) {'kind': 'randomFacing'},
      ],
      'loop': true,
      'pauseDurationMs': 1600,
      'stepDurationMs': 250,
    });

NpcFixedRouteController _controller(
        MapEntityNpcMovementConfig movement, int seed) =>
    NpcFixedRouteController(
        target: SceneActorTarget.entity(mapId: 'map', entityId: 'npc'),
        movement: movement,
        random: Random(seed));

GameplayWorldState _world(
  MapEntityNpcMovementConfig movement, {
  GridPos origin = const GridPos(x: 3, y: 3),
  GridPos? player,
  GridPos? terrain,
  GridPos? blocker,
  int width = 7,
  int height = 7,
}) =>
    GameplayWorldState.initial(
      tileWidth: 32,
      tileHeight: 32,
      playerPos: player ?? const GridPos(x: 0, y: 0),
      map: MapData(
        id: 'map',
        name: 'Random route',
        size: GridSize(width: width, height: height),
        entities: [
          MapEntity(
              id: 'npc',
              kind: MapEntityKind.npc,
              pos: origin,
              npc: MapEntityNpcData(movement: movement)),
          if (blocker != null)
            MapEntity(
                id: 'blocker',
                kind: MapEntityKind.npc,
                pos: blocker,
                npc: const MapEntityNpcData(),
                blocksMovement: true),
        ],
        layers: [
          MapLayer.collision(id: 'collision', name: 'Collision', collisions: [
            for (var index = 0; index < width * height; index++)
              terrain?.x == index % width && terrain?.y == index ~/ width,
          ])
        ],
      ),
    );
