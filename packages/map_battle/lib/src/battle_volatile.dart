/// Identifiant minimal de volatile réellement supporté par BE8.
///
/// On n'ouvre volontairement pas une taxonomie générique de volatiles :
/// - BE8 n'a besoin que de `protect` ;
/// - le reste (`confusion`, `substitute`, semi-invulnérabilité, etc.) reste
///   explicitement hors scope ;
/// - ce type documente donc un sous-ensemble battle local, pas un futur
///   catalogue complet de mécaniques.
enum BattleVolatileStatusId {
  protect,
}

/// Petit payload battle pour un move à charge sur deux tours.
///
/// BE8 choisit un contrat volontairement minimal :
/// - `chargeStateId` reste optionnel, uniquement pour garder une trace lisible
///   quand la donnée canonique en fournit une ;
/// - aucun système générique de "phases de move" n'est ouvert ;
/// - ce payload n'a de sens que pour `chargeThenStrike`.
final class BattleChargeThenStrikeEffect {
  const BattleChargeThenStrikeEffect({
    this.chargeStateId,
  });

  final String? chargeStateId;
}

/// État local du move actuellement chargé sur le combattant.
///
/// On porte exactement ce que le moteur doit retrouver au tour suivant :
/// - quel slot move doit être rejoué ;
/// - quel move est attendu, pour protéger le moteur d'un état incohérent ;
/// - un éventuel `chargeStateId` lisible pour la trace.
final class BattlePendingChargeState {
  const BattlePendingChargeState({
    required this.moveIndex,
    required this.moveId,
    this.chargeStateId,
  });

  final int moveIndex;
  final String moveId;
  final String? chargeStateId;
}

/// Sous-état volatile battle local du combattant.
///
/// Invariants BE8 :
/// - `protectActive` ne vaut que pour le tour courant et doit être nettoyé en
///   fin de tour ;
/// - `mustRecharge` représente uniquement le tour perdu qui suit certains
///   moves ; il ne doit pas coexister avec un move chargé en attente ;
/// - `pendingCharge` représente uniquement la deuxième moitié d'un move à
///   charge, sans ouvrir une pile de verrous/actions forcées.
final class BattleVolatileState {
  const BattleVolatileState({
    this.protectActive = false,
    this.mustRecharge = false,
    this.pendingCharge,
  }) : assert(
          !(mustRecharge && pendingCharge != null),
          'A battle combatant cannot be both recharging and holding a pending charged move.',
        );

  final bool protectActive;
  final bool mustRecharge;
  final BattlePendingChargeState? pendingCharge;

  bool get hasAny => protectActive || mustRecharge || pendingCharge != null;

  BattleVolatileState withProtectActive(bool value) {
    if (protectActive == value) {
      return this;
    }
    return BattleVolatileState(
      protectActive: value,
      mustRecharge: mustRecharge,
      pendingCharge: pendingCharge,
    );
  }

  BattleVolatileState withMustRecharge(bool value) {
    if (mustRecharge == value) {
      return this;
    }
    return BattleVolatileState(
      protectActive: protectActive,
      mustRecharge: value,
      pendingCharge: pendingCharge,
    );
  }

  BattleVolatileState withPendingCharge(BattlePendingChargeState? value) {
    if (pendingCharge == value) {
      return this;
    }
    return BattleVolatileState(
      protectActive: protectActive,
      mustRecharge: mustRecharge,
      pendingCharge: value,
    );
  }

  /// Nettoie les marqueurs qui ne doivent jamais survivre au tour suivant.
  ///
  /// BE8 garde cette règle explicite au niveau du petit contrat local :
  /// - `protect` protège uniquement pendant la fenêtre de résolution du tour ;
  /// - ni les résiduels BE7 ni le tour suivant ne doivent encore le voir actif ;
  /// - `mustRecharge` et `pendingCharge`, eux, vivent au-delà du tour et ne
  ///   doivent donc pas être effacés ici.
  BattleVolatileState clearedEndOfTurnFlags() {
    if (!protectActive) {
      return this;
    }
    return BattleVolatileState(
      protectActive: false,
      mustRecharge: mustRecharge,
      pendingCharge: pendingCharge,
    );
  }
}

/// Taxonomie minimale des événements volatiles visibles dans un tour.
///
/// BE8 n'étend pas `statusEvents` pour tout mélanger :
/// - les statuts majeurs et les volatiles n'ont pas la même temporalité ;
/// - `protect`, `mustRecharge` et `chargeThenStrike` ont besoin d'une trace
///   propre sans grossir `BattleMoveExecution` jusqu'à l'illisible ;
/// - on garde donc une petite liste sœur, bornée au lot BE8.
enum BattleVolatileEventKind {
  protectActivated,
  protectBlocked,
  protectBroken,
  rechargeRequired,
  rechargeTurnSpent,
  chargeStarted,
  chargeReleased,
}

/// Trace minimale d'un événement volatile pendant un tour.
///
/// Le contrat reste volontairement petit :
/// - pas de bus d'événements ;
/// - pas de payload dynamique ;
/// - juste les champs nécessaires pour expliquer ce qu'un tour BE8 a vraiment
///   fait ou empêché.
final class BattleVolatileEvent {
  const BattleVolatileEvent.protectActivated({
    required this.actor,
    required this.sourceMoveId,
  })  : kind = BattleVolatileEventKind.protectActivated,
        target = null,
        chargeStateId = null;

  const BattleVolatileEvent.protectBlocked({
    required this.actor,
    required this.target,
    required this.sourceMoveId,
  })  : kind = BattleVolatileEventKind.protectBlocked,
        chargeStateId = null;

  const BattleVolatileEvent.protectBroken({
    required this.actor,
    required this.target,
    required this.sourceMoveId,
  })  : kind = BattleVolatileEventKind.protectBroken,
        chargeStateId = null;

  const BattleVolatileEvent.rechargeRequired({
    required this.actor,
    required this.sourceMoveId,
  })  : kind = BattleVolatileEventKind.rechargeRequired,
        target = null,
        chargeStateId = null;

  const BattleVolatileEvent.rechargeTurnSpent({
    required this.actor,
  })  : kind = BattleVolatileEventKind.rechargeTurnSpent,
        target = null,
        sourceMoveId = null,
        chargeStateId = null;

  const BattleVolatileEvent.chargeStarted({
    required this.actor,
    required this.sourceMoveId,
    this.chargeStateId,
  })  : kind = BattleVolatileEventKind.chargeStarted,
        target = null;

  const BattleVolatileEvent.chargeReleased({
    required this.actor,
    required this.sourceMoveId,
    this.chargeStateId,
  })  : kind = BattleVolatileEventKind.chargeReleased,
        target = null;

  /// Combattant qui a provoqué l'événement (`player` ou `enemy`).
  final String actor;

  /// Cible explicite quand l'événement a une cible distincte.
  final String? target;

  final BattleVolatileEventKind kind;
  final String? sourceMoveId;
  final String? chargeStateId;
}
