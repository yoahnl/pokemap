import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/project_visuals/application/spatial_visual_editing.dart';

void main() {
  late SpatialVisualPatch patch;
  late SpatialVisualPatch inherited;

  setUp(() {
    patch = SpatialVisualPatch();
    inherited = SpatialVisualPatch.fromScene(
      camera: SpatialCameraProfile(),
      atmosphere: SpatialAtmosphereSettings(),
    );
  });

  SpatialVisualEditing editing() => SpatialVisualEditing(
    patch: patch,
    inherited: inherited,
    onChanged: (next) => patch = next,
  );

  test(
    'occasional weather owns its mode without changing unrelated settings',
    () {
      patch = patch.set(SpatialVisualParameter.haloStrength, 1.2);
      editing().change(SpatialVisualParameter.weatherMode, 'occasional');
      expect(patch.choice(SpatialVisualParameter.weatherMode), 'occasional');
      expect(patch.enabled(SpatialVisualParameter.weatherEnabled), isTrue);
      expect(patch.number(SpatialVisualParameter.haloStrength), 1.2);
      expect(
        patch.value(SpatialVisualParameter.weatherIntervalSeconds),
        isNull,
      );
    },
  );

  test('time modes and automatic weather edit only their local settings', () {
    for (final mode in ['real', 'cycle', 'fixed']) {
      editing().change(SpatialVisualParameter.timeMode, mode);
      expect(patch.choice(SpatialVisualParameter.timeMode), mode);
    }
    editing().change(SpatialVisualParameter.weatherMode, 'real');
    expect(patch.choice(SpatialVisualParameter.weatherMode), 'real');
    editing().change(SpatialVisualParameter.weatherMode, 'automatic');
    expect(patch.enabled(SpatialVisualParameter.weatherEnabled), isTrue);
    editing().selectWeather(SpatialWeatherKind.snow);
    expect(patch.value(SpatialVisualParameter.weatherSequence), [
      'clear',
      'cloudy',
      'rain',
      'snow',
    ]);
    expect(patch.choice(SpatialVisualParameter.weatherKind), isNull);
    expect(patch.choice(SpatialVisualParameter.timeMode), 'fixed');
  });

  test('FOV retains framing, fog bounds stay valid and inheritance removes only one field', () {
    patch = SpatialVisualPatch.fromJson({
      'pitchDegrees': 34,
      'haloStrength': 1.2,
      'fogStart': 40,
      'fogEnd': 60,
    });
    final before = editing();
    final span =
        before.number(SpatialVisualParameter.cameraDistance) *
        math.tan(
          before.number(SpatialVisualParameter.fieldOfViewDegrees) *
              math.pi /
              360,
        );
    editing().change(SpatialVisualParameter.fieldOfViewDegrees, 24.0);
    final after = editing();
    expect(
      after.number(SpatialVisualParameter.cameraDistance) *
          math.tan(
            after.number(SpatialVisualParameter.fieldOfViewDegrees) *
                math.pi /
                360,
          ),
      closeTo(span, 1e-9),
    );
    editing().change(SpatialVisualParameter.fogStart, 80.0);
    expect(patch.number(SpatialVisualParameter.fogEnd), 81);
    editing().inherit(SpatialVisualParameter.haloStrength);
    expect(patch.value(SpatialVisualParameter.haloStrength), isNull);
    expect(patch.number(SpatialVisualParameter.pitchDegrees), 34);
    expect(patch.number(SpatialVisualParameter.fieldOfViewDegrees), 24);
  });

  test('weather presets, values and inheritance use one local patch', () {
    patch = patch.set(SpatialVisualParameter.haloStrength, 1.2);
    editing().selectWeather(SpatialWeatherKind.snow);
    expect(patch.choice(SpatialVisualParameter.weatherKind), 'snow');
    expect(patch.enabled(SpatialVisualParameter.weatherEnabled), isTrue);
    for (final level in [.15, .35, .55, .8, 1.0]) {
      editing().change(SpatialVisualParameter.weatherIntensity, level);
      expect(patch.number(SpatialVisualParameter.weatherIntensity), level);
      expect(patch.number(SpatialVisualParameter.haloStrength), 1.2);
    }
    for (final kind in SpatialWeatherKind.values.where(
      (kind) => kind.isExtended,
    )) {
      editing().selectWeather(kind);
      expect(patch.choice(SpatialVisualParameter.weatherKind), kind.name);
    }
    editing().change(SpatialVisualParameter.weatherSoundEnabled, true);
    editing().change(SpatialVisualParameter.weatherRainVolume, .6);
    expect(patch.enabled(SpatialVisualParameter.weatherSoundEnabled), isTrue);
    expect(patch.number(SpatialVisualParameter.weatherRainVolume), .6);
    editing().inherit(SpatialVisualParameter.weatherSoundEnabled);
    editing().inherit(SpatialVisualParameter.weatherKind);
    expect(patch.enabled(SpatialVisualParameter.weatherSoundEnabled), isNull);
    expect(patch.choice(SpatialVisualParameter.weatherKind), isNull);
    expect(patch.number(SpatialVisualParameter.haloStrength), 1.2);
    expect(patch.enabled(SpatialVisualParameter.weatherLightning), isNull);
  });

  test('automatic weather never removes its last available kind', () {
    patch = SpatialVisualPatch.fromJson({
      'weatherMode': 'automatic',
      'weatherSequence': ['snow'],
    });
    final original = patch;
    editing().selectWeather(SpatialWeatherKind.snow);
    expect(patch, original);
    editing().selectWeather(SpatialWeatherKind.rain);
    editing().selectWeather(SpatialWeatherKind.snow);
    expect(patch.value(SpatialVisualParameter.weatherSequence), ['rain']);
  });

  test(
    'occasional ranges remain ordered and their last nonzero weight survives',
    () {
      patch = SpatialVisualPatch.fromJson({
        'weatherMode': 'occasional',
        'weatherDryMinSeconds': 10,
        'weatherDryMaxSeconds': 20,
        'weatherDrizzleWeight': 0,
        'weatherRainWeight': 0,
        'weatherDownpourWeight': 0,
        'weatherStormWeight': 1,
      });
      editing().change(SpatialVisualParameter.weatherDryMinSeconds, 30.0);
      expect(patch.number(SpatialVisualParameter.weatherDryMaxSeconds), 30);
    final ordered = patch;
    expect(() => editing().change(SpatialVisualParameter.weatherDryMaxSeconds, 5.0),
      throwsFormatException);
    expect(patch, ordered);
    editing().change(SpatialVisualParameter.weatherDryMaxSeconds, 15.0);
    expect(patch.number(SpatialVisualParameter.weatherDryMinSeconds), 15);
      final before = patch;
      editing().change(SpatialVisualParameter.weatherStormWeight, 0.0);
      expect(patch, before);
    },
  );

  test('numeric drafts reject nonfinite values and accept a comma without publishing invalid text', () {
    final errors = <SpatialVisualParameter, String>{};
    SpatialVisualEditing input() => SpatialVisualEditing(
      patch: patch,
      inherited: inherited,
      onChanged: (next) => patch = next,
      onInvalidInput: (parameter, text) =>
          text == null ? errors.remove(parameter) : errors[parameter] = text,
    );
    final parameter = SpatialVisualParameter.cameraDistance;
    for (final text in ['NaN', 'Infinity', '-1', 'abc']) {
      final before = patch;
      input().editNumber(parameter, text);
      expect(errors[parameter], text);
      expect(patch, before);
    }
    input().editNumber(parameter, '30,5');
    expect(errors, isEmpty);
    expect(patch.number(parameter), 30.5);
  });
}
