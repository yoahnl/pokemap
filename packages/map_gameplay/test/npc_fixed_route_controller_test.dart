import 'dart:math';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  for (final blocked in [false, true]) {
    test(
        'autonomous contact identifies only the first unobstructed player footprint blocked=$blocked',
        () {
      final world = _world(blocker: blocked);
      final withPlayer = world.withPlayer(GameplayPlayerState.fromGridSpawn(
          cell: const GridPos(x: 5, y: 5),
          facing: Direction.west,
          tileWidthPx: 32,
          tileHeightPx: 32,
          mapWidthCells: 20,
          mapHeightCells: 15));
      final attempt =
          _controller().nextStep(const Duration(milliseconds: 2550))!;
      final result = planNpcFixedRouteStep(world: withPlayer, attempt: attempt);
      expect(result.isBlocked, isTrue);
      expect(result.playerContact, !blocked);
    });
  }

  test('an initial player overlap is not a new autonomous contact', () {
    final world = _world();
    final overlapping = world.withPlayer(GameplayPlayerState.fromGridSpawn(
        cell: const GridPos(x: 4, y: 5),
        facing: Direction.east,
        tileWidthPx: 32,
        tileHeightPx: 32,
        mapWidthCells: 20,
        mapHeightCells: 15));
    final attempt = _controller().nextStep(const Duration(milliseconds: 2550))!;
    expect(
        planNpcFixedRouteStep(world: overlapping, attempt: attempt)
            .playerContact,
        isFalse);
  });

  test(
      'autonomous contact uses the wide owner footprint and respects reservations',
      () {
    final source = _world();
    final world = GameplayWorldState.initial(
        map: source.map.copyWith(entities: [
          source.map.entities.single
              .copyWith(size: const GridSize(width: 2, height: 1)),
        ]),
        playerPos: const GridPos(x: 6, y: 5),
        tileWidth: 32,
        tileHeight: 32);
    expect(
        npcFixedRouteTouchesPlayer(
            world: world, entityId: 'actor', direction: EntityFacing.east),
        isTrue);
    expect(
        npcFixedRouteTouchesPlayer(
            world: world,
            entityId: 'actor',
            direction: EntityFacing.east,
            characterReservations: const [
              PixelRect(leftPx: 192, topPx: 160, widthPx: 32, heightPx: 32)
            ]),
        isFalse);
  });

  test('initial delay and post-step cadence exclude time spent moving', () {
    final controller = _controller();
    expect(controller.nextStep(const Duration(milliseconds: 2549)), isNull);
    final attempt = controller.nextStep(const Duration(milliseconds: 1))!;
    expect(attempt.direction, EntityFacing.east);
    expect(attempt.stepDurationMs, 250);
    expect(attempt.stepIndex, 0);
    expect(controller.nextStep(const Duration(seconds: 20)), isNull);
    expect(controller.stepIndex, 0);
    expect(controller.resolveStep(attempt, NpcFixedRouteStepOutcome.completed),
        isTrue);
    expect(controller.stepIndex, 1);
    expect(controller.nextStep(const Duration(milliseconds: 2549)), isNull);
    expect(controller.nextStep(const Duration(milliseconds: 1))!.direction,
        EntityFacing.west);
  });

  test('a blocked direct step faces its direction and retries the same index',
      () {
    final controller = _controller();
    final first = controller.nextStep(const Duration(milliseconds: 2550))!;
    final original = _world(blocker: true);
    final blocked = planNpcFixedRouteStep(world: original, attempt: first);
    expect(blocked.motion, isNull);
    expect(blocked.isBlocked, isTrue);
    expect(blocked.world.map.entities.first.pos, const GridPos(x: 4, y: 5));
    expect(blocked.world.map.entities.first.npc!.facing, EntityFacing.east);
    expect(original.map.entities.first.npc!.facing, EntityFacing.south);
    expect(controller.resolveStep(first, NpcFixedRouteStepOutcome.blocked),
        isTrue);
    expect(controller.stepIndex, 0);
    expect(controller.nextStep(const Duration(milliseconds: 2549)), isNull);
    final second = controller.nextStep(const Duration(milliseconds: 1))!;
    expect(second.direction, EntityFacing.east);
    final open = planNpcFixedRouteStep(world: _world(), attempt: second);
    expect(open.motion!.from, const GridPos(x: 4, y: 5));
    expect(open.motion!.to, const GridPos(x: 5, y: 5));
    expect(controller.resolveStep(second, NpcFixedRouteStepOutcome.completed),
        isTrue);
    expect(controller.stepIndex, 1);
  });

  test('native global pause preserves the remaining cadence and route index',
      () {
    final controller = _controller();
    expect(controller.nextStep(const Duration(milliseconds: 1500)), isNull);
    expect(
        controller.nextStep(const Duration(seconds: 90), paused: true), isNull);
    expect(controller.nextStep(const Duration(milliseconds: 1049)), isNull);
    final attempt = controller.nextStep(const Duration(milliseconds: 1))!;
    expect(attempt.stepIndex, 0);
    expect(attempt.direction, EntityFacing.east);
  });

  test('owner interruption keeps the command and invalidates late completion',
      () {
    final controller = _controller();
    final stale = controller.nextStep(const Duration(milliseconds: 2550))!;
    controller.interrupt();
    expect(controller.resolveStep(stale, NpcFixedRouteStepOutcome.completed),
        isFalse);
    expect(controller.stepIndex, 0);
    expect(() => planNpcFixedRouteStep(world: _world(), attempt: stale),
        throwsStateError);
    expect(controller.nextStep(const Duration(milliseconds: 2549)), isNull);
    final resumed = controller.nextStep(const Duration(milliseconds: 1))!;
    expect(resumed.direction, stale.direction);
    expect(controller.resolveStep(resumed, NpcFixedRouteStepOutcome.completed),
        isTrue);
    controller.interrupt();
    expect(controller.stepIndex, 1);
    expect(controller.nextStep(const Duration(milliseconds: 2550))!.direction,
        EntityFacing.west);
  });

  test('a request from another route cannot advance this route', () {
    final controller = _controller();
    final other = _controller();
    final first = controller.nextStep(const Duration(milliseconds: 2550))!;
    final second = other.nextStep(const Duration(milliseconds: 2550))!;
    expect(controller.resolveStep(second, NpcFixedRouteStepOutcome.completed),
        isFalse);
    expect(controller.stepIndex, 0);
    expect(controller.resolveStep(first, NpcFixedRouteStepOutcome.completed),
        isTrue);
    expect(controller.resolveStep(first, NpcFixedRouteStepOutcome.completed),
        isFalse);
    expect(other.stepIndex, 0);
  });

  test('nonlooping route completes only after its final successful step', () {
    final controller = _controller(loop: false);
    for (var index = 0; index < 14; index++) {
      expect(controller.isComplete, isFalse);
      final attempt = controller.nextStep(const Duration(milliseconds: 2550))!;
      expect(attempt.stepIndex, index);
      expect(
          controller.resolveStep(attempt, NpcFixedRouteStepOutcome.completed),
          isTrue);
    }
    expect(controller.isComplete, isTrue);
    expect(controller.nextStep(const Duration(days: 1)), isNull);
  });

  for (final sourceEvent in [11, 15]) {
    test('original Centre event $sourceEvent repeats its exact fourteen steps',
        () {
      final directions = sourceEvent == 11
          ? [3, 2, 2, 3, 2, 3, 2, 3, 3, 2, 3, 2, 3, 2]
          : [2, 3, 2, 3, 2, 3, 2, 3, 3, 2, 3, 2, 3, 2];
      final pause = sourceEvent == 11 ? 2550 : 1600;
      final initialX = sourceEvent == 11 ? 4 : 11;
      final initialY = sourceEvent == 11 ? 5 : 6;
      final movement = _movement(directions: directions, pause: pause);
      final controller = _controller(movement: movement);
      var world = _world(movement: movement, x: initialX, y: initialY);
      final visited = <int>{initialX};
      for (var index = 0; index < 28; index++) {
        final attempt = controller.nextStep(Duration(milliseconds: pause))!;
        expect(attempt.stepIndex, index % 14);
        expect(
            attempt.direction,
            directions[index % 14] == 3
                ? EntityFacing.east
                : EntityFacing.west);
        final planned = planNpcFixedRouteStep(world: world, attempt: attempt);
        expect(planned.motion, isNotNull);
        expect(planned.motion!.to.y, initialY);
        world = planned.world.withEntityPosition('actor', planned.motion!.to);
        visited.add(planned.motion!.to.x);
        expect(
            controller.resolveStep(attempt, NpcFixedRouteStepOutcome.completed),
            isTrue);
        if (index % 14 == 13) {
          expect(world.map.entities.single.pos.x, initialX);
          expect(controller.stepIndex, 0);
        }
      }
      expect(visited, {initialX - 1, initialX, initialX + 1});
    });
  }

  test('Brice keeps his native trainer data through two exact moving loops',
      () {
    const directions = [2, 3, 2, 2, 3, 3, 3, 2, 3, 3, 3, 2, 2, 3, 2, 2];
    final movement = _movement(directions: directions, pause: 1600);
    final controller = _controller(movement: movement);
    var world = _world(
        movement: movement, x: 53, y: 7, width: 80, trainerId: 'native-brice');
    final visited = <int>{53};
    for (var index = 0; index < 32; index++) {
      final attempt = controller.nextStep(const Duration(milliseconds: 1600))!;
      final planned = planNpcFixedRouteStep(world: world, attempt: attempt);
      expect(attempt.direction,
          directions[index % 16] == 3 ? EntityFacing.east : EntityFacing.west);
      expect(planned.motion, isNotNull);
      expect(planned.world.map.entities.single.npc!.trainerId, 'native-brice');
      world = planned.world.withEntityPosition('actor', planned.motion!.to);
      visited.add(world.map.entities.single.pos.x);
      expect(
          controller.resolveStep(attempt, NpcFixedRouteStepOutcome.completed),
          isTrue);
      if (index % 16 == 15) {
        expect(world.map.entities.single.pos, const GridPos(x: 53, y: 7));
      }
    }
    expect(visited, {51, 52, 53, 54, 55, 56});
  });

  test('reservation blocks one direct step without choosing a detour', () {
    final controller = _controller();
    final attempt = controller.nextStep(const Duration(milliseconds: 2550))!;
    final planned = planNpcFixedRouteStep(
        world: _world(),
        attempt: attempt,
        characterReservations: const [
          PixelRect(leftPx: 160, topPx: 160, widthPx: 32, heightPx: 32)
        ]);
    expect(planned.motion, isNull);
    expect(planned.world.map.entities.single.pos, const GridPos(x: 4, y: 5));
  });

  test('request refuses a changed map, route configuration or missing actor',
      () {
    final controller = _controller();
    final attempt = controller.nextStep(const Duration(milliseconds: 2550))!;
    for (final world in [
      _world(mapId: 'other'),
      _world(movement: _movement(pause: 1600)),
      GameplayWorldState.initial(
          map: const MapData(
              id: 'map',
              name: 'Missing',
              size: GridSize(width: 20, height: 15)),
          playerPos: const GridPos(x: 0, y: 0))
    ]) {
      expect(() => planNpcFixedRouteStep(world: world, attempt: attempt),
          throwsStateError);
    }
    expect(controller.stepIndex, 0);
  });

  test('disposing a route invalidates its pending and future requests', () {
    final controller = _controller();
    final attempt = controller.nextStep(const Duration(milliseconds: 2550))!;
    controller.dispose();
    expect(controller.resolveStep(attempt, NpcFixedRouteStepOutcome.completed),
        isFalse);
    expect(controller.nextStep(const Duration(days: 1)), isNull);
    expect(() => planNpcFixedRouteStep(world: _world(), attempt: attempt),
        throwsStateError);
  });

  test('controller accepts only an entity with a valid fixed route', () {
    expect(
        () => NpcFixedRouteController(
            target: SceneActorTarget.player(mapId: 'map'),
            movement: _movement(),
            random: Random(1)),
        throwsArgumentError);
    expect(
        () => NpcFixedRouteController(
            target: SceneActorTarget.entity(mapId: 'map', entityId: 'actor'),
            movement: const MapEntityNpcMovementConfig(),
            random: Random(1)),
        throwsArgumentError);
    expect(
        () => NpcFixedRouteController(
            target: SceneActorTarget.entity(mapId: 'map', entityId: 'actor'),
            movement: _movement(directions: []),
            random: Random(1)),
        throwsA(isA<ValidationException>()));
  });

  test('a mutable caller list cannot rewrite an admitted route', () {
    final directions = [
      const MapEntityNpcRouteStep.move(direction: EntityFacing.east),
      const MapEntityNpcRouteStep.move(direction: EntityFacing.west)
    ];
    final controller = _controller(
        movement: MapEntityNpcMovementConfig(
            mode: MapEntityNpcMovementMode.fixedRoute,
            routeSteps: directions,
            pauseDurationMs: 1600,
            stepDurationMs: 250));
    directions[0] =
        const MapEntityNpcRouteStep.face(direction: EntityFacing.north);
    final attempt = controller.nextStep(const Duration(milliseconds: 1600))!;
    expect(attempt.direction, EntityFacing.east);
    expect(
        () => controller.movement.routeSteps[0] =
            const MapEntityNpcRouteStep.face(direction: EntityFacing.south),
        throwsUnsupportedError);
  });

  test('north and south remain single direct cardinal steps', () {
    final movement = MapEntityNpcMovementConfig(
        mode: MapEntityNpcMovementMode.fixedRoute,
        routeSteps: const [
          MapEntityNpcRouteStep.move(direction: EntityFacing.north),
          MapEntityNpcRouteStep.move(direction: EntityFacing.south)
        ],
        pauseDurationMs: 0,
        stepDurationMs: 250);
    final controller = _controller(movement: movement);
    final first = controller.nextStep(Duration.zero)!;
    final planned = planNpcFixedRouteStep(
        world: _world(movement: movement), attempt: first);
    expect(planned.motion!.to, const GridPos(x: 4, y: 4));
    expect(controller.resolveStep(first, NpcFixedRouteStepOutcome.completed),
        isTrue);
    final second = controller.nextStep(Duration.zero)!;
    expect(second.direction, EntityFacing.south);
    expect(second.stepIndex, 1);
  });

  test('Jeremy facing route changes direction without moving the trainer', () {
    const movement = MapEntityNpcMovementConfig(
        mode: MapEntityNpcMovementMode.fixedRoute,
        routeSteps: [
          MapEntityNpcRouteStep.face(direction: EntityFacing.west),
          MapEntityNpcRouteStep.face(direction: EntityFacing.north)
        ],
        pauseDurationMs: 1600,
        stepDurationMs: 250);
    final controller = _controller(movement: movement);
    var world = _world(movement: movement);
    for (final direction in [
      EntityFacing.west,
      EntityFacing.north,
      EntityFacing.west
    ]) {
      final attempt = controller.nextStep(const Duration(milliseconds: 1600))!;
      expect(attempt.step.kind, MapEntityNpcRouteStepKind.face);
      final planned = planNpcFixedRouteStep(world: world, attempt: attempt);
      expect(planned.motion, isNull);
      expect(planned.isBlocked, isFalse);
      expect(planned.world.map.entities.single.pos, const GridPos(x: 4, y: 5));
      expect(planned.world.map.entities.single.npc!.facing, direction);
      world = planned.world;
      expect(
          controller.resolveStep(attempt, NpcFixedRouteStepOutcome.completed),
          isTrue);
    }
  });

  test('Chris random facing uses the injected native RNG once per emitted step',
      () {
    const movement = MapEntityNpcMovementConfig(
        mode: MapEntityNpcMovementMode.fixedRoute,
        routeSteps: [MapEntityNpcRouteStep.randomFacing()],
        pauseDurationMs: 1600,
        stepDurationMs: 250);
    final random = _RouteRandom([0, 1, 2, 3]);
    final controller = _controller(movement: movement, random: random);
    final initial = _world(movement: movement);
    for (var index = 0; index < 4; index++) {
      expect(controller.nextStep(const Duration(milliseconds: 1599)), isNull);
      expect(controller.nextStep(const Duration(seconds: 5), paused: true),
          isNull);
      expect(random.calls, index);
      final attempt = controller.nextStep(const Duration(milliseconds: 1))!;
      expect(attempt.step.kind, MapEntityNpcRouteStepKind.randomFacing);
      expect(
          attempt.direction,
          const [
            EntityFacing.north,
            EntityFacing.east,
            EntityFacing.west,
            EntityFacing.south
          ][index]);
      expect(random.calls, index + 1);
      expect(controller.nextStep(const Duration(days: 1)), isNull);
      expect(random.calls, index + 1);
      final planned = planNpcFixedRouteStep(world: initial, attempt: attempt);
      expect(planned.world.map.entities.single.pos,
          initial.map.entities.single.pos);
      expect(planned.world.map.entities.single.npc!.facing, attempt.direction);
      expect(planned.motion, isNull);
      expect(planned.isBlocked, isFalse);
      expect(
          controller.resolveStep(attempt, NpcFixedRouteStepOutcome.completed),
          isTrue);
    }
  });

  test('an instance-bound route requires its injected state reader', () {
    expect(() => _controller(movement: _suspendingMovement()),
        throwsArgumentError);
  });

  test('instance suspension invalidates a pending step and preserves its index',
      () {
    var suspended = false;
    final controller = _controller(
        movement: _suspendingMovement(),
        readInstanceBoolean: (key) {
          expect(key, 'npc.autonomousRouteStopped');
          return suspended;
        });
    final pending = controller.nextStep(const Duration(milliseconds: 2550))!;
    suspended = true;
    expect(controller.nextStep(const Duration(seconds: 60)), isNull);
    expect(controller.resolveStep(pending, NpcFixedRouteStepOutcome.completed),
        isFalse);
    expect(
        () => planNpcFixedRouteStep(
            world: _world(movement: _suspendingMovement()), attempt: pending),
        throwsStateError);
    expect(controller.stepIndex, 0);
    suspended = false;
    expect(controller.nextStep(const Duration(milliseconds: 2549)), isNull);
    expect(controller.nextStep(const Duration(milliseconds: 1))!.stepIndex, 0);
  });

  test(
      'route suspension survives save and retained visits but resets with its instance',
      () {
    var instances = setupDifferentMapInstance(
        state: const MapInstanceWorldState.empty(),
        targetMapId: 'map',
        allocateId: (_) => 'visit-1');
    final firstScope = instances.instanceRef('map')!;
    final movement = _suspendingMovement();
    final first = _controller(
        movement: movement,
        readInstanceBoolean: (key) =>
            instances.eventBoolean(firstScope, 'actor', key));
    instances = instances.setEventBoolean(
        firstScope, 'actor', 'npc.autonomousRouteStopped', true);
    instances = MapInstanceWorldState.fromJson(instances.toJson());
    instances = preserveSameMapInstance(state: instances, mapId: 'map');
    expect(first.nextStep(const Duration(seconds: 60)), isNull);
    first.dispose();
    instances = setupDifferentMapInstance(
        state: instances, targetMapId: 'map', allocateId: (_) => 'visit-2');
    final secondScope = instances.instanceRef('map')!;
    final second = _controller(
        movement: movement,
        readInstanceBoolean: (key) =>
            instances.eventBoolean(secondScope, 'actor', key));
    expect(second.nextStep(const Duration(milliseconds: 2550))!.stepIndex, 0);
    expect(first.nextStep(const Duration(days: 1)), isNull);
  });

  test('a suspended random-facing route does not consume native random draws',
      () {
    final movement = MapEntityNpcMovementConfig.fromJson({
      ..._suspendingMovement().toJson(),
      'routeSteps': [
        {'kind': 'randomFacing'}
      ],
    });
    final random = _RouteRandom([0]);
    var suspended = true;
    final controller = _controller(
        movement: movement,
        random: random,
        readInstanceBoolean: (_) => suspended);
    expect(controller.nextStep(const Duration(days: 1)), isNull);
    expect(random.calls, 0);
    suspended = false;
    expect(controller.nextStep(const Duration(milliseconds: 2550))!.direction,
        EntityFacing.north);
    expect(random.calls, 1);
  });

  test('one update cannot accumulate or skip multiple commands', () {
    final controller = _controller();
    final attempt = controller.nextStep(const Duration(days: 1))!;
    expect(attempt.stepIndex, 0);
    expect(controller.resolveStep(attempt, NpcFixedRouteStepOutcome.completed),
        isTrue);
    expect(controller.nextStep(Duration.zero), isNull);
    expect(() => controller.nextStep(const Duration(milliseconds: -1)),
        throwsArgumentError);
  });
}

MapEntityNpcMovementConfig _movement({
  List<int> directions = const [3, 2, 2, 3, 2, 3, 2, 3, 3, 2, 3, 2, 3, 2],
  int pause = 2550,
  bool loop = true,
}) =>
    MapEntityNpcMovementConfig.fromJson({
      'mode': 'fixedRoute',
      'routeSteps': directions
          .map((code) =>
              {'kind': 'move', 'direction': code == 3 ? 'east' : 'west'})
          .toList(),
      'pauseDurationMs': pause,
      'stepDurationMs': 250,
      'loop': loop,
    });

NpcFixedRouteController _controller(
        {MapEntityNpcMovementConfig? movement,
        bool loop = true,
        Random? random,
        NpcRouteInstanceBooleanReader? readInstanceBoolean}) =>
    NpcFixedRouteController(
        target: SceneActorTarget.entity(mapId: 'map', entityId: 'actor'),
        movement: movement ?? _movement(loop: loop),
        random: random ?? Random(123),
        readInstanceBoolean: readInstanceBoolean);

GameplayWorldState _world(
        {MapEntityNpcMovementConfig? movement,
        bool blocker = false,
        int x = 4,
        int y = 5,
        String mapId = 'map',
        int width = 20,
        String? trainerId}) =>
    GameplayWorldState.initial(
        map: MapData(
            id: mapId,
            name: 'Centre',
            size: GridSize(width: width, height: 15),
            entities: [
              MapEntity(
                  id: 'actor',
                  kind: MapEntityKind.npc,
                  pos: GridPos(x: x, y: y),
                  npc: MapEntityNpcData(
                      movement: movement ?? _movement(), trainerId: trainerId)),
              if (blocker)
                const MapEntity(
                    id: 'blocker',
                    kind: MapEntityKind.npc,
                    pos: GridPos(x: 5, y: 5),
                    npc: MapEntityNpcData())
            ]),
        playerPos: const GridPos(x: 0, y: 0),
        tileWidth: 32,
        tileHeight: 32);

final class _RouteRandom implements Random {
  _RouteRandom(this.values);
  final List<int> values;
  var calls = 0;
  @override
  int nextInt(int max) {
    expect(max, 4);
    return values[calls++];
  }

  @override
  bool nextBool() => throw UnsupportedError('nextBool');
  @override
  double nextDouble() => throw UnsupportedError('nextDouble');
}

MapEntityNpcMovementConfig _suspendingMovement() =>
    MapEntityNpcMovementConfig.fromJson({
      ..._movement().toJson(),
      'suspendWhenInstanceBoolean': {
        'key': 'npc.autonomousRouteStopped',
        'value': true
      },
    });
