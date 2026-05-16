import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/shadow/editor_shadow_light_preview.dart';

void main() {
  group('createEditorShadowLightPreviewPresets', () {
    test('returns stable unique ids', () {
      final presets = createEditorShadowLightPreviewPresets();

      expect(presets.map((preset) => preset.id), [
        'neutral',
        'noon',
        'morning',
        'evening',
        'soft-night',
      ]);
      expect(presets.map((preset) => preset.id).toSet(), hasLength(5));
    });

    test('returns valid transform values', () {
      for (final preset in createEditorShadowLightPreviewPresets()) {
        expect(preset.directionX.isFinite, isTrue);
        expect(preset.directionY.isFinite, isTrue);
        expect(preset.lengthMultiplier, greaterThanOrEqualTo(0));
        expect(preset.scaleXMultiplier, greaterThan(0));
        expect(preset.scaleYMultiplier, greaterThan(0));
        expect(preset.opacityMultiplier, greaterThanOrEqualTo(0));
      }
    });
  });

  group('applyEditorShadowLightPreviewPreset', () {
    test('neutral preserves geometry and opacity exactly', () {
      final result = applyEditorShadowLightPreviewPreset(
        left: 20,
        top: 88,
        width: 24,
        height: 16,
        opacity: 0.35,
        visualHeight: 64,
        preset: editorShadowLightPreviewPresetById('neutral')!,
      );

      expect(result.left, 20);
      expect(result.top, 88);
      expect(result.width, 24);
      expect(result.height, 16);
      expect(result.opacity, 0.35);
    });

    test('noon shortens and softens the shadow around the same center', () {
      final result = applyEditorShadowLightPreviewPreset(
        left: 20,
        top: 88,
        width: 24,
        height: 16,
        opacity: 0.35,
        visualHeight: 64,
        preset: editorShadowLightPreviewPresetById('noon')!,
      );

      expect(result.width, lessThan(24));
      expect(result.height, lessThan(16));
      expect(result.opacity, lessThan(0.35));
      expect(result.centerX, closeTo(32, 0.001));
      expect(result.centerY, closeTo(96, 0.001));
    });

    test('morning and evening move the shadow in opposite x directions', () {
      final morning = applyEditorShadowLightPreviewPreset(
        left: 20,
        top: 88,
        width: 24,
        height: 16,
        opacity: 0.35,
        visualHeight: 64,
        preset: editorShadowLightPreviewPresetById('morning')!,
      );
      final evening = applyEditorShadowLightPreviewPreset(
        left: 20,
        top: 88,
        width: 24,
        height: 16,
        opacity: 0.35,
        visualHeight: 64,
        preset: editorShadowLightPreviewPresetById('evening')!,
      );

      expect(morning.centerX, greaterThan(32));
      expect(evening.centerX, lessThan(32));
      expect(morning.centerY, greaterThan(96));
      expect(evening.centerY, greaterThan(96));
    });

    test('clamps opacity to 0..1 after multiplier', () {
      final high = applyEditorShadowLightPreviewPreset(
        left: 20,
        top: 88,
        width: 24,
        height: 16,
        opacity: 0.8,
        visualHeight: 64,
        preset: EditorShadowLightPreviewPreset(
          id: 'test-high',
          label: 'Test high',
          description: 'Test high',
          directionX: 0,
          directionY: 0,
          lengthMultiplier: 0,
          scaleXMultiplier: 1,
          scaleYMultiplier: 1,
          opacityMultiplier: 2,
        ),
      );
      final low = applyEditorShadowLightPreviewPreset(
        left: 20,
        top: 88,
        width: 24,
        height: 16,
        opacity: 0.8,
        visualHeight: 64,
        preset: EditorShadowLightPreviewPreset(
          id: 'test-low',
          label: 'Test low',
          description: 'Test low',
          directionX: 0,
          directionY: 0,
          lengthMultiplier: 0,
          scaleXMultiplier: 1,
          scaleYMultiplier: 1,
          opacityMultiplier: -1,
        ),
      );

      expect(high.opacity, 1);
      expect(low.opacity, 0);
    });
  });
}
