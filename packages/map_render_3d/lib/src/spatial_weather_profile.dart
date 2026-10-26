import 'dart:math' as math;
import 'dart:ui';

import 'package:map_core/map_core.dart';

const spatialWeatherMaximumParticles = 384;

final class SpatialWeatherFrame {
  const SpatialWeatherFrame({
    this.particleCount = 0,
    this.shape = -1,
    this.fallSpeed = 0,
    this.streakLength = 0,
    this.size = 0,
    this.opacity = 0,
    this.windX = 0,
    this.windZ = 0,
    this.fogOpacity = 0,
    this.lightFactor = 1,
    this.flash = 0,
    this.color = const Color(0xffd6e6f4),
    this.fogColor = const Color(0xffb8c6d1),
  });

  final int particleCount, shape;
  final double fallSpeed, streakLength, size, opacity, windX, windZ;
  final double fogOpacity, lightFactor, flash;
  final Color color, fogColor;
  static const disabled = SpatialWeatherFrame();
}

SpatialWeatherFrame spatialWeatherFrame(
  SpatialWeatherSettings settings, {
  required double seconds,
  double night = 0,
  bool indoors = false,
}) {
  if (!seconds.isFinite || !night.isFinite) {
    throw ArgumentError('Weather time and lighting must be finite.');
  }
  if (!settings.active || (indoors && !settings.indoors)) {
    return SpatialWeatherFrame.disabled;
  }
  final style = spatialWeatherStyle(settings.kind);
  final amount = settings.intensity;
  final angle = settings.windDirection * math.pi / 180;
  final wind = settings.windStrength * style.wind;
  final darkness = night.clamp(0.0, 1.0);
  var flash = 0.0;
  if (settings.kind == SpatialWeatherKind.storm && settings.lightning) {
    final phase = seconds % 24;
    flash =
        .09 *
        amount *
        _smooth((phase - 6) / .6) *
        (1 - _smooth((phase - 6.6) / 1.2));
  }
  final light =
      (1 -
              style.cloud *
                  settings.cloudCover *
                  amount *
                  (1 - darkness * .65) +
              flash)
          .clamp(.4, 1.1);
  final tint = 1 - darkness * .4;
  final color = Color.from(
    alpha: 1,
    red: style.color.r * tint,
    green: style.color.g * tint,
    blue: style.color.b * math.min(1, tint + darkness * .12),
  );
  return SpatialWeatherFrame(
    particleCount: (style.count * settings.density * amount).round().clamp(
      0,
      spatialWeatherMaximumParticles,
    ),
    shape: style.shape,
    fallSpeed: style.fall * settings.speed,
    streakLength: style.streak * settings.particleSize,
    size: style.size * settings.particleSize,
    opacity: style.opacity * settings.opacity * amount,
    windX: math.sin(angle) * wind,
    windZ: math.cos(angle) * wind,
    fogOpacity: (style.fog * settings.fogStrength * amount).clamp(0, .5),
    lightFactor: light,
    flash: flash,
    color: color,
    fogColor: Color.lerp(
      style.fogColor,
      const Color(0xff34415d),
      darkness * .75,
    )!,
  );
}

double _smooth(double value) {
  final t = value.clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

final class SpatialWeatherStyle {
  const SpatialWeatherStyle({
    this.count = 0,
    this.shape = -1,
    this.fall = 0,
    this.streak = 0,
    this.size = 0,
    this.opacity = 0,
    this.wind = 1,
    this.cloud = 0,
    this.fog = 0,
    this.color = const Color(0xffd1e3f0),
    this.fogColor = const Color(0xffb8c6d1),
  });
  final int count, shape;
  final double fall, streak, size, opacity, wind, cloud, fog;
  final Color color, fogColor;
}

SpatialWeatherStyle spatialWeatherStyle(SpatialWeatherKind kind) =>
    switch (kind) {
      SpatialWeatherKind.clear => const SpatialWeatherStyle(),
      SpatialWeatherKind.cloudy => const SpatialWeatherStyle(
        cloud: .24,
        fog: .05,
      ),
      SpatialWeatherKind.drizzle => const SpatialWeatherStyle(
        count: 144,
        shape: 0,
        fall: 4,
        streak: .22,
        size: .014,
        opacity: .55,
        wind: 2,
        cloud: .16,
        fog: .08,
      ),
      SpatialWeatherKind.rain => const SpatialWeatherStyle(
        count: 256,
        shape: 0,
        fall: 8,
        streak: .48,
        size: .019,
        opacity: .72,
        wind: 3,
        cloud: .27,
        fog: .12,
      ),
      SpatialWeatherKind.downpour => const SpatialWeatherStyle(
        count: 384,
        shape: 0,
        fall: 14,
        streak: .85,
        size: .025,
        opacity: .85,
        wind: 4,
        cloud: .35,
        fog: .22,
      ),
      SpatialWeatherKind.storm => const SpatialWeatherStyle(
        count: 384,
        shape: 0,
        fall: 17,
        streak: 1.1,
        size: .028,
        opacity: .9,
        wind: 7,
        cloud: .48,
        fog: .3,
        color: Color(0xffb8cfe3),
        fogColor: Color(0xff8397ab),
      ),
      SpatialWeatherKind.snow => const SpatialWeatherStyle(
        count: 192,
        shape: 1,
        fall: .7,
        streak: .08,
        size: .06,
        opacity: 1,
        wind: .8,
        cloud: .1,
        fog: .08,
        color: Color(0xfff1f5ff),
        fogColor: Color(0xffd9e2ed),
      ),
      SpatialWeatherKind.blizzard => const SpatialWeatherStyle(
        count: 384,
        shape: 1,
        fall: 2.3,
        streak: .12,
        size: .075,
        opacity: 1,
        wind: 8,
        cloud: .3,
        fog: .5,
        color: Color(0xffe5efff),
        fogColor: Color(0xffc5d4e7),
      ),
      SpatialWeatherKind.hail => const SpatialWeatherStyle(
        count: 256,
        shape: 2,
        fall: 11,
        streak: .07,
        size: .045,
        opacity: 1,
        wind: 3,
        cloud: .28,
        fog: .12,
        color: Color(0xffdceef6),
      ),
      SpatialWeatherKind.mist => const SpatialWeatherStyle(
        cloud: .04,
        fog: .28,
        fogColor: Color(0xffd2dce1),
      ),
      SpatialWeatherKind.fog => const SpatialWeatherStyle(
        cloud: .14,
        fog: .7,
        fogColor: Color(0xffbdcbd2),
      ),
      SpatialWeatherKind.dust => const SpatialWeatherStyle(
        count: 128,
        shape: 3,
        fall: .08,
        streak: .1,
        size: .09,
        opacity: .55,
        wind: 2,
        cloud: .04,
        fog: .1,
        color: Color(0xffead7b0),
        fogColor: Color(0xffd5c5aa),
      ),
      SpatialWeatherKind.sandstorm => const SpatialWeatherStyle(
        count: 384,
        shape: 3,
        fall: .25,
        streak: .22,
        size: .13,
        opacity: .85,
        wind: 12,
        cloud: .32,
        fog: .65,
        color: Color(0xffe4c081),
        fogColor: Color(0xffc4a77b),
      ),
      SpatialWeatherKind.petals => const SpatialWeatherStyle(
        count: 112,
        shape: 4,
        fall: .55,
        streak: .12,
        size: .105,
        opacity: 1,
        wind: 1.8,
        color: Color(0xffffc6df),
        fogColor: Color(0xffecd6e4),
      ),
      SpatialWeatherKind.leaves => const SpatialWeatherStyle(
        count: 144,
        shape: 5,
        fall: .9,
        streak: .14,
        size: .12,
        opacity: 1,
        wind: 2.4,
        color: Color(0xffe3b85f),
        fogColor: Color(0xffded1a9),
      ),
    };
