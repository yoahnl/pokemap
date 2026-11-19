import 'package:flutter/widgets.dart';

import '../localization/player_localizations.dart';

final class PlayerPokemonSummaryStrings {
  const PlayerPokemonSummaryStrings._(this._strings);

  factory PlayerPokemonSummaryStrings.of(BuildContext context) =>
      PlayerPokemonSummaryStrings._(context.playerL10n);

  final PokeMapPlayerLocalizations _strings;

  String levelValue(int level) => _strings.pokemonLevel(level: level);
  String hpValue(int current, int max) => _strings.hpFraction(current, max);
  String ppValue(int current, int max) =>
      _strings.pokemonPpValue(current: current, max: max);
  String friendshipValue(int friendship) =>
      _strings.pokemonFriendshipValue(friendship: friendship);

  String get hp => _strings.hpAbbreviation;
  String get ppUnavailable => _strings.pokemonPpUnavailable;
  String get species => _strings.pokemonSpecies;
  String get form => _strings.pokemonForm;
  String get experience => _strings.pokemonExperience;
  String get nature => _strings.pokemonNature;
  String get ability => _strings.pokemonAbility;
  String get gender => _strings.pokemonGender;
  String get shiny => _strings.pokemonShiny;
  String get heldItem => _strings.pokemonHeldItem;
  String get friendship => _strings.pokemonFriendship;
  String get stats => _strings.pokemonStats;
  String get attack => _strings.pokemonAttack;
  String get defense => _strings.pokemonDefense;
  String get specialAttack => _strings.pokemonSpecialAttack;
  String get specialDefense => _strings.pokemonSpecialDefense;
  String get speed => _strings.pokemonSpeed;
  String get moves => _strings.pokemonMoves;
  String get provenance => _strings.pokemonProvenance;
  String get origin => _strings.pokemonOrigin;
  String get metLocation => _strings.pokemonMetLocation;
  String get metSource => _strings.pokemonMetSource;
  String get metLevel => _strings.pokemonMetLevel;
  String get captureBall => _strings.pokemonCaptureBall;
  String get none => _strings.pokemonNone;
  String get viewSummary => _strings.pokemonViewSummary;
  String get close => _strings.close;
}
