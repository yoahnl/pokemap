import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

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
}
