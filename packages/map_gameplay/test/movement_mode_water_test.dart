import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  group('movement mode water traversal', () {
    test('walking can move on regular ground', () {
      final world = GameplayWorldState.initial(
        map: _baseMap(
          includeWaterPath: false,
          includeCollisionAtTarget: false,
        ),
        playerPos: const GridPos(x: 0, y: 0),
        project: _projectWithWaterPreset(),
      );

      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));
      expect(result, isA<Moved>());
      expect(result.world.player.pos, const GridPos(x: 1, y: 0));
    });

    test('walking is blocked on water path cells with explicit reason', () {
      final world = GameplayWorldState.initial(
        map: _baseMap(
          includeWaterPath: true,
          includeCollisionAtTarget: false,
        ),
        playerPos: const GridPos(x: 0, y: 0),
        project: _projectWithWaterPreset(),
      );

      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));
      expect(result, isA<Blocked>());
      final blocked = result as Blocked;
      expect(blocked.reason, GameplayMovementBlockReason.waterRequiresSurf);
      expect(blocked.world.player.pos, const GridPos(x: 0, y: 0));
    });

    test('surfing can move on water path cells', () {
      final world = GameplayWorldState.initial(
        map: _baseMap(
          includeWaterPath: true,
          includeCollisionAtTarget: false,
        ),
        playerPos: const GridPos(x: 0, y: 0),
        playerMovementMode: MovementMode.surf,
        project: _projectWithWaterPreset(),
      );

      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));
      expect(result, isA<Moved>());
      expect(result.world.player.pos, const GridPos(x: 1, y: 0));
    });

    test('solid collisions still block movement while surfing', () {
      final world = GameplayWorldState.initial(
        map: _baseMap(
          includeWaterPath: true,
          includeCollisionAtTarget: true,
        ),
        playerPos: const GridPos(x: 0, y: 0),
        playerMovementMode: MovementMode.surf,
        project: _projectWithWaterPreset(),
      );

      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));
      expect(result, isA<Blocked>());
      final blocked = result as Blocked;
      expect(blocked.reason, GameplayMovementBlockReason.solid);
      expect(blocked.world.player.pos, const GridPos(x: 0, y: 0));
    });

    test('movement zone requiring surf is treated as water for walking mode',
        () {
      final map = _baseMap(
        includeWaterPath: false,
        includeCollisionAtTarget: false,
      ).copyWith(
        gameplayZones: const [
          MapGameplayZone(
            id: 'surf_zone',
            kind: GameplayZoneKind.movement,
            area: MapRect(
                pos: GridPos(x: 1, y: 0), size: GridSize(width: 1, height: 1)),
            movement: MovementZonePayload(requiredMode: MovementMode.surf),
          ),
        ],
      );
      final world = GameplayWorldState.initial(
        map: map,
        playerPos: const GridPos(x: 0, y: 0),
        project: _projectWithWaterPreset(),
      );

      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));
      expect(result, isA<Blocked>());
      final blocked = result as Blocked;
      expect(blocked.reason, GameplayMovementBlockReason.waterRequiresSurf);
    });
  });
}

MapData _baseMap({
  required bool includeWaterPath,
  required bool includeCollisionAtTarget,
}) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 3, height: 1),
    layers: [
      const MapLayer.tile(
        id: 'tile',
        name: 'Tile',
        tiles: [0, 0, 0],
      ),
      MapLayer.path(
        id: 'path',
        name: 'Path',
        presetId: 'water_path',
        cells: includeWaterPath
            ? const [false, true, false]
            : const [false, false, false],
      ),
      MapLayer.collision(
        id: 'collision',
        name: 'Collision',
        collisions: includeCollisionAtTarget
            ? const [false, true, false]
            : const [false, false, false],
      ),
    ],
  );
}

ProjectManifest _projectWithWaterPreset() {
  return const ProjectManifest(
    name: 'project',
    maps: [],
    tilesets: [
      ProjectTilesetEntry(
          id: 'ts', name: 'Tileset', relativePath: 'tileset.png'),
    ],
    pathPresets: [
      ProjectPathPreset(
        id: 'water_path',
        name: 'Water',
        surfaceKind: PathSurfaceKind.water,
        tilesetId: 'ts',
      ),
    ],
  );
}
