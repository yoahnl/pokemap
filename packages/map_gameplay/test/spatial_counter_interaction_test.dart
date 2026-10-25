import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  for (final facing in EntityFacing.values) {
    test('counter reaches exactly one extra cell facing ${facing.name}', () {
      final (dx, dz, side) = switch (facing) {
        EntityFacing.north => (0, -1, EntityFacing.south),
        EntityFacing.south => (0, 1, EntityFacing.north),
        EntityFacing.east => (1, 0, EntityFacing.west),
        EntityFacing.west => (-1, 0, EntityFacing.east),
      };
      final target = npc(4 + 2 * dx, 4 + 2 * dz, sides: [side]);
      final scene = field([
        SpatialBlockedArea(
            x: (4 + dx).toDouble(), z: (4 + dz).toDouble(), width: 1, depth: 1)
      ]);
      expect(
          findSpatialEntityInteraction(
                  scene: scene,
                  entities: [target],
                  x: 4.5,
                  z: 4.5,
                  facing: facing)
              ?.id,
          target.id);
    });
  }
  test('wall without an authored counter side stays opaque', () {
    expect(reach(npc(4, 4)), isNull);
    expect(reach(npc(4, 4, sides: [EntityFacing.west])), isNull);
  });
  test('counter requires a blocking intermediate cell', () {
    expect(
        reach(npc(4, 4, sides: [EntityFacing.east]), scene: field([])), isNull);
  });
  test('counter never crosses a second blocked cell or a height tier', () {
    final target = npc(4, 4, sides: [EntityFacing.east]);
    expect(
        reach(target,
            scene: field([SpatialBlockedArea(x: 4, z: 4, width: 2, depth: 1)])),
        isNull);
    expect(
        reach(target,
            scene: field([SpatialBlockedArea(x: 5, z: 4, width: 1, depth: 1)],
                raised: true)),
        isNull);
  });
  test('adjacent target wins before a counter target', () {
    final target = npc(4, 4, sides: [EntityFacing.east]);
    final front = MapEntity(
        id: 'front', kind: MapEntityKind.sign, pos: GridPos(x: 5, y: 4));
    expect(
        findSpatialEntityInteraction(
                scene:
                    field([SpatialBlockedArea(x: 5, z: 4, width: 1, depth: 1)]),
                entities: [target, front],
                x: 6.5,
                z: 4.5,
                facing: EntityFacing.west)
            ?.id,
        'front');
  });
  test('physical counter can provide its blocker without opening a second wall',
      () {
    final target = npc(4, 4, sides: [EntityFacing.east]);
    MapEntity? query(bool wall) => findSpatialEntityInteraction(
        scene: field([]),
        entities: [target],
        x: 6.5,
        z: 4.5,
        facing: EntityFacing.west,
        isPositionBlocked: (x, z, ignored) =>
            x.floor() == 5 || wall && x.floor() == 4);
    expect(query(false)?.id, 'clerk');
    expect(query(true), isNull);
  });
  test('a target in a third cell cannot extend the counter reach', () {
    expect(reach(npc(3, 4, sides: [EntityFacing.east])), isNull);
  });
  test('counter side survives strict entity save and reopen', () {
    final target =
        MapEntity.fromJson(npc(4, 4, sides: [EntityFacing.east]).toJson());
    expect(reach(target)?.id, target.id);
  });
}

MapEntity npc(int x, int z, {List<EntityFacing> sides = const []}) => MapEntity(
    id: 'clerk',
    kind: MapEntityKind.npc,
    pos: GridPos(x: x, y: z),
    npc: MapEntityNpcData(counterInteractionSides: sides));
MapSpatialScene field(List<SpatialBlockedArea> blocked,
        {bool raised = false}) =>
    MapSpatialScene(
        width: 10,
        depth: 10,
        heightLevels: [
          for (var z = 0; z < 10; z++)
            for (var x = 0; x < 10; x++) raised && x == 4 && z == 4 ? 1 : 0
        ],
        navigation: SpatialNavigationProfile(blockedAreas: blocked));
MapEntity? reach(MapEntity target, {MapSpatialScene? scene}) =>
    findSpatialEntityInteraction(
        scene: scene ??
            field([SpatialBlockedArea(x: 5, z: 4, width: 1, depth: 1)]),
        entities: [target],
        x: 6.5,
        z: 4.5,
        facing: EntityFacing.west);
