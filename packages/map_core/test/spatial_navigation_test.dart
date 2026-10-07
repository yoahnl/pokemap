import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'navigation has immutable roundtrip value semantics and default policy',
    () {
      final navigation = SpatialNavigationProfile(
        spawn: SpatialSpawn(x: 2, z: 3),
        allowDiagonalMovement: true,
        blockedAreas: [SpatialBlockedArea(x: 0, z: 0, width: 1, depth: 1)],
      );
      final copy = SpatialNavigationProfile.fromJson(navigation.toJson());
      expect(copy, navigation);
      expect(copy.hashCode, navigation.hashCode);
      expect(() => copy.blockedAreas.clear(), throwsUnsupportedError);
      final scene = MapSpatialScene(width: 4, depth: 4, navigation: navigation);
      expect(MapSpatialScene.fromJson(scene.toJson()), scene);
      final omitted = {...scene.toJson()}..remove('navigation');
      expect(
        MapSpatialScene.fromJson(omitted).navigation.allowDiagonalMovement,
        isFalse,
      );
    },
  );
  test('finite bounds, count limits, overlaps and spawn are rejected', () {
    expect(() => SpatialSpawn(x: double.nan, z: 1), throwsFormatException);
    expect(
      () => SpatialBlockedArea(x: 0, z: 0, width: double.infinity, depth: 1),
      throwsFormatException,
    );
    expect(
      () => SpatialNavigationProfile(
        blockedAreas: [
          SpatialBlockedArea(x: 0, z: 0, width: 2, depth: 2),
          SpatialBlockedArea(x: 1, z: 1, width: 1, depth: 1),
        ],
      ),
      throwsFormatException,
    );
    expect(
      () => MapSpatialScene(
        width: 2,
        depth: 2,
        navigation: SpatialNavigationProfile(spawn: SpatialSpawn(x: 2, z: 1)),
      ),
      throwsFormatException,
    );
    expect(
      () => SpatialNavigationProfile(
        ramps: List.generate(
          257,
          (i) => SpatialRamp(
            id: 'r$i',
            x: 0,
            z: 0,
            width: 1,
            depth: 1,
            lowLevel: 0,
            highLevel: 1,
            direction: SpatialRampDirection.north,
          ),
        ),
      ),
      throwsFormatException,
    );
  });
  test('all ramp directions interpolate and require contact with terrain', () {
    for (final direction in SpatialRampDirection.values) {
      final ramp = SpatialRamp(
        id: 'r',
        x: 1,
        z: 1,
        width: 1,
        depth: 1,
        lowLevel: 0,
        highLevel: 1,
        direction: direction,
      );
      final levels = List.filled(9, 0);
      switch (direction) {
        case SpatialRampDirection.north:
          levels[1] = 1;
        case SpatialRampDirection.south:
          levels[7] = 1;
        case SpatialRampDirection.east:
          levels[5] = 1;
        case SpatialRampDirection.west:
          levels[3] = 1;
      }
      final scene = MapSpatialScene(
        width: 3,
        depth: 3,
        heightLevels: levels,
        navigation: SpatialNavigationProfile(ramps: [ramp]),
      );
      expect(scene.worldHeightAt(1.5, 1.5), .5);
      expect(MapSpatialScene.fromJson(scene.toJson()), scene);
      expect(
        () => MapSpatialScene(
          width: 3,
          depth: 3,
          navigation: SpatialNavigationProfile(ramps: [ramp]),
        ),
        throwsFormatException,
      );
    }
  });
}
