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
  String get manageHeldItem =>
      _isFrench ? 'Gérer l’objet tenu' : 'Manage held item';

  String heldItemSummary(String item) =>
      _isFrench ? 'Objet tenu : $item' : 'Held item: $item';

  String giveHeldItem(String item) => _isFrench ? 'Donner $item' : 'Give $item';

  String replaceHeldItem(String item) =>
      _isFrench ? 'Remplacer par $item' : 'Replace with $item';

  String takeHeldItem(String item) =>
      _isFrench ? 'Retirer $item' : 'Take $item';

  String useOn(String pokemon) =>
      _isFrench ? 'Utiliser sur $pokemon' : 'Use on $pokemon';

  String useOnMove(String pokemon, String move) =>
      _isFrench ? 'Utiliser sur $pokemon — $move' : 'Use on $pokemon — $move';

  String teachTo(String pokemon) =>
      _isFrench ? 'Apprendre à $pokemon' : 'Teach to $pokemon';

  String teachReplacing(String pokemon, String move) => _isFrench
      ? 'Apprendre à $pokemon en oubliant $move'
      : 'Teach to $pokemon and forget $move';
}
