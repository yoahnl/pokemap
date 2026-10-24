import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  final scene = MapSpatialScene(width: 8, depth: 8);
  final model = _model();
  final door = _instance('door', x: 3.5, z: 2.5);
  SpatialModelInstance? find({
    MapSpatialScene? map,
    List<ProjectModel3dEntry>? models,
    List<SpatialModelInstance>? instances,
    double x = 3.5,
    double z = 3.75,
    EntityFacing facing = EntityFacing.north,
  }) =>
      findSpatialModelInteraction(
          scene: map ?? scene,
          models: models ?? [model],
          instances: instances ?? [door],
          x: x,
          z: z,
          facing: facing);

  test('a narrow door is reachable by its footprint in front of the player',
      () {
    expect(find()?.id, 'door');
    expect(find(facing: EntityFacing.south), isNull);
    expect(find(z: 4), isNull);
    expect(find(x: 4.5), isNull);
    expect(find(instances: []), isNull);
  });

  test('interaction follows rotation, pivot and combined model scale', () {
    final model = _model(pivot: Model3dVector3(x: 1, y: 0, z: 0), scale: 2);
    final rotated = _instance('rotated', x: 4, z: 2.5, angle: 90, scale: .5);
    expect(find(models: [model], instances: [rotated], x: 4, z: 4.5)?.id,
        'rotated');
    expect(find(models: [model], instances: [rotated], x: 4, z: 2), isNull);
  });

  test('reach is measured from the closest bound rather than the pivot', () {
    final offset = _model(pivot: Model3dVector3(x: 0, y: 0, z: 2));
    final farPivot = _instance('offset', x: 3.5, z: 4.5);
    expect(find(models: [offset], instances: [farPivot])?.id, 'offset');
  });

  test('a door on another height is rejected and ground obstruction blocks',
      () {
    expect(
        find(instances: [_instance('floating', x: 3.5, z: 2.5, y: 3)]), isNull);
    final raised = scene.copyWith(heightLevels: [
      for (var z = 0; z < 8; z++)
        for (var x = 0; x < 8; x++) z < 3 ? 2 : 0,
    ]);
    expect(find(map: raised), isNull);
    final blocked = scene.copyWith(
        navigation: SpatialNavigationProfile(
      blockedAreas: [SpatialBlockedArea(x: 3, z: 3, width: 1, depth: .2)],
    ));
    expect(find(map: blocked), isNull);
  });

  test(
      'visible furniture face remains reachable inside its quantized floor mask',
      () {
    final furniture = _model(
        bounds: Model3dBounds(
            min: Model3dVector3(x: -1, y: .03125, z: -.625),
            max: Model3dVector3(x: 1, y: 2.0625, z: .375)));
    final instance = _instance('television', x: 3.5, z: 3.5);
    final map = scene.copyWith(
        navigation: SpatialNavigationProfile(
            spawn: SpatialSpawn(x: 3.5, z: 4.5),
            blockedAreas: [
          SpatialBlockedArea(x: 2, z: 3, width: 3, depth: 1)
        ]));
    expect(
        find(map: map, models: [furniture], instances: [instance], z: 4.5)?.id,
        'television');
    expect(
        find(
            map: map,
            models: [furniture],
            instances: [instance],
            z: 4.5,
            facing: EntityFacing.south),
        isNull);
    final movement = SpatialMovementController(scene: map, models: [furniture]);
    expect(movement.canTraverseActor(3.5, 4.5, 3.5, 3.5), isFalse);
  });

  test('a wall in front of the furniture still occludes its face', () {
    final furniture = _model(
        bounds: Model3dBounds(
            min: Model3dVector3(x: -1, y: 0, z: -.625),
            max: Model3dVector3(x: 1, y: 2, z: .375)));
    final map = scene.copyWith(
        navigation: SpatialNavigationProfile(blockedAreas: [
      SpatialBlockedArea(x: 2, z: 3, width: 3, depth: 1),
      SpatialBlockedArea(x: 3, z: 4.1, width: 1, depth: .1),
    ]));
    expect(
        find(
            map: map,
            models: [furniture],
            instances: [_instance('television', x: 3.5, z: 3.5)],
            z: 4.5),
        isNull);
  });

  test('custom and sign targets remain usable inside their occupied floor cell',
      () {
    final map = scene.copyWith(
        navigation: SpatialNavigationProfile(blockedAreas: [
      SpatialBlockedArea(x: 3, z: 2, width: 1, depth: 1),
    ]));
    for (final kind in [MapEntityKind.custom, MapEntityKind.sign]) {
      final entity =
          MapEntity(id: 'fixture', kind: kind, pos: GridPos(x: 3, y: 2));
      expect(
          findSpatialEntityInteraction(
                  scene: map,
                  entities: [entity],
                  x: 3.5,
                  z: 3.5,
                  facing: EntityFacing.north)
              ?.id,
          'fixture');
      expect(
          findSpatialEntityInteraction(
              scene: map,
              entities: [entity],
              x: 3.5,
              z: 3.5,
              facing: EntityFacing.south),
          isNull);
      expect(
          findSpatialEntityInteraction(
              scene: map.copyWith(
                  navigation: map.navigation.copyWith(blockedAreas: [
                ...map.navigation.blockedAreas,
                SpatialBlockedArea(x: 3, z: 3.1, width: 1, depth: .1)
              ])),
              entities: [entity],
              x: 3.5,
              z: 3.5,
              facing: EntityFacing.north),
          isNull);
    }
    expect(
        findSpatialEntityInteraction(
            scene: map,
            entities: [
              MapEntity(
                  id: 'npc', kind: MapEntityKind.npc, pos: GridPos(x: 3, y: 2))
            ],
            x: 3.5,
            z: 3.5,
            facing: EntityFacing.north),
        isNull);
  });

  test('a physical model between player and fixture occludes the target', () {
    final wall = _instance('wall', x: 3.5, z: 3.15);
    expect(find(map: scene.copyWith(instances: [wall]), z: 3.75), isNull);
    expect(
        findSpatialModelInteraction(
            scene: scene.copyWith(instances: [wall]),
            models: [model],
            instances: [door],
            x: 3.5,
            z: 3.75,
            facing: EntityFacing.north,
            modelStateProvider: (id) => id == wall.id
                ? SpatialModelRuntimeState(
                    modelId: wall.modelId,
                    animationIndex: null,
                    normalizedTime: 0,
                    blocksMovement: false)
                : null)?.id,
        'door');
  });

  test('closest footprint wins and ties are stable across iterable order', () {
    final far = _instance('a-far', x: 3.5, z: 2.5);
    final near = _instance('z-near', x: 3.5, z: 3);
    expect(find(instances: [far, near])?.id, 'z-near');
    expect(find(instances: [near, far])?.id, 'z-near');
    final first = _instance('a-first', x: 3.5, z: 2.5);
    final second = _instance('z-second', x: 3.5, z: 2.5);
    expect(find(instances: [second, first])?.id, 'a-first');
    expect(find(instances: [first, second])?.id, 'a-first');
  });
}

ProjectModel3dEntry _model(
        {Model3dVector3? pivot, double scale = 1, Model3dBounds? bounds}) =>
    ProjectModel3dEntry(
        id: 'door',
        name: 'Door',
        sourceAssetId: 'door-source',
        relativePath: 'assets/models3d/door.glb',
        pivot: pivot ?? Model3dVector3(x: 0, y: 0, z: 0),
        scale: scale,
        inspection: Model3dInspection(
            bounds: bounds ??
                Model3dBounds(
                    min: Model3dVector3(x: -.1, y: 0, z: -.1),
                    max: Model3dVector3(x: .1, y: 2, z: .1)),
            meshCount: 1,
            triangleCount: 1));

SpatialModelInstance _instance(String id,
        {required double x,
        required double z,
        double y = 0,
        double angle = 0,
        double scale = 1}) =>
    SpatialModelInstance(
        id: id,
        modelId: 'door',
        position: Model3dVector3(x: x, y: y, z: z),
        rotationDegrees: angle,
        scale: scale);
