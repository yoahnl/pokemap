import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

@immutable
final class PokeMapPlayerDialogueTheme
    extends ThemeExtension<PokeMapPlayerDialogueTheme> {
  const PokeMapPlayerDialogueTheme(this.profile);

  final ProjectDialoguePresentationProfile profile;

  @override
  PokeMapPlayerDialogueTheme copyWith({
    ProjectDialoguePresentationProfile? profile,
  }) =>
      PokeMapPlayerDialogueTheme(profile ?? this.profile);

  @override
  PokeMapPlayerDialogueTheme lerp(
    covariant ThemeExtension<PokeMapPlayerDialogueTheme>? other,
    double t,
  ) =>
      t < .5 || other is! PokeMapPlayerDialogueTheme ? this : other;
}

extension PokeMapPlayerDialogueContext on BuildContext {
  ProjectDialoguePresentationProfile? get playerDialogueProfile =>
      Theme.of(this).extension<PokeMapPlayerDialogueTheme>()?.profile;
}
