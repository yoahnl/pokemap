import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'spatial_movement_controller_test.dart' show plateau;

void main() {
  final npc = MapEntity(
      id: 'npc',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 3, y: 2),
      npc: MapEntityNpcData(characterId: 'hero'));
  final scene = MapSpatialScene(
      width: 8,
      depth: 8,
      heightLevels: List.filled(64, 0),
      navigation: SpatialNavigationProfile(spawn: SpatialSpawn(x: 3.5, z: 4)));
  test('static NPC collision stops a running hero and release clears sprint',
      () {
    final player =
        SpatialMovementController(scene: scene, models: [], entities: [npc]);
    player.setInput(x: 0, z: -1, run: true);
    for (var i = 0; i < 20; i++) {
      player.update(.05);
    }
    expect(player.z, greaterThanOrEqualTo(2.5));
    expect(player.z, lessThan(4));
    player.releaseInput();
    expect(player.running, isFalse);
  });
  test('NPC on a continuous ramp blocks movement and remains talkable', () {
    final ramp = MapSpatialScene(
        width: 8,
        depth: 8,
        heightLevels: [
          for (var z = 0; z < 8; z++)
            for (var x = 0; x < 8; x++) z < 2 ? 2 : 0
        ],
        navigation:
            SpatialNavigationProfile(spawn: SpatialSpawn(x: 3.5, z: 4), ramps: [
          SpatialRamp(
              id: 'ramp',
              x: 3,
              z: 2,
              width: 1,
              depth: 2,
              lowLevel: 0,
              highLevel: 2,
              direction: SpatialRampDirection.north)
        ]));
    final player =
        SpatialMovementController(scene: ramp, models: [], entities: [npc]);
    player.setInput(x: 0, z: -1, run: true);
    for (var i = 0; i < 20; i++) {
      player.update(.05);
    }
    expect(player.z, greaterThan(3));
    expect(player.z, lessThan(4));
    expect((player.y - ramp.worldHeightAt(3.5, 2.5)).abs(), greaterThan(.1));
    expect(
        findSpatialNpcInteraction(
                scene: ramp,
                entities: [npc],
                x: player.x,
                z: player.z,
                facing: EntityFacing.north)
            ?.id,
        npc.id);
    final unobstructed = SpatialMovementController(scene: ramp, models: []);
    unobstructed.setInput(x: 0, z: -1);
    for (var i = 0; i < 16; i++) {
      unobstructed.update(.05);
    }
    expect(unobstructed.z, lessThan(2.5));
  });
  test(
      'lower plateau ramp permits interaction across different terrain heights',
      () {
    final map = plateau();
    final rampNpc = npc.copyWith(pos: GridPos(x: 7, y: 7));
    expect(map.worldHeightAt(7.5, 8.5), 0);
    expect(map.worldHeightAt(7.5, 7.5), .5);
    expect(
        findSpatialNpcInteraction(
                scene: map,
                entities: [rampNpc],
                x: 7.5,
                z: 8.5,
                facing: EntityFacing.north)
            ?.id,
        npc.id);
    final player = SpatialMovementController(
        scene: map.copyWith(
            navigation:
                map.navigation.copyWith(spawn: SpatialSpawn(x: 8, z: 8.5))),
        models: [],
        entities: [rampNpc]);
    player.setInput(x: 0, z: -1, run: true);
    for (var i = 0; i < 20; i++) {
      player.update(.05);
    }
    expect(player.z, greaterThan(7.5));
    expect(player.z, lessThan(8.5));
    expect(
        findSpatialNpcInteraction(
                scene: map,
                entities: [rampNpc],
                x: player.x,
                z: player.z,
                facing: EntityFacing.north)
            ?.id,
        npc.id);
    final cliff = map.copyWith(heightLevels: [
      for (var i = 0; i < map.heightLevels.length; i++)
        i == 7 * map.width + 7 ? 1 : map.heightLevels[i]
    ], navigation: map.navigation.copyWith(ramps: []));
    expect(
        findSpatialNpcInteraction(
            scene: cliff,
            entities: [rampNpc],
            x: 7.5,
            z: 8.5,
            facing: EntityFacing.north),
        isNull);
  });
  test('interaction requires facing, cardinal reach and traversable terrain',
      () {
    MapEntity? target(double x, double z, EntityFacing facing,
            {MapSpatialScene? map}) =>
        findSpatialNpcInteraction(
            scene: map ?? scene, entities: [npc], x: x, z: z, facing: facing);
    expect(target(3.5, 3.5, EntityFacing.north)?.id, 'npc');
    expect(target(3.5, 3.5, EntityFacing.south), isNull);
    expect(target(3.5, 4, EntityFacing.north), isNull);
    expect(target(4.2, 3.5, EntityFacing.north), isNull);
    final raised = scene
        .copyWith(heightLevels: [for (var i = 0; i < 64; i++) i == 19 ? 2 : 0]);
    expect(target(3.5, 3.5, EntityFacing.north, map: raised), isNull);
    expect(spatialNpcFacingPlayer(npc, x: 3.5, z: 3.5), EntityFacing.south);
  });
}
