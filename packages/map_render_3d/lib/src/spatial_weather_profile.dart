import 'dart:math' as math;
import 'dart:ui';

import 'package:map_core/map_core.dart';

const spatialWeatherMaximumParticles = 1536;

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
    this.fogDensity = 0,
    this.impactStrength = 0,
    this.impactSpeed = 0,
    this.lightFactor = 1,
    this.flash = 0,
    this.veilOpacity = 0,
    this.color = const Color(0xffd6e6f4),
    this.fogColor = const Color(0xffb8c6d1),
  });

  final int particleCount, shape;
  final double fallSpeed, streakLength, size, opacity, windX, windZ;
  final double fogOpacity, lightFactor, flash, veilOpacity;
  final double fogDensity;
  final double impactStrength, impactSpeed;
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
  final substance = math.sqrt(amount);
  final angle = settings.windDirection * math.pi / 180;
  final wind = math.sqrt(settings.windStrength * 2) * style.wind;
  final darkness = night.clamp(0.0, 1.0);
  var flash = 0.0;
  final strike = spatialStormEventAt(seconds);
  if ((settings.kind == SpatialWeatherKind.storm || settings.kind == SpatialWeatherKind.tempest || settings.kind == SpatialWeatherKind.hail) && settings.lightning) {
    final phase = seconds - strike.strikeSeconds;
    double pulse(double at, double hold, double tail) => _smooth(at / .18) * (1 - _smooth((at - hold) / tail));
    final shape = switch (strike.soundVariant) {
      0 => pulse(phase, .25, 1.5),
      1 => math.max(pulse(phase, .18, .4), .7 * pulse(phase - .65, .18, .65)),
      _ => pulse(phase, .55, .9),
    };
    flash = .09 * strike.strength * amount * shape;

  }
  final light =
      (1 -
              style.cloud *
                  settings.cloudCover *
                  amount *
                  (1 - darkness * .65) +
              flash)
          .clamp(settings.kind == SpatialWeatherKind.storm || settings.kind == SpatialWeatherKind.tempest ? .65 : .4, 1.1);
  final tint = 1 - darkness * .4;
  final color = Color.from(
    alpha: 1,
    red: style.color.r * tint,
    green: style.color.g * tint,
    blue: style.color.b * math.min(1, tint + darkness * .12),
  );
  return SpatialWeatherFrame(
    particleCount: (style.count * settings.density * substance).round().clamp(0, spatialWeatherMaximumParticles),
    shape: style.shape,
    fallSpeed: style.fall * settings.speed,
    streakLength: style.streak * settings.particleSize,
    size: style.size * settings.particleSize,
    opacity: style.opacity * settings.opacity * substance,
    windX: math.sin(angle) * wind,
    windZ: math.cos(angle) * wind,
    fogOpacity: (style.fog * settings.fogStrength * substance).clamp(0, .5),
    fogDensity: style.fog * settings.fogStrength * substance,
    impactStrength: style.impact * amount * settings.density * settings.opacity,
    impactSpeed:
        settings.speed * (settings.kind == SpatialWeatherKind.drizzle ? 1 : 2),
    lightFactor: light,
    flash: flash,
    veilOpacity: (settings.kind == SpatialWeatherKind.tempest ? .12 : settings.kind == SpatialWeatherKind.storm ? .08 : 0) * substance * settings.cloudCover * (.85 + .15 * math.sin(seconds * .43 + math.sin(seconds * .17))),
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
    this.impact = 0,
    this.color = const Color(0xffd1e3f0),
    this.fogColor = const Color(0xffb8c6d1),
  });
  final int count, shape;
  final double fall, streak, size, opacity, wind, cloud, fog;
  final double impact;
  final Color color, fogColor;
}

SpatialWeatherStyle spatialWeatherStyle(SpatialWeatherKind kind) =>
    switch (kind) {
      SpatialWeatherKind.clear => const SpatialWeatherStyle(),
      SpatialWeatherKind.partlyCloudy => const SpatialWeatherStyle(cloud: .12, fog: .03),
      SpatialWeatherKind.windy => const SpatialWeatherStyle(count: 96, shape: 3, fall: .12, size: .055, opacity: .4, wind: 10, cloud: .18, fog: .2),
      SpatialWeatherKind.heavySnow => const SpatialWeatherStyle(count: 384, shape: 1, fall: 1.4, streak: .1, size: .1, opacity: 1, wind: 2, cloud: .22, fog: .7, color: Color(0xfff1f5ff), fogColor: Color(0xffd9e2ed)),
      SpatialWeatherKind.sleet => const SpatialWeatherStyle(count: 352, shape: 7, fall: 10, streak: .8, size: .08, opacity: .95, wind: 5, cloud: .36, fog: .42, impact: .65),
      SpatialWeatherKind.tempest => const SpatialWeatherStyle(count: 1536, shape: 0, fall: 25, streak: .95, size: .022, opacity: 1, wind: 13, cloud: .35, fog: .65, impact: 1.8, color: Color(0xffb8cfe3), fogColor: Color(0xff8397ab)),
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
        impact: .22,
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
        impact: .5,
      ),
      SpatialWeatherKind.downpour => const SpatialWeatherStyle(
        count: 768,
        shape: 0,
        fall: 14,
        streak: .65,
        size: .018,
        opacity: .85,
        wind: 4,
        cloud: .35,
        fog: .22,
        impact: .8,
      ),
      SpatialWeatherKind.storm => const SpatialWeatherStyle(
        count: 1024,
        shape: 0,
        fall: 17,
        streak: .8,
        size: .02,
        opacity: .9,
        wind: 7,
        cloud: .3,
        fog: .45,
        impact: 1.3,
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
        fog: 1.1,
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
        fog: .9,
        fogColor: Color(0xffd2dce1),
      ),
      SpatialWeatherKind.fog => const SpatialWeatherStyle(
        cloud: .14,
        fog: 2.6,
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
        fog: 1.3,
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
