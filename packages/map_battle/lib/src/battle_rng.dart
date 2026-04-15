/// Seam RNG battle minimal introduit par BE4.
///
/// But strict :
/// - rendre le hit pipeline testable ;
/// - éviter un `Random()` caché au milieu du moteur ;
/// - garder un contrat assez petit pour ne pas ouvrir un système générique
///   d'événements aléatoires.
///
/// Frontière volontaire :
/// - pour l'instant, le moteur ne sait tirer qu'un roll de précision `1..100` ;
/// - pas de PRNG global ;
/// - pas de singleton ;
/// - pas de notion d'event random autre que le hit check.
abstract class BattleRng {
  const BattleRng();

  /// Tire un pourcentage entier dans l'intervalle fermé `[1, 100]`.
  ///
  /// Le contrat retourne aussi l'instance RNG suivante pour préserver le style
  /// immutable du moteur : une session de combat produit une nouvelle session,
  /// avec un nouvel état RNG si un tirage a eu lieu.
  BattleRngRoll nextPercentRoll();
}

/// Résultat d'un tirage RNG battle.
class BattleRngRoll {
  const BattleRngRoll({
    required this.value,
    required this.next,
  }) : assert(value >= 1 && value <= 100);

  /// Valeur tirée, toujours entre 1 et 100 inclus.
  final int value;

  /// État RNG suivant à réinjecter dans la session.
  final BattleRng next;
}

/// RNG par défaut du moteur battle.
///
/// On choisit un petit générateur déterministe local plutôt que `Random()` :
/// - cela garde le moteur pur et reproductible ;
/// - cela évite une dépendance implicite à un état global ;
/// - cela suffit largement pour le hit pipeline minimal de BE4.
class BattleSeededRng extends BattleRng {
  const BattleSeededRng({
    this.state = 0x00C0FFEE,
  });

  final int state;

  @override
  BattleRngRoll nextPercentRoll() {
    // LCG volontairement simple :
    // - assez bon pour un MVP déterministe ;
    // - très facile à rejouer ;
    // - pas présenté comme un futur PRNG universel du moteur.
    final nextState = (1664525 * state + 1013904223) & 0xFFFFFFFF;
    final value = (nextState % 100) + 1;
    return BattleRngRoll(
      value: value,
      next: BattleSeededRng(state: nextState),
    );
  }
}

/// RNG scripté pour les tests ciblés.
///
/// Ce type permet d'écrire des preuves fortes du genre :
/// - ce move touche ;
/// - ce move miss ;
/// - l'état RNG avance bien d'un tirage à chaque tentative.
///
/// Si la séquence est épuisée, on préfère échouer explicitement plutôt que de
/// repartir silencieusement sur un fallback arbitraire.
class BattleScriptedRng extends BattleRng {
  const BattleScriptedRng(
    this.rolls, {
    this.index = 0,
  });

  final List<int> rolls;
  final int index;

  @override
  BattleRngRoll nextPercentRoll() {
    if (index >= rolls.length) {
      throw StateError(
        'BattleScriptedRng exhausted while a battle hit check still needed randomness.',
      );
    }
    final value = rolls[index];
    if (value < 1 || value > 100) {
      throw StateError(
        'BattleScriptedRng only accepts rolls between 1 and 100; got $value.',
      );
    }
    return BattleRngRoll(
      value: value,
      next: BattleScriptedRng(
        rolls,
        index: index + 1,
      ),
    );
  }
}
