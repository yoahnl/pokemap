import 'package:flame_3d/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_authored_shadows.dart';
import 'package:map_render_3d/src/spatial_lighting_preview.dart';
import 'package:map_render_3d/src/spatial_shadow_profile.dart';
import 'package:map_render_3d/src/spatial_environment_lighting.dart';

ProjectModel3dEntry model(bool enabled) => ProjectModel3dEntry(
  id: 'house',
  name: 'House',
  sourceAssetId: 'source-house',
  relativePath: 'assets/models3d/house.glb',
  castsShadowsByDefault: enabled,
  inspection: Model3dInspection(
    bounds: Model3dBounds(
      min: Model3dVector3.zero,
      max: Model3dVector3(x: 3, y: 5, z: 2),
    ),
    meshCount: 1,
    triangleCount: 12,
  ),
);

SpatialModelInstance instance({bool? enabled}) => SpatialModelInstance(
  id: 'placed-house',
  modelId: 'house',
  position: Model3dVector3(x: 10, y: 2, z: 12),
  castsShadows: enabled,
);

SpatialAuthoredShadowCaster? caster(
  ProjectModel3dEntry model,
  SpatialModelInstance instance, {
  String mapId = 'town',
}) => spatialAuthoredShadowCaster(
  mapId: mapId,
  instance: instance,
  definition: model,
  bounds: model.inspection.bounds,
  worldTransform: Matrix4.translationValues(10, 2, 12),
);

void main() {
  test('daylight refits the light volume for every moving caster ground projection', () {
    final source = caster(model(true), instance())!;
    final base = spatialAuthoredShadowLighting(
      [source],
      receiverMinY: 0,
      receiverMaxY: 3,
    );
    for (final minute in [300.0, 480.0, 720.0, 1020.0, 1260.0]) {
      final direction = spatialDayNightSunDirection(
        base.sunDirection,
        spatialDayNightFrame(minute),
      );
      final lighting = spatialAuthoredShadowLighting(
        [source],
        receiverMinY: 0,
        receiverMaxY: 3,
        sunDirection: direction,
      );
      final matrix = spatialShadowProjection(
        lighting.shadow!,
        lighting.sunDirection,
      ).viewProjection;
      final sun = Vector3(direction.x, direction.y, direction.z);
      for (final point in source.worldCorners) {
        for (final sample in [point, point - sun * (point.y / sun.y)]) {
          final clip = matrix.transform(
            Vector4(sample.x, sample.y, sample.z, 1),
          );
          expect(clip.x, inInclusiveRange(-1, 1));
          expect(clip.y, inInclusiveRange(-1, 1));
          expect(clip.z, inInclusiveRange(0, 1));
        }
      }
      expect(lighting.shadow!.resolution, 1024);
      expect(
        lighting.shadow!.casterInstanceIds,
        base.shadow!.casterInstanceIds,
      );
      if (minute == 720) {
        expect(lighting.sunDirection, base.sunDirection);
        expect(lighting.shadow!.center, base.shadow!.center);
        expect(lighting.shadow!.extent, base.shadow!.extent);
        expect(lighting.shadow!.depth, base.shadow!.depth);
      }
    }
    for (final direction in [
      (x: 0.0, y: 1.0, z: 0.0),
      (x: 1.0, y: .01, z: 0.0),
    ]) {
      final result = spatialAuthoredShadowLighting(
        [source],
        receiverMinY: 0,
        receiverMaxY: 3,
        sunDirection: direction,
      );
      expect(result.shadow!.extent.isFinite, isTrue);
      expect(result.sunStrength, inInclusiveRange(0, 2));
    }
    expect(
      () => spatialAuthoredShadowLighting(
        [source],
        receiverMinY: 0,
        receiverMaxY: 3,
        sunDirection: (x: 0, y: -1, z: 0),
      ),
      throwsArgumentError,
    );
  });
  test('receiver floor follows elevated terrain instead of an imaginary zero plane', () {
    final scene = MapSpatialScene(
      width: 2,
      depth: 1,
      levelHeight: 16,
      heightLevels: [32, 33],
    );
    expect(spatialShadowReceiverMinimumHeight(scene), 512);
    final a = caster(model(true), instance())!;
    final b = SpatialAuthoredShadowCaster(
      id: a.id,
      bounds: model(true).inspection.bounds,
      worldTransform: Matrix4.translationValues(10, 514, 12),
    );
    final low = spatialAuthoredShadowLighting(
      [a],
      receiverMinY: 0,
      receiverMaxY: 3,
    ).shadow!;
    final high = spatialAuthoredShadowLighting(
      [b],
      receiverMinY: 512,
      receiverMaxY: 515,
    ).shadow!;
    expect(high.extent, closeTo(low.extent, 1e-6));
    expect(high.depth, closeTo(low.depth, 1e-6));
  });

  test(
    'resources default off, instances inherit or explicitly enable and disable',
    () {
      expect(caster(model(false), instance()), isNull);
      expect(caster(model(false), instance(enabled: true)), isNotNull);
      expect(caster(model(true), instance()), isNotNull);
      expect(caster(model(true), instance(enabled: false)), isNull);
      final reset = instance(enabled: false).copyWith(clearCastsShadows: true);
      expect(caster(model(true), reset), isNotNull);
      expect(caster(model(false), reset), isNull);
    },
  );

  test('no effective caster keeps the normal renderer disabled', () {
    expect(
      spatialAuthoredShadowLighting(const [], receiverMinY: 0, receiverMaxY: 2),
      same(SpatialLightingProfile.disabled),
    );
  });

  test(
    'normal shadows preserve native artwork and use neutral receiving light',
    () {
      final lighting = spatialAuthoredShadowLighting(
        [caster(model(true), instance())!],
        receiverMinY: 0,
        receiverMaxY: 3,
      );
      expect(lighting.enabled, isTrue);
      expect(lighting.surfaceStrength, 0);
      expect(lighting.actorStrength, 1);
      expect(lighting.groundStrength, 1);
      expect(lighting.shadow!.actorReceivers, isTrue);
      for (final color in [
        lighting.ambientColor.r,
        lighting.ambientColor.g,
        lighting.ambientColor.b,
      ]) {
        expect(
          color * lighting.ambientStrength +
              lighting.sunStrength * lighting.sunDirection.y,
          closeTo(1, 1e-6),
        );
      }
    },
  );

  test('derived light volume contains transformed geometry and its ground projection', () {
    final source = caster(model(true), instance())!;
    final lighting = spatialAuthoredShadowLighting(
      [source],
      receiverMinY: 0,
      receiverMaxY: 3,
    );
    final projection = spatialShadowProjection(
      lighting.shadow!,
      lighting.sunDirection,
    ).viewProjection;
    for (final point in source.worldCorners) {
      final ground =
          point -
          Vector3(
                lighting.sunDirection.x,
                lighting.sunDirection.y,
                lighting.sunDirection.z,
              ) *
              (point.y / lighting.sunDirection.y);
      for (final sample in [point, ground]) {
        final clip = projection.transform(
          Vector4(sample.x, sample.y, sample.z, 1),
        );
        expect(clip.x, inInclusiveRange(-1, 1));
        expect(clip.y, inInclusiveRange(-1, 1));
        expect(clip.z, inInclusiveRange(0, 1));
      }
    }
  });

  test(
    'neighboring maps qualify their instance identities without collisions',
    () {
      final a = caster(model(true), instance(), mapId: 'a')!;
      final b = caster(model(true), instance(), mapId: 'b')!;
      expect(a.id, isNot(b.id));
      final lighting = spatialAuthoredShadowLighting(
        [a, b],
        receiverMinY: 0,
        receiverMaxY: 2,
      );
      expect(lighting.shadow!.casterInstanceIds, {a.id, b.id});
    },
  );
}
