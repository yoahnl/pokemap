import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

MapData spatialMap(
        {List<MapLayer> layers = const [],
        List<MapEntity> entities = const [],
        MapMetadata metadata = const MapMetadata()}) =>
    MapData(
      id: 'room',
      name: 'Room',
      version: ProjectVersion.v9,
      size: const GridSize(width: 6, height: 6),
      spatialScene: MapSpatialScene(
          width: 6,
          depth: 6,
          heightLevels: List.filled(36, 0),
          navigation:
              SpatialNavigationProfile(spawn: SpatialSpawn(x: 2.5, z: 2.5))),
      layers: layers,
      entities: entities,
      mapMetadata: metadata,
    );
MapLayer collisionAt(int x, int z, {bool visible = true}) => MapLayer.collision(
    id: 'solid',
    name: 'Solid',
    isVisible: visible,
    collisions: [for (var i = 0; i < 36; i++) i == z * 6 + x]);
MapEntity spawnAt(String id, int x, int z,
        {EntityFacing facing = EntityFacing.west}) =>
    MapEntity(
        id: id,
        kind: MapEntityKind.spawn,
        pos: GridPos(x: x, y: z),
        spawn: MapEntitySpawnData(facing: facing));
void walk(SpatialMovementController player, {int x = 1, int z = 0}) {
  player.setInput(x: x, z: z);
  for (var i = 0; i < 30; i++) {
    player.update(.05);
  }
}

void main() {
  test('authored start is centered with authored facing and never blocks', () {
    final player = SpatialMovementController.fromMap(
        map: spatialMap(entities: [spawnAt('start', 1, 3)]), models: []);
    expect(player.x, 1.5);
    expect(player.z, 3.5);
    expect(player.facing, EntityFacing.west);
    walk(player);
    expect(player.x, greaterThan(4));
    player.reset();
    expect(player.x, 1.5);
    expect(player.z, 3.5);
    expect(player.facing, EntityFacing.west);
  });
  test('default spawn wins and arrival overrides both starts', () {
    final map = spatialMap(
        entities: [spawnAt('start', 1, 3), spawnAt('door', 4, 2)],
        metadata: const MapMetadata(defaultSpawnId: 'door'));
    final player = SpatialMovementController.fromMap(map: map, models: []);
    expect(player.x, 4.5);
    final arrival = SpatialMovementController.fromMap(
        map: map,
        models: [],
        arrival: const GridPos(x: 2, y: 4),
        facing: EntityFacing.north);
    expect(arrival.x, 2.5);
    expect(arrival.z, 4.5);
    expect(arrival.facing, EntityFacing.north);
  });
  test('existing spatial spawn remains the no-entity start', () {
    final player =
        SpatialMovementController.fromMap(map: spatialMap(), models: []);
    expect(player.x, 2.5);
    expect(player.z, 2.5);
    expect(player.facing, EntityFacing.south);
  });
  test('collision paint blocks and erase restores the same route', () {
    for (final visible in [true, false]) {
      final painted = SpatialMovementController.fromMap(
          map: spatialMap(layers: [collisionAt(3, 2, visible: visible)]),
          models: []);
      walk(painted);
      expect(painted.x, lessThan(3));
      expect(painted.bumpedCell, const GridPos(x: 3, y: 2));
      final erased = SpatialMovementController.fromMap(
          map: spatialMap(layers: [
            MapLayer.collision(
                id: 'solid', name: 'Solid', collisions: List.filled(36, false))
          ]),
          models: []);
      walk(erased);
      expect(erased.x, greaterThan(5));
    }
  });
  test('blocked and out-of-bounds arrival or authored spawn are rejected', () {
    for (final cell in [
      const GridPos(x: 3, y: 2),
      const GridPos(x: -1, y: 2),
      const GridPos(x: 6, y: 2),
      const GridPos(x: 2, y: -1),
      const GridPos(x: 2, y: 6)
    ]) {
      expect(
          () => SpatialMovementController.fromMap(
              map: spatialMap(layers: [collisionAt(3, 2)]),
              models: [],
              arrival: cell),
          throwsStateError);
    }
    expect(
        () => SpatialMovementController.fromMap(
            map: spatialMap(entities: [spawnAt('outside', 6, 2)]), models: []),
        throwsStateError);
  });
  test('boundaries stop the hitbox and report the attempted outside cell', () {
    final player =
        SpatialMovementController.fromMap(map: spatialMap(), models: []);
    walk(player);
    expect(player.x, lessThanOrEqualTo(5.625));
    expect(player.bumpedCell, const GridPos(x: 6, y: 2));
    walk(player, x: -1);
    walk(player, x: -1);
    expect(player.x, greaterThanOrEqualTo(.375));
    expect(player.bumpedCell, const GridPos(x: -1, y: 2));
  });
  test('diagonal side sliding does not bump an unobstructed facing cell', () {
    final player = SpatialMovementController.fromMap(
      map: spatialMap(layers: [collisionAt(3, 2)]),
      models: [],
    );
    player.setDiagonalMovement(true);
    player.setInput(x: 1, z: 1);
    for (var i = 0; i < 3; i++) {
      player.update(.05);
    }
    expect(player.z, greaterThan(2.5));
    expect(player.x, lessThan(2.8));
    expect(player.bumpedCell, isNull);
  });

  test('reset rejects a newly blocked spawn before changing current state', () {
    ProjectModel3dEntry model(double baseY) => ProjectModel3dEntry(
          id: 'door',
          name: 'Door',
          sourceAssetId: 'source',
          relativePath: 'assets/models3d/door.glb',
          inspection: Model3dInspection(
            bounds: Model3dBounds(
              min: Model3dVector3(x: -.5, y: baseY, z: -.5),
              max: Model3dVector3(x: .5, y: baseY + 2, z: .5),
            ),
            meshCount: 1,
            triangleCount: 1,
          ),
        );
    final map = spatialMap();
    final player = SpatialMovementController.fromMap(
      map: map.copyWith(
          spatialScene: map.spatialScene!.copyWith(instances: [
        SpatialModelInstance(
            id: 'door-1',
            modelId: 'door',
            position: Model3dVector3(x: 2.5, y: 0, z: 2.5)),
      ])),
      models: [model(10)],
    );
    walk(player);
    final currentX = player.x,
        currentZ = player.z,
        currentFacing = player.facing;
    player.models['door'] = model(0);
    expect(player.reset, throwsStateError);
    expect(player.x, currentX);
    expect(player.z, currentZ);
    expect(player.facing, currentFacing);
  });

  test('bump requires an actual pixel step and clears on idle and pause', () {
    final player = SpatialMovementController.fromMap(
        map: spatialMap(layers: [collisionAt(3, 2)]), models: []);
    walk(player);
    expect(player.bumpedCell, isNotNull);
    player.releaseInput();
    expect(player.bumpedCell, isNull);
    player.update(.05);
    expect(player.bumpedCell, isNull);
    player.setInput(x: 1, z: 0);
    player.update(.00001);
    expect(player.bumpedCell, isNull);
    player.update(.05);
    expect(player.bumpedCell, isNotNull);
    player.setPaused(true);
    player.update(.05);
    expect(player.bumpedCell, isNull);
  });
}
