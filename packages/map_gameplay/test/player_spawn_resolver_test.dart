import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

MapData _mapWithSpawn({EntityFacing? facing}) => MapData(
      id: 'room',
      name: 'Room',
      size: const GridSize(width: 8, height: 8),
      entities: [
        MapEntity(
          id: 'start',
          kind: MapEntityKind.spawn,
          pos: const GridPos(x: 3, y: 2),
          spawn: facing == null
              ? const MapEntitySpawnData()
              : MapEntitySpawnData(facing: facing),
          blocksMovement: false,
        ),
      ],
    );

void main() {
  test('non-square tiles place the sprite and feet from the authored cell', () {
    final player = resolveInitialPlayerSpawn(
      _mapWithSpawn(facing: EntityFacing.east),
      preferredSpawnId: 'start',
      tileWidthPx: 24,
      tileHeightPx: 32,
    );

    expect(player.playerPositionPx.leftPx, 68);
    expect(player.playerPositionPx.topPx, 64);
    expect(player.pos, const GridPos(x: 3, y: 2));
    expect(player.facing, Direction.east);
    expect(player.movementMode, MovementMode.walk);
    expect(player.playerSpriteWidthPx, 32);
    expect(player.playerSpriteHeightPx, 32);
  });

  test('invalid tile sizes fall back to sixteen pixels and default facing', () {
    final player = resolveInitialPlayerSpawn(
      _mapWithSpawn(),
      tileWidthPx: 0,
      tileHeightPx: -4,
    );

    expect(player.playerPositionPx.leftPx, 40);
    expect(player.playerPositionPx.topPx, 16);
    expect(player.pos, const GridPos(x: 3, y: 2));
    expect(player.facing, Direction.south);
  });
}
