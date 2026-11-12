import 'dart:math' as math;

import 'package:map_core/map_core_domain.dart';

double? parseSpatialVisualNumber(String text) {
  final value = double.tryParse(text.trim().replaceAll(',', '.'));
  return value != null && value.isFinite ? value : null;
}

enum MapTimeSource { inherit, fixed, custom }

class SpatialVisualEditing {
  const SpatialVisualEditing({
    required this.patch,
    required this.inherited,
    required this.onChanged,
    this.onInvalidInput,
  });

  final SpatialVisualPatch patch, inherited;
  final void Function(SpatialVisualPatch)? onChanged;
  final void Function(SpatialVisualParameter, String?)? onInvalidInput;
  SpatialVisualPatch get effective => inherited.overriddenBy(patch);
  double number(SpatialVisualParameter p) =>
      effective.number(p) ??
      p.defaultNumber ??
      (p == SpatialVisualParameter.weatherIntervalSeconds ? 600 : p.minimum);
  String get timeMode =>
      effective.choice(SpatialVisualParameter.timeMode) ??
      (flag(SpatialVisualParameter.dayNightEnabled) ? 'cycle' : 'fixed');
  bool get occasionalWeather =>
      effective.choice(SpatialVisualParameter.weatherMode) == 'occasional';
  bool get automaticWeather => const [
    'automatic',
    'real',
  ].contains(effective.choice(SpatialVisualParameter.weatherMode));
  List<String> get weatherSequence =>
      effective.value(SpatialVisualParameter.weatherSequence)
          as List<String>? ??
      const ['clear', 'cloudy', 'rain'];
  String get mapWeatherSource =>
      patch.choice(SpatialVisualParameter.weatherMode) == 'fixed'
      ? patch.choice(SpatialVisualParameter.weatherKind) == 'clear' ||
                patch.enabled(SpatialVisualParameter.weatherEnabled) == false
            ? 'clear'
            : 'fixed'
      : patch.values.keys.any((p) => p.isWeather)
      ? 'custom'
      : 'inherit';

  MapTimeSource get mapTimeSource {
    if (!patch.values.keys.any((p) => p.isClock)) return MapTimeSource.inherit;
    return patch.choice(SpatialVisualParameter.timeMode) ==
                WorldTimeMode.fixed.name &&
            patch.number(SpatialVisualParameter.minuteOfDay) != null
        ? MapTimeSource.fixed
        : MapTimeSource.custom;
  }

  int get mapMinuteOfDay =>
      number(SpatialVisualParameter.minuteOfDay).round() % 1440;

  void setMapTimeSource(MapTimeSource value) {
    var next = SpatialVisualPatch({
      for (final entry in patch.values.entries)
        if (!entry.key.isClock) entry.key: entry.value,
    });
    if (value != MapTimeSource.inherit) {
      next = next
          .set(SpatialVisualParameter.timeMode, WorldTimeMode.fixed.name)
          .set(SpatialVisualParameter.minuteOfDay, mapMinuteOfDay);
    }
    onChanged?.call(next);
  }

  bool setMapMinuteOfDay(int minute) {
    if (minute < 0 || minute > 1439) return false;
    onChanged?.call(
      patch
          .set(SpatialVisualParameter.timeMode, WorldTimeMode.fixed.name)
          .set(SpatialVisualParameter.minuteOfDay, minute),
    );
    return true;
  }

  void setMapWeatherSource(String value) {
    var next = SpatialVisualPatch({
      for (final entry in patch.values.entries)
        if (!entry.key.isWeather) entry.key: entry.value,
    });
    if (value != 'inherit') {
      final currentKind = effective.choice(SpatialVisualParameter.weatherKind);
      next = next
          .set(SpatialVisualParameter.weatherMode, 'fixed')
          .set(SpatialVisualParameter.weatherEnabled, value != 'clear')
          .set(
            SpatialVisualParameter.weatherKind,
            value == 'clear'
                ? 'clear'
                : currentKind == null || currentKind == 'clear'
                ? 'rain'
                : currentKind,
          );
      if (value != 'clear') {
        next = next.set(
          SpatialVisualParameter.weatherIntensity,
          effective.number(SpatialVisualParameter.weatherIntensity) ?? .7,
        );
      }
    }
    onChanged?.call(next);
  }

  void selectWeather(SpatialWeatherKind kind) {
    if (onChanged == null) return;
    if (automaticWeather) {
      final sequence = [...weatherSequence];
      if (sequence.contains(kind.name)) {
        if (sequence.length == 1) return;
        sequence.remove(kind.name);
      } else {
        sequence.add(kind.name);
      }
      onChanged!(patch.set(SpatialVisualParameter.weatherSequence, sequence));
    } else {
      onChanged!(
        patch
            .set(SpatialVisualParameter.weatherKind, kind.name)
            .set(
              SpatialVisualParameter.weatherEnabled,
              kind != SpatialWeatherKind.clear,
            ),
      );
    }
  }

  bool flag(SpatialVisualParameter p) => effective.enabled(p) ?? false;
  void change(SpatialVisualParameter p, Object value) {
    if (p.isWeatherEpisode) {
      final current = effective;
      if (p.index >= SpatialVisualParameter.weatherDrizzleWeight.index &&
          value == 0 &&
          const [
                SpatialVisualParameter.weatherDrizzleWeight,
                SpatialVisualParameter.weatherRainWeight,
                SpatialVisualParameter.weatherDownpourWeight,
                SpatialVisualParameter.weatherStormWeight,
              ]
              .where((field) => field != p)
              .every(
                (field) => (current.number(field) ?? field.defaultNumber!) == 0,
              )) {
        return;
      }
      for (final pair in const [
        (
          SpatialVisualParameter.weatherDryMinSeconds,
          SpatialVisualParameter.weatherDryMaxSeconds,
        ),
        (
          SpatialVisualParameter.weatherEventMinSeconds,
          SpatialVisualParameter.weatherEventMaxSeconds,
        ),
      ]) {
        if (p == pair.$1 || p == pair.$2) {
          final other = p == pair.$1 ? pair.$2 : pair.$1;
          var next = patch.set(p, null).set(other, null).set(p, value);
          final changed = value as double;
          final existing = number(other);
          next = next.set(
            other,
            p == pair.$1
                ? math.max(changed, existing)
                : math.min(changed, existing),
          );
          onChanged?.call(next);
          return;
        }
      }
    }
    var next =
        (p == SpatialVisualParameter.fogStart ||
            p == SpatialVisualParameter.fogEnd)
        ? patch
              .set(SpatialVisualParameter.fogStart, null)
              .set(SpatialVisualParameter.fogEnd, null)
              .set(p, value)
        : patch.set(p, value);
    if (p.isClock &&
        p != SpatialVisualParameter.timeMode &&
        next.choice(SpatialVisualParameter.timeMode) == null) {
      next = next.set(SpatialVisualParameter.timeMode, timeMode);
    }
    if (p == SpatialVisualParameter.weatherMode &&
        (value == 'automatic' || value == 'real' || value == 'occasional')) {
      next = next.set(SpatialVisualParameter.weatherEnabled, true);
    }
    if (p == SpatialVisualParameter.fieldOfViewDegrees) {
      final before = number(p) * math.pi / 360;
      final after = (value as double) * math.pi / 360;
      next = next.set(
        SpatialVisualParameter.cameraDistance,
        (number(SpatialVisualParameter.cameraDistance) *
                math.tan(before) /
                math.tan(after))
            .clamp(.01, 10000),
      );
    }
    if (p == SpatialVisualParameter.fogStart &&
        (value as double) >= number(SpatialVisualParameter.fogEnd)) {
      next = next.set(SpatialVisualParameter.fogEnd, value + 1);
    }
    if (p == SpatialVisualParameter.fogEnd &&
        (value as double) <= number(SpatialVisualParameter.fogStart)) {
      next = next.set(SpatialVisualParameter.fogStart, math.max(0, value - 1));
    }
    if (p == SpatialVisualParameter.fogStart &&
        next.value(SpatialVisualParameter.fogEnd) == null &&
        patch.value(SpatialVisualParameter.fogEnd) != null) {
      next = next.set(
        SpatialVisualParameter.fogEnd,
        patch.value(SpatialVisualParameter.fogEnd),
      );
    }
    if (p == SpatialVisualParameter.fogEnd &&
        next.value(SpatialVisualParameter.fogStart) == null &&
        patch.value(SpatialVisualParameter.fogStart) != null) {
      next = next.set(
        SpatialVisualParameter.fogStart,
        patch.value(SpatialVisualParameter.fogStart),
      );
    }
    onChanged?.call(next);
  }

  void inherit(SpatialVisualParameter parameter) {
    if (onChanged == null || patch.value(parameter) == null) return;
    onInvalidInput?.call(parameter, null);
    onChanged!(patch.set(parameter, null));
  }

  void editNumber(SpatialVisualParameter parameter, String text) {
    final value = parseSpatialVisualNumber(text);
    if (value == null ||
        value < parameter.minimum ||
        value > parameter.maximum) {
      onInvalidInput?.call(parameter, text);
      return;
    }
    onInvalidInput?.call(parameter, null);
    change(parameter, value);
  }
}
