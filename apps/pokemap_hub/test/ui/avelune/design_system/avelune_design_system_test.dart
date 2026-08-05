import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';

void main() {
  group('Avelune design system foundations', () {
    test('standard theme contains every token family', () {
      final theme = AveluneThemeData.standard;

      expect(theme.colors.values, hasLength(23));
      expect(
          theme.colors.values.values, everyElement(isNot(Colors.transparent)));
      expect(theme.typography.values, hasLength(8));
      expect(
        theme.typography.values.values.map((style) => style.fontSize),
        everyElement(isNotNull),
      );
      expect(theme.depth.values, hasLength(6));
      expect(theme.depth.values.values, everyElement(isNotEmpty));
      expect(theme.materials.values, hasLength(8));
      expect(
        theme.materials.values.values,
        everyElement(allOf(greaterThanOrEqualTo(0), lessThanOrEqualTo(1))),
      );
      expect(theme.motion.press, const Duration(milliseconds: 100));
      expect(theme.motion.exchange, const Duration(milliseconds: 440));
      expect(theme.motion.ambientFloat, const Duration(milliseconds: 2800));
    });

    test('spacing, shape and breakpoint scales are centralized', () {
      expect(
        AveluneSpacing.scale,
        const <double>[2, 4, 6, 8, 12, 16, 20, 24, 32, 40],
      );
      expect(AveluneShapes.radii, const <double>[4, 8, 12, 16, 24]);
      expect(AveluneShapes.minimumTouchTarget, 48);

      expect(
        AveluneBreakpoints.resolve(const Size(320, 548)),
        AveluneBreakpointClass.compact,
      );
      expect(
        AveluneBreakpoints.resolve(const Size(360, 752)),
        AveluneBreakpointClass.regular,
      );
      expect(
        AveluneBreakpoints.resolve(const Size(427, 896)),
        AveluneBreakpointClass.large,
      );
    });

    test('component layer cannot introduce raw visual primitives', () {
      final root = Directory('lib/src/ui/avelune/design_system');
      final componentSources = root
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .where(
            (file) =>
                !file.path.contains('/foundation/') &&
                !file.path.contains('/theme/'),
          );
      final forbidden = <RegExp>[
        RegExp(r'Color\(0x'),
        RegExp(r'Colors\.'),
        RegExp(r'Duration\('),
        RegExp(r'BorderRadius\.circular\('),
        RegExp(r'Radius\.circular\('),
      ];

      for (final file in componentSources) {
        final source = file.readAsStringSync();
        for (final pattern in forbidden) {
          expect(
            pattern.hasMatch(source),
            isFalse,
            reason: '${file.path} contains ${pattern.pattern}',
          );
        }
        expect(source, isNot(contains('package:map_editor/')));
        expect(source, isNot(contains('package:map_runtime/')));
      }
    });

    test('theme extensions support copyWith and lerp', () {
      final standard = AveluneThemeData.standard;
      final highContrast = AveluneThemeData.highContrast;
      const replacement = Color(0xFFABCDEF);

      expect(standard.colors.copyWith(accent: replacement).accent, replacement);
      expect(
        standard.typography
            .copyWith(
              title: standard.typography.title.copyWith(fontSize: 31),
            )
            .title
            .fontSize,
        31,
      );
      expect(
        standard.depth
            .copyWith(floatingObject: const <BoxShadow>[]).floatingObject,
        isEmpty,
      );
      expect(
        standard.materials.copyWith(absGrainOpacity: 0.5).absGrainOpacity,
        0.5,
      );
      expect(
        standard.motion.copyWith(press: const Duration(milliseconds: 64)).press,
        const Duration(milliseconds: 64),
      );

      expect(
        standard.colors.lerp(highContrast.colors, 0),
        standard.colors,
      );
      expect(
        standard.colors.lerp(highContrast.colors, 1),
        highContrast.colors,
      );
      expect(
        standard.typography.lerp(highContrast.typography, 0.5).title.fontSize,
        standard.typography.title.fontSize,
      );
      expect(
        standard.motion.lerp(AveluneMotionTokens.reduced, 1).ambientFloat,
        AveluneMotionTokens.reduced.ambientFloat,
      );
    });

    test('standard and high contrast palettes meet readable contrast', () {
      for (final theme in <AveluneThemeData>[
        AveluneThemeData.standard,
        AveluneThemeData.highContrast,
      ]) {
        expect(
          _contrastRatio(theme.colors.textPrimary, theme.colors.canvas),
          greaterThanOrEqualTo(7),
        );
        expect(
          _contrastRatio(theme.colors.textSecondary, theme.colors.canvas),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrastRatio(theme.colors.focus, theme.colors.surface),
          greaterThanOrEqualTo(3),
        );
        expect(
          _contrastRatio(theme.colors.error, theme.colors.surfaceInset),
          greaterThanOrEqualTo(4.5),
        );
      }

      expect(
        _contrastRatio(
          AveluneThemeData.highContrast.colors.outline,
          AveluneThemeData.highContrast.colors.canvas,
        ),
        greaterThan(
          _contrastRatio(
            AveluneThemeData.standard.colors.outline,
            AveluneThemeData.standard.colors.canvas,
          ),
        ),
      );
    });

    testWidgets('context resolution is identical on iOS and Android',
        (tester) async {
      final resolved = <TargetPlatform, AveluneThemeData>{};

      for (final platform in <TargetPlatform>[
        TargetPlatform.iOS,
        TargetPlatform.android,
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AveluneThemeData.standard.applyTo(
              ThemeData.dark().copyWith(platform: platform),
            ),
            home: Builder(
              builder: (context) {
                resolved[platform] = context.aveluneTheme;
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      }

      expect(
        resolved[TargetPlatform.iOS]!.colors,
        resolved[TargetPlatform.android]!.colors,
      );
      expect(
        resolved[TargetPlatform.iOS]!.typography,
        resolved[TargetPlatform.android]!.typography,
      );
      expect(
        resolved[TargetPlatform.iOS]!.motion,
        resolved[TargetPlatform.android]!.motion,
      );
    });

    testWidgets('system animation preference resolves reduced motion tokens',
        (tester) async {
      late AveluneMotionTokens resolved;

      await tester.pumpWidget(
        MaterialApp(
          theme: AveluneThemeData.standard.applyTo(ThemeData.dark()),
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (context) {
                resolved = context.aveluneMotion;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(resolved, AveluneMotionTokens.reduced);
      expect(resolved.ambientFloatAmplitude, 0);
      expect(
        resolved.values.values,
        everyElement(lessThanOrEqualTo(const Duration(milliseconds: 120))),
      );
    });
  });
}

double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lightest = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darkest = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lightest + 0.05) / (darkest + 0.05);
}
