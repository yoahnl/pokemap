import 'package:flutter/widgets.dart';

import '../localization/player_localizations.dart';

final class PlayerPcStrings {
  const PlayerPcStrings._(this._strings);

  factory PlayerPcStrings.of(BuildContext context) =>
      PlayerPcStrings._(context.playerL10n);

  final PokeMapPlayerLocalizations _strings;

  String summaryTitle(String pokemon) =>
      _strings.pcSummaryTitle(pokemon: pokemon);

  String get summaryTooltip => _strings.pcSummaryTooltip;
  String get swapTooltip => _strings.pcSwapTooltip;
  String get close => _strings.close;
  String get party => _strings.party;
  String get emptyParty => _strings.emptyPartyMessage;
  String get emptyBox => _strings.pcEmptyBox;
  String get emptyPokemon => _strings.noPokemon;
  String get deposit => _strings.pcDeposit;
  String get withdraw => _strings.pcWithdraw;
  String get unavailable => _strings.pcUnavailable;
  String levelValue(int value) => _strings.pokemonLevel(level: value);
  String get species => _strings.pcSpecies;
  String get level => _strings.pcLevel;
  String get currentHp => _strings.pcCurrentHp;
  String get nature => _strings.pokemonNature;
  String get ability => _strings.pcAbility;
  String get gender => _strings.pcGender;
  String get status => _strings.pcStatus;
  String get shiny => _strings.pcShiny;
  String get heldItem => _strings.pcHeldItem;
  String get moves => _strings.pcMoves;
  String get nickname => _strings.pcNickname;
  String get friendship => _strings.pcFriendship;
  String get origin => _strings.pcOrigin;
  String get metLocation => _strings.pcMetLocation;
  String get metSource => _strings.pcMetSource;
  String get metLevel => _strings.pcMetLevel;
  String get captureBall => _strings.pcCaptureBall;
  String get none => _strings.pcNone;
  String get yes => _strings.yes;
  String get no => _strings.no;

  String originLabel(String origin) => switch (origin) {
    'captured' => _strings.pokemonOriginCaptured,
    'gift' => _strings.pokemonOriginGift,
    'starter' => _strings.pokemonOriginStarter,
    'trade' => _strings.pokemonOriginTrade,
    'scripted' => _strings.pokemonOriginScripted,
    _ => _strings.pokemonOriginUnknown,
  };

  String swapWith(String pokemon) => _strings.pcSwapWith(pokemon: pokemon);
}
