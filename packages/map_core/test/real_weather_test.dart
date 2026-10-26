import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'weather cache retains city time offset and accepts older observations',
    () {
      final value = RealWeatherSnapshot(
        location: RealWeatherLocation(
          latitude: 6.25,
          longitude: -75.56,
          label: 'Medellín',
        ),
        conditions: SpatialVisualPatch.fromJson({'weatherKind': 'storm'}),
        fetchedAt: DateTime.utc(2026),
        utcOffsetSeconds: -18000,
        timeZone: 'America/Bogota',
      );
      final restored = RealWeatherSnapshot.fromJson(value.toJson());
      expect(restored.utcOffsetSeconds, -18000);
      expect(restored.timeZone, 'America/Bogota');
      final legacy = {...value.toJson()}
        ..remove('utcOffsetSeconds')
        ..remove('timeZone');
      legacy['schemaVersion'] = 1;
      expect(RealWeatherSnapshot.fromJson(legacy).utcOffsetSeconds, isNull);
      expect(
        () => RealWeatherSnapshot.fromJson({
          ...value.toJson(),
          'utcOffsetSeconds': 999999,
        }),
        throwsFormatException,
      );
    },
  );
  test(
    'real weather is explicit, versioned and old modes retain their versions',
    () {
      final patch = SpatialVisualPatch.fromJson({'weatherMode': 'real'});
      final json = SpatialVisualDocument(profile: patch).toJson();
      expect(json['schemaVersion'], 6);
      expect(SpatialVisualDocument.fromJson(json).profile, patch);
      expect(
        () => SpatialVisualDocument.fromJson({...json, 'schemaVersion': 5}),
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
  test(
    'external conditions remain below scene overrides and offline fallback is deterministic',
    () {
      final base = SpatialVisualPatch.fromJson({
        'weatherMode': 'real',
        'weatherSequence': ['clear', 'rain'],
        'weatherIntervalSeconds': 60,
      });
      expect(
        resolveWorldEnvironment(
          settings: base,
          elapsedSeconds: 75,
          realWeatherKind: SpatialWeatherKind.snow,
        ).weatherKind,
        SpatialWeatherKind.snow,
      );
      expect(
        resolveWorldEnvironment(settings: base, elapsedSeconds: 75).weatherKind,
        SpatialWeatherKind.rain,
      );
      final story = SpatialVisualPatch.fromJson({'weatherKind': 'storm'});
      expect(
        resolveWorldEnvironment(
          settings: base.overriddenBy(story),
          overrides: story,
          elapsedSeconds: 75,
          realWeatherKind: SpatialWeatherKind.snow,
        ).weatherKind,
        isNull,
      );
    },
  );
  test('player weather choices round trip without an IP address', () {
    final location = RealWeatherLocation(
      latitude: 48.86,
      longitude: 2.35,
      label: 'Paris',
      countryCode: 'FR',
    );
    final prefs = RealWeatherPreferences(enabled: true, location: location);
    expect(RealWeatherPreferences.fromJson(prefs.toJson()), prefs);
    expect(location.toJson(), isNot(contains('ip')));
    expect(
      () => RealWeatherLocation(
        latitude: double.nan,
        longitude: 2,
        label: 'City',
      ),
      throwsFormatException,
    );
    expect(
      () => RealWeatherPreferences.fromJson({'enabled': 'yes'}),
      throwsFormatException,
    );
    expect(
      () =>
          RealWeatherLocation.fromJson({...location.toJson(), 'ip': 'address'}),
      throwsFormatException,
    );
  });
}
