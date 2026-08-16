import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';

final class PlayerSaveRecoveryStrings {
  const PlayerSaveRecoveryStrings._(this._languageCode);

  factory PlayerSaveRecoveryStrings.of(BuildContext context) =>
      PlayerSaveRecoveryStrings._(
        Localizations.localeOf(context).languageCode,
      );

  final String _languageCode;

  bool get _isFrench => _languageCode == 'fr';

  String cause(SaveLoadFailureCode code) => switch (code) {
        SaveLoadFailureCode.unreadable => _isFrench
            ? 'La sauvegarde est illisible.'
            : 'The save file cannot be read.',
        SaveLoadFailureCode.unsupportedSchema => _isFrench
            ? 'Cette sauvegarde vient d’une autre version du jeu.'
            : 'This save comes from another version of the game.',
        SaveLoadFailureCode.invalidState => _isFrench
            ? 'La sauvegarde est incomplète ou incohérente.'
            : 'The save is incomplete or inconsistent.',
      };

  String? versions({int? detected, int? expected}) {
    if (expected == null) return null;
    if (detected == null) {
      return _isFrench
          ? 'Ce jeu attend la version $expected.'
          : 'This game expects version $expected.';
    }
    return _isFrench
        ? 'Sauvegarde en version $detected, ce jeu attend la version $expected.'
        : 'Save is version $detected, this game expects version $expected.';
  }

  String action(SaveRecoveryAction action) => switch (action) {
        SaveRecoveryAction.retry =>
          _isFrench ? 'Réessayer' : 'Try again',
        SaveRecoveryAction.restoreBackup => _isFrench
            ? 'Restaurer la sauvegarde précédente'
            : 'Restore the previous save',
        SaveRecoveryAction.migrate =>
          _isFrench ? 'Mettre à jour la sauvegarde' : 'Update the save',
        SaveRecoveryAction.deleteSave =>
          _isFrench ? 'Supprimer la sauvegarde' : 'Delete the save',
        SaveRecoveryAction.returnToTitle =>
          _isFrench ? 'Retour au titre' : 'Back to title',
      };

  String get deleteConfirmTitle =>
      _isFrench ? 'Supprimer définitivement ?' : 'Delete permanently?';

  String get deleteConfirmBody => _isFrench
      ? 'Cette partie sera effacée et ne pourra pas être récupérée.'
      : 'This game will be erased and cannot be recovered.';

  String get deleteConfirm =>
      _isFrench ? 'Supprimer définitivement' : 'Delete permanently';

  String get deleteCancel => _isFrench ? 'Annuler' : 'Cancel';
}
