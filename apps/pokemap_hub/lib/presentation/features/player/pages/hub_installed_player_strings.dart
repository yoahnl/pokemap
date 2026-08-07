import 'package:flutter/widgets.dart';

final class HubInstalledPlayerStrings {
  const HubInstalledPlayerStrings._(this._languageCode);

  factory HubInstalledPlayerStrings.of(BuildContext context) =>
      HubInstalledPlayerStrings.forLocale(
        Localizations.localeOf(context).languageCode,
      );

  factory HubInstalledPlayerStrings.forLocale(String locale) =>
      HubInstalledPlayerStrings._(
        locale.trim().split(RegExp('[-_]')).first.toLowerCase(),
      );

  final String _languageCode;

  bool get _isFrench => _languageCode == 'fr';

  String get defaultProfile => _isFrench ? 'Joueur' : 'Player';
  String get launchFailureTitle =>
      _isFrench ? 'Impossible d’ouvrir ce jeu' : 'Unable to open this game';
  String get launchFailureMessage => _isFrench
      ? 'La session joueur n’a pas pu être validée.'
      : 'The player session could not be validated.';
  String get launchFailureRecommendation => _isFrench
      ? 'Le jeu installé et ses sauvegardes n’ont pas été modifiés.'
      : 'The installed game and its saves were not changed.';
  String get verifyingGame =>
      _isFrench ? 'Vérification du jeu installé…' : 'Verifying installed game…';
}
