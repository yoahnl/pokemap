import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

SpatialMovementController player(
        {List<SpatialBlockedArea> obstacles = const []}) =>
    SpatialMovementController(
        scene: MapSpatialScene(
            width: 8,
            depth: 8,
            navigation: SpatialNavigationProfile(
                spawn: SpatialSpawn(x: 4.5, z: 4.5), blockedAreas: obstacles)),
        models: []);

void walk(SpatialMovementController movement, int x, int z) {
  movement.setInput(x: x, z: z);
  for (var i = 0; i < 100; i++) {
    movement.update(.05);
  }
}

void main() {
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
