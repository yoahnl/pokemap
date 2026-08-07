import 'package:flutter/material.dart';

import 'package:pokemap_hub/presentation/design_system/foundation/avelune_color_tokens.dart';
import 'package:pokemap_hub/presentation/design_system/foundation/avelune_depth_tokens.dart';
import 'package:pokemap_hub/presentation/design_system/foundation/avelune_material_tokens.dart';
import 'package:pokemap_hub/presentation/design_system/foundation/avelune_motion_tokens.dart';
import 'package:pokemap_hub/presentation/design_system/foundation/avelune_typography_tokens.dart';

@immutable
final class AveluneThemeData {
  const AveluneThemeData({
    required this.colors,
    required this.typography,
    required this.depth,
    required this.materials,
    required this.motion,
  });

  static final AveluneThemeData standard = _create(AveluneColors.standard);

  static final AveluneThemeData highContrast = _create(
    AveluneColors.standard.copyWith(
      outline: const Color(0xFF94869F),
      focus: const Color(0xFFD5B8FF),
      textSecondary: const Color(0xFFD7CEDB),
      accentBright: const Color(0xFFC39AFF),
      error: const Color(0xFFFF9C9C),
    ),
  );

  final AveluneColors colors;
  final AveluneTypographyTokens typography;
  final AveluneDepthTokens depth;
  final AveluneMaterialTokens materials;
  final AveluneMotionTokens motion;

  AveluneThemeData copyWith({
    AveluneColors? colors,
    AveluneTypographyTokens? typography,
    AveluneDepthTokens? depth,
    AveluneMaterialTokens? materials,
    AveluneMotionTokens? motion,
  }) =>
      AveluneThemeData(
        colors: colors ?? this.colors,
        typography: typography ?? this.typography,
        depth: depth ?? this.depth,
        materials: materials ?? this.materials,
        motion: motion ?? this.motion,
      );

  ThemeData applyTo(ThemeData base) {
    final extensions = base.extensions.values
        .where(
          (extension) =>
              extension is! AveluneColors &&
              extension is! AveluneTypographyTokens &&
              extension is! AveluneDepthTokens &&
              extension is! AveluneMaterialTokens &&
              extension is! AveluneMotionTokens,
        )
        .toList(growable: true)
      ..addAll(<ThemeExtension<dynamic>>[
        colors,
        typography,
        depth,
        materials,
        motion,
      ]);
    final colorScheme = base.colorScheme.copyWith(
      brightness: Brightness.dark,
      primary: colors.accent,
      onPrimary: colors.textPrimary,
      secondary: colors.accentBright,
      onSecondary: colors.canvas,
      surface: colors.surface,
      onSurface: colors.textPrimary,
      error: colors.error,
      onError: colors.canvas,
      outline: colors.outline,
    );

    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colors.canvas,
      colorScheme: colorScheme,
      textTheme: typography.applyTo(base.textTheme),
      extensions: extensions,
    );
  }

  static AveluneThemeData _create(AveluneColors colors) => AveluneThemeData(
        colors: colors,
        typography: AveluneTypographyTokens.standard,
        depth: AveluneDepthTokens.fromColors(colors),
        materials: AveluneMaterialTokens.standard,
        motion: AveluneMotionTokens.standard,
      );
}

ThemeData applyAveluneTheme(
  ThemeData theme, {
  bool highContrast = false,
  bool reducedMotion = false,
}) {
  final aveluneTheme =
      highContrast ? AveluneThemeData.highContrast : AveluneThemeData.standard;
  return aveluneTheme
      .copyWith(
        motion:
            reducedMotion ? AveluneMotionTokens.reduced : aveluneTheme.motion,
      )
      .applyTo(theme);
}
