import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

@immutable
final class PokeMapPlayerBattleChrome
    extends ThemeExtension<PokeMapPlayerBattleChrome> {
  const PokeMapPlayerBattleChrome({
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSelected,
    required this.underplate,
    required this.textPrimary,
    required this.textSecondary,
    required this.outline,
    required this.focus,
    required this.water,
    required this.normal,
  });

  static const darkFieldManual = PokeMapPlayerBattleChrome(
    surface: Color(0xFF111916),
    surfaceRaised: Color(0xFF1E2A25),
    surfaceSelected: Color(0xFF173229),
    underplate: Color(0xFF0B120F),
    textPrimary: Color(0xFFF3ECD9),
    textSecondary: Color(0xFF93A299),
    outline: Color(0xFF827866),
    focus: Color(0xFFE86445),
    water: Color(0xFF3E9FE8),
    normal: Color(0xFFA99F8E),
  );

  final Color surface;
  final Color surfaceRaised;
  final Color surfaceSelected;
  final Color underplate;
  final Color textPrimary;
  final Color textSecondary;
  final Color outline;
  final Color focus;
  final Color water;
  final Color normal;

  @override
  PokeMapPlayerBattleChrome copyWith({
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceSelected,
    Color? underplate,
    Color? textPrimary,
    Color? textSecondary,
    Color? outline,
    Color? focus,
    Color? water,
    Color? normal,
  }) =>
      PokeMapPlayerBattleChrome(
        surface: surface ?? this.surface,
        surfaceRaised: surfaceRaised ?? this.surfaceRaised,
        surfaceSelected: surfaceSelected ?? this.surfaceSelected,
        underplate: underplate ?? this.underplate,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        outline: outline ?? this.outline,
        focus: focus ?? this.focus,
        water: water ?? this.water,
        normal: normal ?? this.normal,
      );

  @override
  PokeMapPlayerBattleChrome lerp(
    covariant ThemeExtension<PokeMapPlayerBattleChrome>? other,
    double t,
  ) {
    if (other is! PokeMapPlayerBattleChrome) return this;
    return PokeMapPlayerBattleChrome(
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceSelected: Color.lerp(surfaceSelected, other.surfaceSelected, t)!,
      underplate: Color.lerp(underplate, other.underplate, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      focus: Color.lerp(focus, other.focus, t)!,
      water: Color.lerp(water, other.water, t)!,
      normal: Color.lerp(normal, other.normal, t)!,
    );
  }
}

@immutable
final class PokeMapPlayerBattleTheme
    extends ThemeExtension<PokeMapPlayerBattleTheme> {
  const PokeMapPlayerBattleTheme(this.profile);

  final ProjectBattlePresentationProfile profile;

  @override
  PokeMapPlayerBattleTheme copyWith({
    ProjectBattlePresentationProfile? profile,
  }) =>
      PokeMapPlayerBattleTheme(profile ?? this.profile);

  @override
  PokeMapPlayerBattleTheme lerp(
    covariant ThemeExtension<PokeMapPlayerBattleTheme>? other,
    double t,
  ) =>
      t < .5 || other is! PokeMapPlayerBattleTheme ? this : other;
}

extension PokeMapPlayerBattleContext on BuildContext {
  ProjectBattlePresentationProfile? get playerBattleProfile =>
      Theme.of(this).extension<PokeMapPlayerBattleTheme>()?.profile;

  PokeMapPlayerBattleChrome get playerBattleChrome =>
      Theme.of(this).extension<PokeMapPlayerBattleChrome>() ??
      PokeMapPlayerBattleChrome.darkFieldManual;
}
