import 'package:flutter/material.dart';

final class AveluneColors extends ThemeExtension<AveluneColors> {
  const AveluneColors({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.outline,
    required this.primary,
    required this.primaryBright,
    required this.glow,
    required this.textPrimary,
    required this.textSecondary,
    required this.gold,
    required this.wood,
    required this.woodHighlight,
    required this.shell,
    required this.shellHighlight,
    required this.invalid,
  });

  static const AveluneColors standard = AveluneColors(
    background: Color(0xFF07070A),
    surface: Color(0xFF111116),
    surfaceElevated: Color(0xFF19171E),
    outline: Color(0xFF39323F),
    primary: Color(0xFF7137DA),
    primaryBright: Color(0xFFA66AFF),
    glow: Color(0xFF6D28D9),
    textPrimary: Color(0xFFF6EFE4),
    textSecondary: Color(0xFFA9A2B0),
    gold: Color(0xFFD8A64B),
    wood: Color(0xFF29170F),
    woodHighlight: Color(0xFF5B3521),
    shell: Color(0xFF211A2C),
    shellHighlight: Color(0xFF51346F),
    invalid: Color(0xFFD46666),
  );

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color outline;
  final Color primary;
  final Color primaryBright;
  final Color glow;
  final Color textPrimary;
  final Color textSecondary;
  final Color gold;
  final Color wood;
  final Color woodHighlight;
  final Color shell;
  final Color shellHighlight;
  final Color invalid;

  @override
  AveluneColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? outline,
    Color? primary,
    Color? primaryBright,
    Color? glow,
    Color? textPrimary,
    Color? textSecondary,
    Color? gold,
    Color? wood,
    Color? woodHighlight,
    Color? shell,
    Color? shellHighlight,
    Color? invalid,
  }) =>
      AveluneColors(
        background: background ?? this.background,
        surface: surface ?? this.surface,
        surfaceElevated: surfaceElevated ?? this.surfaceElevated,
        outline: outline ?? this.outline,
        primary: primary ?? this.primary,
        primaryBright: primaryBright ?? this.primaryBright,
        glow: glow ?? this.glow,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        gold: gold ?? this.gold,
        wood: wood ?? this.wood,
        woodHighlight: woodHighlight ?? this.woodHighlight,
        shell: shell ?? this.shell,
        shellHighlight: shellHighlight ?? this.shellHighlight,
        invalid: invalid ?? this.invalid,
      );

  @override
  AveluneColors lerp(covariant AveluneColors? other, double t) {
    if (other == null) return this;
    return AveluneColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryBright: Color.lerp(primaryBright, other.primaryBright, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      wood: Color.lerp(wood, other.wood, t)!,
      woodHighlight: Color.lerp(woodHighlight, other.woodHighlight, t)!,
      shell: Color.lerp(shell, other.shell, t)!,
      shellHighlight: Color.lerp(shellHighlight, other.shellHighlight, t)!,
      invalid: Color.lerp(invalid, other.invalid, t)!,
    );
  }
}

ThemeData applyAveluneTheme(
  ThemeData theme, {
  bool highContrast = false,
}) {
  final palette = highContrast
      ? AveluneColors.standard.copyWith(
          outline: Color.lerp(
            AveluneColors.standard.outline,
            AveluneColors.standard.textPrimary,
            0.45,
          ),
          primaryBright: Color.lerp(
            AveluneColors.standard.primaryBright,
            AveluneColors.standard.textPrimary,
            0.18,
          ),
          textSecondary: Color.lerp(
            AveluneColors.standard.textSecondary,
            AveluneColors.standard.textPrimary,
            0.52,
          ),
          invalid: Color.lerp(
            AveluneColors.standard.invalid,
            AveluneColors.standard.textPrimary,
            0.14,
          ),
        )
      : AveluneColors.standard;
  final extensions = theme.extensions.values
      .where((extension) => extension is! AveluneColors)
      .toList(growable: true)
    ..add(palette);
  return theme.copyWith(extensions: extensions);
}

extension AveluneThemeContext on BuildContext {
  AveluneColors get aveluneColors =>
      Theme.of(this).extension<AveluneColors>() ?? AveluneColors.standard;
}
