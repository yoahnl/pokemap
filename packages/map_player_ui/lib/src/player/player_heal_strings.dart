import 'package:flutter/widgets.dart';

import '../localization/player_localizations.dart';

final class PlayerHealStrings {
  const PlayerHealStrings._(this._strings);

  factory PlayerHealStrings.of(BuildContext context) =>
      PlayerHealStrings._(context.playerL10n);

  final PokeMapPlayerLocalizations _strings;

  String get emptyTitle => _strings.noPokemon;
  String get emptyParty => _strings.emptyPartyMessage;
  String get returnToGame => _strings.returnToGame;
  String get retry => _strings.healRetry;
  String get healParty => _strings.healHealParty;
  String get cancel => _strings.cancel;
  String get close => _strings.close;
  String get unavailable => _strings.healUnavailable;
  String hp(int current, int maximum) =>
      _strings.healHp(current: current, maximum: maximum);
  String status(bool needsHealing) => needsHealing
      ? _strings.healStatusNeedsHealing
      : _strings.healStatusHealthy;
  String pp(int depletedMoveCount) => depletedMoveCount > 0
      ? _strings.healPpToRestore(count: depletedMoveCount)
      : _strings.healPpFull;
}
