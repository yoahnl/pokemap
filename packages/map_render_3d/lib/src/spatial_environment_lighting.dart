import 'dart:math' as math;
import 'dart:ui';

import 'package:flame_3d/core.dart';
import 'package:map_core/map_core.dart';

import 'spatial_lighting_preview.dart';
import 'spatial_point_light.dart';

final class SpatialDayNightFrame {
  const SpatialDayNightFrame(this.tint, this.daylight);
  final Color tint;
  final double daylight;
}

double _smooth(double value) {
  final t = value.clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

SpatialDayNightFrame spatialDayNightFrame(double minuteOfDay) {
  final minute = minuteOfDay % 1440;
  const stops = [
    (0.0, Color(0xff4d5e94)),
    (300.0, Color(0xff4d5e94)),
    (360.0, Color(0xffa18fb3)),
    (480.0, Color(0xffffffff)),
    (1020.0, Color(0xffffffff)),
    (1140.0, Color(0xffd99e8c)),
    (1260.0, Color(0xff4d5e94)),
    (1440.0, Color(0xff4d5e94)),
  ];
  var tint = stops.first.$2;
  for (var index = 1; index < stops.length; index++) {
    final before = stops[index - 1], after = stops[index];
    if (minute <= after.$1) {
      tint = Color.lerp(
        before.$2,
        after.$2,
        _smooth((minute - before.$1) / (after.$1 - before.$1)),
      )!;
      break;
    }
  }
  final daylight =
      _smooth((minute - 300) / 180) * (1 - _smooth((minute - 1020) / 240));
  return SpatialDayNightFrame(tint, daylight);
}

final class SpatialDayNightPreviewClock {
  double? minuteOverride;
  bool running = false;
  double _elapsed = 0;

  void seek(double? minute) {
    if (minute != null && (!minute.isFinite || minute < 0 || minute >= 1440)) {
      throw ArgumentError.value(minute, 'minute');
    }
    minuteOverride = minute;
    running = false;
    _elapsed = 0;
  }

  void advance(double dt) {
    if (running && dt.isFinite && dt > 0) _elapsed += dt;
  }

  double minute(SpatialDayNightCycle cycle, {double? externalElapsedSeconds}) {
    if (minuteOverride == null && externalElapsedSeconds != null) {
      return cycle.minuteAtElapsed(externalElapsedSeconds);
    }
    return ((minuteOverride ?? cycle.startMinuteOfDay) +
            _elapsed / cycle.durationSeconds * 1440) %
        1440;
  }
}

SpatialPointLight spatialPlacedPointLight(
  Model3dPointLight definition,
  Matrix4 transform, {
  required double daylight,
}) {
  final local = definition.localPosition;
  final position = transform.transform3(Vector3(local.x, local.y, local.z));
  return SpatialPointLight(
    position: (x: position.x, y: position.y, z: position.z),
    radius: definition.radius,
    color: Color(0xff000000 | definition.colorRgb),
    intensity: definition.intensity * (definition.nightOnly ? 1 - daylight : 1),
  );
}

List<SpatialPointLight> spatialVisiblePointLights(
  Iterable<SpatialPointLight> lights,
  Vector3 anchor,
) {
  final ranked = lights.where((light) => light.intensity > 0).indexed.toList();
  double distance(SpatialPointLight light) =>
      math.pow(light.position.x - anchor.x, 2).toDouble() +
      math.pow(light.position.z - anchor.z, 2).toDouble();
  ranked.sort((a, b) {
    final order = distance(a.$2).compareTo(distance(b.$2));
    return order != 0 ? order : a.$1.compareTo(b.$1);
  });
  return [for (final entry in ranked.take(4)) entry.$2];
}

SpatialLightingProfile spatialEnvironmentLighting(
  SpatialLightingProfile base, {
  SpatialDayNightFrame? frame,
  List<SpatialPointLight> lights = const [],
}) {
  if (frame == null && lights.isEmpty) return base;
  final daylight = frame?.daylight ?? 1;
  return SpatialLightingProfile.stylized(
    ambientColor: base.ambientColor,
    sunColor: base.sunColor,
    ambientStrength: 1 - (1 - base.ambientStrength) * daylight,
    sunStrength: base.sunStrength * daylight,
    sunDirection: base.sunDirection,
    surfaceStrength: base.enabled ? base.surfaceStrength : 0,
    groundStrength: base.groundStrength,
    actorStrength: base.actorStrength,
    unlitMaterialNames: base.unlitMaterialNames,
    hiddenMaterialsByInstance: base.hiddenMaterialsByInstance,
    shadow: daylight > .001 ? base.shadow : null,
    sceneTint: frame?.tint ?? const Color(0xffffffff),
    pointLights: lights,
    pointShadowCasterInstanceIds:
        base.shadow?.casterInstanceIds ?? base.pointShadowCasterInstanceIds,
  );
}
