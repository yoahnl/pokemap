import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'a ramp retains its model surface through copying and serialization',
    () {
      final ramp = SpatialRamp.fromJson(rampJson(surface: 'stairs'));
      expect(ramp.toJson()['surfaceInstanceId'], 'stairs');
      expect(ramp.copyWith(x: 1.5).toJson()['surfaceInstanceId'], 'stairs');
      expect(
        ramp.copyWith(surfaceInstanceId: null),
        SpatialRamp.fromJson(rampJson()),
      );
      expect(SpatialRamp.fromJson(ramp.toJson()), ramp);
      expect(ramp, isNot(SpatialRamp.fromJson(rampJson())));
      final scene = surfaceScene(surface: 'stairs');
      expect(
        MapSpatialScene.fromJson(jsonDecode(jsonEncode(scene.toJson()))),
        scene,
      );
      expect(scene.worldHeightAt(2.625, 2), closeTo(.5, 1e-12));
    },
  );

  test('an ordinary ramp does not serialize a model surface', () {
    final ramp = SpatialRamp.fromJson(rampJson());
    expect(ramp.toJson().containsKey('surfaceInstanceId'), isFalse);
    final cleared = SpatialRamp.fromJson(rampJson(surface: null));
    expect(cleared, ramp);
  });

  test(
    'ramp surface identities follow model instance identity constraints',
    () {
      for (final id in ['', 'invalid/id', 'a' * 129]) {
        expect(
          () => SpatialRamp.fromJson(rampJson(surface: id)),
          throwsFormatException,
        );
      }
    },
  );

  test('a ramp cannot use a missing or blocking instance as its surface', () {
    expect(() => surfaceScene(surface: 'missing'), throwsFormatException);
    expect(
      () => surfaceScene(surface: 'stairs', blocking: true),
      throwsFormatException,
    );
    expect(
      surfaceScene(surface: 'stairs').instances.single.blocksMovement,
      isFalse,
    );
  });

  test(
    'deleting a referenced stair is rejected without changing navigation',
    () {
      final map = MapData(
        id: 'map',
        name: 'Escalier',
        version: ProjectVersion.v9,
        size: const GridSize(width: 6, height: 4),
        spatialScene: surfaceScene(surface: 'stairs'),
      );
      expect(
        () => const SpatialMapOperations().deleteInstance(map, 'stairs'),
        throwsFormatException,
      );
      expect(map.spatialScene!.instances.single.id, 'stairs');
      expect(
        map.spatialScene!.navigation.ramps.single.toJson()['surfaceInstanceId'],
        'stairs',
      );
    },
  );
}

Map<String, dynamic> rampJson({String? surface}) => {
  'id': 'slope',
  'x': 1.25,
  'z': 1.25,
  'width': 2.75,
  'depth': 1.5,
  'lowLevel': 0,
  'highLevel': 4,
  'direction': 'east',
  'surfaceInstanceId': ?surface,
};

MapSpatialScene surfaceScene({String? surface, bool blocking = false}) =>
    MapSpatialScene(
      width: 6,
      depth: 4,
      levelHeight: .25,
      heightLevels: List.generate(24, (index) => index % 6 >= 4 ? 4 : 0),
      navigation: SpatialNavigationProfile(
        ramps: [SpatialRamp.fromJson(rampJson(surface: surface))],
      ),
      instances: [
        SpatialModelInstance(
          id: 'stairs',
          modelId: 'stair-model',
          position: Model3dVector3(x: 2.625, y: 0, z: 2),
          blocksMovement: blocking,
        ),
      ],
    );
