import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import 'pokemap_player_theme.dart';

@immutable
final class PokeMapPlayerWindowTheme
    extends ThemeExtension<PokeMapPlayerWindowTheme> {
  const PokeMapPlayerWindowTheme(this.profile);

  final ProjectPresentationWindowsProfile profile;

  double get pauseBackdropOpacity => profile.pauseBackdropOpacity;

  ProjectWindowStyleProfile style(ProjectWindowRole role) =>
      profile.resolve(role);

  Color resolveToken(
    String token,
    PokeMapPlayerSemanticTheme semantic,
  ) =>
      switch (token) {
        'surface' => semantic.surface,
        'surfaceElevated' => semantic.surfaceElevated,
        'titleSurface' => semantic.titleSurface,
        'dialogueSurface' => semantic.dialogueSurface,
        'menuSurface' => semantic.menuSurface,
        'overworldHudSurface' => semantic.overworldHudSurface,
        'battleHudSurface' => semantic.battleHudSurface,
        'outline' => semantic.outline,
        'primary' => semantic.primary,
        'success' => semantic.success,
        'warning' => semantic.warning,
        'danger' => semantic.danger,
        _ => throw ArgumentError.value(token, 'token'),
      };

  @override
  PokeMapPlayerWindowTheme copyWith({
    ProjectPresentationWindowsProfile? profile,
  }) =>
      PokeMapPlayerWindowTheme(profile ?? this.profile);

  @override
  PokeMapPlayerWindowTheme lerp(
    covariant ThemeExtension<PokeMapPlayerWindowTheme>? other,
    double t,
  ) =>
      t < .5 || other is! PokeMapPlayerWindowTheme ? this : other;
}

extension PokeMapPlayerWindowThemeContext on BuildContext {
  PokeMapPlayerWindowTheme? get playerWindowTheme =>
      Theme.of(this).extension<PokeMapPlayerWindowTheme>();

  Color get playerPauseBackdropColor {
    final windowTheme = playerWindowTheme;
    if (windowTheme == null) return playerColors.scrim;
    return playerColors.scrim.withValues(
      alpha: windowTheme.pauseBackdropOpacity,
    );
  }
}
