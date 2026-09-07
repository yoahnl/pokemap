import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  test('default 2x2 NPC blocks feet while head and side margins stay free', () {
    final map = MapData(
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 12, height: 12),
      layers: const <MapLayer>[
        MapLayer.collision(
          id: 'collision',
          name: 'Collision',
          collisions: <bool>[],
        ),
      ],
      entities: const <MapEntity>[
        MapEntity(
          id: 'emma',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 5, y: 5),
          size: GridSize(width: 2, height: 2),
          npc: MapEntityNpcData(),
        ),
      ],
    );

    final world = GameplayWorldState.initial(
      map: map,
      playerPos: const GridPos(x: 0, y: 0),
    );

    expect(
      world.worldStaticObstaclesCollidePixelRect(
        const PixelRect(leftPx: 85, topPx: 82, widthPx: 12, heightPx: 8),
      ),
      isFalse,
      reason: 'The player can pass behind the NPC above its feet',
    );

    for (final point in [
      const PixelPoint(xPx: 89, yPx: 108),
      const PixelPoint(xPx: 102, yPx: 108),
      const PixelPoint(xPx: 95, yPx: 103),
      const PixelPoint(xPx: 95, yPx: 112),
    ]) {
      expect(
        world.worldStaticObstaclesCollidePixelRect(PixelRect(
          leftPx: point.xPx,
          topPx: point.yPx,
          widthPx: 1,
          heightPx: 1,
        )),
        isFalse,
      );
    }
    expect(
      world.worldStaticObstaclesCollidePixelRect(
        const PixelRect(leftPx: 90, topPx: 104, widthPx: 12, heightPx: 8),
      ),
      isTrue,
    );
    expect(world.entityAt(5, 6)?.id, 'emma');
    expect(world.entityAt(6, 6)?.id, 'emma');
    expect(world.entityAt(5, 5), isNull);
    for (final (cell, facing) in [
      (const GridPos(x: 4, y: 6), Direction.east),
      (const GridPos(x: 7, y: 6), Direction.west),
      (const GridPos(x: 5, y: 5), Direction.south),
      (const GridPos(x: 5, y: 7), Direction.north),
    ]) {
      final adjacent = GameplayWorldState.initial(
        map: map,
        playerPos: cell,
        playerFacing: facing,
      );
      expect(
        stepGameplayWorld(adjacent, const InteractIntent()),
        isA<NpcInteracted>(),
      );
    }
    final behind = GameplayWorldState.initial(
      map: map,
      playerPos: const GridPos(x: 4, y: 5),
      playerFacing: Direction.east,
    );
    expect(stepGameplayWorld(behind, const MoveIntent(Direction.east)),
        isA<Moved>());
    final below = GameplayWorldState.initial(
      map: map,
      playerPos: const GridPos(x: 5, y: 7),
      playerFacing: Direction.north,
    );
    final stopped = stepGameplayWorld(below, const MoveIntent(Direction.north));
    expect(stopped.world.player.playerPositionPx.topPx,
        below.player.playerPositionPx.topPx);
    final movedNpc =
        world.withEntityPosition('emma', const GridPos(x: 8, y: 5));
    expect(
        movedNpc.worldStaticObstaclesCollidePixelRect(
          const PixelRect(leftPx: 90, topPx: 104, widthPx: 12, heightPx: 8),
        ),
        isFalse);
    expect(
        movedNpc.worldStaticObstaclesCollidePixelRect(
          const PixelRect(leftPx: 138, topPx: 104, widthPx: 12, heightPx: 8),
        ),
        isTrue);
    expect(world.isCellCenterBlockedLegacyForGridIndexedSystems(5, 5), isFalse);
    expect(world.isCellCenterBlockedLegacyForGridIndexedSystems(6, 5), isFalse);
    expect(world.isCellCenterBlockedLegacyForGridIndexedSystems(5, 6), isTrue);
    expect(world.isCellCenterBlockedLegacyForGridIndexedSystems(6, 6), isTrue);

    expect(world.isCellCenterBlockedLegacyForGridIndexedSystems(4, 5), isFalse);
    expect(world.isCellCenterBlockedLegacyForGridIndexedSystems(7, 5), isFalse);
    expect(world.isCellCenterBlockedLegacyForGridIndexedSystems(5, 4), isFalse);
    expect(world.isCellCenterBlockedLegacyForGridIndexedSystems(5, 7), isFalse);
  });
}
