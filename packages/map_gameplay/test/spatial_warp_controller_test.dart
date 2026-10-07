import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

MapData warpMap(MapWarp warp) => MapData(
    id: 'room',
    name: 'Room',
    size: const GridSize(width: 6, height: 6),
    warps: [warp]);
MapWarp passage(
        {MapWarpTriggerMode mode = MapWarpTriggerMode.onEnter,
        List<EntityFacing> allowed = const [],
        WarpTriggerPadding padding = const WarpTriggerPadding()}) =>
    MapWarp(
        id: 'door',
        pos: const GridPos(x: 3, y: 2),
        targetMapId: 'outside',
        targetPos: const GridPos(x: 1, y: 1),
        triggerMode: mode,
        allowedApproachFacings: allowed,
        triggerPadding: padding);
void main() {
  test('every padded cell and approach matches the canonical 2D resolver', () {
    for (final mode in MapWarpTriggerMode.values) {
      final warp = passage(
        mode: mode,
        allowed: [EntityFacing.west, EntityFacing.north],
        padding:
            const WarpTriggerPadding(left: 1, right: 16, top: 17, bottom: 1),
      );
      final map = warpMap(warp).copyWith(entities: [
        const MapEntity(
          id: 'start',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 5),
          spawn: MapEntitySpawnData(),
          blocksMovement: false,
        ),
      ]);
      final oracle = GameplayWorldState.fromMap(map);
      for (var z = 0; z < 6; z++) {
        for (var x = 0; x < 6; x++) {
          for (final facing in EntityFacing.values) {
            final controller = SpatialWarpController(map: map, x: -1, z: -1);
            final expected = mode == MapWarpTriggerMode.onEnter
                ? oracle.warpOnEnterAt(x, z, facing.asDirection)
                : oracle.warpOnBumpAt(x, z, facing.asDirection);
            final actual = controller.update(
              x: mode == MapWarpTriggerMode.onEnter ? x + .5 : -1,
              z: mode == MapWarpTriggerMode.onEnter ? z + .5 : -1,
              facing: facing,
              bumpedCell: mode == MapWarpTriggerMode.onBump
                  ? GridPos(x: x, y: z)
                  : null,
            );
            expect(actual, expected, reason: '$mode ($x,$z) $facing');
          }
        }
      }
    }
  });

  test('enter is edge triggered and arrival requires leaving then reentering',
      () {
    final warp = passage();
    final controller =
        SpatialWarpController(map: warpMap(warp), x: 3.5, z: 2.5);
    expect(
        controller.update(x: 3.5, z: 2.5, facing: EntityFacing.south), isNull);
    expect(
        controller.update(x: 2.5, z: 2.5, facing: EntityFacing.west), isNull);
    expect(controller.update(x: 3.5, z: 2.5, facing: EntityFacing.east), warp);
    expect(
        controller.update(x: 3.5, z: 2.5, facing: EntityFacing.east), isNull);
  });
  test(
      'approach uses the side opposite movement and cannot retrigger by turning',
      () {
    final warp = passage(allowed: [EntityFacing.west]);
    final controller =
        SpatialWarpController(map: warpMap(warp), x: 3.5, z: 1.5);
    expect(
        controller.update(x: 3.5, z: 2.5, facing: EntityFacing.south), isNull);
    expect(
        controller.update(x: 3.5, z: 2.5, facing: EntityFacing.east), isNull);
    controller.update(x: 2.5, z: 2.5, facing: EntityFacing.west);
    expect(controller.update(x: 3.5, z: 2.5, facing: EntityFacing.east), warp);
  });
  test('pixel padding expands whole trigger cells exactly like 2D', () {
    final warp = passage(
        padding:
            const WarpTriggerPadding(left: 1, right: 16, top: 17, bottom: 1));
    final controller =
        SpatialWarpController(map: warpMap(warp), x: 1.5, z: 2.5);
    expect(controller.update(x: 2.0, z: 2.5, facing: EntityFacing.east), warp);
    expect(
        controller.update(x: 4.9, z: 3.9, facing: EntityFacing.south), isNull);
    controller.update(x: 5.0, z: 2.5, facing: EntityFacing.east);
    expect(controller.update(x: 4.9, z: 2.5, facing: EntityFacing.west), warp);
    final arrival = SpatialWarpController(map: warpMap(warp), x: 2.5, z: .5);
    expect(arrival.update(x: 3.5, z: 2.5, facing: EntityFacing.south), isNull);
  });
  test('on bump requires actual bumped cell and suppresses repeated frames',
      () {
    final warp =
        passage(mode: MapWarpTriggerMode.onBump, allowed: [EntityFacing.west]);
    final controller =
        SpatialWarpController(map: warpMap(warp), x: 2.5, z: 2.5);
    expect(
        controller.update(x: 2.5, z: 2.5, facing: EntityFacing.east), isNull);
    expect(
        controller.update(
            x: 2.5,
            z: 2.5,
            facing: EntityFacing.south,
            bumpedCell: const GridPos(x: 3, y: 2)),
        isNull);
    expect(
        controller.update(
            x: 2.5,
            z: 2.5,
            facing: EntityFacing.east,
            bumpedCell: const GridPos(x: 3, y: 2)),
        warp);
    expect(
        controller.update(
            x: 2.5,
            z: 2.5,
            facing: EntityFacing.east,
            bumpedCell: const GridPos(x: 3, y: 2)),
        isNull);
    controller.update(x: 2.5, z: 2.5, facing: EntityFacing.east);
    expect(
        controller.update(
            x: 2.5,
            z: 2.5,
            facing: EntityFacing.east,
            bumpedCell: const GridPos(x: 3, y: 2)),
        warp);
  });
  test('bump cannot activate an enter warp and leaving bounds cannot trigger',
      () {
    final warp = passage(padding: const WarpTriggerPadding(right: 100));
    final controller =
        SpatialWarpController(map: warpMap(warp), x: 2.5, z: 2.5);
    expect(
        controller.update(
            x: 2.5,
            z: 2.5,
            facing: EntityFacing.east,
            bumpedCell: const GridPos(x: 3, y: 2)),
        isNull);
    expect(controller.update(x: 6, z: 2.5, facing: EntityFacing.east), isNull);
  });
}
