import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Studio keeps its original dark default and exposes a light palette',
    () {
      final dark = studioTheme();
      final light = studioTheme(brightness: Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(dark.colorScheme.surface, const Color(0xff0d1d2c));
      expect(light.brightness, Brightness.light);
      expect(light.colorScheme.surface, const Color(0xffffffff));
      expect(light.colorScheme.primary, const Color(0xff2057c4));
      expect(light.textTheme.bodyMedium?.fontSize, StudioTypeScale.body);
      expect(light.visualDensity, dark.visualDensity);
    },
  );

  test('light Studio foregrounds meet text contrast on their surfaces', () {
    final light = studioTheme(brightness: Brightness.light);
    final scheme = light.colorScheme;
    final studio = light.extension<StudioColors>()!;
    final cases = [
      (scheme.onSurface, scheme.surface),
      (scheme.onSurfaceVariant, scheme.surfaceContainer),
      (scheme.onPrimary, scheme.primary),
      (scheme.onErrorContainer, scheme.errorContainer),
      for (final tone in [
        studio.success,
        studio.warning,
        studio.featureAccent,
        studio.canvasSelection,
      ])
        (tone, Color.alphaBlend(tone.withValues(alpha: .12), scheme.surface)),
    ];
    for (final (ink, background) in cases) {
      final contrast =
          (background.computeLuminance() + .05) /
          (ink.computeLuminance() + .05);
      expect(contrast < 1 ? 1 / contrast : contrast, greaterThanOrEqualTo(4.5));
    }
  });
}
