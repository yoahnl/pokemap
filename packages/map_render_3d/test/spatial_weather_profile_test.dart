import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_weather_profile.dart';

void main() {
  test(
    'disabled and indoor weather allocate no visible particles or flashes',
    () {
      final disabled = spatialWeatherFrame(
        SpatialWeatherSettings(),
        seconds: 8,
      );
      expect(disabled.particleCount, 0);
      expect(disabled.fogOpacity, 0);
      expect(disabled.lightFactor, 1);
      final storm = SpatialWeatherSettings(
        enabled: true,
        kind: SpatialWeatherKind.storm,
      );
      expect(
        spatialWeatherFrame(storm, seconds: 8, indoors: true).particleCount,
        0,
      );
      expect(spatialWeatherFrame(storm, seconds: 8).flash, 0);
      expect(
        spatialWeatherFrame(
          storm.copyWith(indoors: true),
          seconds: 8,
          indoors: true,
        ).particleCount,
        greaterThan(0),
      );
    },
  );

  test('every style has a bounded distinct visual signature', () {
    final signatures = <String>{};
    for (final kind in SpatialWeatherKind.values) {
      final settings = SpatialWeatherSettings(
        enabled: true,
        kind: kind,
        intensity: 1,
        density: 1,
      );
      final frame = spatialWeatherFrame(settings, seconds: 4);
      expect(
        frame.particleCount,
        inInclusiveRange(0, spatialWeatherMaximumParticles),
      );
      expect(frame.fogOpacity, inInclusiveRange(0, .5));
      expect(frame.lightFactor, inInclusiveRange(.4, 1.1));
      signatures.add(
        '${frame.shape}/${frame.particleCount}/${frame.fallSpeed}/${frame.streakLength}/${frame.fogOpacity}/${frame.lightFactor}',
      );
    }
    expect(signatures.length, SpatialWeatherKind.values.length);
  });

  test('wind and density are scalar changes with a fixed particle budget', () {
    final settings = SpatialWeatherSettings(
      enabled: true,
      kind: SpatialWeatherKind.downpour,
      intensity: 1,
      density: 1,
      windStrength: 2,
      windDirection: 90,
    );
    final full = spatialWeatherFrame(settings, seconds: 10);
    final light = spatialWeatherFrame(
      settings.copyWith(density: .25),
      seconds: 10,
    );
    expect(full.particleCount, spatialWeatherMaximumParticles);
    expect(light.particleCount, lessThan(full.particleCount));
    expect(full.windX, greaterThan(0));
    expect(full.windZ.abs(), lessThan(.000001));
    expect(
      spatialWeatherFrame(
        settings.copyWith(intensity: 0),
        seconds: 10,
      ).particleCount,
      0,
    );
  });

  test(
    'optional storm light is a slow bounded pulse and is absent by default',
    () {
      final settings = SpatialWeatherSettings(
        enabled: true,
        kind: SpatialWeatherKind.storm,
        lightning: true,
        intensity: 1,
      );
      var maximum = 0.0;
      var previous = 0.0;
      for (var index = 0; index < 1500; index++) {
        final frame = spatialWeatherFrame(settings, seconds: index / 60);
        maximum = frame.flash > maximum ? frame.flash : maximum;
        expect((frame.flash - previous).abs(), lessThan(.01));
        expect(frame.flash, inInclusiveRange(0, .1));
        previous = frame.flash;
      }
      expect(maximum, greaterThan(0));
    },
  );
}
