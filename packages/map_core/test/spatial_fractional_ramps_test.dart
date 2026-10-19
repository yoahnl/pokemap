import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  const operations = SpatialMapOperations();

  test('fractional ramp endpoint numbers survive JSON and value semantics', () {
    for (final high in [1.5, 2.625, 18439 / 16384]) {
      final ramp = SpatialRamp.fromJson(rampJson(low: .125, high: high));
      expect(ramp.lowLevel, .125);
      expect(ramp.highLevel, high);
      expect(ramp.hasFractionalLevels, isTrue);
      expect(ramp.levelAt(8, 7), (.125 + high) / 2);
      final copy = SpatialRamp.fromJson(
        jsonDecode(jsonEncode(ramp.toJson())) as Map<String, dynamic>,
      );
      expect(copy, ramp);
      expect(copy.hashCode, ramp.hashCode);
      expect(ramp.copyWith(x: 8).highLevel, high);
    }
  });

  test('integral endpoint numbers retain canonical JSON integer encoding', () {
    final ramp = SpatialRamp.fromJson(rampJson(low: 0.0, high: 3.0));
    expect(ramp.toJson()['lowLevel'], isA<int>());
    expect(ramp.toJson()['highLevel'], isA<int>());
    expect(ramp.toJson()['highLevel'], 3);
    expect(ramp.hasFractionalLevels, isFalse);
    expect(
      SpatialRamp.fractionalLevelsCapabilityId,
      'map3d.fractional-ramps@1',
    );
    expect(SpatialRamp.fromJson(rampJson(low: 0, high: 64)).highLevel, 64);
  });

  test(
    'nonfinite reversed negative and excessive ramp levels are rejected',
    () {
      for (final (low, high) in <(num, num)>[
        (double.nan, 2),
        (0, double.nan),
        (double.infinity, 2),
        (0, double.infinity),
        (double.negativeInfinity, 2),
        (0, double.negativeInfinity),
        (-.125, 2),
        (0, 64.0001),
        (2, 2),
        (2, 1.5),
      ]) {
        expect(
          () => SpatialRamp.fromJson(rampJson(low: low, high: high)),
          throwsFormatException,
          reason: '$low -> $high',
        );
      }
    },
  );

  for (final high in [1.5, 2.625, 18439 / 16384]) {
    test(
      'source height $high contacts explicit continuous landings in four turns',
      () {
        final model = sourceModel(high);
        for (final angle in [0.0, 90.0, 180.0, 270.0]) {
          final placed = operations.upsertInstance(
            flatMap(),
            sourceInstance(model).copyWith(rotationDegrees: angle),
            model: model,
          );
          final unfinished = placed.spatialScene!;
          final ramp = unfinished.navigation.ramps.single;
          expect(unfinished.levelHeight, 1);
          expect(unfinished.heightLevels, everyElement(isA<int>()));
          expect(ramp.lowLevel, 0);
          expect(ramp.highLevel, high);
          expect(ramp.surfaceInstanceId, 'stairs');
          expect(unfinished.rampHasTerrainContacts(ramp), isFalse);
          expect(unfinished.instances.single.blocksMovement, isFalse);
          expect(
            unfinished.worldHeightAt(
              ramp.x + ramp.width / 2,
              ramp.z + ramp.depth / 2,
            ),
            high / 2,
          );
          final connected = withLandings(placed);
          expect(connected.spatialScene!.rampHasTerrainContacts(ramp), isTrue);
          expect(
            MapData.fromJson(
              jsonDecode(jsonEncode(connected.toJson()))
                  as Map<String, dynamic>,
            ),
            connected,
          );
          expect(connected.spatialScene!.heightLevels, unfinished.heightLevels);
          expect(
            operations
                .deleteInstance(connected, 'stairs')
                .spatialScene!
                .navigation
                .ramps,
            isEmpty,
          );
        }
      },
    );
  }

  test(
    'linked fractional endpoints move rotate and scale without quantization',
    () {
      final model = sourceModel(18439 / 16384);
      final placed = operations.upsertInstance(
        flatMap(),
        sourceInstance(model),
        model: model,
      );
      final before = placed.spatialScene!.instances.single;
      final changed = before.copyWith(
        position: Model3dVector3(x: 10, y: .1, z: 11),
        rotationDegrees: 90,
        scale: 1.25,
      );
      final moved = operations.upsertInstance(placed, changed);
      final ramp = moved.spatialScene!.navigation.ramps.single;
      expect(ramp.lowLevel, .1);
      expect(ramp.highLevel, .1 + (18439 / 16384) * 1.25);
      expect(ramp.direction, SpatialRampDirection.west);
      expect((ramp.width, ramp.depth), (2.5, 1.25));
      expect(moved.spatialScene!.rampHasTerrainContacts(ramp), isFalse);
      expect(
        withLandings(moved).spatialScene!.rampHasTerrainContacts(ramp),
        isTrue,
      );
      expect(operations.upsertInstance(moved, before), placed);
    },
  );

  test(
    'fractional source pivot and both scales affect physical endpoints once',
    () {
      final model = sourceModel(
        2.625,
      ).copyWith(scale: 2, pivot: Model3dVector3(x: .25, y: .125, z: -.25));
      final placed = operations.upsertInstance(
        flatMap(),
        sourceInstance(
          model,
        ).copyWith(position: Model3dVector3(x: 8, y: .25, z: 8), scale: .75),
        model: model,
      );
      final scene = placed.spatialScene!;
      final ramp = scene.navigation.ramps.single;
      expect(ramp.lowLevel, .25 - .125 * 1.5);
      expect(ramp.highLevel, .25 + (2.625 - .125) * 1.5);
      expect(
        scene.worldHeightAt(ramp.x + ramp.width / 2, ramp.z + ramp.depth / 2),
        .25 + (2.625 / 2 - .125) * 1.5,
      );
      expect(
        withLandings(placed).spatialScene!.rampHasTerrainContacts(ramp),
        isTrue,
      );
    },
  );

  test(
    'fractional endpoints reanchor with their explicit continuous landings',
    () {
      final model = sourceModel(18439 / 16384);
      final placed = operations.upsertInstance(
        flatMap(),
        sourceInstance(model),
        model: model,
      );
      final connected = withLandings(placed);
      final raised = operations.upsertTerrainSurfaces(connected, [
        for (final surface in connected.spatialScene!.terrainSurfaces.surfaces)
          surface.copyWith(height: surface.height + .375),
      ]);
      final ramp = raised.spatialScene!.navigation.ramps.single;
      expect(raised.spatialScene!.instances.single.position.y, .375);
      expect(ramp.lowLevel, .375);
      expect(ramp.highLevel, .375 + 18439 / 16384);
      expect(raised.spatialScene!.rampHasTerrainContacts(ramp), isTrue);
      expect(
        raised.spatialScene!.heightLevels,
        connected.spatialScene!.heightLevels,
      );
    },
  );

  test(
    'changing levelHeight preserves physical fractional ramp and landing heights',
    () {
      final model = sourceModel(18439 / 16384);
      final placed = operations.upsertInstance(
        flatMap(),
        sourceInstance(model),
        model: model,
      );
      final connected = withLandings(placed);
      final changed = operations.configureLevelHeight(connected, .3);
      final ramp = changed.spatialScene!.navigation.ramps.single;
      expect(ramp.highLevel * .3, closeTo(18439 / 16384, 1e-12));
      expect(
        changed.spatialScene!.worldHeightAt(
          ramp.x + ramp.width / 2,
          ramp.z + ramp.depth / 2,
        ),
        closeTo((18439 / 16384) / 2, 1e-12),
      );
      expect(changed.spatialScene!.rampHasTerrainContacts(ramp), isTrue);
      expect(
        changed.spatialScene!.terrainSurfaces,
        connected.spatialScene!.terrainSurfaces,
      );
      expect(operations.configureLevelHeight(changed, 1), connected);
    },
  );

  test(
    'fractional attachment keeps cardinal bounds ownership and contact guards',
    () {
      final model = sourceModel(1.5);
      final before = flatMap();
      final instance = sourceInstance(model);
      for (final invalid in [
        instance.copyWith(rotationDegrees: 37),
        instance.copyWith(position: Model3dVector3(x: .1, y: 0, z: .1)),
        instance.copyWith(position: Model3dVector3(x: 8, y: -.1, z: 8)),
        instance.copyWith(position: Model3dVector3(x: 8, y: 64, z: 8)),
      ]) {
        expect(
          () => operations.upsertInstance(before, invalid, model: model),
          throwsFormatException,
        );
      }
      final placed = operations.upsertInstance(before, instance, model: model);
      expect(
        () => operations.upsertInstance(
          placed,
          SpatialModelInstance(
            id: 'other',
            modelId: model.id,
            position: instance.position,
          ),
          model: model,
        ),
        throwsFormatException,
      );
      final ramp = placed.spatialScene!.navigation.ramps.single;
      expect(
        () => placed.spatialScene!.copyWith(instances: const []),
        throwsFormatException,
      );
      expect(
        () => placed.spatialScene!.copyWith(
          instances: [instance.copyWith(blocksMovement: true)],
        ),
        throwsFormatException,
      );
      expect(
        () => placed.spatialScene!.copyWith(
          navigation: SpatialNavigationProfile(
            ramps: [ramp.copyWith(surfaceInstanceId: null)],
          ),
        ),
        throwsFormatException,
      );
      expect(before.spatialScene!.instances, isEmpty);
    },
  );
}

Map<String, dynamic> rampJson({required num low, required num high}) => {
  'id': 'fractional',
  'x': 7.5,
  'z': 6,
  'width': 1,
  'depth': 2,
  'lowLevel': low,
  'highLevel': high,
  'direction': 'north',
};

MapData flatMap() => MapData(
  id: 'fractional',
  name: 'Fractional source stairs',
  version: ProjectVersion.v9,
  size: const GridSize(width: 20, height: 20),
  spatialScene: MapSpatialScene(width: 20, depth: 20),
);

ProjectModel3dEntry sourceModel(double high) => ProjectModel3dEntry(
  id: 'source-stairs',
  name: 'Source-height fixture',
  sourceAssetId: 'stairs-source',
  relativePath: 'assets/models3d/source-stairs.glb',
  inspection: Model3dInspection(
    bounds: Model3dBounds(
      min: Model3dVector3(x: -.5, y: 0, z: -2),
      max: Model3dVector3(x: .5, y: high, z: 0),
    ),
    meshCount: 1,
    triangleCount: 2,
  ),
  rampProfile: Model3dRampProfile(
    x: -.5,
    z: -2,
    width: 1,
    depth: 2,
    lowHeight: 0,
    highHeight: high,
    direction: SpatialRampDirection.north,
  ),
);

SpatialModelInstance sourceInstance(ProjectModel3dEntry model) =>
    SpatialModelInstance(
      id: 'stairs',
      modelId: model.id,
      position: Model3dVector3(x: 8, y: 0, z: 8),
    );

MapData withLandings(MapData map) {
  final scene = map.spatialScene!;
  final ramp = scene.navigation.ramps.single;
  final alongZ =
      ramp.direction == SpatialRampDirection.north ||
      ramp.direction == SpatialRampDirection.south;
  final negativeHigh =
      ramp.direction == SpatialRampDirection.north ||
      ramp.direction == SpatialRampDirection.west;
  final width = alongZ ? ramp.width : 1.0;
  final depth = alongZ ? 1.0 : ramp.depth;
  return map.copyWith(
    spatialScene: scene.copyWith(
      terrainSurfaces: SpatialTerrainSurfaceSet(
        surfaces: [
          for (final negative in [true, false])
            SpatialTerrainSurface(
              id: negative ? 'negative-landing' : 'positive-landing',
              x: alongZ
                  ? ramp.x
                  : negative
                  ? ramp.x - 1
                  : ramp.x + ramp.width,
              z: alongZ
                  ? negative
                        ? ramp.z - 1
                        : ramp.z + ramp.depth
                  : ramp.z,
              height:
                  (negative == negativeHigh ? ramp.highLevel : ramp.lowLevel) *
                  scene.levelHeight,
              footprints: [
                BorderGroundFootprint(
                  points: [
                    BorderGroundPoint(x: 0, z: 0),
                    BorderGroundPoint(x: width, z: 0),
                    BorderGroundPoint(x: width, z: depth),
                    BorderGroundPoint(x: 0, z: depth),
                  ],
                ),
              ],
            ),
        ],
      ),
    ),
  );
}
