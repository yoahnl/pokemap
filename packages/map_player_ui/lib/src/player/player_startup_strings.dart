import 'package:flutter/widgets.dart';

final class PlayerStartupStrings {
  const PlayerStartupStrings._(this._languageCode);

  factory PlayerStartupStrings.of(BuildContext context) =>
      PlayerStartupStrings._(Localizations.localeOf(context).languageCode);

  final String _languageCode;

  bool get _isFrench => _languageCode == 'fr';

  String get pressStart => _isFrench ? 'Appuyer sur Start' : 'Press Start';
  String get replayIntro => _isFrench ? 'Rejouer l’intro' : 'Replay intro';
  String get replaceSaveTitle => _isFrench
      ? 'Remplacer la partie actuelle ?'
      : 'Replace the current game?';
  String get replaceSaveBody => _isFrench
      ? 'Une nouvelle partie remplacera la sauvegarde actuelle au prochain enregistrement.'
      : 'A new game will replace the current save the next time it is saved.';
  String get cancel => _isFrench ? 'Annuler' : 'Cancel';
  String get begin => _isFrench ? 'Commencer' : 'Start';
  String get startupUnavailable => _isFrench
      ? 'Le démarrage du jeu a rencontré un problème.'
      : 'The game could not finish starting.';
  String get retry => _isFrench ? 'Réessayer' : 'Retry';
  String get preparing => _isFrench ? 'Préparation…' : 'Preparing…';
}
