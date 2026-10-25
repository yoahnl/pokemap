import 'package:flame_3d/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:map_render_3d/src/spatial_shadow_profile.dart';

void main() {
  test('light axes do not change when the scene is far from the origin', () {
    const direction = (x: -.61, y: .78, z: .15);
    final local = spatialShadowProjection(
      SpatialShadowProfile(casterInstanceIds: {'block'}),
      direction,
    ).view;
    final distant = spatialShadowProjection(
      SpatialShadowProfile(
        casterInstanceIds: {'block'},
        center: (x: 10000, y: 0, z: 10000),
      ),
      direction,
    ).view;
    for (var row = 0; row < 3; row++) {
      for (var column = 0; column < 3; column++) {
        expect(
          distant.entry(row, column),
          closeTo(local.entry(row, column), 1e-7),
        );
      }
    }
  });

  test('shadow bases remain orthonormal for arbitrary light directions', () {
    for (final direction in [
      (x: 0.0, y: 1.0, z: 0.0),
      (x: .4, y: .0001, z: -.7),
      (x: 0.0, y: -1.0, z: 0.0),
      (x: -.7, y: .8, z: .2),
    ]) {
      final basis = spatialShadowBasis(direction);
      expect(basis.right.length, closeTo(1, 1e-6));
      expect(basis.up.length, closeTo(1, 1e-6));
      expect(basis.forward.length, closeTo(1, 1e-6));
      expect(basis.right.dot(basis.up), closeTo(0, 1e-6));
      expect(basis.right.dot(basis.forward), closeTo(0, 1e-6));
      expect(basis.up.dot(basis.forward), closeTo(0, 1e-6));
    }
  });

  test(
    'solar projection stays continuous when sunlight approaches vertical',
    () {
      final profile = SpatialShadowProfile(casterInstanceIds: {'block'});
      final before = spatialShadowProjection(profile, (
        x: .141,
        y: 1,
        z: 0,
      )).viewProjection;
      final after = spatialShadowProjection(profile, (
        x: .144,
        y: 1,
        z: 0,
      )).viewProjection;
      for (var i = 0; i < 16; i++) {
        expect(after.storage[i], closeTo(before.storage[i], .002));
      }
    },
  );

  test('softness and actor receivers opt in with bounded filter radii', () {
    final original = SpatialShadowProfile(casterInstanceIds: {'house'});
    expect(original.filterRadius, 1);
    expect(original.actorReceivers, isFalse);
    final soft = SpatialShadowProfile(
      casterInstanceIds: {'house'},
      filterRadius: 2.5,
      actorReceivers: true,
    );
    expect(soft.filterRadius, 2.5);
    expect(soft.actorReceivers, isTrue);
    for (final radius in [-.1, 8.1, double.nan]) {
      expect(
        () => SpatialShadowProfile(
          casterInstanceIds: {'house'},
          filterRadius: radius,
        ),
        throwsArgumentError,
      );
    }
  });
  test(
    'the light projection puts a roof before its ground shadow on the same ray',
    () {
      final profile = SpatialShadowProfile(
        casterInstanceIds: {'house'},
        center: (x: 26.5, y: 2.5, z: 13),
      );
      final projection = spatialShadowProjection(profile, (
        x: -.65,
        y: .8,
        z: -.45,
      ));
      final roof = projection.viewProjection.transform(Vector4(26.5, 6, 13, 1));
      final ground = projection.viewProjection.transform(
        Vector4(26.5 + .65 * 5 / .8, 1, 13 + .45 * 5 / .8, 1),
      );
      expect(roof.x, closeTo(ground.x, 1e-5));
      expect(roof.y, closeTo(ground.y, 1e-5));
      expect(roof.z, lessThan(ground.z));
      expect(ground.z, inInclusiveRange(0, 1));
      expect(roof.z, inInclusiveRange(0, 1));
    },
  );

  test('shadow profiles reject unsafe volumes, negative bias and inverted receivers', () {
    for (final make in <void Function()>[
      () => SpatialShadowProfile(casterInstanceIds: {'house'}, bias: -.001),
      () => SpatialShadowProfile(casterInstanceIds: {'house'}, extent: 0),
      () =>
          SpatialShadowProfile(casterInstanceIds: {'house'}, resolution: 8192),
      () => SpatialShadowProfile(
        casterInstanceIds: {'house'},
        receiverMinY: 2,
        receiverMaxY: 1,
      ),
      () => SpatialShadowProfile(
        casterInstanceIds: {'house'},
        opacity: double.nan,
      ),
    ]) {
      expect(make, throwsArgumentError);
    }
  });

  test(
    'caster and hidden-material filters are immutable and independently opt in',
    () {
      final ids = {'house'};
      final materials = {'shadow'};
      final shadow = SpatialShadowProfile(casterInstanceIds: ids);
      final lighting = SpatialLightingProfile.stylized(
        shadow: shadow,
        hiddenMaterialsByInstance: {'house': materials},
      );
      ids.add('tree');
      materials.add('wall');
      expect(shadow.casterInstanceIds, {'house'});
      expect(lighting.hiddenMaterialsByInstance, {
        'house': {'shadow'},
      });
      expect(SpatialLightingProfile.disabled.shadow, isNull);
      expect(
        SpatialLightingProfile.disabled.hiddenMaterialsByInstance,
        isEmpty,
      );
      expect(SpatialLightingProfile.stylized().shadow, isNull);
    },
  );
}
