import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'support/moving_platform_fixture.dart';
import 'support/materialized_border_collision_fixture.dart';

void main() {
  test(
      'support exempts nominated terrain only and remains precise between cells',
      () {
    final fixture = MovingPlatformFixture();
    final world = fixture.world();
    expect(world.isBlocked(2, 2), false);
    expect(world.isBlocked(3, 2), true);
    final translated = fixture.state.withPlatform(
        mapId: 'gym',
        platformId: 'bridge',
        pose: MovingPlatformPose(leftPx: 65, topPx: 64, quarterTurns: 0));
    final moving = fixture.world(state: translated);
    expect(
        moving.worldStaticObstaclesCollidePixelRect(
            const PixelRect(leftPx: 64, topPx: 70, widthPx: 1, heightPx: 1)),
        true);
    expect(
        moving.worldStaticObstaclesCollidePixelRect(
            const PixelRect(leftPx: 65, topPx: 70, widthPx: 1, heightPx: 1)),
        false);
    expect(
        moving.worldStaticObstaclesCollidePixelRect(
            const PixelRect(leftPx: 96, topPx: 70, widthPx: 1, heightPx: 1)),
        false);
    expect(
        moving.worldStaticObstaclesCollidePixelRect(
            const PixelRect(leftPx: 97, topPx: 70, widthPx: 1, heightPx: 1)),
        true);
    for (final extra in [
      MapLayer.collision(
          id: 'wall',
          name: 'Wall',
          collisions: [for (var i = 0; i < 100; i++) i == 22]),
      MovingPlatformFixture.terrain('unrelated', blockedIndex: 22),
    ]) {
      expect(
          fixture
              .world(
                  map: fixture.map
                      .copyWith(layers: [...fixture.map.layers, extra]))
              .isBlocked(2, 2),
          true);
    }
  });

  for (var rotation = 0; rotation < 4; rotation++) {
    test(
        'platform carries player in local direction at rotation $rotation and restores save pose',
        () {
      final fixture = MovingPlatformFixture(quarterTurns: rotation);
      final before = fixture.world();
      final result = moveGameplayPlatform(
          world: before,
          project: fixture.project,
          worldState: fixture.state,
          platformId: 'bridge',
          motion: MovingPlatformMotion.forward);
      expect(result.outcome, MovingPlatformMoveOutcome.moved);
      expect(result.frames.length, 32);
      final (dx, dy) = switch (rotation) {
        0 => (32, 0),
        1 => (0, 32),
        2 => (-32, 0),
        _ => (0, -32)
      };
      expect(result.finalWorld.player.playerPositionPx.leftPx,
          before.player.playerPositionPx.leftPx + dx);
      expect(result.finalWorld.player.playerPositionPx.topPx,
          before.player.playerPositionPx.topPx + dy);
      final restored =
          MovingPlatformWorldState.fromJson(result.finalWorldState.toJson());
      expect(restored.platform('gym', 'bridge')!.leftPx, 64 + dx);
      expect(restored.platform('gym', 'bridge')!.topPx, 64 + dy);
      final reverse = moveGameplayPlatform(
          world: result.finalWorld,
          project: fixture.project,
          worldState: restored,
          platformId: 'bridge',
          motion: MovingPlatformMotion.backward);
      expect(reverse.outcome, MovingPlatformMoveOutcome.moved);
      expect(reverse.finalWorldState, fixture.state);
      expect(reverse.finalWorld.player.playerPositionPx.leftPx,
          before.player.playerPositionPx.leftPx);
      expect(reverse.finalWorld.player.playerPositionPx.topPx,
          before.player.playerPositionPx.topPx);
    });
  }

  test(
      'obstacle encountered after travel returns every pixel to original pose without saving partial travel',
      () {
    final fixture = MovingPlatformFixture(distance: 3);
    final map = fixture.map.copyWith(layers: [
      ...fixture.map.layers,
      MapLayer.collision(
          id: 'wall',
          name: 'Wall',
          collisions: [for (var index = 0; index < 100; index++) index == 24])
    ]);
    final before = fixture.world(map: map);
    final result = moveGameplayPlatform(
        world: before,
        project: fixture.project,
        worldState: fixture.state,
        platformId: 'bridge',
        motion: MovingPlatformMotion.forward);
    expect(result.outcome, MovingPlatformMoveOutcome.blocked);
    expect(result.frames.where((frame) => !frame.returning).length, 32);
    expect(result.frames.where((frame) => frame.returning).length, 32);
    expect(identical(result.finalWorld, before), true);
    expect(result.finalWorldState, fixture.state);
    expect(result.frames.last.worldState, fixture.state);
  });

  test(
      'rotation chooses authored variant and preserves player pixel anchor and saved orientation',
      () {
    final fixture = MovingPlatformFixture();
    var world = fixture.world();
    var state = fixture.state;
    final original = world.player.playerPositionPx;
    for (var turn = 1; turn <= 4; turn++) {
      final result = moveGameplayPlatform(
          world: world,
          project: fixture.project,
          worldState: state,
          platformId: 'bridge',
          motion: MovingPlatformMotion.rotateClockwise);
      expect(result.outcome, MovingPlatformMoveOutcome.moved);
      world = result.finalWorld;
      state = result.finalWorldState;
      expect(state.platform('gym', 'bridge')!.quarterTurns, turn % 4);
      expect(world.map.placedElements.single.elementId, 'platform-${turn % 4}');
      expect(world.map.placedElements.single.quarterTurns, 0);
      expect(world.player.playerPositionPx.leftPx, original.leftPx);
      expect(world.player.playerPositionPx.topPx, original.topPx);
    }
    expect(state, fixture.state);
  });

  test('standing outside platform cannot command it', () {
    final fixture = MovingPlatformFixture();
    final result = moveGameplayPlatform(
        world: fixture.world(player: const GridPos(x: 4, y: 4)),
        project: fixture.project,
        worldState: fixture.state,
        platformId: 'bridge',
        motion: MovingPlatformMotion.forward);
    expect(result.outcome, MovingPlatformMoveOutcome.notRiding);
    expect(result.finalWorldState, fixture.state);
  });

  test(
      'projected HGSS lattice keeps fractional height independently of map tile height',
      () {
    const sourceStep = 24.03323336836951;
    final fixture = MovingPlatformFixture(
        distance: 5,
        quarterTurns: 1,
        lattice: MovingPlatformLattice(
            widthPx: 32,
            heightPx: sourceStep,
            originLeftPx: 0,
            originTopPx: 0,
            cellOffsetLeftPx: 0,
            cellOffsetTopPx: 0));
    final gridWorld = fixture.world();
    final original = gridWorld.withPlayer(gridWorld.player.copyWith(
        playerPositionPx: PixelPosition(
            leftPx: gridWorld.player.playerPositionPx.leftPx,
            topPx: gridWorld.player.playerPositionPx.topPx - 8)));
    final move = moveGameplayPlatform(
        world: original,
        project: fixture.project,
        worldState: fixture.state,
        platformId: 'bridge',
        motion: MovingPlatformMotion.forward);
    expect(move.outcome, MovingPlatformMoveOutcome.moved);
    final pose = move.finalWorldState.platform('gym', 'bridge')!;
    expect(pose.topPx, closeTo(64 + sourceStep * 5, 1e-9));
    expect(move.finalWorld.player.playerPositionPx.topPx,
        original.player.playerPositionPx.topPx + pose.topPx.round() - 64);
    expect(move.frames.length, (sourceStep * 5).ceil());
    final restored =
        MovingPlatformWorldState.fromJson(move.finalWorldState.toJson());
    expect(restored.platform('gym', 'bridge')!.topPx, pose.topPx);
    final back = moveGameplayPlatform(
        world: move.finalWorld,
        project: fixture.project,
        worldState: restored,
        platformId: 'bridge',
        motion: MovingPlatformMotion.backward);
    expect(back.outcome, MovingPlatformMoveOutcome.moved);
    expect(back.finalWorldState.platform('gym', 'bridge')!.topPx,
        closeTo(64, 1e-9));
    expect(back.finalWorld.player.playerPositionPx.topPx,
        original.player.playerPositionPx.topPx);
  });

  test(
      'NPC, fine placed object and Border collisions survive support at the same position',
      () {
    final fixture = MovingPlatformFixture();
    final npcMap = fixture.map.copyWith(entities: const [
      MapEntity(
          id: 'npc',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 2, y: 2),
          blocksMovement: true)
    ]);
    expect(fixture.world(map: npcMap).isBlocked(2, 2), true);
    final obstacle = fixture.project.elements.first.copyWith(
        id: 'obstacle',
        collisionProfile:
            const ElementCollisionProfile(cells: [GridPos(x: 0, y: 0)]));
    final project = fixture.project
        .copyWith(elements: [...fixture.project.elements, obstacle]);
    final map = fixture.map.copyWith(placedElements: [
      ...fixture.map.placedElements,
      const MapPlacedElement(
          id: 'obstacle',
          layerId: 'magma',
          elementId: 'obstacle',
          pos: GridPos(x: 2, y: 2),
          properties: {
            pokemapPlacementOriginProperty: pokemapPlacementOriginAuthored
          })
    ]);
    final world = GameplayWorldState.initial(
        map: map,
        project: project,
        movingPlatformWorldState: fixture.state,
        playerPos: const GridPos(x: 2, y: 2),
        tileWidth: 32,
        tileHeight: 32);
    expect(world.isBlocked(2, 2), true);
    final border = MaterializedBorderCollisionFixture(
        profile: const ElementCollisionProfile(cells: [GridPos(x: 0, y: 1)]));
    final definitionJson = fixture.definition.toJson();
    final art = border.feature.materialization!.placements.single;
    final obstacleX = art.topLeftWorldPx.x + 3,
        obstacleY = art.topLeftWorldPx.y + 33;
    definitionJson['initialPose'] = {
      'leftPx': obstacleX ~/ 32 * 32,
      'topPx': obstacleY ~/ 32 * 32,
      'quarterTurns': 0
    };
    final borderMap = fixture.map.copyWith(
        layers: [...fixture.map.layers, ...border.map.layers],
        movingPlatforms: [MovingPlatformDefinition.fromJson(definitionJson)]);
    final borderProject = fixture.project.copyWith(
        borderCatalog: border.project.borderCatalog,
        elements: [...fixture.project.elements, ...border.project.elements]);
    final borderWorld = GameplayWorldState.initial(
        map: borderMap,
        project: borderProject,
        playerPos: const GridPos(x: 2, y: 4),
        tileWidth: 32,
        tileHeight: 32);
    expect(
        borderWorld.worldStaticObstaclesCollidePixelRect(PixelRect(
            leftPx: obstacleX, topPx: obstacleY, widthPx: 1, heightPx: 1)),
        true);
  });

  test(
      'source HGSS support rectangle uses projected cell center offset before raster rounding',
      () {
    final fixture = MovingPlatformFixture();
    final json = fixture.definition.toJson();
    json['lattice'] = {
      'widthPx': 32,
      'heightPx': 24.03323336836951,
      'originLeftPx': 0,
      'originTopPx': 0,
      'cellOffsetLeftPx': -16,
      'cellOffsetTopPx': -12.016616684184755
    };
    final definition = MovingPlatformDefinition.fromJson(json);
    final rect = movingPlatformCellRect(
        platform: definition,
        pose: MovingPlatformPose(leftPx: 96, topPx: 96, quarterTurns: 0),
        cell: const GridPos(x: -1, y: -1));
    expect((rect.leftPx, rect.topPx, rect.widthPx, rect.heightPx),
        (48, 60, 32, 24));
  });

  test(
      'saved poses reject unknown maps, unfinished travel, out of bounds and colliding support',
      () {
    final fixture = MovingPlatformFixture();
    validateGameplayMovingPlatformWorldState(
        project: fixture.project,
        maps: [fixture.map],
        worldState: fixture.state);
    for (final pose in [
      MovingPlatformPose(leftPx: 10000, topPx: 10000, quarterTurns: 0),
      MovingPlatformPose(leftPx: 65, topPx: 64, quarterTurns: 0)
    ]) {
      final state = fixture.state
          .withPlatform(mapId: 'gym', platformId: 'bridge', pose: pose);
      expect(
          () => validateMovingPlatformWorldState(
              project: fixture.project, maps: [fixture.map], worldState: state),
          throwsFormatException);
    }
    final outside = fixture.state.withPlatform(
        mapId: 'gym',
        platformId: 'bridge',
        pose: MovingPlatformPose(leftPx: 10000, topPx: 10000, quarterTurns: 0));
    expect(() => fixture.world(state: outside), throwsFormatException);
    final unknown = fixture.state.withPlatform(
        mapId: 'unknown',
        platformId: 'bridge',
        pose: fixture.definition.initialPose);
    expect(
        () => validateMovingPlatformWorldState(
            project: fixture.project, maps: [fixture.map], worldState: unknown),
        throwsFormatException);
    final unknownId = fixture.state.withPlatform(
        mapId: 'gym',
        platformId: 'unknown',
        pose: fixture.definition.initialPose);
    expect(
        () => validateMovingPlatformWorldState(
            project: fixture.project,
            maps: [fixture.map],
            worldState: unknownId),
        throwsFormatException);
    final blocked = fixture.map.copyWith(layers: [
      ...fixture.map.layers,
      MapLayer.collision(
          id: 'wall',
          name: 'Wall',
          collisions: [for (var i = 0; i < 100; i++) i == 22])
    ]);
    expect(
        () => validateGameplayMovingPlatformWorldState(
            project: fixture.project,
            maps: [blocked],
            worldState: fixture.state),
        throwsFormatException);
  });

  test(
      'rotation probe obstacle rejects the rotation and leaves both sprite and saved pose intact',
      () {
    final fixture = MovingPlatformFixture();
    final json = fixture.definition.toJson();
    ((json['variants'] as List).first as Map)['rotationClearanceCells'] = [
      {'x': 1, 'y': 0}
    ];
    final map = fixture.map.copyWith(movingPlatforms: [
      MovingPlatformDefinition.fromJson(json)
    ], layers: [
      ...fixture.map.layers,
      MapLayer.collision(
          id: 'wall',
          name: 'Wall',
          collisions: [for (var i = 0; i < 100; i++) i == 23])
    ]);
    final before = fixture.world(map: map);
    final result = moveGameplayPlatform(
        world: before,
        project: fixture.project,
        worldState: fixture.state,
        platformId: 'bridge',
        motion: MovingPlatformMotion.rotateClockwise);
    expect(result.outcome, MovingPlatformMoveOutcome.blocked);
    expect(result.finalWorldState, fixture.state);
    expect(identical(result.finalWorld, before), true);
    expect(result.frames, isEmpty);
  });

  test('translation is bounded before allocating animation frames', () {
    expect(() => MovingPlatformFixture(distance: 40), throwsFormatException);
    final fixture = MovingPlatformFixture();
    final json = fixture.definition.toJson()..['translationDistanceCells'] = 40;
    final map = fixture.map
        .copyWith(movingPlatforms: [MovingPlatformDefinition.fromJson(json)]);
    expect(() => fixture.world(map: map), throwsFormatException);
    expect(
        () => validateMovingPlatformDefinitions(
            map: map,
            project: fixture.project,
            tileSize: const PixelSize(width: 32, height: 32)),
        throwsFormatException);
  });
}
