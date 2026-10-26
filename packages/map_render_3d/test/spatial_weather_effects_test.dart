import 'dart:ui';

import 'package:flame_3d/camera.dart';
import 'package:flame_3d/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:flame_3d/graphics.dart';
import 'package:map_render_3d/src/spatial_render_context.dart';
import 'package:map_render_3d/src/spatial_weather_effects.dart';
import 'package:map_render_3d/src/spatial_weather_material.dart';
import 'package:map_render_3d/src/spatial_weather_profile.dart';

void main() {
  test('weather edits retain existing atmosphere and presentation pools', () {
    final control = SpatialSceneController();
    addTearDown(control.dispose);
    control.applyAtmosphereSettings(SpatialAtmosphereSettings());
    final atmosphere = control.atmosphereProfile;
    final presentation = control.presentationProfile;
    var invalidations = 0;
    control.sceneChanges.addListener(() => invalidations++);
    for (final kind in SpatialWeatherKind.values) {
      control.applyAtmosphereSettings(
        SpatialAtmosphereSettings(
          weather: SpatialWeatherSettings(enabled: true, kind: kind),
        ),
      );
      expect(control.weatherSettings.kind, kind);
      expect(control.atmosphereProfile, same(atmosphere));
      expect(control.presentationProfile, same(presentation));
    }
    expect(invalidations, 0);
  });
  test(
    'transitions are bounded and interiors suppress weather immediately',
    () {
      final effects = SpatialWeatherEffects(World3D());
      final context = SpatialRenderContext(_Device());
      final base = SpatialPresentationProfile(
        fogStart: 20,
        fogEnd: 60,
        fogOpacity: .2,
      );
      void sync(
        SpatialWeatherKind kind, {
        bool indoors = false,
        bool enabled = true,
      }) {
        context
          ..lighting = SpatialLightingProfile.disabled
          ..presentationProfile = base
          ..depthFogEnabled = false;
        effects.sync(
          settings: SpatialWeatherSettings(
            enabled: enabled,
            kind: kind,
            intensity: 1,
            density: 1,
          ),
          context: context,
          dt: .1,
          seconds: 1,
          night: 0,
          indoors: indoors,
          anchor: Vector3.zero(),
          bounds: const Rect.fromLTWH(0, 0, 100, 100),
          cameraDistance: 40,
        );
        expect(
          effects.particleCount,
          inInclusiveRange(0, spatialWeatherMaximumParticles),
        );
        expect(context.presentationProfile.fogOpacity, lessThanOrEqualTo(.5));
      }

      for (final kind in SpatialWeatherKind.values) {
        for (var i = 0; i < 9; i++) {
          sync(kind);
        }
      }
      sync(SpatialWeatherKind.blizzard);
      sync(SpatialWeatherKind.blizzard, indoors: true);
      expect(effects.particleCount, 0);
      expect(context.lighting, same(SpatialLightingProfile.disabled));
      expect(context.depthFogEnabled, isFalse);
      expect(base.fogOpacity, .2);
      expect(base.fogStart, 20);
      expect(base.fogEnd, 60);
    },
  );
  test(
    'particle geometry is one fixed reusable surface with deterministic seeds',
    () {
      final first = SpatialWeatherBatch();
      final second = SpatialWeatherBatch();
      expect(first.mesh.surfaces.length, 1);
      expect(first.mesh.vertexCount, spatialWeatherMaximumParticles * 4);
      expect(
        first.mesh.surfaces.single.aabb.min,
        second.mesh.surfaces.single.aabb.min,
      );
      expect(
        first.mesh.surfaces.single.aabb.max,
        second.mesh.surfaces.single.aabb.max,
      );
      expect(first.material.visible, isFalse);
      first.position.setValues(200, 5, 300);
      expect(first.aabb.min.x, 170);
      expect(first.aabb.max.x, 230);
      expect(first.aabb.min.z, 270);
      expect(first.aabb.max.y, 21);
      expect(first.mesh.aabb.max.x, greaterThan(300));
    },
  );
}

class _Device implements GraphicsDevice {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
