import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'support/moving_platform_fixture.dart';

void main() {
  test(
      'a narrow control stops movement before the unsupported ground beyond it',
      () {
    final fixture = MovingPlatformFixture();
    final definition = MovingPlatformDefinition.fromJson({
      ...fixture.definition.toJson(),
      'lattice': {...fixture.definition.lattice.toJson(), 'widthPx': 16},
      'controls': [
        {
          'id': 'go',
          'cell': {'x': 0, 'y': 0},
          'motion': 'forward'
        }
      ],
    });
    final map = fixture.map.copyWith(
        movingPlatforms: [definition],
        layers: [MovingPlatformFixture.terrain('magma', blockedIndex: 22)]);
    var world = fixture.world(map: map, player: const GridPos(x: 1, y: 2));
    world = world.withPlayer(world.player.copyWith(
        playerPositionPx: const PixelPosition(leftPx: 40, topPx: 64)));
    final step = stepGameplayWorld(
        world, const MoveIntent(Direction.east, pixelsPerStep: 32));
    expect(step, isA<Moved>());
    expect((step as Moved).platformControl?.controlId, 'go');
    expect(step.world.player.playerPositionPx.leftPx, 54);
    final wall = MapLayer.collision(id: 'wall', name: 'Wall', collisions: [
      for (var index = 0; index < 100; index++) index == 22,
    ]);
    final blocked = fixture
        .world(
            map: map.copyWith(layers: [...map.layers, wall]),
            player: const GridPos(x: 1, y: 2))
        .withPlayer(world.player);
    expect(
        stepGameplayWorld(
            blocked, const MoveIntent(Direction.east, pixelsPerStep: 32)),
        isA<Blocked>());
  });

  test('controls round trip, rotate and reject ambiguous or unsupported cells',
      () {
    final fixture = MovingPlatformFixture();
    final definition = MovingPlatformDefinition.fromJson({
      ...fixture.definition.toJson(),
      'controls': [
        {
          'id': 'go',
          'cell': {'x': 0, 'y': 0},
          'motion': 'forward'
        },
      ],
    });
    expect(MovingPlatformDefinition.fromJson(definition.toJson()), definition);
    expect(definition.controls.single.motion, MovingPlatformMotion.forward);
    expect(() => definition.controls.clear(), throwsUnsupportedError);
    for (final controls in [
      null,
      [
        {
          'id': 'go',
          'cell': {'x': 0, 'y': 0},
          'motion': 'unknown'
        }
      ],
      [
        for (var i = 0; i < 2; i++)
          {
            'id': '$i',
            'cell': {'x': 0, 'y': 0},
            'motion': 'forward'
          }
      ],
      [
        {
          'id': 'go',
          'cell': {'x': 1, 'y': 0},
          'motion': 'forward'
        }
      ],
    ]) {
      expect(
          () => MovingPlatformDefinition.fromJson({
                ...fixture.definition.toJson(),
                'controls': controls,
              }),
          throwsFormatException);
    }
  });

  test('a side control follows every rotation and a fractional moving lattice',
      () {
    final fixture = MovingPlatformFixture();
    final definition = MovingPlatformDefinition.fromJson({
      ...fixture.definition.toJson(),
      'lattice': {
        ...fixture.definition.lattice.toJson(),
        'heightPx': 24.033233368369512
      },
      'variants': [
        for (final variant in fixture.definition.variants)
          {
            ...variant.toJson(),
            'supportCells': [
              for (var y = -1; y <= 1; y++)
                for (var x = -1; x <= 1; x++) {'x': x, 'y': y}
            ],
          }
      ],
      'controls': [
        {
          'id': 'go',
          'cell': {'x': 1, 'y': 0},
          'motion': 'forward'
        }
      ],
    });
    for (var turns = 0; turns < 4; turns++) {
      final pose =
          MovingPlatformPose(leftPx: 128, topPx: 128, quarterTurns: turns);
      final rect = movingPlatformCellRect(
          platform: definition,
          pose: pose,
          cell: definition.controls.single.cellForQuarterTurns(turns));
      expect(
          definition.controls.single.cellForQuarterTurns(turns),
          const [
            GridPos(x: 1, y: 0),
            GridPos(x: 0, y: 1),
            GridPos(x: -1, y: 0),
            GridPos(x: 0, y: -1)
          ][turns]);
      final state = fixture.state
          .withPlatform(mapId: 'gym', platformId: 'bridge', pose: pose);
      final map = fixture.map.copyWith(
          movingPlatforms: [definition],
          layers: [MovingPlatformFixture.terrain('magma', blockedIndex: 99)]);
      var world = fixture.world(map: map, state: state);
      final target = PixelPosition(
          leftPx: rect.leftPx - 10, topPx: rect.topPx + rect.heightPx - 32);
      world = world.withPlayer(world.player.copyWith(
          playerPositionPx:
              PixelPosition(leftPx: target.leftPx - 16, topPx: target.topPx)));
      final entry = resolveMovingPlatformControlEntry(
          world: world,
          destination:
              PixelPosition(leftPx: target.leftPx + 32, topPx: target.topPx));
      expect(entry?.controlId, 'go', reason: 'orientation $turns');
      expect((entry?.playerPositionPx.leftPx, entry?.playerPositionPx.topPx),
          (target.leftPx, target.topPx));
      final standing =
          world.withPlayer(world.player.copyWith(playerPositionPx: target));
      expect(
          resolveMovingPlatformControlEntry(
              world: standing, destination: target),
          isNull);
      expect(
          resolveMovingPlatformControlEntry(
              world: standing,
              destination: PixelPosition(
                  leftPx: target.leftPx + 1, topPx: target.topPx)),
          isNull);
    }
  });

  test(
      'leaving and returning activates again, facing and blocked movement do not',
      () {
    final fixture = MovingPlatformFixture();
    final definition = MovingPlatformDefinition.fromJson({
      ...fixture.definition.toJson(),
      'controls': [
        {
          'id': 'turn',
          'cell': {'x': 0, 'y': 0},
          'motion': 'rotateClockwise'
        }
      ],
    });
    final map = fixture.map.copyWith(
        movingPlatforms: [definition],
        layers: [MovingPlatformFixture.terrain('magma', blockedIndex: 99)]);
    final standing = fixture.world(map: map);
    final leaving = stepGameplayWorld(
        standing, const MoveIntent(Direction.west, pixelsPerStep: 32)) as Moved;
    expect(leaving.platformControl, isNull);
    final returning = stepGameplayWorld(
            leaving.world, const MoveIntent(Direction.east, pixelsPerStep: 32))
        as Moved;
    expect(returning.platformControl?.motion,
        MovingPlatformMotion.rotateClockwise);
    expect(
        (stepGameplayWorld(standing,
                const MoveIntent(Direction.east, pixelsPerStep: 0)) as Blocked)
            .world
            .player
            .playerPositionPx,
        standing.player.playerPositionPx);
  });

  test(
      'walking stops on a narrow moving button and carrying does not retrigger',
      () {
    final fixture = MovingPlatformFixture();
    final definition = MovingPlatformDefinition.fromJson({
      ...fixture.definition.toJson(),
      'controls': [
        {
          'id': 'go',
          'cell': {'x': 0, 'y': 0},
          'motion': 'forward'
        },
      ],
    });
    final map = fixture.map.copyWith(
      layers: [MovingPlatformFixture.terrain('magma', blockedIndex: 99)],
      movingPlatforms: [definition],
    );
    final world = fixture.world(map: map, player: const GridPos(x: 1, y: 2));
    final step = stepGameplayWorld(
        world, const MoveIntent(Direction.east, pixelsPerStep: 32));
    expect(step, isA<Moved>());
    final arrival = step as Moved;
    expect(arrival.platformControl?.controlId, 'go');
    expect(arrival.platformControl?.motion, MovingPlatformMotion.forward);
    final moved = moveGameplayPlatform(
        world: arrival.world,
        project: fixture.project,
        worldState: fixture.state,
        platformId: 'bridge',
        motion: arrival.platformControl!.motion);
    expect(moved.outcome, MovingPlatformMoveOutcome.moved);
    final stillOnButton = stepGameplayWorld(
        moved.finalWorld, const MoveIntent(Direction.east, pixelsPerStep: 1));
    expect((stillOnButton as Moved).platformControl, isNull);
    final restored = fixture
        .world(map: map, state: moved.finalWorldState)
        .withPlayer(moved.finalWorld.player);
    expect(
        (stepGameplayWorld(restored,
                const MoveIntent(Direction.east, pixelsPerStep: 1)) as Moved)
            .platformControl,
        isNull);
  });
}
