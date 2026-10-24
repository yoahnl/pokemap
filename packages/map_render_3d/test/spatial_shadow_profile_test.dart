import 'package:flame_3d/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:map_render_3d/src/spatial_shadow_profile.dart';

void main() {
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
