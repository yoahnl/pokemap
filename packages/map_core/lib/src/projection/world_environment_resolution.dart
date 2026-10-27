import 'dart:math' as math;
import '../models/spatial_visual_profile.dart';
import '../models/spatial_weather_settings.dart';
import '../models/world_environment.dart';

final class WorldEnvironmentFrame {
  const WorldEnvironmentFrame({
    this.minuteOfDay,
    this.weatherKind,
    this.weatherIntensity,
  });
  final double? minuteOfDay;
  final SpatialWeatherKind? weatherKind;
  final double? weatherIntensity;
}

WorldEnvironmentFrame resolveWorldEnvironment({
  required SpatialVisualPatch settings,
  required double elapsedSeconds,
  SpatialVisualPatch? overrides,
  DateTime? localTime,
  SpatialWeatherKind? realWeatherKind,
}) {
  if (!elapsedSeconds.isFinite || elapsedSeconds < 0) {
    throw const FormatException('Invalid world environment elapsed time.');
  }
  var mode = settings.choice(SpatialVisualParameter.timeMode);
  if (mode != null &&
      overrides?.choice(SpatialVisualParameter.timeMode) == null &&
      (overrides?.value(SpatialVisualParameter.minuteOfDay) != null ||
          overrides?.enabled(SpatialVisualParameter.dayNightEnabled) ==
              false)) {
    mode = WorldTimeMode.fixed.name;
  }
  final start = settings.number(SpatialVisualParameter.minuteOfDay) ?? 720;
  double? minute;
  if (mode == WorldTimeMode.real.name) {
    if (localTime == null) {
      throw const FormatException(
        'Real time requires an explicit local time source.',
      );
    }
    minute =
        localTime.hour * 60 +
        localTime.minute +
        localTime.second / 60 +
        localTime.millisecond / 60000;
  } else if (mode == WorldTimeMode.fixed.name) {
    minute = start;
  } else if (mode == WorldTimeMode.cycle.name) {
    final duration =
        settings.number(SpatialVisualParameter.dayDurationSeconds) ?? 1200;
    minute = (start + (elapsedSeconds % duration) * 1440 / duration) % 1440;
  }
  final weatherMode = resolveWorldWeatherMode(settings, overrides: overrides);
  SpatialWeatherKind? kind;
  double? intensity;
  if (weatherMode == WorldWeatherMode.occasional.name) {
    final episode = _occasionalWeather(settings, elapsedSeconds);
    kind = episode.$1;
    intensity = episode.$2;
  } else if (weatherMode == WorldWeatherMode.real.name &&
      realWeatherKind != null) {
    kind = realWeatherKind;
  } else if (weatherMode == WorldWeatherMode.automatic.name ||
      weatherMode == WorldWeatherMode.real.name) {
    final sequence =
        settings.value(SpatialVisualParameter.weatherSequence)
            as List<String>? ??
        const ['clear', 'cloudy', 'rain'];
    final interval =
        settings.number(SpatialVisualParameter.weatherIntervalSeconds) ?? 600;
    kind = SpatialWeatherKind.parse(
      sequence[(elapsedSeconds / interval).floor() % sequence.length],
    );
  }
  return WorldEnvironmentFrame(
    minuteOfDay: minute,
    weatherKind: kind,
    weatherIntensity: intensity,
  );
}

String? resolveWorldWeatherMode(
  SpatialVisualPatch settings, {
  SpatialVisualPatch? overrides,
}) {
  final mode = overrides?.choice(SpatialVisualParameter.weatherMode);
  if (mode != null) return mode;
  if (overrides?.choice(SpatialVisualParameter.weatherKind) != null) {
    return WorldWeatherMode.fixed.name;
  }
  return settings.choice(SpatialVisualParameter.weatherMode);
}

(SpatialWeatherKind, double) _occasionalWeather(
  SpatialVisualPatch settings,
  double seconds,
) {
  double value(SpatialVisualParameter p) =>
      settings.number(p) ?? p.defaultNumber!;
  final dryMin = value(SpatialVisualParameter.weatherDryMinSeconds);
  final dryMax = math.max(
    dryMin,
    value(SpatialVisualParameter.weatherDryMaxSeconds),
  );
  final durationMin = value(SpatialVisualParameter.weatherEventMinSeconds);
  final durationMax = math.max(
    durationMin,
    value(SpatialVisualParameter.weatherEventMaxSeconds),
  );
  final blockLength = dryMin + dryMax + durationMin + durationMax;
  final block = (seconds / blockLength).floor();
  final phase = seconds % blockLength;
  final firstDry = dryMin + (dryMax - dryMin) * _weatherRandom(block, 13);
  final firstDuration =
      durationMin + (durationMax - durationMin) * _weatherRandom(block, 71);
  final secondDry = dryMin + dryMax - firstDry;
  final secondDuration = durationMin + durationMax - firstDuration;
  final first = phase < firstDry + firstDuration;
  final start = first ? firstDry : firstDry + firstDuration + secondDry;
  final duration = first ? firstDuration : secondDuration;
  final age = phase - start;
  if (age < 0 || age >= duration) return (SpatialWeatherKind.clear, 0);
  final weights = [
    value(SpatialVisualParameter.weatherDrizzleWeight),
    value(SpatialVisualParameter.weatherRainWeight),
    value(SpatialVisualParameter.weatherDownpourWeight),
    value(SpatialVisualParameter.weatherStormWeight),
  ];
  var selection =
      _weatherRandom(block, first ? 137 : 251) *
      weights.reduce((a, b) => a + b);
  var index = weights.length - 1;
  for (var i = 0; i < weights.length; i++) {
    selection -= weights[i];
    if (selection < 0) {
      index = i;
      break;
    }
  }
  final ramp = math.min(8.0, duration / 4);
  final fade = math
      .min(1.0, math.min(age / ramp, (duration - age) / ramp))
      .clamp(0.0, 1.0);
  final smooth = fade * fade * (3 - 2 * fade);
  return (
    const [
      SpatialWeatherKind.drizzle,
      SpatialWeatherKind.rain,
      SpatialWeatherKind.downpour,
      SpatialWeatherKind.storm,
    ][index],
    smooth,
  );
}

double _weatherRandom(int block, int salt) {
  var value = ((block + 1) * 104729 + salt * 7919) % 2147483647;
  value = (value * 48271) % 2147483647;
  value = (value * 48271) % 2147483647;
  return value / 2147483647;
}
