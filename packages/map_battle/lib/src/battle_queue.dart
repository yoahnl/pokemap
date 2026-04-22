import 'dart:collection';

import 'battle_action.dart';
import 'battle_topology.dart';

/// Queue locale des étapes d'un tour singles.
///
/// Frontière Phase F volontairement stricte :
/// - cette queue ne devient pas un contrat public du runtime ;
/// - elle ne remplace ni `BattleTurnResult.timeline`, ni `BattleDecisionRequest` ;
/// - elle ne sait gérer que les grandes étapes réellement supportées aujourd'hui ;
/// - elle n'ouvre ni targeting riche, ni callbacks génériques, ni hooks.
///
/// Son rôle est uniquement de devenir la vraie source de vérité du scheduling
/// interne du tour :
/// - des actions déjà légales (`Fight`, `Switch`, `Recharge`, `Potion`,
///   `Super Potion`) ;
/// - de la fin de tour ;
/// - des checks post-résolution ;
/// - des remplacements déjà honnêtement supportés.
final class BattleTurnQueue {
  BattleTurnQueue(Iterable<BattleQueueStep> initialSteps)
      : _steps = ListQueue<BattleQueueStep>.of(initialSteps);

  final ListQueue<BattleQueueStep> _steps;

  bool get isEmpty => _steps.isEmpty;

  int get length => _steps.length;

  BattleQueueStep takeNext() {
    if (_steps.isEmpty) {
      throw StateError('BattleTurnQueue est vide.');
    }
    return _steps.removeFirst();
  }

  void pushBack(BattleQueueStep step) {
    _steps.addLast(step);
  }

  void pushBackAll(Iterable<BattleQueueStep> steps) {
    _steps.addAll(steps);
  }

  /// Retire et retourne les étapes encore en attente.
  ///
  /// H1/H2 entry hazards en ont besoin pour un cas très précis :
  /// - un switch volontaire peut faire entrer un Pokémon qui meurt aussitôt sur
  ///   un hazard d'entrée déjà supporté ;
  /// - le moteur doit alors suspendre honnêtement le tour, demander un vrai
  ///   remplacement joueur, puis reprendre les étapes restantes ;
  /// - on expose donc un drainage explicite de la queue au lieu d'introduire
  ///   un scheduler caché ou un deuxième conteneur parallèle.
  List<BattleQueueStep> drainRemainingSteps() {
    final remaining = List<BattleQueueStep>.of(_steps);
    _steps.clear();
    return remaining;
  }
}

/// Taxonomie volontairement petite des étapes que la queue peut transporter.
///
/// On choisit ici les vraies familles utiles au scheduling actuel, rien de plus.
enum BattleQueueStepKind {
  action,
  endOfTurn,
  postTurnChecks,
  autoSwitch,
  replacementRequired,
}

sealed class BattleQueueStep {
  const BattleQueueStep();

  BattleQueueStepKind get kind;
}

/// Retourne `true` seulement pour les actions réellement gérées par la queue.
///
/// Important :
/// - `Run` / `Capture` vivent encore hors queue car ils terminent
///   immédiatement le combat hors résolution normale ;
/// - `BattleActionNone` reste un marqueur d'étape inter-tour locale et ne doit
///   pas être déguisé en action de queue ;
/// - Phase F refuse donc de transformer toute `BattleAction` existante en
///   pseudo commande universelle.
bool isBattleQueueManagedAction(BattleAction action) {
  return action is BattleActionFight ||
      action is BattleActionBagHpHealItemUse ||
      action is BattleActionRecharge ||
      action is BattleActionSwitch;
}

/// Étape de queue qui résout une action réellement jouée pendant le tour.
final class BattleQueueActionStep extends BattleQueueStep {
  factory BattleQueueActionStep({
    required BattleSideId side,
    required BattleSlotRef slot,
    required BattleAction action,
    bool wasForced = false,
  }) {
    _validateSlotAttachment(
      expectedSide: side,
      slot: slot,
      stepLabel: 'BattleQueueActionStep',
    );
    if (!isBattleQueueManagedAction(action)) {
      throw ArgumentError.value(
        action,
        'action',
        'BattleQueueActionStep n’accepte que Fight/HP-heal-item/Switch/Recharge.',
      );
    }
    return BattleQueueActionStep._(
      side: side,
      slot: slot,
      action: action,
      wasForced: wasForced,
    );
  }

  const BattleQueueActionStep._({
    required this.side,
    required this.slot,
    required this.action,
    required this.wasForced,
  });

  final BattleSideId side;
  final BattleSlotRef slot;
  final BattleAction action;

  /// Distingue le switch volontaire de l'étape de remplacement forcé joueur.
  ///
  /// Phase F garde ce flag localement borné :
  /// - il ne s'applique utilement qu'aux `BattleActionSwitch` ;
  /// - il évite de recréer une seconde taxonomie de step juste pour préserver
  ///   la vérité d'un flow déjà supporté ;
  /// - il n'ouvre aucun targeting ni scheduler plus riche.
  final bool wasForced;

  @override
  BattleQueueStepKind get kind => BattleQueueStepKind.action;
}

/// Étape explicite de fin de tour.
///
/// On la garde sans payload :
/// - la fin de tour actuelle s'applique encore au combat entier ;
/// - la vraie causalité vit dans l'engine de conditions et dans l'état courant ;
/// - ajouter ici des champs décoratifs ne ferait que gonfler l'API.
final class BattleQueueEndOfTurnStep extends BattleQueueStep {
  const BattleQueueEndOfTurnStep();

  @override
  BattleQueueStepKind get kind => BattleQueueStepKind.endOfTurn;
}

/// Étape qui inspecte l'état après la fin de tour et insère les suites utiles.
///
/// Elle existe pour rendre explicite le moment où le moteur décide :
/// - un auto-remplacement ennemi ;
/// - un remplacement requis côté joueur ;
/// - ou rien.
final class BattleQueuePostTurnChecksStep extends BattleQueueStep {
  const BattleQueuePostTurnChecksStep();

  @override
  BattleQueueStepKind get kind => BattleQueueStepKind.postTurnChecks;
}

/// Étape de switch automatique déjà réellement supportée.
final class BattleQueueAutoSwitchStep extends BattleQueueStep {
  factory BattleQueueAutoSwitchStep({
    required BattleSideId side,
    required BattleSlotRef slot,
    required int reserveIndex,
  }) {
    _validateSlotAttachment(
      expectedSide: side,
      slot: slot,
      stepLabel: 'BattleQueueAutoSwitchStep',
    );
    return BattleQueueAutoSwitchStep._(
      side: side,
      slot: slot,
      reserveIndex: reserveIndex,
    );
  }

  const BattleQueueAutoSwitchStep._({
    required this.side,
    required this.slot,
    required this.reserveIndex,
  });

  final BattleSideId side;
  final BattleSlotRef slot;
  final int reserveIndex;

  @override
  BattleQueueStepKind get kind => BattleQueueStepKind.autoSwitch;
}

/// Étape explicite disant qu'un remplacement joueur est requis avant le tour
/// suivant.
///
/// Cette étape n'effectue pas le switch elle-même :
/// - le moteur singles actuel laisse encore ce remplacement au prochain
///   `decisionRequest` joueur ;
/// - Phase F rend simplement ce moment explicite dans le scheduling.
final class BattleQueueReplacementRequiredStep extends BattleQueueStep {
  factory BattleQueueReplacementRequiredStep({
    required BattleSideId side,
    required BattleSlotRef slot,
    required String faintedSpeciesId,
  }) {
    _validateSlotAttachment(
      expectedSide: side,
      slot: slot,
      stepLabel: 'BattleQueueReplacementRequiredStep',
    );
    return BattleQueueReplacementRequiredStep._(
      side: side,
      slot: slot,
      faintedSpeciesId: faintedSpeciesId,
    );
  }

  const BattleQueueReplacementRequiredStep._({
    required this.side,
    required this.slot,
    required this.faintedSpeciesId,
  });

  final BattleSideId side;
  final BattleSlotRef slot;
  final String faintedSpeciesId;

  @override
  BattleQueueStepKind get kind => BattleQueueStepKind.replacementRequired;
}

void _validateSlotAttachment({
  required BattleSideId expectedSide,
  required BattleSlotRef slot,
  required String stepLabel,
}) {
  if (slot.side != expectedSide) {
    throw ArgumentError(
      '$stepLabel attend un slot rattaché au side ${expectedSide.name}, '
      'mais a reçu ${slot.side.name}.',
    );
  }
}
