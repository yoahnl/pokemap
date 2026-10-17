import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  const operations = SpatialMapOperations();

  test('a linked stair moves and rotates its ramp in the same map change', () {
    final before = linkedMap();
    final stair = before.spatialScene!.instances.single;
    final after = operations.upsertInstance(
      before,
      stair.copyWith(
        position: Model3dVector3(x: 5.5, y: .5, z: 6),
        rotationDegrees: 90,
      ),
    );
    final ramp = after.spatialScene!.navigation.ramps.single;
    expect(ramp.x, 3.5);
    expect(ramp.z, 5.5);
    expect(ramp.width, 2);
    expect(ramp.depth, 1);
    expect(ramp.direction, SpatialRampDirection.west);
    expect(ramp.lowLevel, 2);
    expect(ramp.highLevel, 6);
    expect(ramp.surfaceInstanceId, stair.id);
    expect(before.spatialScene!.navigation.ramps.single.x, 2);
    expect(MapData.fromJson(after.toJson()), after);
  });

  test(
    'deleting a stair also removes its own ramp and preserves other data',
    () {
      final before = linkedMap();
      final after = operations.deleteInstance(before, 'stairs');
      expect(after.spatialScene!.instances, isEmpty);
      expect(after.spatialScene!.navigation.ramps, isEmpty);
      expect(
        after.spatialScene!.heightLevels,
        before.spatialScene!.heightLevels,
      );
      expect(
        after.spatialScene!.navigation.spawn,
        before.spatialScene!.navigation.spawn,
      );
      expect(before.spatialScene!.navigation.ramps, hasLength(1));
    },
  );

  test('a stair rejects a non-cardinal rotation without publishing a map', () {
    final before = linkedMap();
    expect(
      () => operations.upsertInstance(
        before,
        before.spatialScene!.instances.single.copyWith(rotationDegrees: 45),
      ),
      throwsFormatException,
    );
    expect(before.spatialScene!.instances.single.rotationDegrees, 0);
  });

  test(
    'placing an authored stair creates a walkable ramp in all four orientations',
    () {
      final model = stairModel();
      final expected = [
        (
          x: 5.0,
          z: 4.0,
          width: 1.0,
          depth: 2.0,
          direction: SpatialRampDirection.north,
        ),
        (
          x: 3.5,
          z: 5.5,
          width: 2.0,
          depth: 1.0,
          direction: SpatialRampDirection.west,
        ),
        (
          x: 5.0,
          z: 6.0,
          width: 1.0,
          depth: 2.0,
          direction: SpatialRampDirection.south,
        ),
        (
          x: 5.5,
          z: 5.5,
          width: 2.0,
          depth: 1.0,
          direction: SpatialRampDirection.east,
        ),
      ];
      for (var i = 0; i < 4; i++) {
        final after = operations.upsertInstance(
          flatMap(),
          SpatialModelInstance(
            id: 'new-stair',
            modelId: model.id,
            position: Model3dVector3(x: 5.5, y: .5, z: 6),
            rotationDegrees: i * 90,
          ),
          model: model,
        );
        final ramp = after.spatialScene!.navigation.ramps.single;
        expect((
          x: ramp.x,
          z: ramp.z,
          width: ramp.width,
          depth: ramp.depth,
          direction: ramp.direction,
        ), expected[i]);
        expect(ramp.lowLevel, 2);
        expect(ramp.highLevel, 6);
        expect(ramp.surfaceInstanceId, 'new-stair');
        expect(after.spatialScene!.instances.single.blocksMovement, isFalse);
        expect(MapData.fromJson(after.toJson()), after);
      }
    },
  );

  test('model scale and pivot affect its attached surface exactly once', () {
    final model = stairModel().copyWith(
      scale: 2,
      pivot: Model3dVector3(x: 1, y: .25, z: 1),
    );
    final after = operations.upsertInstance(
      flatMap(),
      SpatialModelInstance(
        id: 'new-stair',
        modelId: model.id,
        scale: .5,
        position: Model3dVector3(x: 5.5, y: .75, z: 6),
      ),
      model: model,
    );
    final ramp = after.spatialScene!.navigation.ramps.single;
    expect((ramp.x, ramp.z, ramp.width, ramp.depth), (4, 3, 1, 2));
    expect((ramp.lowLevel, ramp.highLevel), (2, 6));
  });

  test('the resource profile survives copy JSON and clearing', () {
    final model = stairModel();
    expect(ProjectModel3dEntry.fromJson(model.toJson()), model);
    expect(model.copyWith(name: 'Renamed').rampProfile, model.rampProfile);
    expect(
      model
          .copyWith(clearRampProfile: true)
          .toJson()
          .containsKey('rampProfile'),
      isFalse,
    );
    expect(model, isNot(model.copyWith(clearRampProfile: true)));
    final invalid = {...model.rampProfile!.toJson(), 'width': 0};
    expect(() => Model3dRampProfile.fromJson(invalid), throwsFormatException);
    expect(
      () => Model3dRampProfile.fromJson({
        ...model.rampProfile!.toJson(),
        'extra': 1,
      }),
      throwsFormatException,
    );
  });

  test('replacing a staircase model with an ordinary decor removes the slope', () {
    final before = linkedMap();
    final after = operations.upsertInstance(before, SpatialModelInstance(id: 'stairs', modelId: 'tree',
      position: before.spatialScene!.instances.single.position));
    expect(after.spatialScene!.navigation.ramps, isEmpty);
    expect(after.spatialScene!.instances.single.blocksMovement, isTrue);
  });

  test('changing terrain level height preserves physical stair height', () {
    final before = linkedMap();
    final after = operations.configureLevelHeight(before, .5);
    expect(after.spatialScene!.navigation.ramps.single.highLevel, 2);
    expect(after.spatialScene!.worldHeightAt(2.5, 2.001), closeTo(.9995, .000001));
    expect(after.spatialScene!.instances.single.position.y, 0);
    expect(operations.configureLevelHeight(after, .25), before);
  });

  test('raising terrain under a stair raises both stair and slope', () {
    final before = linkedMap();
    final after = operations.setLevels(before, [const SpatialCellLevel(x: 2, z: 4, level: 4)]);
    expect(after.spatialScene!.instances.single.position.y, 1);
    expect(after.spatialScene!.navigation.ramps.single.lowLevel, 4);
    expect(after.spatialScene!.navigation.ramps.single.highLevel, 8);
  });

  test('unfinished attached stairs retain explicit terrain contact diagnostics', () {
    final model = stairModel();
    final unfinished = operations.upsertInstance(flatMap(), SpatialModelInstance(id: 'stairs', modelId: model.id,
      position: Model3dVector3(x: 2.5, y: 0, z: 4)), model: model).spatialScene!;
    expect(unfinished.rampHasTerrainContacts(unfinished.navigation.ramps.single), isFalse);
    final finished = linkedMap().spatialScene!;
    expect(finished.rampHasTerrainContacts(finished.navigation.ramps.single), isTrue);
  });

  test('batch swaps are atomic even when intermediate ramps would overlap', () {
    final model = stairModel();
    final first = SpatialModelInstance(
      id: 'a',
      modelId: model.id,
      position: Model3dVector3(x: 3.5, y: 0, z: 6),
    );
    final second = SpatialModelInstance(
      id: 'b',
      modelId: model.id,
      position: Model3dVector3(x: 5.5, y: 0, z: 6),
    );
    final before = operations.upsertInstances(
      flatMap(),
      [first, second],
      models: [model],
    );
    final after = operations.upsertInstances(
      before,
      [
        first.copyWith(position: second.position),
        second.copyWith(position: first.position),
      ],
      models: [model],
    );
    expect(
      after.spatialScene!.navigation.ramps
          .where((ramp) => ramp.surfaceInstanceId == 'a')
          .single
          .x,
      5,
    );
    expect(
      after.spatialScene!.navigation.ramps
          .where((ramp) => ramp.surfaceInstanceId == 'b')
          .single
          .x,
      3,
    );
    expect(before.spatialScene!.navigation.ramps.first.x, 3);
  });

  test(
    'invalid overlap bounds and level alignment preserve the source map',
    () {
      final model = stairModel();
      final instance = SpatialModelInstance(
        id: 'a',
        modelId: model.id,
        position: Model3dVector3(x: 3.5, y: 0, z: 6),
      );
      final before = operations.upsertInstance(
        flatMap(),
        instance,
        model: model,
      );
      for (final invalid in [
        instance.copyWith(position: Model3dVector3(x: 3.5, y: .1, z: 6)),
        instance.copyWith(position: Model3dVector3(x: .1, y: 0, z: 6)),
      ]) {
        expect(
          () => operations.upsertInstance(before, invalid, model: model),
          throwsFormatException,
        );
      }
      expect(
        () => operations.upsertInstance(
          before,
          SpatialModelInstance(
            id: 'b',
            modelId: model.id,
            position: instance.position,
          ),
          model: model,
        ),
        throwsFormatException,
      );
      expect(before.spatialScene!.instances, hasLength(1));
    },
  );
}

MapData flatMap() => MapData(
  id: 'map',
  name: 'Flat',
  version: ProjectVersion.v9,
  size: const GridSize(width: 12, height: 12),
  spatialScene: MapSpatialScene(width: 12, depth: 12, levelHeight: .25),
);

ProjectModel3dEntry stairModel() => ProjectModel3dEntry(
  id: 'stair-model',
  name: 'Escalier',
  sourceAssetId: 'stair-source',
  relativePath: 'assets/models3d/stair-model.glb',
  inspection: Model3dInspection(
    bounds: Model3dBounds(
      min: Model3dVector3(x: -.5, y: 0, z: -2),
      max: Model3dVector3(x: .5, y: 1, z: 0),
    ),
    meshCount: 1,
    triangleCount: 4,
  ),
  rampProfile: Model3dRampProfile(
    x: -.5,
    z: -2,
    width: 1,
    depth: 2,
    lowHeight: 0,
    highHeight: 1,
    direction: SpatialRampDirection.north,
  ),
);

MapData linkedMap() {
  final levels = List.filled(144, 0);
  levels[1 * 12 + 2] = 4;
  return MapData(
    id: 'map',
    name: 'Escaliers liés',
    version: ProjectVersion.v9,
    size: const GridSize(width: 12, height: 12),
    spatialScene: MapSpatialScene(
      width: 12,
      depth: 12,
      levelHeight: .25,
      heightLevels: levels,
      instances: [
        SpatialModelInstance(
          id: 'stairs',
          modelId: 'stair-model',
          position: Model3dVector3(x: 2.5, y: 0, z: 4),
          blocksMovement: false,
        ),
      ],
      navigation: SpatialNavigationProfile(
        ramps: [
          SpatialRamp(
            id: 'slope',
            x: 2,
            z: 2,
            width: 1,
            depth: 2,
            lowLevel: 0,
            highLevel: 4,
            direction: SpatialRampDirection.north,
            surfaceInstanceId: 'stairs',
          ),
        ],
      ),
    ),
  );
}
