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
  test('native door is found before entering its threshold only with directed input', () {
    final warp = passage(allowed: [EntityFacing.south]).copyWith(door: const MapWarpDoor(instanceId: 'door', openAnimationIndex: 0, closeAnimationIndex: 1, exitPos: GridPos(x: 3, y: 3)));
    final controller = SpatialWarpController(map: warpMap(warp), x: 3.5, z: 3.5);
    expect(controller.candidateDoorApproach(x: 3.5, z: 3.5, facing: EntityFacing.north, inputX: 0, inputZ: -1), warp);
    expect(controller.candidateDoorApproach(x: 3.5, z: 3.5, facing: EntityFacing.north, inputX: 0, inputZ: 0), isNull);
    expect(controller.candidateDoorApproach(x: 3.5, z: 3.5, facing: EntityFacing.south, inputX: 0, inputZ: 1), isNull);
    expect(controller.candidateDoorApproach(x: 3.5, z: 3.5, facing: EntityFacing.north, inputX: 1, inputZ: -1), isNull);
    expect(controller.candidateDoorApproach(x: 3.5, z: 2.5, facing: EntityFacing.north, inputX: 0, inputZ: -1), isNull);
    expect(controller.candidateDoorApproach(x: double.nan, z: 3.5, facing: EntityFacing.north, inputX: 0, inputZ: -1), isNull);
  });

  test('native approach respects approach side and excludes ordinary and scene markers', () {
    final ordinary = passage();
    final native = ordinary.copyWith(door: const MapWarpDoor(instanceId: 'door', openAnimationIndex: 0, closeAnimationIndex: 1, exitPos: GridPos(x: 3, y: 3)));
    for (final warp in [ordinary, native.copyWith(triggerMode: MapWarpTriggerMode.sceneOnly), native.copyWith(allowedApproachFacings: [EntityFacing.north])]) {
      final controller = SpatialWarpController(map: warpMap(warp), x: 3.5, z: 3.5);
      expect(controller.candidateDoorApproach(x: 3.5, z: 3.5, facing: EntityFacing.north, inputX: 0, inputZ: -1), isNull);
    }
    for (final side in EntityFacing.values) {
      final delta = switch(side) {EntityFacing.north => (0, -1), EntityFacing.south => (0, 1), EntityFacing.east => (1, 0), EntityFacing.west => (-1, 0)};
      final warp = native.copyWith(door: native.door!.copyWith(exitPos: GridPos(x: 3 - delta.$1, y: 2 - delta.$2)));
      final controller = SpatialWarpController(map: warpMap(warp), x: 0, z: 0);
      expect(controller.candidateDoorApproach(x: warp.door!.exitPos.x + .5, z: warp.door!.exitPos.y + .5, facing: side, inputX: delta.$1, inputZ: delta.$2), warp);
    }
  });

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
            final expected = switch (mode) {
              MapWarpTriggerMode.onEnter =>
                oracle.warpOnEnterAt(x, z, facing.asDirection),
              MapWarpTriggerMode.onBump =>
                oracle.warpOnBumpAt(x, z, facing.asDirection),
              MapWarpTriggerMode.sceneOnly => null,
            };
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

  test('scene-only markers stay inert on entry and physical bump', () {
    final marker = passage(
      mode: MapWarpTriggerMode.sceneOnly,
      padding: const WarpTriggerPadding(left: 16, right: 16, top: 16, bottom: 16),
    ).copyWith(targetMapId: 'room', targetPos: const GridPos(x: 3, y: 2));
    final controller = SpatialWarpController(map: warpMap(marker), x: 0, z: 0);
    for (final facing in EntityFacing.values) {
      expect(controller.update(x: 3.5, z: 2.5, facing: facing), isNull);
      expect(controller.update(x: 2.5, z: 2.5, facing: facing,
        bumpedCell: const GridPos(x: 3, y: 2)), isNull);
      expect(controller.update(x: 0, z: 0, facing: facing), isNull);
    }
    expect(controller.map.warps.single, marker);
  });

  for (final mode in [MapWarpTriggerMode.onEnter, MapWarpTriggerMode.onBump]) {
    test('scene-only marker does not shadow an automatic ${mode.name} warp', () {
      final automatic = passage(mode: mode);
      final marker = automatic.copyWith(id: 'arrival',
        triggerMode: MapWarpTriggerMode.sceneOnly, targetMapId: 'room',
        targetPos: automatic.pos);
      final controller = SpatialWarpController(
        map: warpMap(marker).copyWith(warps: [marker, automatic]), x: 0, z: 0);
      expect(controller.update(
        x: mode == MapWarpTriggerMode.onEnter ? 3.5 : 2.5,
        z: 2.5, facing: EntityFacing.east,
        bumpedCell: mode == MapWarpTriggerMode.onBump ? automatic.pos : null,
      ), automatic);
    });
  }

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
