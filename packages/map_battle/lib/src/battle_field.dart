import 'battle_topology.dart';

/// Identifiant de météo réellement supporté par le moteur battle BE9.
///
/// Ce type reste volontairement étroit :
/// - `rain` pour la météo posée par l'équivalent de Rain Dance ;
/// - `sandstorm` pour le résiduel simple de tempête de sable ;
/// - aucun autre weather tant qu'il ne produit pas un vrai comportement
///   moteur local, testé et observable.
enum BattleWeatherId {
  rain,
  sandstorm,
}

/// Identifiant de pseudoWeather réellement supporté par le moteur battle BE9.
///
/// On n'ouvre pas ici une taxonomie générique de rooms / field effects :
/// - seul `trickRoom` est réellement consommé ;
/// - il agit uniquement sur l'ordre d'action à priorité égale ;
/// - aucun terrain, aucun side/slot state, aucun doubles.
enum BattlePseudoWeatherId {
  trickRoom,
}

/// État d'une météo active dans le combat.
///
/// Le contrat porte seulement :
/// - quel weather est actif ;
/// - combien de fins de tour il lui reste à survivre.
///
/// BE9 choisit une durée explicite plutôt qu'une magie implicite :
/// - le compteur est décrémenté à la fin de chaque tour ;
/// - une météo posée pendant un tour compte déjà ce tour dans sa durée ;
/// - cela garde une lecture locale simple et testable.
final class BattleWeatherState {
  const BattleWeatherState({
    required this.id,
    required this.remainingTurns,
  }) : assert(
          remainingTurns >= 1,
          'BattleWeatherState remainingTurns must be >= 1.',
        );

  final BattleWeatherId id;
  final int remainingTurns;

  BattleWeatherState decrement() {
    if (remainingTurns <= 1) {
      throw StateError(
        'BattleWeatherState cannot be decremented below 1 remaining turn.',
      );
    }
    return BattleWeatherState(
      id: id,
      remainingTurns: remainingTurns - 1,
    );
  }
}

/// État d'un pseudoWeather actif dans le combat.
///
/// Même règle que pour la météo :
/// - un seul pseudoWeather BE9 est réellement porté ;
/// - il a une durée explicite ;
/// - aucune pile générique de conditions de champ n'est ouverte.
final class BattlePseudoWeatherState {
  const BattlePseudoWeatherState({
    required this.id,
    required this.remainingTurns,
  }) : assert(
          remainingTurns >= 1,
          'BattlePseudoWeatherState remainingTurns must be >= 1.',
        );

  final BattlePseudoWeatherId id;
  final int remainingTurns;

  BattlePseudoWeatherState decrement() {
    if (remainingTurns <= 1) {
      throw StateError(
        'BattlePseudoWeatherState cannot be decremented below 1 remaining turn.',
      );
    }
    return BattlePseudoWeatherState(
      id: id,
      remainingTurns: remainingTurns - 1,
    );
  }
}

/// État de champ observable par le moteur battle.
///
/// BE9 ajoute ce contrat explicitement dans l'état battle pour deux raisons :
/// - la météo / Trick Room cessent d'être des détails cachés de résolution ;
/// - le runtime et les tests peuvent observer honnêtement ce qui est actif.
///
/// Frontière volontaire :
/// - une météo active maximum ;
/// - un pseudoWeather actif maximum ;
/// - aucun side state, aucun slot state, aucune structure vide "pour plus tard".
final class BattleFieldState {
  const BattleFieldState({
    this.weather,
    this.pseudoWeather,
  });

  final BattleWeatherState? weather;
  final BattlePseudoWeatherState? pseudoWeather;

  bool get hasAny => weather != null || pseudoWeather != null;

  bool isWeatherActive(BattleWeatherId id) => weather?.id == id;

  bool isPseudoWeatherActive(BattlePseudoWeatherId id) =>
      pseudoWeather?.id == id;

  BattleFieldState withWeather(BattleWeatherState? value) {
    if (weather == value) {
      return this;
    }
    return BattleFieldState(
      weather: value,
      pseudoWeather: pseudoWeather,
    );
  }

  BattleFieldState withPseudoWeather(BattlePseudoWeatherState? value) {
    if (pseudoWeather == value) {
      return this;
    }
    return BattleFieldState(
      weather: weather,
      pseudoWeather: value,
    );
  }
}

/// Taxonomie minimale des événements de champ visibles pendant un tour.
///
/// BE9 évite volontairement deux dérives :
/// - gonfler `BattleMoveExecution` avec des booléens de météo/room ;
/// - créer un event bus générique pour tout le moteur.
///
/// Une petite liste sœur dédiée suffit pour garder le champ observable.
enum BattleFieldEventKind {
  weatherSet,
  weatherResidualDamage,
  weatherExpired,
  pseudoWeatherSet,
  pseudoWeatherCleared,
  pseudoWeatherExpired,
}

/// Trace minimale d'un événement de champ pendant un tour.
///
/// Le payload reste borné aux besoins réels de BE9 :
/// - quel champ a été posé / retiré / expiré ;
/// - quel combattant subit un résiduel météo ;
/// - quel move l'a éventuellement déclenché.
final class BattleFieldEvent {
  const BattleFieldEvent.weatherSet({
    required this.weather,
    required this.sourceMoveId,
  })  : kind = BattleFieldEventKind.weatherSet,
        pseudoWeather = null,
        targetSlot = null,
        damage = null;

  const BattleFieldEvent.weatherResidualDamage({
    required this.weather,
    required this.targetSlot,
    required this.damage,
  })  : kind = BattleFieldEventKind.weatherResidualDamage,
        pseudoWeather = null,
        sourceMoveId = null;

  const BattleFieldEvent.weatherExpired({
    required this.weather,
  })  : kind = BattleFieldEventKind.weatherExpired,
        pseudoWeather = null,
        sourceMoveId = null,
        targetSlot = null,
        damage = null;

  const BattleFieldEvent.pseudoWeatherSet({
    required this.pseudoWeather,
    required this.sourceMoveId,
  })  : kind = BattleFieldEventKind.pseudoWeatherSet,
        weather = null,
        targetSlot = null,
        damage = null;

  const BattleFieldEvent.pseudoWeatherCleared({
    required this.pseudoWeather,
    required this.sourceMoveId,
  })  : kind = BattleFieldEventKind.pseudoWeatherCleared,
        weather = null,
        targetSlot = null,
        damage = null;

  const BattleFieldEvent.pseudoWeatherExpired({
    required this.pseudoWeather,
  })  : kind = BattleFieldEventKind.pseudoWeatherExpired,
        weather = null,
        sourceMoveId = null,
        targetSlot = null,
        damage = null;

  final BattleFieldEventKind kind;
  final BattleWeatherId? weather;
  final BattlePseudoWeatherId? pseudoWeather;
  final String? sourceMoveId;

  /// Slot explicitement affecté quand l'événement de champ touche un combattant.
  ///
  /// Phase G évite ici un faux contrat générique :
  /// - aujourd'hui seul le résiduel météo cible un combattant ;
  /// - les autres événements de champ restent globaux et gardent `null`.
  final BattleSlotRef? targetSlot;

  BattleSideId? get targetSide => targetSlot?.side;

  /// Compatibilité locale pour les surfaces encore stringly-typed.
  String? get target => targetSide?.actorId;

  final int? damage;
}
