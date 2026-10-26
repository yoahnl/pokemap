import 'dart:math' as math;
import 'dart:ui';

import 'package:flame_3d/camera.dart';
import 'package:flame_3d/game.dart';
import 'package:map_core/map_core.dart';

import 'spatial_lighting_preview.dart';
import 'spatial_presentation_effects.dart';
import 'spatial_render_context.dart';
import 'spatial_weather_material.dart';
import 'spatial_weather_profile.dart';

final class SpatialWeatherEffects {
  SpatialWeatherEffects(this.world);
  final World3D world;
  final List<SpatialWeatherBatch> batches = [];
  SpatialWeatherSettings _current = SpatialWeatherSettings();
  SpatialWeatherSettings _previous = SpatialWeatherSettings();
  double _progress = 1;
  SpatialPresentationProfile? _baseFog, _fog;
  int particleCount = 0;
  int get drawCount => batches.where((batch) => batch.material.visible).length;

  void prepare() {
    if (batches.isNotEmpty) return;
    for (var index = 0; index < 2; index++) {
      final batch = SpatialWeatherBatch()..prepare();
      batches.add(batch);
      world.add(batch);
    }
  }

  void sync({
    required SpatialWeatherSettings settings,
    required SpatialRenderContext context,
    required double dt,
    required double seconds,
    required double night,
    required bool indoors,
    required Vector3 anchor,
    required Rect bounds,
    required double cameraDistance,
  }) {
    final next = indoors && !settings.indoors
        ? SpatialWeatherSettings()
        : settings;
    if (next.kind != _current.kind || next.active != _current.active) {
      _previous = _current;
      _progress = 0;
    }
    _current = next;
    if (indoors && !settings.indoors) {
      _previous = SpatialWeatherSettings();
      _progress = 1;
    } else if (next.transitionSeconds == 0) {
      _progress = 1;
    } else if (dt.isFinite && dt > 0) {
      _progress = math.min(1, _progress + dt / next.transitionSeconds);
    }
    final weight = _progress * _progress * (3 - 2 * _progress);
    final before = spatialWeatherFrame(
      _previous,
      seconds: seconds,
      night: night,
    );
    final after = spatialWeatherFrame(next, seconds: seconds, night: night);
    final oldCount = (before.particleCount * (1 - weight)).round();
    final newCount = math.min(
      (after.particleCount * weight).round(),
      spatialWeatherMaximumParticles - oldCount,
    );
    particleCount = oldCount + newCount;
    if (batches.isNotEmpty) {
      for (final batch in batches) {
        batch.position.setFrom(anchor);
      }
      batches[0].material.configure(
        frame: before,
        anchor: anchor,
        bounds: bounds,
        seconds: seconds,
        weight: 1 - weight,
        count: oldCount,
        cameraDistance: cameraDistance,
      );
      batches[1].material.configure(
        frame: after,
        anchor: anchor,
        bounds: bounds,
        seconds: seconds,
        weight: weight,
        count: newCount,
        cameraDistance: cameraDistance,
      );
    }
    final light =
        before.lightFactor * (1 - weight) + after.lightFactor * weight;
    context.lighting = _lighting(context.lighting, light);
    final opacity =
        before.fogOpacity * (1 - weight) + after.fogOpacity * weight;
    final impact =
        before.impactStrength * (1 - weight) + after.impactStrength * weight;
    if (opacity <= .0001 && impact <= .0001) return;
    final base = context.presentationProfile;
    if (!identical(_baseFog, base)) {
      _baseFog = base;
      _fog = SpatialPresentationProfile(halos: base.halos);
    }
    final fog = _fog!;
    final weatherStart = math.max(
      0.0,
      cameraDistance - math.max(8, cameraDistance * .45),
    );
    final weatherEnd = cameraDistance + math.max(4, cameraDistance * .15);
    final manual = context.depthFogEnabled;
    fog
      ..haloSpread = base.haloSpread
      ..haloStrength = base.haloStrength
      ..weatherFogStrength =
          before.fogDensity * (1 - weight) + after.fogDensity * weight
      ..weatherSeconds = seconds
      ..weatherWindX = before.windX * (1 - weight) + after.windX * weight
      ..weatherWindZ = before.windZ * (1 - weight) + after.windZ * weight
      ..weatherGroundHeight = anchor.y
      ..weatherImpactStrength = impact
      ..weatherImpactSpeed =
          before.impactSpeed * (1 - weight) + after.impactSpeed * weight
      ..weatherManualFogStart = base.fogStart
      ..weatherManualFogEnd = base.fogEnd
      ..weatherManualFogOpacity = manual ? base.fogOpacity : 0
      ..fogStart = weatherStart
      ..fogEnd = weatherEnd
      ..fogOpacity = opacity;
    context
      ..presentationProfile = fog
      ..depthFogEnabled = true
      ..depthFogColor = Color.lerp(before.fogColor, after.fogColor, weight)!;
  }

  SpatialLightingProfile _lighting(SpatialLightingProfile base, double amount) {
    if ((amount - 1).abs() < .0001) return base;
    final tint = base.sceneTint;
    return SpatialLightingProfile.stylized(
      ambientColor: base.ambientColor,
      sunColor: base.sunColor,
      ambientStrength: base.ambientStrength,
      sunStrength: base.sunStrength,
      sunDirection: base.sunDirection,
      actorStrength: base.actorStrength,
      groundStrength: base.groundStrength,
      surfaceStrength: base.surfaceStrength,
      unlitMaterialNames: base.unlitMaterialNames,
      hiddenMaterialsByInstance: base.hiddenMaterialsByInstance,
      shadow: base.shadow,
      sceneTint: Color.from(
        alpha: 1,
        red: (tint.r * amount).clamp(0, 1),
        green: (tint.g * amount).clamp(0, 1),
        blue: (tint.b * amount).clamp(0, 1),
      ),
      pointLights: base.pointLights,
      fireflyLights: base.fireflyLights,
      pointShadowCasterInstanceIds: base.pointShadowCasterInstanceIds,
    );
  }

  void clear() {
    for (final batch in batches) {
      batch.removeFromParent();
    }
    batches.clear();
    particleCount = 0;
    _fog = null;
    _baseFog = null;
  }
}
