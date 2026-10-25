import 'package:flame_3d/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:map_render_3d/src/spatial_point_shadow.dart';
import 'package:map_render_3d/src/spatial_environment_lighting.dart';

void main() {
  test('cube face culling retains near crossings and seam boundaries', () {
    final light = SpatialPointLight(position: (x: 3, y: 4, z: 5), radius: 10);
    for (var face = 0; face < 6; face++) {
      final projection = spatialPointShadowProjection(light, face);
      final direction = spatialPointShadowRay(Vector2(.5, .5), face);
      final center = Vector3(3, 4, 5) + direction * 4;
      final half = Vector3.all(.1);
      final bounds = Aabb3.minMax(center - half, center + half);
      for (var candidate = 0; candidate < 6; candidate++) {
        expect(
          spatialPointShadowIntersectsFace(
            spatialPointShadowProjection(light, candidate).viewProjection,
            bounds,
          ),
          candidate == face,
        );
      }
      expect(
        spatialPointShadowIntersectsFace(
          projection.viewProjection,
          Aabb3.minMax(Vector3(2, 3, 4), Vector3(4, 5, 6)),
        ),
        isTrue,
      );
      expect(
        spatialPointShadowIntersectsFace(
          projection.viewProjection,
          Aabb3.minMax(Vector3(7, 8, 9), Vector3(7.1, 8.1, 9.1)),
        ),
        face == 0 || face == 2 || face == 4,
      );
    }
  });

  test('receiver plane comparison removes grazing self shadow without erasing a nearer blocker', () {
    final receiver = Vector3(6, .6, .3), normal = Vector3(0, 0, 1);
    final face = spatialPointShadowFace(receiver);
    final atlas = spatialPointShadowAtlasUv(receiver, face, 1);
    final localUv = Vector2(atlas.x * 3 - face % 3, atlas.y * 2 - face ~/ 3);
    for (var x = -1; x <= 1; x++) {
      for (var y = -1; y <= 1; y++) {
        final ray = spatialPointShadowRay(
          Vector2(localUv.x + x / 256, localUv.y + y / 256),
          face,
        );
        final samePlaneDistance = normal.dot(receiver) / normal.dot(ray);
        final reference = spatialPointShadowReferenceDistance(
          receiver,
          normal,
          ray,
          radius: 9,
        );
        expect(reference, lessThanOrEqualTo(samePlaneDistance));
        expect(reference, greaterThan(samePlaneDistance - .25));
      }
    }
    final facing = spatialPointShadowReceiverBias(6, 1, 256, 9);
    final grazing = spatialPointShadowReceiverBias(6, .05, 256, 9);
    expect(grazing, greaterThan(facing));
    expect(grazing, lessThanOrEqualTo(.02));
    expect(
      spatialPointShadowReceiverBias(.0005, .01, 256, .001),
      lessThanOrEqualTo(.000005),
    );
  });
  test('tiny positive lights retain a valid near far range and zero rays are rejected', () {
    final light = SpatialPointLight(position: (x: 0, y: 0, z: 0), radius: .001);
    final matrix = spatialPointShadowProjection(light, 0).viewProjection;
    expect(
      matrix.storage,
      everyElement(predicate<double>((value) => value.isFinite)),
    );
    final clip = matrix.transform(Vector4(.0005, 0, 0, 1));
    expect(clip.z / clip.w, inInclusiveRange(0, 1));
    expect(
      () => spatialPointShadowAtlasUv(Vector3.zero(), 0, 1),
      throwsArgumentError,
    );
  });
  test(
    'all six cube faces agree with analytic sampling and zero to one depth',
    () {
      final light = SpatialPointLight(position: (x: 3, y: 4, z: 5), radius: 9);
      final directions = [
        Vector3(2, .3, -.7),
        Vector3(-2, .3, .7),
        Vector3(.3, 2, .7),
        Vector3(.3, -2, -.7),
        Vector3(.3, -.7, 2),
        Vector3(-.3, -.7, -2),
      ];
      for (var face = 0; face < 6; face++) {
        final delta = directions[face];
        expect(spatialPointShadowFace(delta), face);
        final projection = spatialPointShadowProjection(light, face);
        final sample = Vector3(3, 4, 5) + delta;
        final clip = projection.viewProjection.transform(
          Vector4(sample.x, sample.y, sample.z, 1),
        );
        final uv = spatialPointShadowAtlasUv(delta, face, 1);
        expect(
          uv.x,
          closeTo((face % 3 + (clip.x / clip.w * .5 + .5)) / 3, 1e-6),
        );
        expect(
          uv.y,
          closeTo((face ~/ 3 + (.5 - clip.y / clip.w * .5)) / 2, 1e-6),
        );
        expect(clip.z / clip.w, inInclusiveRange(0, 1));
      }
    },
  );

  test(
    'each light owns six disjoint atlas tiles including face boundaries',
    () {
      for (var light = 0; light < 4; light++) {
        for (final delta in [
          Vector3(1, 1, 1),
          Vector3(-1, 1, 1),
          Vector3(.1, -1, 1),
          Vector3(.1, .3, -1),
        ]) {
          final face = spatialPointShadowFace(delta);
          final uv = spatialPointShadowAtlasUv(
            delta,
            face,
            4,
            lightIndex: light,
          );
          expect(
            uv.x,
            inInclusiveRange((face % 3) / 3 - 1e-6, (face % 3 + 1) / 3 + 1e-6),
          );
          expect(
            uv.y,
            inInclusiveRange(
              (light * 2 + face ~/ 3) / 8 - 1e-6,
              (light * 2 + face ~/ 3 + 1) / 8 + 1e-6,
            ),
          );
        }
      }
    },
  );

  test(
    'point shadow caster identities survive solar shadow shutdown at night',
    () {
      final base = SpatialLightingProfile.stylized(
        surfaceStrength: 0,
        shadow: SpatialShadowProfile(casterInstanceIds: {'town:house'}),
      );
      final night = spatialEnvironmentLighting(
        base,
        frame: spatialDayNightFrame(1320),
        lights: [SpatialPointLight(position: (x: 1, y: 3, z: 2), radius: 4)],
      );
      expect(night.shadow, isNull);
      expect(night.pointShadowCasterInstanceIds, {'town:house'});
      final controller = SpatialSceneController();
      addTearDown(controller.dispose);
      expect(controller.previewPointLightShadowsEnabled, isTrue);
      controller.previewPointLightShadowsEnabled = false;
      expect(controller.previewPointLightShadowsEnabled, isFalse);
    },
  );

  test('sphere admission excludes remote geometry without discarding intersections', () {
    final light = SpatialPointLight(position: (x: 0, y: 2, z: 0), radius: 4);
    expect(
      spatialPointShadowIntersects(
        light,
        Aabb3.minMax(Vector3(1, 0, 1), Vector3(3, 5, 3)),
      ),
      isTrue,
    );
    expect(
      spatialPointShadowIntersects(
        light,
        Aabb3.minMax(Vector3(10, 0, 1), Vector3(12, 5, 3)),
      ),
      isFalse,
    );
  });
}
