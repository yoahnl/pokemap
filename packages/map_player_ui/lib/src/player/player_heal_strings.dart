import 'package:flutter/widgets.dart';

final class PlayerHealStrings {
  const PlayerHealStrings._(this._languageCode);

  factory PlayerHealStrings.of(BuildContext context) => PlayerHealStrings._(
        Localizations.localeOf(context).languageCode,
      );

  final String _languageCode;

  bool get _isFrench => _languageCode == 'fr';

  String get emptyTitle => _isFrench ? 'Aucun Pokémon' : 'No Pokémon';
  String get emptyParty =>
      _isFrench ? 'Votre équipe est vide.' : 'Your party is empty.';
  String get returnToGame => _isFrench ? 'Retour au jeu' : 'Return to game';
  String get retry => _isFrench ? 'Réessayer' : 'Try again';
  String get healParty => _isFrench ? 'Soigner l’équipe' : 'Heal party';
  String get cancel => _isFrench ? 'Annuler' : 'Cancel';
  String get close => _isFrench ? 'Fermer' : 'Close';
  String get unavailable => _isFrench
      ? 'Le service de soin ne peut pas être affiché.'
      : 'The healing service cannot be displayed.';
  String hp(int current, int maximum) =>
      _isFrench ? 'PV $current / $maximum' : 'HP $current / $maximum';
  String status(bool needsHealing) => switch ((_isFrench, needsHealing)) {
        (true, true) => 'Statut à soigner',
        (true, false) => 'Statut normal',
        (false, true) => 'Status needs healing',
        (false, false) => 'Status healthy',
      };
  String pp(int depletedMoveCount) {
    if (depletedMoveCount > 0) {
      return _isFrench
          ? 'PP à restaurer : $depletedMoveCount'
          : 'PP to restore: $depletedMoveCount';
    }
    return _isFrench ? 'PP complets' : 'PP full';
  }
}
