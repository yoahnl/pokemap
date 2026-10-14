import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  test(
      'actor facing updates every authoritative reader without moving or dropping collision',
      () {
    final before = _world();
    final after = before.withEntityFacing('actor', EntityFacing.north);
    expect(after.map.entities.first.npc!.facing, EntityFacing.north);
    expect(after.entityAt(2, 2)!.npc!.facing, EntityFacing.north);
    expect(after.entityAt(2, 2)!.pos, const GridPos(x: 2, y: 2));
    expect(after.map.entities.last, before.map.entities.last);
    expect(after.isBlocked(2, 2), isTrue);
    expect(before.entityAt(2, 2)!.npc!.facing, EntityFacing.south);
    expect(after.player, same(before.player));
    expect(after.withEntityFacing('actor', EntityFacing.north), same(after));
  });

  test('actor facing refreshes a facing-dependent presence predicate', () {
    final before = _world().withNpcMapPresencePredicate(
        (_, entity) => entity.npc?.facing == EntityFacing.north);
    expect(before.entityAt(2, 2), isNull);
    final after = before.withEntityFacing('actor', EntityFacing.north);
    expect(after.entityAt(2, 2)!.npc!.facing, EntityFacing.north);
    expect(after.isBlocked(2, 2), isTrue);
    expect(before.entityAt(2, 2), isNull);
  });

  for (final entities in <List<MapEntity>>[
    [],
    [_actor, _actor],
    [_actor.copyWith(kind: MapEntityKind.custom)],
    [_actor.copyWith(npc: null)],
  ]) {
    test(
        'actor facing refuses invalid or ambiguous identity ${entities.length}/${entities.firstOrNull?.kind}',
        () {
      expect(
          () => _world(entities: entities)
              .withEntityFacing('actor', EntityFacing.north),
          throwsStateError);
    });
  }
}

const _actor = MapEntity(
    id: 'actor',
    kind: MapEntityKind.npc,
    pos: GridPos(x: 2, y: 2),
    npc: MapEntityNpcData());
GameplayWorldState _world({List<MapEntity>? entities}) =>
    GameplayWorldState.initial(
      map: MapData(
          id: 'map',
          name: 'Facing',
          size: const GridSize(width: 6, height: 6),
          entities: entities ??
              [
                _actor,
                _actor.copyWith(id: 'other', pos: const GridPos(x: 1, y: 1))
              ]),
      project: const ProjectManifest(name: 'Facing', maps: [], tilesets: []),
      playerPos: const GridPos(x: 4, y: 4),
      tileWidth: 16,
      tileHeight: 16,
    );
