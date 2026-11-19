import 'package:flutter/widgets.dart';

import '../localization/player_localizations.dart';

final class PlayerBagStrings {
  const PlayerBagStrings._(this._strings);

  factory PlayerBagStrings.of(BuildContext context) =>
      PlayerBagStrings._(context.playerL10n);

  final PokeMapPlayerLocalizations _strings;

  String get use => _strings.bagUse;
  String get close => _strings.close;
  String get chooseTarget => _strings.bagChooseTarget;
  String get manageHeldItem => _strings.bagManageHeldItem;

  String heldItemSummary(String item) =>
      _strings.bagHeldItemSummary(item: item);

  String giveHeldItem(String item) => _strings.bagGiveHeldItem(item: item);

  String replaceHeldItem(String item) =>
      _strings.bagReplaceHeldItem(item: item);

  String takeHeldItem(String item) => _strings.bagTakeHeldItem(item: item);

  String useOn(String pokemon) => _strings.bagUseOn(pokemon: pokemon);

  String useOnMove(String pokemon, String move) =>
      _strings.bagUseOnMove(pokemon: pokemon, move: move);

  String teachTo(String pokemon) => _strings.bagTeachTo(pokemon: pokemon);

  String teachReplacing(String pokemon, String move) =>
      _strings.bagTeachReplacing(pokemon: pokemon, move: move);
}
