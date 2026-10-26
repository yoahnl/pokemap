import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_weather_profile.dart';

void main() {
  test('intensity levels progress continuously within the same fixed budget', () {
    for (final kind in SpatialWeatherKind.values.where((kind) => kind != SpatialWeatherKind.clear)) {
      var previous = 0;
      for (final intensity in [.15, .35, .55, .8, 1.0]) {
        final frame = spatialWeatherFrame(SpatialWeatherSettings(enabled: true, kind: kind, intensity: intensity), seconds: 3);
        expect(frame.particleCount, inInclusiveRange(previous, spatialWeatherMaximumParticles));
        previous = frame.particleCount;
      }
    }
  });
  test('storm lightning remains visible even with rain particles disabled', () {
    final settings = SpatialWeatherSettings(
      enabled: true,
      kind: SpatialWeatherKind.storm,
      lightning: true,
      density: 0,
      opacity: 0,
    );
    expect(
      spatialWeatherFrame(settings, seconds: 6.35).particleCount,
      0,
    );
    expect(spatialWeatherFrame(settings, seconds: 6.35).flash, greaterThan(0));
    expect(
      spatialWeatherFrame(
        settings.copyWith(lightning: false),
        seconds: 6.35,
      ).particleCount,
      0,
    );
  });

  test('dense fog keeps its density beyond the shared opacity ceiling', () {
    final settings = SpatialWeatherSettings(
      enabled: true,
      kind: SpatialWeatherKind.mist,
      intensity: 1,
      fogStrength: 1,
    );
    final mist = spatialWeatherFrame(settings, seconds: 1);
    final fog = spatialWeatherFrame(
      settings.copyWith(kind: SpatialWeatherKind.fog),
      seconds: 1,
    );
    expect(fog.fogDensity, greaterThan(mist.fogDensity * 2));
    expect(fog.fogOpacity, lessThanOrEqualTo(.5));
  });
  test(
    'surface rain impacts scale independently of the fixed particle pool',
    () {
      final settings = SpatialWeatherSettings(
        enabled: true,
        kind: SpatialWeatherKind.rain,
        intensity: 1,
        density: 1,
        opacity: 1,
      );
      final rain = spatialWeatherFrame(settings, seconds: 1);
      final drizzle = spatialWeatherFrame(
        settings.copyWith(kind: SpatialWeatherKind.drizzle),
        seconds: 1,
      );
      final downpour = spatialWeatherFrame(
        settings.copyWith(kind: SpatialWeatherKind.downpour),
        seconds: 1,
      );
      expect(drizzle.impactStrength, greaterThan(0));
      expect(rain.impactStrength, greaterThan(drizzle.impactStrength));
      expect(downpour.impactStrength, greaterThan(rain.impactStrength));
      expect(
        spatialWeatherFrame(
          settings.copyWith(density: 0),
          seconds: 1,
        ).impactStrength,
        0,
      );
      expect(
        spatialWeatherFrame(settings, seconds: 1, indoors: true).impactStrength,
        0,
      );
      expect(
        spatialWeatherFrame(
          settings.copyWith(enabled: false),
          seconds: 1,
        ).impactStrength,
        0,
      );
      for (final kind in [
        SpatialWeatherKind.clear,
        SpatialWeatherKind.mist,
        SpatialWeatherKind.snow,
        SpatialWeatherKind.petals,
      ]) {
        expect(
          spatialWeatherFrame(
            settings.copyWith(kind: kind),
            seconds: 1,
          ).impactStrength,
          0,
        );
      }
    },
  );

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
