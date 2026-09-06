import 'package:flutter/widgets.dart';
import 'package:map_runtime/map_runtime.dart';

final class PlayerSaveStrings {
  const PlayerSaveStrings._(this._languageCode);

  factory PlayerSaveStrings.of(BuildContext context) =>
      PlayerSaveStrings._(Localizations.localeOf(context).languageCode);

  final String _languageCode;

  bool get _isFrench => _languageCode == 'fr';

  String get title => _isFrench ? 'Sauvegarder la partie ?' : 'Save game?';
  String get confirm => _isFrench ? 'Sauvegarder' : 'Save';
  String get cancel => _isFrench ? 'Annuler' : 'Cancel';
  String get saving => _isFrench ? 'Sauvegarde en cours…' : 'Saving…';
  String get success => _isFrench ? 'Partie sauvegardée' : 'Game saved';
  String get failure => _isFrench ? 'Sauvegarde impossible' : 'Unable to save';
  String get retry => _isFrench ? 'Réessayer' : 'Retry';
  String get back => _isFrench ? 'Retour' : 'Back';
  String get exitTitle =>
      _isFrench ? 'Retourner au titre ?' : 'Return to title?';
  String get stay => _isFrench ? 'Rester' : 'Stay';
  String get discard => _isFrench
      ? 'Retour au titre sans sauvegarder'
      : 'Return to title without saving';
  String get saveAndExit =>
      _isFrench ? 'Sauvegarder et quitter' : 'Save and quit';
  String get exiting => _isFrench ? 'Retour au titre…' : 'Returning to title…';
  String get exitFailure =>
      _isFrench ? 'Retour au titre impossible' : 'Unable to return to title';
  String get exitWarning => _isFrench
      ? 'Les progrès non sauvegardés seront perdus si vous quittez sans sauvegarder.'
      : 'Unsaved progress will be lost if you leave without saving.';
  String get discardUnavailable => _isFrench
      ? 'Ce lecteur ne permet pas de quitter sans sauvegarder.'
      : 'This player cannot leave without saving.';
  String get saveUnavailable => _isFrench
      ? 'Aucun emplacement de sauvegarde actif n’est disponible.'
      : 'No active save slot is available.';
  String get saveAndExitUnavailable => _isFrench
      ? 'Ce lecteur ne permet pas de sauvegarder puis quitter.'
      : 'This player cannot save and then quit.';
  String get missingReceipt => _isFrench
      ? 'La sauvegarde n’a pas été confirmée. Réessayez.'
      : 'The save was not confirmed. Please retry.';
  String get unexpectedFailure => _isFrench
      ? 'L’opération n’a pas pu être terminée. Réessayez.'
      : 'The operation could not be completed. Please retry.';
  String player(String name) => _isFrench ? 'Joueur : $name' : 'Player: $name';
  String location(String name) =>
      _isFrench ? 'Lieu : $name' : 'Location: $name';
  String playtime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds ~/ 60 % 60).toString().padLeft(2, '0');
    return _isFrench
        ? 'Durée de jeu : $hours h $minutes min'
        : 'Play time: $hours h $minutes min';
  }

  String lastSave(String date, String time) => _isFrench
      ? 'Dernière sauvegarde : $date à $time'
      : 'Last save: $date at $time';

  String target(RuntimePlayerSaveAddress address) => _isFrench
      ? 'Profil « ${address.profileId} », slot « ${address.slotId} ».'
      : 'Profile “${address.profileId}”, slot “${address.slotId}”.';

  String saved(RuntimePlayerSaveReceipt receipt) => _isFrench
      ? 'Partie sauvegardée — profil « ${receipt.address.profileId} », '
          'slot « ${receipt.address.slotId} ».'
      : 'Game saved — profile “${receipt.address.profileId}”, '
          'slot “${receipt.address.slotId}”.';
}
