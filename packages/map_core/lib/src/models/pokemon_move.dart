import 'package:freezed_annotation/freezed_annotation.dart';

import 'pokemon_move_accuracy.dart';
import 'pokemon_move_effect.dart';

part 'pokemon_move.freezed.dart';
part 'pokemon_move.g.dart';

/// Catégorie de move utilisée par la donnée projet.
///
/// On garde ici une projection petite et stable :
/// - directement sérialisable ;
/// - alignée avec la distinction battle la plus fondamentale ;
/// - indépendante de la future implémentation du moteur.
enum PokemonMoveCategory {
  @JsonValue('physical')
  physical,
  @JsonValue('special')
  special,
  @JsonValue('status')
  status,
}

/// Target canonique du move projet.
///
/// On reprend le vocabulaire structurel de Showdown parce qu'il est déjà
/// présent dans les données source et qu'il sera relu plus tard par le
/// convertisseur/runtime loader. Cela évite d'inventer une deuxième taxonomie.
enum PokemonMoveTarget {
  @JsonValue('adjacentAlly')
  adjacentAlly,
  @JsonValue('adjacentAllyOrSelf')
  adjacentAllyOrSelf,
  @JsonValue('adjacentFoe')
  adjacentFoe,
  @JsonValue('all')
  all,
  @JsonValue('allAdjacent')
  allAdjacent,
  @JsonValue('allAdjacentFoes')
  allAdjacentFoes,
  @JsonValue('allies')
  allies,
  @JsonValue('allySide')
  allySide,
  @JsonValue('allyTeam')
  allyTeam,
  @JsonValue('any')
  any,
  @JsonValue('foeSide')
  foeSide,
  @JsonValue('normal')
  normal,
  @JsonValue('randomNormal')
  randomNormal,
  @JsonValue('scripted')
  scripted,
  @JsonValue('self')
  self,
}

/// Flag métier de move.
///
/// Le modèle n'éparpille pas ces marqueurs en dizaines de booléens sur
/// `PokemonMove`. On les garde comme une collection d'identifiants typés,
/// ce qui donne une sérialisation propre et une extension future simple.
enum PokemonMoveFlag {
  @JsonValue('allyanim')
  allyAnim,
  @JsonValue('bypasssub')
  bypassSubstitute,
  @JsonValue('bite')
  bite,
  @JsonValue('bullet')
  bullet,
  @JsonValue('cantusetwice')
  cantUseTwice,
  @JsonValue('charge')
  charge,
  @JsonValue('contact')
  contact,
  @JsonValue('dance')
  dance,
  @JsonValue('defrost')
  defrost,
  @JsonValue('distance')
  distance,
  @JsonValue('failcopycat')
  failCopycat,
  @JsonValue('failencore')
  failEncore,
  @JsonValue('failinstruct')
  failInstruct,
  @JsonValue('failmefirst')
  failMeFirst,
  @JsonValue('failmimic')
  failMimic,
  @JsonValue('futuremove')
  futureMove,
  @JsonValue('gravity')
  gravity,
  @JsonValue('heal')
  heal,
  @JsonValue('metronome')
  metronome,
  @JsonValue('minimize')
  minimize,
  @JsonValue('mirror')
  mirror,
  @JsonValue('mustpressure')
  mustPressure,
  @JsonValue('noassist')
  noAssist,
  @JsonValue('nonsky')
  nonSky,
  @JsonValue('noparentalbond')
  noParentalBond,
  @JsonValue('nosketch')
  noSketch,
  @JsonValue('nosleeptalk')
  noSleepTalk,
  @JsonValue('pledgecombo')
  pledgeCombo,
  @JsonValue('powder')
  powder,
  @JsonValue('protect')
  protect,
  @JsonValue('pulse')
  pulse,
  @JsonValue('punch')
  punch,
  @JsonValue('recharge')
  recharge,
  @JsonValue('reflectable')
  reflectable,
  @JsonValue('slicing')
  slicing,
  @JsonValue('snatch')
  snatch,
  @JsonValue('sound')
  sound,
  @JsonValue('wind')
  wind,
}

/// Niveau de support structurel connu pour le moteur.
///
/// Ce champ sert à être honnête :
/// - un move peut être catalogué sans être prêt pour le moteur ;
/// - un move peut être partiellement structuré ;
/// - un move peut être entièrement structuré du point de vue du modèle,
///   sans pour autant signifier que tout est déjà branché côté `map_battle`.
enum PokemonMoveEngineSupportLevel {
  @JsonValue('catalog_only')
  catalogOnly,
  @JsonValue('structured_partial')
  structuredPartial,
  @JsonValue('structured_supported')
  structuredSupported,
}

/// Traçabilité minimale vers la source Showdown.
///
/// On garde cette structure locale au modèle de données :
/// - elle ne transporte pas de callbacks ;
/// - elle documente uniquement l'origine et les hooks détectés ;
/// - elle aidera plus tard le convertisseur enrichi, la validation et le debug.
@freezed
class PokemonMoveSourceRefs with _$PokemonMoveSourceRefs {
  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveSourceRefs({
    String? showdownMoveId,
    @Default(<String>[]) List<String> showdownHooksPresent,
  }) = _PokemonMoveSourceRefs;

  factory PokemonMoveSourceRefs.fromJson(Map<String, dynamic> json) =>
      _$PokemonMoveSourceRefsFromJson(json);
}

/// Modèle canonique spécialisé d'un move Pokémon.
///
/// Invariants de M2 :
/// - c'est la structure de vérité sérialisable côté `map_core` ;
/// - elle sert plus tard à l'éditeur, au runtime et au pont battle ;
/// - elle ne contient ni code Showdown ni logique d'exécution ;
/// - les comportements de résolution sont décrits dans `effects`.
@freezed
class PokemonMove with _$PokemonMove {
  @JsonSerializable(explicitToJson: true)
  const factory PokemonMove({
    required String id,
    required String name,
    @Default(<String, String>{}) Map<String, String> names,
    int? generation,

    /// `showdown`, `seed`, `project_custom`, etc.
    @Default('') String source,
    required String type,
    required PokemonMoveCategory category,
    @Default(PokemonMoveTarget.normal) PokemonMoveTarget target,
    @Default(0) int basePower,
    required PokemonMoveAccuracy accuracy,
    @Default(0) int pp,
    @Default(false) bool noPpBoosts,
    @Default(0) int priority,
    @Default(1) int critRatio,

    /// Sémantiquement un ensemble, stocké comme liste sérialisable stable.
    @Default(<PokemonMoveFlag>[]) List<PokemonMoveFlag> flags,

    /// Tous les comportements applicatifs vivent ici.
    @Default(<PokemonMoveEffect>[]) List<PokemonMoveEffect> effects,
    @Default('') String shortDescription,
    @Default('') String description,
    @Default(PokemonMoveEngineSupportLevel.catalogOnly)
    PokemonMoveEngineSupportLevel engineSupportLevel,
    @Default(<String>[]) List<String> unsupportedReasons,
    @Default(PokemonMoveSourceRefs()) PokemonMoveSourceRefs sourceRefs,
  }) = _PokemonMove;

  factory PokemonMove.fromJson(Map<String, dynamic> json) =>
      _$PokemonMoveFromJson(json);
}
