import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('local weather ranges resolve coherently against inherited limits', () {
    final base = SpatialVisualPatch.fromJson({
      'weatherDryMinSeconds': 900,
      'weatherDryMaxSeconds': 1800,
    });
    final local = SpatialVisualPatch.fromJson({'weatherDryMinSeconds': 2400});
    final resolved = base.overriddenBy(local);
    expect(resolved.number(SpatialVisualParameter.weatherDryMinSeconds), 2400);
    expect(resolved.number(SpatialVisualParameter.weatherDryMaxSeconds), 2400);
  });
  SpatialVisualPatch settings([Map<String, Object> extra = const {}]) =>
      SpatialVisualPatch.fromJson({'weatherMode': 'occasional', ...extra});
  WorldEnvironmentFrame frame(
    double seconds, [
    Map<String, Object> extra = const {},
  ]) => resolveWorldEnvironment(
    settings: settings(extra),
    elapsedSeconds: seconds,
  );

  test(
    'occasional weather has a versioned contract without changing old documents',
    () {
      final patch = settings({
        'weatherDryMinSeconds': 900,
        'weatherDryMaxSeconds': 1800,
      });
      final json = SpatialVisualDocument(profile: patch).toJson();
      expect(json['schemaVersion'], 8);
      expect(SpatialVisualDocument.fromJson(json).profile, patch);
      expect(
        () => SpatialVisualDocument.fromJson({...json, 'schemaVersion': 7}),
        throwsFormatException,
      );
      expect(
        SpatialVisualDocument(
          profile: SpatialVisualPatch.fromJson({'weatherMode': 'automatic'}),
        ).toJson()['schemaVersion'],
        5,
      );
    },
  );
  test('episodes are sparse, bounded and stable at any elapsed time', () {
    final episodes = <(double, double, SpatialWeatherKind)>[];
    var start = 0.0;
    var previous = SpatialWeatherKind.clear;
    for (var t = 0.0; t < 120000; t += 1) {
      final current = frame(t).weatherKind!;
      if (previous == SpatialWeatherKind.clear && current != previous) {
        start = t;
      }
      if (previous != SpatialWeatherKind.clear &&
          current == SpatialWeatherKind.clear) {
        episodes.add((start, t, previous));
      }
      previous = current;
    }
    expect(episodes.length, greaterThan(40));
    expect(episodes.first.$1, inInclusiveRange(900, 1801));
    for (var i = 0; i < episodes.length; i++) {
      final e = episodes[i];
      expect(e.$2 - e.$1, inInclusiveRange(119, 301));
      if (i > 0) expect(e.$1 - episodes[i - 1].$2, inInclusiveRange(899, 1801));
      expect(frame(e.$1 + 20).weatherKind, e.$3);
      expect(frame(e.$1 + 20).weatherKind, frame(e.$1 + 20).weatherKind);
    }
    expect(
      episodes.map((e) => e.$3).toSet(),
      containsAll([
        SpatialWeatherKind.drizzle,
        SpatialWeatherKind.rain,
        SpatialWeatherKind.downpour,
        SpatialWeatherKind.storm,
      ]),
    );
    expect(
      episodes.where((e) => e.$3 == SpatialWeatherKind.storm).length,
      lessThan(
        episodes.where((e) => e.$3 == SpatialWeatherKind.drizzle).length,
      ),
    );
    expect(frame(1e12).weatherKind, isNotNull);
  });
  test(
    'weights and durations are editable while real and narrative weather stay authoritative',
    () {
      final extra = <String, Object>{
        'weatherDryMinSeconds': 60,
        'weatherDryMaxSeconds': 90,
        'weatherEventMinSeconds': 10,
        'weatherEventMaxSeconds': 20,
        'weatherDrizzleWeight': 0,
        'weatherRainWeight': 0,
        'weatherDownpourWeight': 0,
        'weatherStormWeight': 100,
      };
      final kinds = {
        for (var t = 0.0; t < 1000; t++) frame(t, extra).weatherKind,
      };
      expect(kinds, {SpatialWeatherKind.clear, SpatialWeatherKind.storm});
      final real = settings(
        extra,
      ).set(SpatialVisualParameter.weatherMode, 'real');
      expect(
        resolveWorldEnvironment(
          settings: real,
          elapsedSeconds: 80,
          realWeatherKind: SpatialWeatherKind.snow,
        ).weatherKind,
        SpatialWeatherKind.snow,
      );
      final story = SpatialVisualPatch.fromJson({'weatherKind': 'fog'});
      expect(
        resolveWorldEnvironment(
          settings: settings().overriddenBy(story),
          overrides: story,
          elapsedSeconds: 1300,
        ).weatherKind,
        isNull,
      );
      expect(
        () => settings({
          'weatherDryMinSeconds': 1801,
          'weatherDryMaxSeconds': 1800,
        }),
        throwsFormatException,
      );
      expect(
        () => settings({
          'weatherDrizzleWeight': 0,
          'weatherRainWeight': 0,
          'weatherDownpourWeight': 0,
          'weatherStormWeight': 0,
        }),
        throwsFormatException,
      );
    },
  );
}
