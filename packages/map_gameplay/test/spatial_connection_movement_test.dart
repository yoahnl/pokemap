import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

SpatialMovementController player(
        {List<SpatialBlockedArea> obstacles = const [], double spawnZ = 4.5}) =>
    SpatialMovementController(
        scene: MapSpatialScene(
            width: 8,
            depth: 8,
            navigation: SpatialNavigationProfile(
                spawn: SpatialSpawn(x: 4.5, z: spawnZ),
                blockedAreas: obstacles)),
        models: []);

void walk(SpatialMovementController movement, int x, int z) {
  movement.setInput(x: x, z: z);
  for (var i = 0; i < 100; i++) {
    movement.update(.05);
  }
}

void main() {
  test('configured connections wait at an unprepared edge without losing input',
      () {
    final source = player();
    source.setConnectedNeighbors({}, waitForReady: true);
    walk(source, 1, 0);
    expect(source.edgeExitDirection, isNull);
    final epoch = source.inputEpoch;
    final target = player();
    source.setConnectedNeighbors({
      MapConnectionDirection.east:
          SpatialMovementNeighbor(controller: target, offsetX: 8, offsetZ: 0)
    });
    for (var i = 0; i < 20 && source.connectionArrival == null; i++) {
      source.update(.05);
    }
    expect(source.connectionArrival, isNotNull);
    target.adoptConnectionMotion(source);
    expect(target.inputEpoch, epoch);
    expect(target.moving, isTrue);
  });
  test(
      'an exact saved edge position becomes traversable after neighbor linking',
      () {
    final map = MapData(
        version: ProjectVersion.v9,
        id: 'edge',
        name: 'Edge',
        size: const GridSize(width: 8, height: 8),
        spatialScene: MapSpatialScene(
            width: 8,
            depth: 8,
            navigation:
                SpatialNavigationProfile(spawn: SpatialSpawn(x: 4.5, z: 4.5))));
    final saved = PlayerSpatialPosition.fromJson(
        PlayerSpatialPosition(x: .125, z: 3.8125).toJson());
    final restored = SpatialMovementController.fromMap(
        map: map, models: [], spatialArrival: saved, validateSpawn: false);
    expect(restored.isPositionTraversable, isFalse);
    restored.setConnectedNeighbors({
      MapConnectionDirection.west:
          SpatialMovementNeighbor(controller: player(), offsetX: -8, offsetZ: 0)
    });
    expect(restored.isPositionTraversable, isTrue);
    expect(restored.spatialPosition, saved);
    restored.setConnectedNeighbors({
      MapConnectionDirection.west: SpatialMovementNeighbor(
          controller: player(
              obstacles: [SpatialBlockedArea(x: 7, z: 0, width: 1, depth: 8)]),
          offsetX: -8,
          offsetZ: 0)
    });
    expect(restored.isPositionTraversable, isFalse);
    expect(restored.spatialPosition, saved);
  });
  for (final direction in MapConnectionDirection.values) {
    for (final run in [false, true]) {
      test('continuous ${direction.name} raccord and reversal, run=$run', () {
        final source = player();
        final target = player();
        final dx = direction == MapConnectionDirection.east
            ? 1
            : direction == MapConnectionDirection.west
                ? -1
                : 0;
        final dz = direction == MapConnectionDirection.south
            ? 1
            : direction == MapConnectionDirection.north
                ? -1
                : 0;
        final ox = dx == 0 ? 1.0 : dx * 8.0;
        final oz = dz == 0 ? -1.0 : dz * 8.0;
        source.setConnectedNeighbors({
          direction: SpatialMovementNeighbor(
              controller: target, offsetX: ox, offsetZ: oz)
        });
        source.setInput(x: dx, z: dz, run: run);
        var ticks = 0;
        while (source.connectionArrival == null && ticks < 100) {
          source.update(.05);
          ticks++;
        }
        expect(source.connectionArrival, isNotNull);
        final expectedDistance =
            (ticks * .05 * (run ? 6 : 3) * 16).floor() / 16;
        target.adoptConnectionMotion(source);
        expect(target.x + ox, closeTo(4.5 + dx * expectedDistance, .0625));
        expect(target.z + oz, closeTo(4.5 + dz * expectedDistance, .0625));
        expect(target.running, run);
        expect(target.animationSeconds, source.animationSeconds);
        expect(target.inputEpoch, source.inputEpoch);
        target.setInput(x: -dx, z: -dz, run: run);
        for (var i = 0; i < 10 && target.connectionArrival == null; i++) {
          target.update(.05);
        }
        expect(target.connectionArrival, isNotNull);
        final arrival = target.connectionArrival!;
        source.adoptConnectionMotion(target);
        expect(source.spatialPosition, arrival);
        expect(source.running, run);
      });
    }
  }

  for (final obstacle in ['paint', 'npc', 'cliff', 'model']) {
    test('prepared target $obstacle blocks the footprint before the seam', () {
      final source = player();
      final target = SpatialMovementController.fromMap(
          map: MapData(
              version: ProjectVersion.v9,
              id: 'target',
              name: 'Target',
              size: const GridSize(width: 8, height: 8),
              spatialScene: MapSpatialScene(
                  width: 8,
                  depth: 8,
                  heightLevels: List.filled(64, obstacle == 'cliff' ? 2 : 0),
                  navigation: SpatialNavigationProfile(
                      spawn: SpatialSpawn(x: 4.5, z: 4.5)),
                  instances: [
                    if (obstacle == 'model')
                      SpatialModelInstance(
                          id: 'wall',
                          modelId: 'wall',
                          position: Model3dVector3(x: .5, y: 0, z: 4.5))
                  ]),
              layers: [
                CollisionLayer(id: 'solid', name: 'Solid', collisions: [
                  for (var i = 0; i < 64; i++) obstacle == 'paint' && i % 8 == 0
                ])
              ],
              entities: [
                if (obstacle == 'npc')
                  const MapEntity(
                      id: 'guard',
                      kind: MapEntityKind.npc,
                      pos: GridPos(x: 0, y: 4),
                      blocksMovement: true,
                      npc: MapEntityNpcData(characterId: 'hero'))
              ]),
          models: [
            ProjectModel3dEntry(
                id: 'wall',
                name: 'Wall',
                sourceAssetId: 'wall',
                relativePath: 'assets/models3d/wall.glb',
                inspection: Model3dInspection(
                    bounds: Model3dBounds(
                        min: Model3dVector3(x: -.5, y: 0, z: -.5),
                        max: Model3dVector3(x: .5, y: 2, z: .5)),
                    meshCount: 1,
                    triangleCount: 1))
          ]);
      source.setConnectedNeighbors({
        MapConnectionDirection.east:
            SpatialMovementNeighbor(controller: target, offsetX: 8, offsetZ: 0)
      });
      walk(source, 1, 0);
      expect(source.connectionArrival, isNull);
      expect(source.edgeExitDirection, isNull);
      expect(source.x, lessThanOrEqualTo(obstacle == 'npc' ? 7.75 : 7.625));
    });
  }

  test('a partial connection never opens the uncovered part of an edge', () {
    final source = player();
    source.setConnectedNeighbors({
      MapConnectionDirection.east:
          SpatialMovementNeighbor(controller: player(), offsetX: 8, offsetZ: 5)
    });
    walk(source, 1, 0);
    expect(source.connectionArrival, isNull);
    expect(source.x, lessThanOrEqualTo(7.625));
  });

  test('diagonal movement crosses a covered seam without losing either axis',
      () {
    final source = player(spawnZ: 2.5);
    final target = player();
    source.setConnectedNeighbors({
      MapConnectionDirection.east:
          SpatialMovementNeighbor(controller: target, offsetX: 8, offsetZ: 0)
    });
    source.setDiagonalMovement(true);
    source.setInput(x: 1, z: 1, run: true);
    for (var i = 0; i < 100 && source.connectionArrival == null; i++) {
      source.update(.05);
    }
    expect(source.connectionArrival, isNotNull);
    target.adoptConnectionMotion(source);
    expect(target.x + 8, target.z + 2);
    expect(target.allowDiagonalMovement, isTrue);
    expect(target.running, isTrue);
  });

  test('pause clears preserved held input after a connection', () {
    final source = player();
    final target = player();
    source.setConnectedNeighbors({
      MapConnectionDirection.east:
          SpatialMovementNeighbor(controller: target, offsetX: 8, offsetZ: 0)
    });
    source.setInput(x: 1, z: 0, run: true);
    for (var i = 0; i < 100 && source.connectionArrival == null; i++) {
      source.update(.05);
    }
    target.adoptConnectionMotion(source);
    target.setPaused(false);
    expect(target.running, isTrue);
    target.setPaused(true);
    target.setPaused(false);
    final position = target.spatialPosition;
    target.update(.05);
    expect(target.spatialPosition, position);
    expect(target.moving, isFalse);
    expect(target.animationSeconds, 0);
  });
  test('a connected exit keeps the complete travel distance of its tick', () {
    final movement = player();
    final next = player();
    movement.setConnectedNeighbors({
      MapConnectionDirection.east:
          SpatialMovementNeighbor(controller: next, offsetX: 8, offsetZ: 0),
    });
    movement.setInput(x: 1, z: 0, run: true);
    var elapsed = 0.0;
    while (movement.edgeExitDirection == null && elapsed < 2) {
      movement.update(.05);
      elapsed += .05;
    }
    expect(movement.connectionArrival, isNotNull);
    expect(movement.spatialPosition.x, lessThan(8));
    next.adoptConnectionMotion(movement);
    expect(next.x + 8, closeTo(4.5 + elapsed * 6, .0625));
    expect(next.running, isTrue);
    expect(next.animationSeconds, elapsed);
    expect(next.inputEpoch, movement.inputEpoch);
    final before = next.x;
    next.update(.05);
    expect(next.x - before, closeTo(.3, .0625));
  });
  for (final direction in MapConnectionDirection.values) {
    test('signals an attempted exit through a free ${direction.name} edge', () {
      final movement = player();
      final dx = direction == MapConnectionDirection.east
          ? 1
          : direction == MapConnectionDirection.west
              ? -1
              : 0;
      final dz = direction == MapConnectionDirection.south
          ? 1
          : direction == MapConnectionDirection.north
              ? -1
              : 0;
      walk(movement, dx, dz);
      expect(movement.edgeExitDirection, direction);
      expect(movement.x, inExclusiveRange(0, 8));
      expect(movement.z, inExclusiveRange(0, 8));
      movement.releaseInput();
      movement.update(.05);
      expect(movement.edgeExitDirection, isNull);
    });
  }

  test('an obstacle in front of the edge cannot become an exit attempt', () {
    final movement =
        player(obstacles: [SpatialBlockedArea(x: 6, z: 0, width: 2, depth: 8)]);
    walk(movement, 1, 0);
    expect(movement.edgeExitDirection, isNull);
    expect(movement.x, lessThan(6));
  });

  test('diagonal sliding against an edge cannot trigger a connection', () {
    final movement = player();
    movement.setDiagonalMovement(true);
    walk(movement, 1, 1);
    expect(movement.edgeExitDirection, isNull);
  });

  for (final z in [-1, 1]) {
    test('disabled diagonals retain the resolved cardinal edge for z=$z', () {
      final movement = player();
      walk(movement, 1, z);
      expect(movement.x, 4.5);
      expect(movement.edgeExitDirection,
          z < 0 ? MapConnectionDirection.north : MapConnectionDirection.south);
    });
  }

  for (final obstacle in ['paint', 'npc', 'cliff']) {
    test('$obstacle on the edge prevents a connection attempt', () {
      final scene = MapSpatialScene(
          width: 8,
          depth: 8,
          heightLevels: [
            for (var i = 0; i < 64; i++)
              obstacle == 'cliff' && i % 8 == 7 ? 2 : 0
          ],
          navigation:
              SpatialNavigationProfile(spawn: SpatialSpawn(x: 4.5, z: 4.5)));
      final map = MapData(
          version: ProjectVersion.v9,
          id: 'edge',
          name: 'Edge',
          size: const GridSize(width: 8, height: 8),
          spatialScene: scene,
          layers: [
            CollisionLayer(id: 'solid', name: 'Solid', collisions: [
              for (var i = 0; i < 64; i++) obstacle == 'paint' && i % 8 == 7
            ])
          ],
          entities: [
            if (obstacle == 'npc')
              const MapEntity(
                  id: 'guard',
                  kind: MapEntityKind.npc,
                  pos: GridPos(x: 7, y: 4),
                  blocksMovement: true,
                  npc: MapEntityNpcData(characterId: 'hero'))
          ]);
      final movement = SpatialMovementController.fromMap(map: map, models: []);
      walk(movement, 1, 0);
      expect(movement.edgeExitDirection, isNull);
      expect(movement.x, lessThan(7));
    });
  }
}
