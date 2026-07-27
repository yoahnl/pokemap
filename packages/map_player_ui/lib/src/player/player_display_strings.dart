import 'package:flutter/widgets.dart';

final class PlayerDisplayStrings {
  const PlayerDisplayStrings._(this._fr);

  factory PlayerDisplayStrings.of(BuildContext context) =>
      PlayerDisplayStrings._(
        Localizations.localeOf(context).languageCode == 'fr',
      );

  final bool _fr;

  String get title => _fr ? 'Affichage' : 'Display';
  String get mode => _fr ? 'Mode d’affichage' : 'Display mode';
  String get windowed => _fr ? 'Fenêtré' : 'Windowed';
  String get fullscreen => _fr ? 'Plein écran' : 'Fullscreen';
  String get windowSize => _fr ? 'Taille de fenêtre' : 'Window size';
  String get compact => _fr ? 'Compacte' : 'Compact';
  String get balanced => _fr ? 'Équilibrée' : 'Balanced';
  String get spacious => _fr ? 'Spacieuse' : 'Spacious';
  String get unsupported => _fr
      ? 'Les réglages de fenêtre sont disponibles sur ordinateur.'
      : 'Window settings are available on desktop.';
  String get applyFailed => _fr
      ? 'Le réglage d’affichage n’a pas pu être appliqué.'
      : 'The display setting could not be applied.';
}
