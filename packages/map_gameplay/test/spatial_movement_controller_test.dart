import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

MapSpatialScene plateau(
        {double spawnX = 8, List<SpatialModelInstance> instances = const []}) =>
    MapSpatialScene(
        width: 16,
        depth: 14,
        heightLevels: [
          for (var z = 0; z < 14; z++)
            for (var x = 0; x < 16; x++)
              z < 6
                  ? 2
                  : z == 6
                      ? 1
                      : 0
        ],
        instances: instances,
        navigation: SpatialNavigationProfile(
            spawn: SpatialSpawn(x: spawnX, z: 11),
            ramps: [
              SpatialRamp(
                  id: 'upper',
                  x: 7.3125,
                  z: 6,
                  width: 1.375,
                  depth: 1,
                  lowLevel: 1,
                  highLevel: 2,
                  direction: SpatialRampDirection.north),
              SpatialRamp(
                  id: 'lower',
                  x: 7.3125,
                  z: 7,
                  width: 1.375,
                  depth: 1,
                  lowLevel: 0,
                  highLevel: 1,
                  direction: SpatialRampDirection.north)
            ],
            blockedAreas: [
              SpatialBlockedArea(x: 0, z: 6, width: 7.3125, depth: 2),
              SpatialBlockedArea(x: 8.6875, z: 6, width: 7.3125, depth: 2)
            ]));
void steps(SpatialMovementController player, int count,
    {int x = 0, int z = -1, bool run = false}) {
  player.setInput(x: x, z: z, run: run);
  for (var i = 0; i < count; i++) {
    player.update(.05);
  }
}

void main() {
  test(
      'a validated five-level ramp stays traversable while its side cliff blocks',
      () {
    final scene = MapSpatialScene(
        width: 6,
        depth: 6,
        heightLevels: [
          for (var z = 0; z < 6; z++)
            for (var x = 0; x < 6; x++) z < 2 ? 5 : 0
        ],
        navigation:
            SpatialNavigationProfile(spawn: SpatialSpawn(x: 3, z: 5), ramps: [
          SpatialRamp(
              id: 'steep',
              x: 2,
              z: 2,
              width: 2,
              depth: 1,
              lowLevel: 0,
              highLevel: 5,
              direction: SpatialRampDirection.north)
        ]));
    final player = SpatialMovementController(scene: scene, models: []);
    steps(player, 25);
    expect(player.y, 5);
    expect(player.z, closeTo(1.25, .1));
    steps(player, 25, z: 1);
    expect(player.y, 0);
    expect(player.z, closeTo(5, .1));
    steps(player, 17);
    expect(player.y, greaterThan(0));
    expect(player.y, lessThan(5));
    final height = player.y;
    steps(player, 25, x: -1, z: 0);
    expect(player.x, greaterThanOrEqualTo(2));
    expect(player.y, height);
    final cliff = SpatialMovementController(
        scene: scene.copyWith(
            navigation:
                scene.navigation.copyWith(spawn: SpatialSpawn(x: 1, z: 5))),
        models: []);
    steps(cliff, 30);
    expect(cliff.y, 0);
    expect(cliff.z, greaterThanOrEqualTo(2));
  });

  test('two north ramps connect spawn to upper plateau and back', () {
    final player = SpatialMovementController(scene: plateau(), models: []);
    expect(player.y, 0);
    steps(player, 45);
    expect(player.z, closeTo(4.25, .1));
    expect(player.y, 2);
    expect(player.facing, EntityFacing.north);
    expect(player.moving, isTrue);
    expect(player.animationSeconds, greaterThan(0));
    steps(player, 45, z: 1);
    expect(player.z, closeTo(11, .1));
    expect(player.y, 0);
    player.reset();
    expect(player.z, 11);
    expect(player.moving, isFalse);
  });
  test('ramp interpolation and cliff boundaries block leaving the corridor',
      () {
    final scene = plateau();
    expect(scene.worldHeightAt(8, 6.5), 1.5);
    expect(scene.worldHeightAt(8, 7.5), .5);
    final player =
        SpatialMovementController(scene: plateau(spawnX: 4), models: []);
    steps(player, 70);
    expect(player.z, greaterThanOrEqualTo(8));
    expect(player.y, 0);
    final cliff = SpatialMovementController(
        scene: MapSpatialScene(
            width: 4,
            depth: 4,
            heightLevels: [
              for (var z = 0; z < 4; z++)
                for (var x = 0; x < 4; x++) z < 2 ? 2 : 0
            ],
            navigation:
                SpatialNavigationProfile(spawn: SpatialSpawn(x: 2, z: 3))),
        models: []);
    steps(cliff, 30);
    expect(cliff.z, greaterThanOrEqualTo(2));
    expect(cliff.y, 0);
  });
  test('model collision respects yaw, scale, pivot and blocksMovement', () {
    final model = ProjectModel3dEntry(
        id: 'house',
        name: 'House',
        sourceAssetId: 'house-source',
        relativePath: 'assets/models3d/house.glb',
        pivot: Model3dVector3(x: 1, y: 0, z: 0),
        scale: 2,
        inspection: Model3dInspection(
            bounds: Model3dBounds(
                min: Model3dVector3(x: -1, y: 0, z: -.5),
                max: Model3dVector3(x: 1, y: 2, z: .5)),
            meshCount: 1,
            triangleCount: 1));
    final instance = SpatialModelInstance(
        id: 'house-1',
        modelId: 'house',
        position: Model3dVector3(x: 8, y: 0, z: 8),
        rotationDegrees: 90,
        scale: .5);
    final player = SpatialMovementController(
        scene: plateau(instances: [instance]), models: [model]);
    steps(player, 30);
    expect(player.z, greaterThanOrEqualTo(10.4));
    final decoration = SpatialMovementController(
        scene: plateau(instances: [instance.copyWith(blocksMovement: false)]),
        models: [model]);
    steps(decoration, 30);
    expect(decoration.z, lessThan(7));
  });
  test('diagonal setting, running, pause and dt clamp are input safe', () {
    final player = SpatialMovementController(scene: plateau(), models: []);
    steps(player, 1, x: 1, z: -1);
    expect(player.x, 8);
    expect(player.z, lessThan(11));
    player.setDiagonalMovement(true);
    final beforeX = player.x;
    steps(player, 5, x: 1, z: -1, run: true);
    expect(player.x, greaterThan(beforeX));
    expect(player.running, isTrue);
    player.setPaused(true);
    final frozenX = player.x;
    player.update(1);
    expect(player.x, frozenX);
    player.setPaused(false);
    player.update(1);
    expect(player.x, frozenX);
    player.reset();
    player.setInput(x: 0, z: 1);
    player.update(100);
    expect(player.z - 11, lessThan(.2));
    player.releaseInput();
    expect(player.running, isFalse);
    player.update(double.nan);
    expect(player.z.isFinite, isTrue);
  });
}
