import 'battle_field.dart';
import 'battle_move.dart';
import 'battle_rng.dart';
import 'battle_state.dart';
import 'battle_status.dart';
import 'battle_volatile.dart';

const Set<String> _sandstormResidualImmuneTypes = <String>{
  'ground',
  'rock',
  'steel',
};

/// Mini event / condition engine réellement consommé par le moteur singles.
///
/// Frontière Phase E volontairement stricte :
/// - ce n'est pas un bus d'événements générique ;
/// - ce n'est pas une queue d'actions ;
/// - ce n'est pas un registry Showdown-like ;
/// - ce n'est pas une taxonomie universelle de callbacks.
///
/// Ce type sert uniquement à sortir de `battle_session.dart` les règles
/// conditionnelles déjà réellement supportées aujourd'hui :
/// - statuts majeurs (`par`, `brn`, `psn`, `tox`) ;
/// - volatiles BE8 (`protect`, recharge, charge then strike) ;
/// - field BE9 (`rain`, `sandstorm`, `trickRoom`).
///
/// Les event points exposés sont explicites et bornés :
/// - [runActionAttempt]
/// - [runHitInterception]
/// - [runMoveResolved]
/// - [runForcedContinueTurn]
/// - [runEndOfTurn]
///
/// `BattleSession` reste l'orchestrateur du tour. Cet engine ne pilote ni les
/// requests, ni les switches, ni l'outcome, ni l'ordre global des actions.
final class BattleConditionEngine {
  const BattleConditionEngine();

  static const _statusRules = _BattleStatusRules();
  static const _volatileRules = _BattleVolatileRules();
  static const _fieldRules = _BattleFieldRules();

  /// Résout les conditions qui s'appliquent à une tentative d'action.
  ///
  /// Ordre volontairement figé pour le sous-ensemble actuel :
  /// 1. consommation honnête des PP ou libération locale d'une charge pendante ;
  /// 2. gate de statut majeur (`par`) ;
  /// 3. éventuelle entrée en charge pour un move sur deux tours ;
  /// 4. émission des événements visibles associés.
  BattleActionAttemptResult runActionAttempt({
    required String attackerLabel,
    required BattleMove move,
    required int moveIndex,
    required BattleCombatant attacker,
    required BattleRng rng,
  }) {
    final preparation = _volatileRules.prepareActionAttempt(
      attackerLabel: attackerLabel,
      move: move,
      moveIndex: moveIndex,
      attacker: attacker,
    );
    final actionGate = _statusRules.runActionAttemptGate(
      combatantLabel: attackerLabel,
      combatant: preparation.attacker,
      rng: rng,
    );

    if (!actionGate.canAct) {
      return BattleActionAttemptResult(
        outcome: BattleActionAttemptOutcome.preventedAction,
        attacker: preparation.attacker,
        rng: actionGate.nextRng,
        statusEvents: actionGate.statusEvents,
        volatileEvents: const <BattleVolatileEvent>[],
      );
    }

    final continuation = _volatileRules.finalizeActionAttempt(
      attackerLabel: attackerLabel,
      move: move,
      moveIndex: moveIndex,
      preparedAttacker: preparation.attacker,
      preparedChargeRelease: preparation.preparedChargeRelease,
      canStartCharge: preparation.canStartCharge,
    );

    if (continuation.outcome == BattleActionAttemptOutcome.chargeStarted) {
      return BattleActionAttemptResult(
        outcome: BattleActionAttemptOutcome.chargeStarted,
        attacker: continuation.attacker,
        rng: actionGate.nextRng,
        statusEvents: const <BattleStatusEvent>[],
        volatileEvents: continuation.volatileEvents,
      );
    }

    return BattleActionAttemptResult(
      outcome: BattleActionAttemptOutcome.proceed,
      attacker: continuation.attacker,
      rng: actionGate.nextRng,
      statusEvents: const <BattleStatusEvent>[],
      volatileEvents: continuation.volatileEvents,
    );
  }

  /// Résout les interceptions volatiles après le hit check.
  ///
  /// Frontière actuelle :
  /// - `protect` / `breakProtect` seulement ;
  /// - aucune autre interception, semi-invulnérabilité ou callback générique.
  BattleHitInterceptionResult runHitInterception({
    required BattleMove move,
    required String attackerLabel,
    required String targetLabel,
    required BattleCombatant attacker,
    required BattleCombatant defender,
  }) {
    return _volatileRules.runHitInterception(
      move: move,
      attackerLabel: attackerLabel,
      targetLabel: targetLabel,
      attacker: attacker,
      defender: defender,
    );
  }

  /// Résout les conditions qui s'appliquent après la résolution principale.
  ///
  /// Aujourd'hui cela couvre exactement :
  /// - application de statut majeur par move ;
  /// - pose / retrait de weather ou pseudoWeather ;
  /// - pose d'une recharge obligatoire.
  BattleMoveResolvedConditionResult runMoveResolved({
    required BattleMove move,
    required String attackerLabel,
    required String targetLabel,
    required BattleCombatant attacker,
    required BattleCombatant defender,
    required BattleFieldState field,
    required bool wasImmune,
    required BattleRng rng,
  }) {
    final statusApplication = _statusRules.runMoveResolved(
      move: move,
      targetLabel: targetLabel,
      defender: defender,
      wasImmune: wasImmune,
      rng: rng,
    );
    final fieldApplication = _fieldRules.runMoveResolved(
      move: move,
      field: field,
    );
    final volatileFollowUp = _volatileRules.runMoveResolved(
      move: move,
      attackerLabel: attackerLabel,
      attacker: attacker,
      wasImmune: wasImmune,
    );

    return BattleMoveResolvedConditionResult(
      attacker: volatileFollowUp.attacker,
      defender: statusApplication.defender,
      field: fieldApplication.field,
      rng: statusApplication.nextRng,
      statusEvents: statusApplication.statusEvents,
      volatileEvents: volatileFollowUp.volatileEvents,
      fieldEvents: fieldApplication.fieldEvents,
    );
  }

  /// Résout un tour forcé de continuation.
  ///
  /// Phase E n'ouvre ici qu'un seul cas réellement vivant :
  /// - le tour perdu par recharge.
  BattleForcedContinueTurnResult runForcedContinueTurn({
    required String combatantLabel,
    required BattleCombatant combatant,
  }) {
    return _volatileRules.runForcedContinueTurn(
      combatantLabel: combatantLabel,
      combatant: combatant,
    );
  }

  /// Résout la phase de fin de tour des conditions déjà supportées.
  ///
  /// Ordre conservé explicitement :
  /// 1. résiduels de statuts majeurs ;
  /// 2. résiduels météo ;
  /// 3. progression / expiration du champ ;
  /// 4. nettoyage des flags volatiles transitoires de fin de tour.
  BattleEndOfTurnConditionResult runEndOfTurn({
    required BattleCombatant player,
    required BattleCombatant enemy,
    required BattleFieldState field,
  }) {
    final statusResiduals = _statusRules.runEndOfTurn(
      player: player,
      enemy: enemy,
    );
    final fieldResiduals = _fieldRules.runEndOfTurn(
      player: statusResiduals.player,
      enemy: statusResiduals.enemy,
      field: field,
    );

    return BattleEndOfTurnConditionResult(
      player: _volatileRules.clearEndOfTurnFlags(fieldResiduals.player),
      enemy: _volatileRules.clearEndOfTurnFlags(fieldResiduals.enemy),
      field: fieldResiduals.field,
      statusEvents: statusResiduals.statusEvents,
      fieldEvents: fieldResiduals.fieldEvents,
    );
  }

  /// Retourne `true` si le champ inverse l'ordre de vitesse.
  ///
  /// Ce seam reste volontairement minuscule :
  /// - il évite que `BattleSession` relise directement `trickRoom` ;
  /// - il n'ouvre pas un système générique de modificateurs d'initiative.
  bool doesFieldInvertSpeedOrder(BattleFieldState field) {
    return _fieldRules.doesFieldInvertSpeedOrder(field);
  }

  /// Retourne le multiplicateur météo local réellement supporté.
  ///
  /// Phase E l'extrait hors de `BattleSession` parce que c'est bien une règle
  /// de condition de champ, pas une partie de la formule de dégâts pure.
  double resolveFieldDamageMultiplier({
    required BattleMove move,
    required BattleFieldState field,
  }) {
    return _fieldRules.resolveFieldDamageMultiplier(
      move: move,
      field: field,
    );
  }

  /// Retourne le multiplicateur de dégâts induit par un statut majeur.
  ///
  /// Frontière volontairement bornée :
  /// - seule la brûlure sur moves physiques vit ici aujourd'hui ;
  /// - aucun autre modificateur offensif conditionnel n'est inventé ;
  /// - la formule complète de dégâts reste orchestrée par `BattleSession`.
  double resolveStatusDamageMultiplier({
    required BattleMove move,
    required BattleCombatant attacker,
  }) {
    return _statusRules.resolveDamageMultiplier(
      move: move,
      attacker: attacker,
    );
  }

  /// Applique le ralentissement de statut à une vitesse déjà stage-résolue.
  ///
  /// Cet engine ne remplace pas le calcul de stat de `BattleSession` :
  /// - la session garde le snapshot runtime + les stages ;
  /// - l'engine consomme seulement la partie réellement "condition" ;
  /// - aujourd'hui cela signifie le malus simple de paralysie.
  int resolveStatusAdjustedSpeed({
    required BattleCombatant combatant,
    required int stagedSpeed,
  }) {
    return _statusRules.resolveAdjustedSpeed(
      combatant: combatant,
      stagedSpeed: stagedSpeed,
    );
  }
}

enum BattleActionAttemptOutcome {
  proceed,
  preventedAction,
  chargeStarted,
}

final class BattleActionAttemptResult {
  const BattleActionAttemptResult({
    required this.outcome,
    required this.attacker,
    required this.rng,
    required this.statusEvents,
    required this.volatileEvents,
  });

  final BattleActionAttemptOutcome outcome;
  final BattleCombatant attacker;
  final BattleRng rng;
  final List<BattleStatusEvent> statusEvents;
  final List<BattleVolatileEvent> volatileEvents;
}

final class BattleHitInterceptionResult {
  const BattleHitInterceptionResult({
    required this.attacker,
    required this.defender,
    required this.blockedByProtect,
    required this.volatileEvents,
  });

  final BattleCombatant attacker;
  final BattleCombatant defender;
  final bool blockedByProtect;
  final List<BattleVolatileEvent> volatileEvents;
}

final class BattleMoveResolvedConditionResult {
  const BattleMoveResolvedConditionResult({
    required this.attacker,
    required this.defender,
    required this.field,
    required this.rng,
    required this.statusEvents,
    required this.volatileEvents,
    required this.fieldEvents,
  });

  final BattleCombatant attacker;
  final BattleCombatant defender;
  final BattleFieldState field;
  final BattleRng rng;
  final List<BattleStatusEvent> statusEvents;
  final List<BattleVolatileEvent> volatileEvents;
  final List<BattleFieldEvent> fieldEvents;
}

final class BattleForcedContinueTurnResult {
  const BattleForcedContinueTurnResult({
    required this.combatant,
    required this.volatileEvents,
  });

  final BattleCombatant combatant;
  final List<BattleVolatileEvent> volatileEvents;
}

final class BattleEndOfTurnConditionResult {
  const BattleEndOfTurnConditionResult({
    required this.player,
    required this.enemy,
    required this.field,
    required this.statusEvents,
    required this.fieldEvents,
  });

  final BattleCombatant player;
  final BattleCombatant enemy;
  final BattleFieldState field;
  final List<BattleStatusEvent> statusEvents;
  final List<BattleFieldEvent> fieldEvents;
}

final class _BattleStatusRules {
  const _BattleStatusRules();

  _StatusActionGateResult runActionAttemptGate({
    required String combatantLabel,
    required BattleCombatant combatant,
    required BattleRng rng,
  }) {
    final status = combatant.majorStatus;
    if (status?.id != BattleMajorStatusId.par) {
      return _StatusActionGateResult(
        canAct: true,
        nextRng: rng,
        statusEvents: const <BattleStatusEvent>[],
      );
    }

    final roll = rng.nextChance(
      numerator: 1,
      denominator: 4,
    );
    if (!roll.didOccur) {
      return _StatusActionGateResult(
        canAct: true,
        nextRng: roll.next,
        statusEvents: const <BattleStatusEvent>[],
      );
    }

    return _StatusActionGateResult(
      canAct: false,
      nextRng: roll.next,
      statusEvents: <BattleStatusEvent>[
        BattleStatusEvent.preventedAction(
          target: combatantLabel,
          status: BattleMajorStatusId.par,
        ),
      ],
    );
  }

  _StatusMoveResolvedResult runMoveResolved({
    required BattleMove move,
    required String targetLabel,
    required BattleCombatant defender,
    required bool wasImmune,
    required BattleRng rng,
  }) {
    final effect = move.majorStatusEffect;
    if (effect == null) {
      return _StatusMoveResolvedResult(
        defender: defender,
        nextRng: rng,
        statusEvents: const <BattleStatusEvent>[],
      );
    }

    if (wasImmune && move.resolvedCategory != BattleMoveCategory.status) {
      return _StatusMoveResolvedResult(
        defender: defender,
        nextRng: rng,
        statusEvents: const <BattleStatusEvent>[],
      );
    }

    if (defender.majorStatus != null) {
      return _StatusMoveResolvedResult(
        defender: defender,
        nextRng: rng,
        statusEvents: <BattleStatusEvent>[
          BattleStatusEvent.blockedExistingMajorStatus(
            target: targetLabel,
            status: effect.status,
            existingStatus: defender.majorStatus!.id,
            sourceMoveId: move.id,
          ),
        ],
      );
    }

    if (effect.chancePercent case final chance?) {
      final chanceRoll = rng.nextChance(
        numerator: chance,
        denominator: 100,
      );
      if (!chanceRoll.didOccur) {
        return _StatusMoveResolvedResult(
          defender: defender,
          nextRng: chanceRoll.next,
          statusEvents: const <BattleStatusEvent>[],
        );
      }

      return _StatusMoveResolvedResult(
        defender: defender.withMajorStatus(_majorStatusStateFor(effect.status)),
        nextRng: chanceRoll.next,
        statusEvents: <BattleStatusEvent>[
          BattleStatusEvent.applied(
            target: targetLabel,
            status: effect.status,
            sourceMoveId: move.id,
          ),
        ],
      );
    }

    return _StatusMoveResolvedResult(
      defender: defender.withMajorStatus(_majorStatusStateFor(effect.status)),
      nextRng: rng,
      statusEvents: <BattleStatusEvent>[
        BattleStatusEvent.applied(
          target: targetLabel,
          status: effect.status,
          sourceMoveId: move.id,
        ),
      ],
    );
  }

  _StatusEndOfTurnResult runEndOfTurn({
    required BattleCombatant player,
    required BattleCombatant enemy,
  }) {
    final playerResidual = !player.isFainted
        ? _applyResidualForCombatant(
            combatant: player,
            combatantLabel: 'player',
          )
        : _SingleStatusResidual(
            combatant: player,
            statusEvents: const <BattleStatusEvent>[],
          );
    final enemyResidual = !enemy.isFainted
        ? _applyResidualForCombatant(
            combatant: enemy,
            combatantLabel: 'enemy',
          )
        : _SingleStatusResidual(
            combatant: enemy,
            statusEvents: const <BattleStatusEvent>[],
          );

    return _StatusEndOfTurnResult(
      player: playerResidual.combatant,
      enemy: enemyResidual.combatant,
      statusEvents: <BattleStatusEvent>[
        ...playerResidual.statusEvents,
        ...enemyResidual.statusEvents,
      ],
    );
  }

  _SingleStatusResidual _applyResidualForCombatant({
    required BattleCombatant combatant,
    required String combatantLabel,
  }) {
    final status = combatant.majorStatus;
    if (status == null || combatant.isFainted) {
      return _SingleStatusResidual(
        combatant: combatant,
        statusEvents: const <BattleStatusEvent>[],
      );
    }

    final residualDamage = switch (status.id) {
      BattleMajorStatusId.par => 0,
      BattleMajorStatusId.brn => _fractionalResidual(
          maxHp: combatant.maxHp,
          numerator: 1,
          denominator: 16,
        ),
      BattleMajorStatusId.psn => _fractionalResidual(
          maxHp: combatant.maxHp,
          numerator: 1,
          denominator: 8,
        ),
      BattleMajorStatusId.tox => _fractionalResidual(
          maxHp: combatant.maxHp,
          numerator: status.toxicCounter,
          denominator: 16,
        ),
    };

    if (residualDamage <= 0) {
      return _SingleStatusResidual(
        combatant: combatant,
        statusEvents: const <BattleStatusEvent>[],
      );
    }

    final damagedCombatant = combatant.withDamage(residualDamage);
    final nextCombatant =
        status.id == BattleMajorStatusId.tox && !damagedCombatant.isFainted
            ? damagedCombatant.withMajorStatus(status.incrementToxicCounter())
            : damagedCombatant;

    return _SingleStatusResidual(
      combatant: nextCombatant,
      statusEvents: <BattleStatusEvent>[
        BattleStatusEvent.residualDamage(
          target: combatantLabel,
          status: status.id,
          damage: residualDamage,
          toxicCounter:
              status.id == BattleMajorStatusId.tox ? status.toxicCounter : null,
        ),
      ],
    );
  }

  BattleMajorStatusState _majorStatusStateFor(BattleMajorStatusId status) {
    return switch (status) {
      BattleMajorStatusId.par => const BattleMajorStatusState.par(),
      BattleMajorStatusId.brn => const BattleMajorStatusState.brn(),
      BattleMajorStatusId.psn => const BattleMajorStatusState.psn(),
      BattleMajorStatusId.tox => const BattleMajorStatusState.tox(),
    };
  }

  int _fractionalResidual({
    required int maxHp,
    required int numerator,
    required int denominator,
  }) {
    final raw = (maxHp * numerator) ~/ denominator;
    return raw < 1 ? 1 : raw;
  }

  double resolveDamageMultiplier({
    required BattleMove move,
    required BattleCombatant attacker,
  }) {
    if (attacker.majorStatus?.id != BattleMajorStatusId.brn ||
        move.resolvedCategory != BattleMoveCategory.physical) {
      return 1.0;
    }
    return 0.5;
  }

  int resolveAdjustedSpeed({
    required BattleCombatant combatant,
    required int stagedSpeed,
  }) {
    if (combatant.majorStatus?.id != BattleMajorStatusId.par) {
      return stagedSpeed;
    }

    final slowedSpeed = (stagedSpeed * 0.5).floor();
    return slowedSpeed < 1 ? 1 : slowedSpeed;
  }
}

final class _BattleVolatileRules {
  const _BattleVolatileRules();

  /// Prépare l'action volatile avant le gate de statut.
  ///
  /// Frontière importante :
  /// - on peut consommer les PP d'une tentative honnête même si `par` bloque ;
  /// - en revanche on ne doit pas armer une nouvelle charge tant que l'action
  ///   n'a pas réellement passé le gate de statut ;
  /// - cette nuance évite de créer un faux `pendingCharge` sur un tour où le
  ///   move n'a jamais vraiment commencé.
  _VolatileActionPreparation prepareActionAttempt({
    required String attackerLabel,
    required BattleMove move,
    required int moveIndex,
    required BattleCombatant attacker,
  }) {
    final pendingCharge = attacker.volatileState.pendingCharge;
    final isChargeRelease = pendingCharge != null &&
        pendingCharge.moveIndex == moveIndex &&
        pendingCharge.moveId == move.id;

    if (!isChargeRelease && !move.hasUsablePp) {
      throw StateError(
        'Le move "${move.name}" n’a plus de PP et ne peut pas être résolu honnêtement.',
      );
    }

    final attackerAfterChargeClear = isChargeRelease
        ? attacker.withVolatileState(
            attacker.volatileState.withPendingCharge(null),
          )
        : attacker;
    final attackerAfterPpUse = isChargeRelease
        ? attackerAfterChargeClear
        : attackerAfterChargeClear.withUpdatedMoveAt(
            moveIndex,
            move.withConsumedPp(),
          );

    return _VolatileActionPreparation(
      attacker: attackerAfterPpUse,
      preparedChargeRelease: isChargeRelease
          ? _PreparedChargeRelease(
              moveId: move.id,
              chargeStateId: pendingCharge.chargeStateId,
            )
          : null,
      canStartCharge:
          isChargeRelease ? null : move.chargeThenStrikeEffect?.chargeStateId,
    );
  }

  _VolatileActionContinuation finalizeActionAttempt({
    required String attackerLabel,
    required BattleMove move,
    required int moveIndex,
    required BattleCombatant preparedAttacker,
    required _PreparedChargeRelease? preparedChargeRelease,
    required String? canStartCharge,
  }) {
    if (canStartCharge case final chargeStateId?) {
      final chargingAttacker = preparedAttacker.withVolatileState(
        preparedAttacker.volatileState.withPendingCharge(
          BattlePendingChargeState(
            moveIndex: moveIndex,
            moveId: move.id,
            chargeStateId: chargeStateId,
          ),
        ),
      );

      return _VolatileActionContinuation(
        outcome: BattleActionAttemptOutcome.chargeStarted,
        attacker: chargingAttacker,
        volatileEvents: <BattleVolatileEvent>[
          BattleVolatileEvent.chargeStarted(
            actor: attackerLabel,
            sourceMoveId: move.id,
            chargeStateId: chargeStateId,
          ),
        ],
      );
    }

    return _VolatileActionContinuation(
      outcome: BattleActionAttemptOutcome.proceed,
      attacker: preparedAttacker,
      volatileEvents: <BattleVolatileEvent>[
        if (preparedChargeRelease case final release?)
          BattleVolatileEvent.chargeReleased(
            actor: attackerLabel,
            sourceMoveId: release.moveId,
            chargeStateId: release.chargeStateId,
          ),
      ],
    );
  }

  BattleHitInterceptionResult runHitInterception({
    required BattleMove move,
    required String attackerLabel,
    required String targetLabel,
    required BattleCombatant attacker,
    required BattleCombatant defender,
  }) {
    var updatedAttacker = attacker;
    var updatedDefender = defender;
    final volatileEvents = <BattleVolatileEvent>[];

    if (move.selfVolatileStatus == BattleVolatileStatusId.protect) {
      updatedAttacker = updatedAttacker.withVolatileState(
        updatedAttacker.volatileState.withProtectActive(true),
      );
      volatileEvents.add(
        BattleVolatileEvent.protectActivated(
          actor: attackerLabel,
          sourceMoveId: move.id,
        ),
      );
    }

    if (move.target != BattleMoveTarget.opponent ||
        !updatedDefender.volatileState.protectActive) {
      return BattleHitInterceptionResult(
        attacker: updatedAttacker,
        defender: updatedDefender,
        blockedByProtect: false,
        volatileEvents: volatileEvents,
      );
    }

    if (move.breaksProtect) {
      updatedDefender = updatedDefender.withVolatileState(
        updatedDefender.volatileState.withProtectActive(false),
      );
      volatileEvents.add(
        BattleVolatileEvent.protectBroken(
          actor: attackerLabel,
          target: targetLabel,
          sourceMoveId: move.id,
        ),
      );
      return BattleHitInterceptionResult(
        attacker: updatedAttacker,
        defender: updatedDefender,
        blockedByProtect: false,
        volatileEvents: volatileEvents,
      );
    }

    volatileEvents.add(
      BattleVolatileEvent.protectBlocked(
        actor: attackerLabel,
        target: targetLabel,
        sourceMoveId: move.id,
      ),
    );
    return BattleHitInterceptionResult(
      attacker: updatedAttacker,
      defender: updatedDefender,
      blockedByProtect: true,
      volatileEvents: volatileEvents,
    );
  }

  _VolatileMoveResolvedResult runMoveResolved({
    required BattleMove move,
    required String attackerLabel,
    required BattleCombatant attacker,
    required bool wasImmune,
  }) {
    if (!move.requiresRecharge ||
        move.resolvedCategory == BattleMoveCategory.status ||
        wasImmune) {
      return _VolatileMoveResolvedResult(
        attacker: attacker,
        volatileEvents: const <BattleVolatileEvent>[],
      );
    }

    return _VolatileMoveResolvedResult(
      attacker: attacker.withVolatileState(
        attacker.volatileState.withMustRecharge(true),
      ),
      volatileEvents: <BattleVolatileEvent>[
        BattleVolatileEvent.rechargeRequired(
          actor: attackerLabel,
          sourceMoveId: move.id,
        ),
      ],
    );
  }

  BattleForcedContinueTurnResult runForcedContinueTurn({
    required String combatantLabel,
    required BattleCombatant combatant,
  }) {
    if (!combatant.volatileState.mustRecharge) {
      return BattleForcedContinueTurnResult(
        combatant: combatant,
        volatileEvents: const <BattleVolatileEvent>[],
      );
    }

    return BattleForcedContinueTurnResult(
      combatant: combatant.withVolatileState(
        combatant.volatileState.withMustRecharge(false),
      ),
      volatileEvents: <BattleVolatileEvent>[
        BattleVolatileEvent.rechargeTurnSpent(
          actor: combatantLabel,
        ),
      ],
    );
  }

  BattleCombatant clearEndOfTurnFlags(BattleCombatant combatant) {
    final cleared = combatant.volatileState.clearedEndOfTurnFlags();
    if (identical(cleared, combatant.volatileState)) {
      return combatant;
    }
    return combatant.withVolatileState(cleared);
  }
}

final class _BattleFieldRules {
  const _BattleFieldRules();

  _FieldMoveResolvedResult runMoveResolved({
    required BattleMove move,
    required BattleFieldState field,
  }) {
    if (move.weatherEffect == null && move.pseudoWeatherEffect == null) {
      return _FieldMoveResolvedResult(
        field: field,
        fieldEvents: const <BattleFieldEvent>[],
      );
    }

    var updatedField = field;
    final fieldEvents = <BattleFieldEvent>[];

    if (move.weatherEffect case final weather?) {
      updatedField = updatedField.withWeather(
        BattleWeatherState(
          id: weather,
          remainingTurns: 5,
        ),
      );
      fieldEvents.add(
        BattleFieldEvent.weatherSet(
          weather: weather,
          sourceMoveId: move.id,
        ),
      );
    }

    if (move.pseudoWeatherEffect case final pseudoWeather?) {
      if (updatedField.pseudoWeather?.id == pseudoWeather) {
        updatedField = updatedField.withPseudoWeather(null);
        fieldEvents.add(
          BattleFieldEvent.pseudoWeatherCleared(
            pseudoWeather: pseudoWeather,
            sourceMoveId: move.id,
          ),
        );
      } else {
        updatedField = updatedField.withPseudoWeather(
          BattlePseudoWeatherState(
            id: pseudoWeather,
            remainingTurns: 5,
          ),
        );
        fieldEvents.add(
          BattleFieldEvent.pseudoWeatherSet(
            pseudoWeather: pseudoWeather,
            sourceMoveId: move.id,
          ),
        );
      }
    }

    return _FieldMoveResolvedResult(
      field: updatedField,
      fieldEvents: List<BattleFieldEvent>.unmodifiable(fieldEvents),
    );
  }

  _FieldEndOfTurnResult runEndOfTurn({
    required BattleCombatant player,
    required BattleCombatant enemy,
    required BattleFieldState field,
  }) {
    final weatherResiduals = _applyWeatherResiduals(
      player: player,
      enemy: enemy,
      field: field,
    );
    final fieldProgression = _advanceField(weatherResiduals.field);

    return _FieldEndOfTurnResult(
      player: weatherResiduals.player,
      enemy: weatherResiduals.enemy,
      field: fieldProgression.field,
      fieldEvents: <BattleFieldEvent>[
        ...weatherResiduals.fieldEvents,
        ...fieldProgression.fieldEvents,
      ],
    );
  }

  bool doesFieldInvertSpeedOrder(BattleFieldState field) {
    return field.isPseudoWeatherActive(BattlePseudoWeatherId.trickRoom);
  }

  double resolveFieldDamageMultiplier({
    required BattleMove move,
    required BattleFieldState field,
  }) {
    final weather = field.weather;
    if (weather == null || weather.id != BattleWeatherId.rain) {
      return 1.0;
    }

    return switch (move.type) {
      'water' => 1.5,
      'fire' => 0.5,
      _ => 1.0,
    };
  }

  _WeatherResidualResult _applyWeatherResiduals({
    required BattleCombatant player,
    required BattleCombatant enemy,
    required BattleFieldState field,
  }) {
    final weather = field.weather;
    if (weather == null || weather.id != BattleWeatherId.sandstorm) {
      return _WeatherResidualResult(
        player: player,
        enemy: enemy,
        field: field,
        fieldEvents: const <BattleFieldEvent>[],
      );
    }

    final playerResidual = _applySandstormResidual(
      combatant: player,
      combatantLabel: 'player',
    );
    final enemyResidual = _applySandstormResidual(
      combatant: enemy,
      combatantLabel: 'enemy',
    );

    return _WeatherResidualResult(
      player: playerResidual.combatant,
      enemy: enemyResidual.combatant,
      field: field,
      fieldEvents: <BattleFieldEvent>[
        ...playerResidual.fieldEvents,
        ...enemyResidual.fieldEvents,
      ],
    );
  }

  _SandstormResidualResult _applySandstormResidual({
    required BattleCombatant combatant,
    required String combatantLabel,
  }) {
    if (combatant.isFainted || _isImmuneToSandstormResidual(combatant)) {
      return _SandstormResidualResult(
        combatant: combatant,
        fieldEvents: const <BattleFieldEvent>[],
      );
    }

    final damage = _fractionalResidual(
      maxHp: combatant.maxHp,
      numerator: 1,
      denominator: 16,
    );

    return _SandstormResidualResult(
      combatant: combatant.withDamage(damage),
      fieldEvents: <BattleFieldEvent>[
        BattleFieldEvent.weatherResidualDamage(
          weather: BattleWeatherId.sandstorm,
          target: combatantLabel,
          damage: damage,
        ),
      ],
    );
  }

  bool _isImmuneToSandstormResidual(BattleCombatant combatant) {
    final typing = combatant.typing;
    if (typing == null) {
      return false;
    }
    return _sandstormResidualImmuneTypes.contains(typing.primaryType) ||
        (typing.secondaryType != null &&
            _sandstormResidualImmuneTypes.contains(typing.secondaryType));
  }

  _FieldProgressionResult _advanceField(BattleFieldState field) {
    var updatedField = field;
    final fieldEvents = <BattleFieldEvent>[];

    if (field.weather case final weather?) {
      if (weather.remainingTurns <= 1) {
        updatedField = updatedField.withWeather(null);
        fieldEvents.add(
          BattleFieldEvent.weatherExpired(
            weather: weather.id,
          ),
        );
      } else {
        updatedField = updatedField.withWeather(weather.decrement());
      }
    }

    if (field.pseudoWeather case final pseudoWeather?) {
      if (pseudoWeather.remainingTurns <= 1) {
        updatedField = updatedField.withPseudoWeather(null);
        fieldEvents.add(
          BattleFieldEvent.pseudoWeatherExpired(
            pseudoWeather: pseudoWeather.id,
          ),
        );
      } else {
        updatedField =
            updatedField.withPseudoWeather(pseudoWeather.decrement());
      }
    }

    return _FieldProgressionResult(
      field: updatedField,
      fieldEvents: List<BattleFieldEvent>.unmodifiable(fieldEvents),
    );
  }

  int _fractionalResidual({
    required int maxHp,
    required int numerator,
    required int denominator,
  }) {
    final raw = (maxHp * numerator) ~/ denominator;
    return raw < 1 ? 1 : raw;
  }
}

final class _StatusActionGateResult {
  const _StatusActionGateResult({
    required this.canAct,
    required this.nextRng,
    required this.statusEvents,
  });

  final bool canAct;
  final BattleRng nextRng;
  final List<BattleStatusEvent> statusEvents;
}

final class _StatusMoveResolvedResult {
  const _StatusMoveResolvedResult({
    required this.defender,
    required this.nextRng,
    required this.statusEvents,
  });

  final BattleCombatant defender;
  final BattleRng nextRng;
  final List<BattleStatusEvent> statusEvents;
}

final class _StatusEndOfTurnResult {
  const _StatusEndOfTurnResult({
    required this.player,
    required this.enemy,
    required this.statusEvents,
  });

  final BattleCombatant player;
  final BattleCombatant enemy;
  final List<BattleStatusEvent> statusEvents;
}

final class _SingleStatusResidual {
  const _SingleStatusResidual({
    required this.combatant,
    required this.statusEvents,
  });

  final BattleCombatant combatant;
  final List<BattleStatusEvent> statusEvents;
}

final class _VolatileActionPreparation {
  const _VolatileActionPreparation({
    required this.attacker,
    required this.preparedChargeRelease,
    required this.canStartCharge,
  });

  final BattleCombatant attacker;
  final _PreparedChargeRelease? preparedChargeRelease;
  final String? canStartCharge;
}

final class _PreparedChargeRelease {
  const _PreparedChargeRelease({
    required this.moveId,
    required this.chargeStateId,
  });

  final String moveId;
  final String? chargeStateId;
}

final class _VolatileActionContinuation {
  const _VolatileActionContinuation({
    required this.outcome,
    required this.attacker,
    required this.volatileEvents,
  });

  final BattleActionAttemptOutcome outcome;
  final BattleCombatant attacker;
  final List<BattleVolatileEvent> volatileEvents;
}

final class _VolatileMoveResolvedResult {
  const _VolatileMoveResolvedResult({
    required this.attacker,
    required this.volatileEvents,
  });

  final BattleCombatant attacker;
  final List<BattleVolatileEvent> volatileEvents;
}

final class _FieldMoveResolvedResult {
  const _FieldMoveResolvedResult({
    required this.field,
    required this.fieldEvents,
  });

  final BattleFieldState field;
  final List<BattleFieldEvent> fieldEvents;
}

final class _FieldEndOfTurnResult {
  const _FieldEndOfTurnResult({
    required this.player,
    required this.enemy,
    required this.field,
    required this.fieldEvents,
  });

  final BattleCombatant player;
  final BattleCombatant enemy;
  final BattleFieldState field;
  final List<BattleFieldEvent> fieldEvents;
}

final class _WeatherResidualResult {
  const _WeatherResidualResult({
    required this.player,
    required this.enemy,
    required this.field,
    required this.fieldEvents,
  });

  final BattleCombatant player;
  final BattleCombatant enemy;
  final BattleFieldState field;
  final List<BattleFieldEvent> fieldEvents;
}

final class _SandstormResidualResult {
  const _SandstormResidualResult({
    required this.combatant,
    required this.fieldEvents,
  });

  final BattleCombatant combatant;
  final List<BattleFieldEvent> fieldEvents;
}

final class _FieldProgressionResult {
  const _FieldProgressionResult({
    required this.field,
    required this.fieldEvents,
  });

  final BattleFieldState field;
  final List<BattleFieldEvent> fieldEvents;
}
