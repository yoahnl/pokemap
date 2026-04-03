import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  test('withEntityPosition updates collision/entity caches consistently', () {
    final map = MapData(
      id: 'm_test',
      name: 'Test',
      size: const GridSize(width: 6, height: 6),
      entities: const <MapEntity>[
        MapEntity(
          id: 'npc_1',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 1, y: 1),
          npc: MapEntityNpcData(),
          blocksMovement: true,
        ),
      ],
    );

    final initial = GameplayWorldState.initial(
      map: map,
      playerPos: const GridPos(x: 0, y: 0),
    );
    expect(initial.isBlocked(1, 1), isTrue);
    expect(initial.isBlocked(3, 1), isFalse);

    final moved =
        initial.withEntityPosition('npc_1', const GridPos(x: 3, y: 1));
    expect(moved.isBlocked(1, 1), isFalse);
    expect(moved.isBlocked(3, 1), isTrue);
    expect(moved.entityAt(3, 1)?.id, 'npc_1');
    expect(moved.entityAt(1, 1), isNull);
  });
}
