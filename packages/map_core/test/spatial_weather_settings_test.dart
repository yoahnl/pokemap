import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('extended weather uses explicit schemas while existing exports keep their schemas', () {
    for (final kind in SpatialWeatherKind.values) {
      final patch = SpatialVisualPatch.fromJson({'weatherKind': kind.name});
      final visual = SpatialVisualDocument(profile: patch).toJson();
      expect(visual['schemaVersion'], kind.isExtended ? 7 : 3);
      expect(SpatialVisualDocument.fromJson(visual).profile, patch);
      final atmosphere = SpatialAtmosphereDocument(mapId: 'town', settings: SpatialAtmosphereSettings(weather: SpatialWeatherSettings(kind: kind))).toJson();
      expect(SpatialAtmosphereDocument.fromJson(atmosphere).settings.weather.kind, kind);
      if (kind.isExtended) {
        expect(() => SpatialVisualDocument.fromJson({...visual, 'schemaVersion': 6}), throwsFormatException);
        expect(() => SpatialAtmosphereDocument.fromJson({...atmosphere, 'schemaVersion': 5}), throwsFormatException);
      }
    }
    final sequence = SpatialVisualPatch.fromJson({'weatherSequence': SpatialWeatherKind.values.map((kind) => kind.name).toList()});
    expect(sequence.requiresExtendedWeather, isTrue);
    expect(SpatialVisualDocument.fromJson(SpatialVisualDocument(profile: sequence).toJson()).profile, sequence);
  });
  test('weather sound is explicit and survives a targeted visual document', () {
    final weather = SpatialWeatherSettings.fromJson({
      'enabled': true,
      'kind': 'rain',
      'soundEnabled': true,
      'rainVolume': .8,
      'windVolume': .4,
    });
    expect(weather.toJson()['soundEnabled'], isTrue);
    final profile = SpatialVisualPatch.fromJson({
      'weatherSoundEnabled': true,
      'weatherRainVolume': .8,
      'weatherWindVolume': .4,
    });
    final document = SpatialVisualDocument(profile: profile);
    expect(SpatialVisualDocument.fromJson(document.toJson()).profile, profile);
    expect(
      SpatialWeatherSettings.fromJson({
        'enabled': true,
        'kind': 'rain',
      }).toJson(),
      isNot(contains('soundEnabled')),
    );
  });

  test(
    'audio settings require their own schemas and reject malformed gains',
    () {
      final weather = SpatialWeatherSettings(
        soundEnabled: true,
        rainVolume: .8,
        windVolume: .4,
      );
      final atmosphere = SpatialAtmosphereDocument(
        mapId: 'town',
        settings: SpatialAtmosphereSettings(weather: weather),
      );
      expect(atmosphere.toJson()['schemaVersion'], 5);
      expect(
        SpatialAtmosphereDocument.fromJson(
          atmosphere.toJson(),
        ).settings.weather,
        weather,
      );
      for (final version in [1, 2, 3, 4]) {
        expect(
          () => SpatialAtmosphereDocument.fromJson({
            ...atmosphere.toJson(),
            'schemaVersion': version,
          }),
          throwsFormatException,
        );
      }
      final patch = SpatialVisualPatch.fromJson({'weatherSoundEnabled': true});
      final visual = SpatialVisualDocument(profile: patch);
      expect(visual.toJson()['schemaVersion'], 4);
      for (final version in [1, 2, 3]) {
        expect(
          () => SpatialVisualDocument.fromJson({
            ...visual.toJson(),
            'schemaVersion': version,
          }),
          throwsFormatException,
        );
      }
      for (final value in [-.1, 1.1, double.nan, double.infinity, 'loud']) {
        expect(
          () => SpatialWeatherSettings.fromJson({'rainVolume': value}),
          throwsFormatException,
        );
        expect(
          () => SpatialWeatherSettings.fromJson({'windVolume': value}),
          throwsFormatException,
        );
      }
      expect(
        SpatialVisualPatch.fromScene(
          camera: SpatialCameraProfile(),
          atmosphere: atmosphere.settings,
        ).applyAtmosphere(SpatialAtmosphereSettings()).weather,
        weather,
      );
    },
  );

  test('legacy atmosphere remains weather-free without new schema fields', () {
    final settings = SpatialAtmosphereSettings.fromJson({});
    expect(settings.weather.enabled, isFalse);
    expect(settings.weather.kind, SpatialWeatherKind.rain);
    expect(settings.toJson(), isNot(contains('weather')));
    final document = SpatialAtmosphereDocument(
      mapId: 'town',
      settings: settings,
    );
    expect(document.toJson()['schemaVersion'], 2);
  });

  test('all weather styles round trip with bounded editable settings', () {
    expect(SpatialWeatherKind.values.length, greaterThanOrEqualTo(15));
    for (final kind in SpatialWeatherKind.values) {
      final weather = SpatialWeatherSettings(
        enabled: true,
        kind: kind,
        intensity: .8,
        density: .6,
        speed: 1.5,
        windStrength: .7,
        windDirection: -35,
        particleSize: 1.2,
        opacity: .65,
        cloudCover: .4,
        fogStrength: .3,
      );
      expect(SpatialWeatherSettings.fromJson(weather.toJson()), weather);
      expect(weather.lightning, isFalse);
      final settings = SpatialAtmosphereSettings(weather: weather);
      final document = SpatialAtmosphereDocument(
        mapId: 'town',
        settings: settings,
      );
      expect(document.toJson()['schemaVersion'], kind.isExtended ? 6 : 4);
      expect(
        SpatialAtmosphereDocument.fromJson(document.toJson()).settings,
        settings,
      );
      expect(settings.copyWith(waterAnimated: true).weather, weather);
    }
  });

  test('invalid weather is rejected without clamping corrupted data', () {
    for (final value in [-.1, 1.1, double.nan, double.infinity]) {
      expect(
        () => SpatialWeatherSettings(intensity: value),
        throwsFormatException,
      );
    }
    expect(() => SpatialWeatherSettings(speed: 0), throwsFormatException);
    expect(
      () => SpatialWeatherSettings(particleSize: 100),
      throwsFormatException,
    );
    expect(
      () => SpatialWeatherSettings.fromJson({'kind': 'tornadoFuture'}),
      throwsFormatException,
    );
    expect(
      () => SpatialWeatherSettings.fromJson({'unknown': 1}),
      throwsFormatException,
    );
  });

  test('weather fields cannot be smuggled into legacy atmosphere schemas', () {
    for (final version in [1, 2, 3]) {
      expect(
        () => SpatialAtmosphereDocument.fromJson({
          'schemaVersion': version,
          'mapId': 'town',
          'settings': {
            'weather': SpatialWeatherSettings(enabled: true).toJson(),
          },
        }),
        throwsFormatException,
      );
    }
  });

  test(
    'visual weather choices inherit and serialize without numeric codes',
    () {
      final base = SpatialVisualPatch.fromScene(
        camera: SpatialCameraProfile(),
        atmosphere: SpatialAtmosphereSettings(),
      );
      final patch = SpatialVisualPatch.fromJson({
        'weatherEnabled': true,
        'weatherKind': 'snow',
        'weatherIntensity': .7,
        'weatherWindStrength': .6,
        'weatherLightning': false,
      });
      final effective = base.overriddenBy(patch);
      expect(effective.choice(SpatialVisualParameter.weatherKind), 'snow');
      expect(
        effective.applyAtmosphere(SpatialAtmosphereSettings()).weather.kind,
        SpatialWeatherKind.snow,
      );
      expect(patch.requiresWeather, isTrue);
      expect(patch.requiresLightWorkshop, isFalse);
      expect(
        SpatialVisualDocument(profile: patch).toJson()['schemaVersion'],
        3,
      );
      expect(
        SpatialVisualDocument.fromJson(
          SpatialVisualDocument(profile: patch).toJson(),
        ).profile,
        patch,
      );
      final restored = patch.set(SpatialVisualParameter.weatherKind, null);
      expect(
        base.overriddenBy(restored).choice(SpatialVisualParameter.weatherKind),
        'rain',
      );
      expect(
        () => patch.set(SpatialVisualParameter.weatherKind, 1),
        throwsFormatException,
      );
      expect(
        () => patch.set(SpatialVisualParameter.weatherKind, 'future'),
        throwsFormatException,
      );
    },
  );
}
