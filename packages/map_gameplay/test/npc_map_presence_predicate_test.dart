import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

MapData _mapEmma1x1() {
  return MapData(
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
        size: GridSize(width: 1, height: 1),
        npc: MapEntityNpcData(),
      ),
    ],
  );
}

void main() {
  test('PNJ absent des caches spatiaux quand le prédicat retourne false', () {
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

    final hidden = GameplayWorldState.initial(
      map: map,
      playerPos: const GridPos(x: 0, y: 0),
      npcMapPresencePredicate: (_, __) => false,
    );

    expect(hidden.isBlocked(5, 5), isFalse);
    expect(hidden.entityAt(5, 5), isNull);

    final visible = hidden.withNpcMapPresencePredicate((_, __) => true);
    expect(visible.isBlocked(5, 5), isTrue);
    expect(visible.entityAt(5, 5)?.id, 'emma');
  });

  test('MoveIntent : case PNJ franchissable si prédicat retire le PNJ', () {
    final world = GameplayWorldState.initial(
      map: _mapEmma1x1(),
      playerPos: const GridPos(x: 4, y: 5),
      playerFacing: Direction.east,
      npcMapPresencePredicate: (_, e) => e.id != 'emma',
    );
    final r = stepGameplayWorld(world, const MoveIntent(Direction.east));
    expect(r, isA<Moved>());
    expect(r.world.player.pos, const GridPos(x: 5, y: 5));
  });

  test('InteractIntent : pas de NpcInteracted si le PNJ est retiré du prédicat', () {
    final world = GameplayWorldState.initial(
      map: _mapEmma1x1(),
      playerPos: const GridPos(x: 4, y: 5),
      playerFacing: Direction.east,
      npcMapPresencePredicate: (_, e) => e.id != 'emma',
    );
    final r = stepGameplayWorld(world, const InteractIntent());
    expect(r, isA<NothingToInteract>());
  });

  test('Réapparition : withNpcMapPresencePredicate réactive blocage + interaction', () {
    final hidden = GameplayWorldState.initial(
      map: _mapEmma1x1(),
      playerPos: const GridPos(x: 4, y: 5),
      playerFacing: Direction.east,
      npcMapPresencePredicate: (_, e) => e.id != 'emma',
    );
    expect(
      stepGameplayWorld(hidden, const InteractIntent()),
      isA<NothingToInteract>(),
    );
    final shown = hidden.withNpcMapPresencePredicate((_, __) => true);
    final interact = stepGameplayWorld(shown, const InteractIntent());
    expect(interact, isA<NpcInteracted>());
    expect((interact as NpcInteracted).entity.id, 'emma');
  });
}
