import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  group('checkLineOfSight', () {
    // Helper pour créer un GameplayWorldState de test
    GameplayWorldState _createWorld({
      required MapData map,
      GridPos playerPos = const GridPos(x: 5, y: 5),
    }) {
      return GameplayWorldState.initial(
        map: map,
        playerPos: playerPos,
      );
    }

    test('joueur dans axe + distance valide + pas d\'obstacle → true', () {
      final map = MapData(
        id: 'test',
        name: 'Test',
        size: const GridSize(width: 10, height: 10),
      );
      final world = _createWorld(
        map: map,
        playerPos: const GridPos(x: 5, y: 2),  // 3 cases au nord
      );

      final result = checkLineOfSight(
        npcPos: const GridPos(x: 5, y: 5),
        npcFacing: EntityFacing.north,
        lineOfSightRange: 5,
        playerPos: const GridPos(x: 5, y: 2),
        world: world,
      );

      expect(result, isTrue);
    });

    test('joueur hors axe → false', () {
      final map = MapData(
        id: 'test',
        name: 'Test',
        size: const GridSize(width: 10, height: 10),
      );
      final world = _createWorld(
        map: map,
        playerPos: const GridPos(x: 6, y: 2),  // Décalé d'une case
      );

      final result = checkLineOfSight(
        npcPos: const GridPos(x: 5, y: 5),
        npcFacing: EntityFacing.north,
        lineOfSightRange: 5,
        playerPos: const GridPos(x: 6, y: 2),
        world: world,
      );

      expect(result, isFalse);
    });

    test('distance > lineOfSightRange → false', () {
      final map = MapData(
        id: 'test',
        name: 'Test',
        size: const GridSize(width: 10, height: 10),
      );
      final world = _createWorld(
        map: map,
        playerPos: const GridPos(x: 5, y: 0),  // 5 cases (distance > 3)
      );

      final result = checkLineOfSight(
        npcPos: const GridPos(x: 5, y: 5),
        npcFacing: EntityFacing.north,
        lineOfSightRange: 3,  // Trop court
        playerPos: const GridPos(x: 5, y: 0),
        world: world,
      );

      expect(result, isFalse);
    });

    test('obstacle entre NPC et joueur → false', () {
      // Map avec collision layer : case (5, 3) = index 35 bloquante (entre NPC à (5,5) et joueur à (5,2))
      final map = MapData(
        id: 'test',
        name: 'Test',
        size: const GridSize(width: 10, height: 10),
        layers: [
          const MapLayer.tile(
            id: 'terrain',
            name: 'Terrain',
            tilesetId: 'ts',
            tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
          ),
          MapLayer.collision(
            id: 'collision',
            name: 'Collision',
            collisions: List.generate(100, (i) => i == 35),  // Index 35 = (5, 3)
          ),
        ],
      );
      final world = _createWorld(
        map: map,
        playerPos: const GridPos(x: 5, y: 2),
      );

      final result = checkLineOfSight(
        npcPos: const GridPos(x: 5, y: 5),
        npcFacing: EntityFacing.north,
        lineOfSightRange: 5,
        playerPos: const GridPos(x: 5, y: 2),
        world: world,
      );

      expect(result, isFalse);
    });

    test('joueur adjacent → true (pas d\'obstacle testé)', () {
      final map = MapData(
        id: 'test',
        name: 'Test',
        size: const GridSize(width: 10, height: 10),
      );
      final world = _createWorld(
        map: map,
        playerPos: const GridPos(x: 5, y: 4),  // Adjacent (1 case)
      );

      final result = checkLineOfSight(
        npcPos: const GridPos(x: 5, y: 5),
        npcFacing: EntityFacing.north,
        lineOfSightRange: 5,
        playerPos: const GridPos(x: 5, y: 4),
        world: world,
      );

      expect(result, isTrue);
    });

    test('lineOfSightRange = 0 → false', () {
      final map = MapData(
        id: 'test',
        name: 'Test',
        size: const GridSize(width: 10, height: 10),
      );
      final world = _createWorld(
        map: map,
        playerPos: const GridPos(x: 5, y: 4),
      );

      final result = checkLineOfSight(
        npcPos: const GridPos(x: 5, y: 5),
        npcFacing: EntityFacing.north,
        lineOfSightRange: 0,  // Désactivé
        playerPos: const GridPos(x: 5, y: 4),
        world: world,
      );

      expect(result, isFalse);
    });

    test('joueur dans mauvais sens → false', () {
      final map = MapData(
        id: 'test',
        name: 'Test',
        size: const GridSize(width: 10, height: 10),
      );
      final world = _createWorld(
        map: map,
        playerPos: const GridPos(x: 5, y: 6),  // Au SUD du NPC (qui regarde au NORD)
      );

      final result = checkLineOfSight(
        npcPos: const GridPos(x: 5, y: 5),
        npcFacing: EntityFacing.north,
        lineOfSightRange: 5,
        playerPos: const GridPos(x: 5, y: 6),
        world: world,
      );

      expect(result, isFalse);
    });

    test('joueur à l\'est → true avec facing east', () {
      final map = MapData(
        id: 'test',
        name: 'Test',
        size: const GridSize(width: 10, height: 10),
      );
      final world = _createWorld(
        map: map,
        playerPos: const GridPos(x: 8, y: 5),
      );

      final result = checkLineOfSight(
        npcPos: const GridPos(x: 5, y: 5),
        npcFacing: EntityFacing.east,
        lineOfSightRange: 5,
        playerPos: const GridPos(x: 8, y: 5),
        world: world,
      );

      expect(result, isTrue);
    });

    test('joueur à l\'ouest → true avec facing west', () {
      final map = MapData(
        id: 'test',
        name: 'Test',
        size: const GridSize(width: 10, height: 10),
      );
      final world = _createWorld(
        map: map,
        playerPos: const GridPos(x: 2, y: 5),
      );

      final result = checkLineOfSight(
        npcPos: const GridPos(x: 5, y: 5),
        npcFacing: EntityFacing.west,
        lineOfSightRange: 5,
        playerPos: const GridPos(x: 2, y: 5),
        world: world,
      );

      expect(result, isTrue);
    });

    test('joueur au sud → true avec facing south', () {
      final map = MapData(
        id: 'test',
        name: 'Test',
        size: const GridSize(width: 10, height: 10),
      );
      final world = _createWorld(
        map: map,
        playerPos: const GridPos(x: 5, y: 8),
      );

      final result = checkLineOfSight(
        npcPos: const GridPos(x: 5, y: 5),
        npcFacing: EntityFacing.south,
        lineOfSightRange: 5,
        playerPos: const GridPos(x: 5, y: 8),
        world: world,
      );

      expect(result, isTrue);
    });
  });
}
