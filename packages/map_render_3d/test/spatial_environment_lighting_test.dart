import 'dart:ui';

import 'package:flame_3d/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:map_render_3d/src/spatial_environment_lighting.dart';
import 'package:map_render_3d/src/spatial_point_light.dart';
import 'package:map_render_3d/src/spatial_authored_shadows.dart';

void main() {
  test(
    'solar shadows fade out at night while point lighting stays independent',
    () {
      final base = spatialAuthoredShadowLighting(
        [
          SpatialAuthoredShadowCaster(
            id: 'house',
            bounds: Model3dBounds(
              min: Model3dVector3.zero,
              max: Model3dVector3(x: 2, y: 3, z: 2),
            ),
            worldTransform: Matrix4.identity(),
          ),
        ],
        receiverMinY: 0,
        receiverMaxY: 1,
      );
      final midnight = spatialEnvironmentLighting(
        base,
        frame: spatialDayNightFrame(0),
      );
      final noon = spatialEnvironmentLighting(
        base,
        frame: spatialDayNightFrame(720),
      );
      expect(midnight.shadow, isNull);
      expect(midnight.sunStrength, 0);
      expect(midnight.ambientStrength, 1);
      expect(noon.shadow, same(base.shadow));
      expect(
        noon.ambientStrength + noon.sunStrength * noon.sunDirection.y,
        closeTo(1, 1e-6),
      );
    },
  );

  test(
    'controller seek validates and pauses preview without changing camera mode',
    () {
      final controller = SpatialSceneController();
      addTearDown(controller.dispose);
      expect(controller.previewDayNightRunning, isFalse);
      expect(controller.previewMinuteOfDay, isNull);
      controller.previewDayNightRunning = true;
      controller.previewMinuteOfDay = 1140;
      expect(controller.previewDayNightRunning, isFalse);
      expect(controller.dayNightMinuteOfDay, 1140);
      expect(controller.view, SpatialEditorView.orbit);
      controller.previewMinuteOfDay = null;
      expect(controller.previewMinuteOfDay, isNull);
      expect(() => controller.previewMinuteOfDay = 1440, throwsArgumentError);
    },
  );

  test('profiles cannot silently exceed the four light budget', () {
    final lights = [
      for (var i = 0; i < 5; i++)
        SpatialPointLight(position: (x: i.toDouble(), y: 1, z: 0), radius: 4),
    ];
    expect(
      () => SpatialLightingProfile.stylized(pointLights: lights),
      throwsArgumentError,
    );
  });
  test('day night palette is continuous and lamps fade across twilight', () {
    final noon = spatialDayNightFrame(720);
    final midnight = spatialDayNightFrame(0);
    final sunset = spatialDayNightFrame(1140);
    expect(noon.tint, const Color(0xffffffff));
    expect(noon.daylight, 1);
    expect(midnight.daylight, 0);
    expect(midnight.tint.b, greaterThan(midnight.tint.r));
    expect(sunset.daylight, inExclusiveRange(0, 1));
    final beforeMidnight = spatialDayNightFrame(1439.999);
    expect(beforeMidnight.tint, midnight.tint);
    expect(spatialDayNightFrame(1440).tint, midnight.tint);
  });

  test(
    'local lights transform the emitter but preserve their world radius',
    () {
      final definition = Model3dPointLight(
        localPosition: Model3dVector3(x: 1, y: 3, z: 0),
        radius: 4,
      );
      final transform = Matrix4.compose(
        Vector3(10, 2, 5),
        Quaternion.axisAngle(Vector3(0, 1, 0), 3.141592653589793 / 2),
        Vector3.all(2),
      );
      final light = spatialPlacedPointLight(definition, transform, daylight: 0);
      expect(light.position.x, closeTo(10, 1e-6));
      expect(light.position.y, 8);
      expect(light.position.z, closeTo(3, 1e-6));
      expect(light.radius, 4);
      expect(light.intensity, 1);
      expect(
        spatialPlacedPointLight(definition, transform, daylight: 1).intensity,
        0,
      );
      expect(
        spatialPlacedPointLight(definition, transform, daylight: .5).intensity,
        .5,
      );
    },
  );

  test('point attenuation is finite, smooth at its radius, and bounded', () {
    expect(spatialPointLightAttenuation(0, 4), 1);
    expect(spatialPointLightAttenuation(4, 4), closeTo(.5625, 1e-6));
    expect(spatialPointLightAttenuation(16, 4), 0);
    expect(spatialPointLightAttenuation(100, 4), 0);
    for (final radius in [0.0, -1.0, double.nan]) {
      expect(
        () => SpatialPointLight(position: (x: 0, y: 0, z: 0), radius: radius),
        throwsArgumentError,
      );
    }
  });

  test(
    'environment tint and lamps apply without enabling normal relighting',
    () {
      final frame = spatialDayNightFrame(0);
      final result = spatialEnvironmentLighting(
        SpatialLightingProfile.disabled,
        frame: frame,
        lights: [SpatialPointLight(position: (x: 1, y: 3, z: 2), radius: 4)],
      );
      expect(result.enabled, isTrue);
      expect(result.surfaceStrength, 0);
      expect(result.sceneTint, frame.tint);
      expect(result.pointLights, hasLength(1));
      expect(result.shadow, isNull);
      expect(
        spatialEnvironmentLighting(SpatialLightingProfile.disabled),
        same(SpatialLightingProfile.disabled),
      );
    },
  );

  test(
    'preview clock supports seek play pause reset and runtime continuity',
    () {
      final clock = SpatialDayNightPreviewClock();
      final cycle = SpatialDayNightCycle(
        durationSeconds: 600,
        startMinuteOfDay: 720,
      );
      expect(clock.minute(cycle), 720);
      clock.advance(150);
      expect(clock.minute(cycle), 720);
      expect(clock.minute(cycle, externalElapsedSeconds: 150), 1080);
      clock.seek(1380);
      clock.running = true;
      clock.advance(50);
      expect(clock.minute(cycle), 60);
      clock.running = false;
      clock.advance(50);
      expect(clock.minute(cycle), 60);
      clock.seek(null);
      expect(clock.minute(cycle, externalElapsedSeconds: 150), 1080);
      expect(() => clock.seek(double.nan), throwsArgumentError);
    },
  );

  test('light selection is bounded deterministic and follows the camera', () {
    final lights = [
      for (var i = 0; i < 7; i++)
        SpatialPointLight(position: (x: i.toDouble(), y: 2, z: 0), radius: 4),
    ];
    final selected = spatialVisiblePointLights(lights, Vector3(6, 0, 0));
    expect(selected, hasLength(4));
    expect(selected.first.position.x, 6);
    expect(selected.last.position.x, 3);
  });
}
