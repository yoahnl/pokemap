import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/shadow/placed_element_shadow_tuning_presets.dart';

void main() {
  group('createPlacedElementShadowTuningPresets', () {
    test('returns stable unique preset ids', () {
      final presets = createPlacedElementShadowTuningPresets();

      expect(presets.map((preset) => preset.id), [
        'compact-footprint',
        'soft-wide-footprint',
        'subtle-footprint',
        'cast-bottom-right',
        'cast-bottom-left',
      ]);
      expect(
        presets.map((preset) => preset.id).toSet(),
        hasLength(presets.length),
      );
    });

    test('keeps every preset within valid numeric ranges', () {
      final presets = createPlacedElementShadowTuningPresets();

      for (final preset in presets) {
        expect(preset.scaleX, greaterThan(0), reason: preset.id);
        expect(preset.scaleY, greaterThan(0), reason: preset.id);
        expect(preset.opacity, inInclusiveRange(0, 1), reason: preset.id);
      }
    });
  });

  group('applyPlacedElementShadowTuningPreset', () {
    test('applies compact footprint values to a null override', () {
      final preset = _preset('compact-footprint');

      final override = applyPlacedElementShadowTuningPreset(
        preset: preset,
        currentOverride: null,
      );

      expect(override.mode, ShadowOverrideMode.custom);
      expect(override.shadowProfileId, isNull);
      expect(override.offsetX, 0);
      expect(override.offsetY, 2);
      expect(override.scaleX, 0.65);
      expect(override.scaleY, 0.45);
      expect(override.opacity, 0.24);
    });

    test('does not inherit a profile id from disabled overrides', () {
      final preset = _preset('compact-footprint');

      final override = applyPlacedElementShadowTuningPreset(
        preset: preset,
        currentOverride: MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.disabled,
        ),
      );

      expect(override.mode, ShadowOverrideMode.custom);
      expect(override.shadowProfileId, isNull);
    });

    test('preserves a profile id from custom overrides', () {
      final preset = _preset('compact-footprint');

      final override = applyPlacedElementShadowTuningPreset(
        preset: preset,
        currentOverride: MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.custom,
          shadowProfileId: 'wide_shadow',
          offsetX: 99,
          offsetY: 99,
          scaleX: 2,
          scaleY: 2,
          opacity: 1,
        ),
      );

      expect(override.mode, ShadowOverrideMode.custom);
      expect(override.shadowProfileId, 'wide_shadow');
      expect(override.offsetX, preset.offsetX);
      expect(override.offsetY, preset.offsetY);
      expect(override.scaleX, preset.scaleX);
      expect(override.scaleY, preset.scaleY);
      expect(override.opacity, preset.opacity);
    });

    test('applies exact cast direction values', () {
      final bottomRight = applyPlacedElementShadowTuningPreset(
        preset: _preset('cast-bottom-right'),
        currentOverride: null,
      );
      final bottomLeft = applyPlacedElementShadowTuningPreset(
        preset: _preset('cast-bottom-left'),
        currentOverride: null,
      );

      expect(bottomRight.offsetX, 6);
      expect(bottomRight.offsetY, 5);
      expect(bottomRight.scaleX, 0.85);
      expect(bottomRight.scaleY, 0.45);
      expect(bottomRight.opacity, 0.26);

      expect(bottomLeft.offsetX, -6);
      expect(bottomLeft.offsetY, 5);
      expect(bottomLeft.scaleX, 0.85);
      expect(bottomLeft.scaleY, 0.45);
      expect(bottomLeft.opacity, 0.26);
    });
  });
}

PlacedElementShadowTuningPreset _preset(String id) {
  return createPlacedElementShadowTuningPresets().singleWhere(
    (preset) => preset.id == id,
  );
}
