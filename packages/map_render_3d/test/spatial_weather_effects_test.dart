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
  test('sky illumination needs no rain geometry and clears immediately indoors', () {
    final effects = SpatialWeatherEffects(World3D());
    final context = SpatialRenderContext(_Device());
    final settings = SpatialWeatherSettings(enabled: true, kind: SpatialWeatherKind.tempest, lightning: true, density: 0, opacity: 0, transitionSeconds: 0);
    void sync(bool indoors) => effects.sync(settings: settings, context: context, dt: .1, seconds: 4.35, night: 1, indoors: indoors, anchor: Vector3.zero(), bounds: const Rect.fromLTWH(0, 0, 35, 35), cameraDistance: 30);
    sync(false);
    expect(context.weatherSkyFlash, greaterThan(0));
    expect(effects.particleCount, 0);
    expect(context.weatherVeilOpacity, greaterThan(0));
    sync(true);
    expect(context.weatherSkyFlash, 0);
    expect(context.weatherVeilOpacity, 0);
  });
  test('rain impacts preserve independent manual fog distances', () {
    final effects = SpatialWeatherEffects(World3D());
    final base = SpatialPresentationProfile(
      fogStart: 100,
      fogEnd: 150,
      fogOpacity: .2,
    );
    final context = SpatialRenderContext(_Device())
      ..presentationProfile = base
      ..depthFogEnabled = true;
    effects.sync(
      settings: SpatialWeatherSettings(
        enabled: true,
        kind: SpatialWeatherKind.rain,
        fogStrength: 0,
        transitionSeconds: 0,
      ),
      context: context,
      dt: .1,
      seconds: 1,
      night: 0,
      indoors: false,
      anchor: Vector3.zero(),
      bounds: const Rect.fromLTWH(0, 0, 100, 100),
      cameraDistance: 30,
    );
    final profile = context.presentationProfile;
    expect(profile.weatherImpactStrength, greaterThan(0));
    expect(profile.fogAtDepth(30), 0);
    expect(profile.fogAtDepth(100), 0);
    expect(profile.fogAtDepth(150), closeTo(.2, 1e-6));
    expect(base.fogStart, 100);
    expect(base.fogEnd, 150);
  });

  test(
    'mist and fog remain visible at the camera target at different zooms',
    () {
      for (final distance in [8.0, 30.0, 70.0]) {
        final effects = SpatialWeatherEffects(World3D());
        final context = SpatialRenderContext(_Device());
        final base = SpatialPresentationProfile(fogOpacity: 0);
        final opacities = <double>[];
        for (final kind in [SpatialWeatherKind.mist, SpatialWeatherKind.fog]) {
          context
            ..lighting = SpatialLightingProfile.disabled
            ..presentationProfile = base
            ..depthFogEnabled = false;
          effects.sync(
            settings: SpatialWeatherSettings(
              enabled: true,
              kind: kind,
              transitionSeconds: 0,
            ),
            context: context,
            dt: .1,
            seconds: 12,
            night: 0,
            indoors: false,
            anchor: Vector3(20, 3, 30),
            bounds: const Rect.fromLTWH(0, 0, 80, 80),
            cameraDistance: distance,
          );
          opacities.add(context.presentationProfile.fogAtDepth(distance));
        }
        expect(opacities.first, greaterThan(.12));
        expect(opacities.last, greaterThan(.32));
        expect(opacities.last, greaterThan(opacities.first * 1.5));
        expect(base.fogOpacity, 0);
      }
    },
  );

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
