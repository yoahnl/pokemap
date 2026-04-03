import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  test('default 2x2 NPC blocks its full footprint in gameplay world', () {
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

    // Footprint complet attendu: (5,5) (6,5) (5,6) (6,6).
    expect(world.isBlocked(5, 5), isTrue);
    expect(world.isBlocked(6, 5), isTrue);
    expect(world.isBlocked(5, 6), isTrue);
    expect(world.isBlocked(6, 6), isTrue);

    // Les cellules voisines restent libres.
    expect(world.isBlocked(4, 5), isFalse);
    expect(world.isBlocked(7, 5), isFalse);
    expect(world.isBlocked(5, 4), isFalse);
    expect(world.isBlocked(5, 7), isFalse);
  });
}
