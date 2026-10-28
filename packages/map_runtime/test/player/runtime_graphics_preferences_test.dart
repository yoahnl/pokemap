import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('defaults keep the authored scene and the automatic scale', () {
    const defaults = RuntimeGraphicsPreferences();
    expect(defaults.toJson(), isEmpty);
    expect(defaults.renderScale, isNull);
    expect(defaults.visualOverrides.isEmpty, isTrue);
  });

  test('each effect switch disables only its authored effects', () {
    Map<SpatialVisualParameter, Object> overrides(
      RuntimeGraphicsPreferences value,
    ) => value.visualOverrides.values;
    expect(
      overrides(const RuntimeGraphicsPreferences(depthOfField: false)),
      {SpatialVisualParameter.depthOfFieldEnabled: false},
    );
    expect(
      overrides(const RuntimeGraphicsPreferences(fogAndHalos: false)),
      {
        SpatialVisualParameter.halosEnabled: false,
        SpatialVisualParameter.depthFogEnabled: false,
      },
    );
    expect(
      overrides(const RuntimeGraphicsPreferences(ambientAnimation: false)),
      {
        SpatialVisualParameter.waterAnimated: false,
        SpatialVisualParameter.windowsLit: false,
        SpatialVisualParameter.fireflies: false,
        SpatialVisualParameter.fireflyLighting: false,
        SpatialVisualParameter.weatherEnabled: false,
      },
    );
    expect(
      overrides(const RuntimeGraphicsPreferences(shadows: false)),
      isEmpty,
    );
  });

  test('a chosen scale maps to the 3D pass and keeps its ratio', () {
    for (final percent in RuntimeGraphicsPreferences.renderScaleChoices) {
      expect(
        RuntimeGraphicsPreferences(renderScalePercent: percent).renderScale,
        percent / 100,
      );
    }
    const chosen = RuntimeGraphicsPreferences(renderScalePercent: 75);
    expect(chosen.copyWith(renderScalePercent: () => null).renderScale, isNull);
    expect(chosen.copyWith(shadows: false).renderScalePercent, 75);
  });

  test('persisted graphics round-trip and reject invalid data', () {
    const chosen = RuntimeGraphicsPreferences(
      renderScalePercent: 67,
      depthOfField: false,
      shadows: false,
      fogAndHalos: false,
      ambientAnimation: false,
    );
    expect(RuntimeGraphicsPreferences.fromJson(chosen.toJson()), chosen);
    expect(
      RuntimeGraphicsPreferences.fromJson(const {}),
      const RuntimeGraphicsPreferences(),
    );
    for (final invalid in <Map<String, Object?>>[
      {'renderScalePercent': 60},
      {'renderScalePercent': '50'},
      {'shadows': 'no'},
      {'bloom': false},
    ]) {
      expect(
        () => RuntimeGraphicsPreferences.fromJson(invalid),
        throwsFormatException,
        reason: '$invalid',
      );
    }
  });

  test('the companion codec transports graphics preferences', () {
    const snapshot = PlayerPreferencesSnapshot(
      locale: 'fr',
      accessibility: GameSessionAccessibilityOptions(),
    );
    PlayerPreferencesSnapshot transport(PlayerPreferencesSnapshot value) =>
        RuntimeCompanionPresentationCodec.decodePlayerPreferencesSnapshot(
          Map<String, dynamic>.from(
            RuntimeCompanionPresentationCodec.encodePlayerPreferencesSnapshot(
              value,
            ),
          ),
        );
    expect(
      RuntimeCompanionPresentationCodec.encodePlayerPreferencesSnapshot(
        snapshot,
      ),
      isNot(contains('graphics')),
    );
    const graphics = RuntimeGraphicsPreferences(
      renderScalePercent: 50,
      shadows: false,
    );
    expect(transport(snapshot.copyWith(graphics: graphics)).graphics, graphics);
  });
}
