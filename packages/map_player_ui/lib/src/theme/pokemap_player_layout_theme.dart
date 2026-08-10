import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

@immutable
final class PokeMapPlayerLayoutTheme
    extends ThemeExtension<PokeMapPlayerLayoutTheme> {
  const PokeMapPlayerLayoutTheme(this.profile);

  final ProjectPresentationLayoutsProfile profile;

  ProjectResolvedSurfaceLayout resolve(
    ProjectPresentationSurfaceRole role,
    BoxConstraints constraints,
  ) =>
      const ProjectPresentationLayoutResolver().resolve(
        layouts: profile,
        role: role,
        width: constraints.maxWidth,
        height: constraints.maxHeight,
      );

  @override
  PokeMapPlayerLayoutTheme copyWith({
    ProjectPresentationLayoutsProfile? profile,
  }) =>
      PokeMapPlayerLayoutTheme(profile ?? this.profile);

  @override
  PokeMapPlayerLayoutTheme lerp(
    covariant ThemeExtension<PokeMapPlayerLayoutTheme>? other,
    double t,
  ) =>
      t < .5 || other is! PokeMapPlayerLayoutTheme ? this : other;
}

extension PokeMapPlayerLayoutThemeContext on BuildContext {
  PokeMapPlayerLayoutTheme? get playerLayoutTheme =>
      Theme.of(this).extension<PokeMapPlayerLayoutTheme>();
}
