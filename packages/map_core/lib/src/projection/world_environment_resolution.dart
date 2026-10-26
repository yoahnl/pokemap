import '../models/spatial_visual_profile.dart';
import '../models/spatial_weather_settings.dart';
import '../models/world_environment.dart';

final class WorldEnvironmentFrame {
  const WorldEnvironmentFrame({this.minuteOfDay, this.weatherKind});
  final double? minuteOfDay;
  final SpatialWeatherKind? weatherKind;
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
  if (weatherMode == WorldWeatherMode.real.name && realWeatherKind != null) {
    kind = realWeatherKind;
  } else if (weatherMode == WorldWeatherMode.automatic.name || weatherMode == WorldWeatherMode.real.name) {
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
  return WorldEnvironmentFrame(minuteOfDay: minute, weatherKind: kind);
}

String? resolveWorldWeatherMode(SpatialVisualPatch settings, {SpatialVisualPatch? overrides}) {
  final mode = overrides?.choice(SpatialVisualParameter.weatherMode);
  if (mode != null) return mode;
  if (overrides?.choice(SpatialVisualParameter.weatherKind) != null) return WorldWeatherMode.fixed.name;
  return settings.choice(SpatialVisualParameter.weatherMode);
}
