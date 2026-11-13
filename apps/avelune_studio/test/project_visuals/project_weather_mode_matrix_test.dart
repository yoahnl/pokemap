import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';


void main() {
  final modes = <String, SpatialVisualPatch>{
    'fixed': SpatialVisualPatch()
        .set(SpatialVisualParameter.weatherMode, 'fixed')
        .set(SpatialVisualParameter.weatherKind, 'storm')
        .set(SpatialVisualParameter.timeMode, 'fixed')
        .set(SpatialVisualParameter.minuteOfDay, 1320),
    'automatic': SpatialVisualPatch()
        .set(SpatialVisualParameter.weatherMode, 'automatic')
        .set(SpatialVisualParameter.weatherSequence, ['clear', 'snow'])
        .set(SpatialVisualParameter.weatherIntervalSeconds, 900)
        .set(SpatialVisualParameter.timeMode, 'cycle')
        .set(SpatialVisualParameter.dayDurationSeconds, 2400),
    'real': SpatialVisualPatch()
        .set(SpatialVisualParameter.weatherMode, 'real')
        .set(SpatialVisualParameter.weatherSequence, ['cloudy', 'rain'])
        .set(SpatialVisualParameter.timeMode, 'real'),
    'occasional': SpatialVisualPatch()
        .set(SpatialVisualParameter.weatherMode, 'occasional')
        .set(SpatialVisualParameter.weatherDryMinSeconds, 600)
        .set(SpatialVisualParameter.weatherDryMaxSeconds, 1200)
        .set(SpatialVisualParameter.weatherStormWeight, 0),
  };

  test('real weather without a service falls back to the saved sequence deterministically', () {
    final settings = modes['real']!.set(
      SpatialVisualParameter.weatherIntervalSeconds,
      600,
    );
    final first = resolveWorldEnvironment(
      settings: settings,
      elapsedSeconds: 700,
      localTime: DateTime(2026, 11, 7, 3, 0),
    );
    final again = resolveWorldEnvironment(
      settings: settings,
      elapsedSeconds: 700,
      localTime: DateTime(2026, 11, 7, 3, 0),
    );
    expect(first.weatherKind, SpatialWeatherKind.rain);
    expect(again.weatherKind, first.weatherKind);
    expect(first.minuteOfDay, 180);
    final live = resolveWorldEnvironment(
      settings: settings,
      elapsedSeconds: 700,
      localTime: DateTime(2026, 11, 7, 3, 0),
      realWeatherKind: SpatialWeatherKind.snow,
    );
    expect(live.weatherKind, SpatialWeatherKind.snow);
  });

}
