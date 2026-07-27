import 'package:flutter/widgets.dart';

final class PlayerBagStrings {
  const PlayerBagStrings._(this._languageCode);

  factory PlayerBagStrings.of(BuildContext context) =>
      PlayerBagStrings._(Localizations.localeOf(context).languageCode);

  final String _languageCode;

  bool get _isFrench => _languageCode == 'fr';

  String get use => _isFrench ? 'Utiliser' : 'Use';
  String get close => _isFrench ? 'Fermer' : 'Close';
  String get chooseTarget =>
      _isFrench ? 'Choisir une cible' : 'Choose a target';

  String useOn(String pokemon) =>
      _isFrench ? 'Utiliser sur $pokemon' : 'Use on $pokemon';

  String useOnMove(String pokemon, String move) =>
      _isFrench ? 'Utiliser sur $pokemon — $move' : 'Use on $pokemon — $move';
}
