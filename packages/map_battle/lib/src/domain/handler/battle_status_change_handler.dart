import '../../psdk/domain/psdk_battle_combatant.dart';
import '../../psdk/domain/psdk_battle_field.dart';
import '../../psdk/domain/psdk_battle_move.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_state.dart';
import '../../psdk/domain/psdk_battle_timeline.dart';
import '../battler/battle_grounding_resolver.dart';
import '../effect/ability/ability_effect.dart';
import '../effect/battle_effect_hooks.dart';
import '../effect/battle_effect_scope.dart';
import '../effect/status/status_effect_registry.dart';
import '../move/battle_move_data.dart';
import '../move/battle_move_prevention.dart';
import '../rng/battle_rng_streams.dart';
import 'battle_handler_context.dart';
import 'battle_damage_handler.dart';
import 'battle_handler_result.dart';

final class BattleStatusChangeHandler {
  const BattleStatusChangeHandler();

  BattleHandlerResult applyMajorStatus({
    required BattleHandlerContext context,
    required PsdkBattleSlotRef target,
    required String moveId,
    required PsdkBattleMajorStatus status,
    BattleMoveDefinition? move,
  }) {
    final targetBattler = context.state.battlerAt(target);
    final hookPrevention = _statusPreventionReason(
      context: context,
      target: target,
      status: status,
      move: move,
    );
    if (hookPrevention != null) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: hookPrevention,
      );
    }
    if (targetBattler.majorStatus != null) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: 'already_statused',
      );
    }
    if (_isStatusImmune(context, target, targetBattler, status)) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: 'status_immune',
      );
    }

    final baseState = context.state.updateBattler(
      target,
      (battler) => battler.copyWith(
        majorStatus: status,
        sleepTurns:
            status == PsdkBattleMajorStatus.sleep ? 0 : battler.sleepTurns,
        toxicCounter:
            status == PsdkBattleMajorStatus.toxic ? 0 : battler.toxicCounter,
        effects: battler.effects.addEffect(
          const StatusEffectRegistry().create(
            status: status,
            target: target,
          ),
        ),
      ),
    );
    final post = _dispatchPostStatusChange(
      context: BattleHandlerContext(
        state: baseState,
        rng: context.rng,
        turn: context.turn,
        user: context.user,
      ),
      target: target,
      status: status,
      cured: false,
      moveId: moveId,
      move: move,
    );

    return BattleHandlerResult(
      state: post.state,
      rng: post.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleStatusEvent(
          user: context.user,
          target: target,
          moveId: moveId,
          status: status,
        ),
        ...post.events,
      ],
    );
  }

  bool canApplyMajorStatus({
    required BattleHandlerContext context,
    required PsdkBattleSlotRef target,
    required PsdkBattleMajorStatus status,
    BattleMoveDefinition? move,
  }) {
    final targetBattler = context.state.battlerAt(target);
    return targetBattler.majorStatus == null &&
        _statusPreventionReason(
              context: context,
              target: target,
              status: status,
              move: move,
            ) ==
            null &&
        !_isStatusImmune(context, target, targetBattler, status);
  }

  BattleHandlerResult cureMajorStatus({
    required BattleHandlerContext context,
    required PsdkBattleSlotRef target,
    required String moveId,
  }) {
    final targetBattler = context.state.battlerAt(target);
    final status = targetBattler.majorStatus;
    if (status == null) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: 'no_major_status',
      );
    }

    final baseState = context.state.updateBattler(
      target,
      (battler) => battler.copyWith(
        clearMajorStatus: true,
        sleepTurns:
            status == PsdkBattleMajorStatus.sleep ? 0 : battler.sleepTurns,
        toxicCounter:
            status == PsdkBattleMajorStatus.toxic ? 0 : battler.toxicCounter,
        effects: battler.effects.remove(status.name),
      ),
    );
    final post = _dispatchPostStatusChange(
      context: BattleHandlerContext(
        state: baseState,
        rng: context.rng,
        turn: context.turn,
        user: context.user,
      ),
      target: target,
      status: status,
      cured: true,
      moveId: moveId,
    );

    return BattleHandlerResult(
      state: post.state,
      rng: post.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleStatusCureEvent(
          user: context.user,
          target: target,
          moveId: moveId,
          status: status,
        ),
        ...post.events,
      ],
    );
  }

  BattleStatusUserPreventionResult? resolveUserPrevention({
    required BattleHandlerContext context,
    required PsdkBattleSlotRef user,
    required BattleMoveDefinition move,
  }) {
    final battler = context.state.battlerAt(user);
    final effectResult = battler.effects.userMovePrevention(
      BattleEffectUserMovePreventionContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: user,
        target: user,
        move: move,
      ),
      where: (effect) => effect is BattleMajorStatusEffect,
    );
    if (effectResult != null) {
      return BattleStatusUserPreventionResult(
        state: effectResult.state,
        rng: effectResult.rng,
        prevented: effectResult.prevented,
        reason: effectResult.reason,
        events: effectResult.events,
      );
    }

    return switch (battler.majorStatus) {
      PsdkBattleMajorStatus.paralysis =>
        _resolveParalysisPrevention(context, user),
      PsdkBattleMajorStatus.sleep =>
        _resolveSleepPrevention(context, user, move),
      PsdkBattleMajorStatus.freeze => _resolveFreezePrevention(context, user),
      _ => null,
    };
  }

  BattleHandlerResult tickEndTurnStatuses(BattleHandlerContext context) {
    var nextState = context.state;
    var nextRng = context.rng;
    final events = <PsdkBattleEvent>[];
    var changed = false;

    for (final slot in context.state.aliveSlots()) {
      final battler = nextState.battlerAt(slot);
      final status = battler.majorStatus;
      if (status == null) {
        continue;
      }

      final effectResult = battler.effects.dispatchEndTurn(
        BattleEffectEndTurnContext(
          state: nextState,
          rng: nextRng,
          turn: context.turn,
          owner: slot,
        ),
        where: (effect) => effect is BattleMajorStatusEffect,
      );
      if (effectResult.applied || effectResult.events.isNotEmpty) {
        nextState = effectResult.state;
        nextRng = effectResult.rng;
        events.addAll(effectResult.events);
        changed = true;
        continue;
      }

      final toxicCounter = status == PsdkBattleMajorStatus.toxic
          ? battler.toxicCounter + 1
          : battler.toxicCounter;
      if (toxicCounter != battler.toxicCounter) {
        nextState = nextState.updateBattler(
          slot,
          (current) => current.copyWith(toxicCounter: toxicCounter),
        );
        changed = true;
      }

      final damage = _endTurnDamage(
        nextState.battlerAt(slot),
        status,
        toxicCounter: toxicCounter,
      );
      if (damage <= 0) {
        continue;
      }
      final damageResult = const BattleDamageHandler().applyDamage(
        context: BattleHandlerContext(
          state: nextState,
          rng: nextRng,
          turn: context.turn,
          user: slot,
        ),
        target: slot,
        moveId: 'status:${status.name}',
        rawDamage: damage,
      );
      nextState = damageResult.state;
      nextRng = damageResult.rng;
      events.addAll(damageResult.events);
      changed = true;
    }

    return BattleHandlerResult(
      state: nextState,
      rng: nextRng,
      events: events,
      applied: changed,
      reason: changed ? null : 'no_status_progression',
    );
  }
}

String? _statusPreventionReason({
  required BattleHandlerContext context,
  required PsdkBattleSlotRef target,
  required PsdkBattleMajorStatus status,
  BattleMoveDefinition? move,
}) {
  for (final owner in _orderedSlots(context.state)) {
    final reason =
        context.state.battlerAt(owner).effects.statusPreventionReason(
              BattleEffectStatusPreventionContext(
                state: context.state,
                rng: context.rng,
                turn: context.turn,
                owner: owner,
                user: context.user,
                target: target,
                status: status,
                move: move,
              ),
            );
    if (reason != null) {
      return reason;
    }
  }
  return null;
}

BattleEffectStatusChangeResult _dispatchPostStatusChange({
  required BattleHandlerContext context,
  required PsdkBattleSlotRef target,
  required PsdkBattleMajorStatus status,
  required bool cured,
  required String moveId,
  BattleMoveDefinition? move,
}) {
  var nextState = context.state;
  var nextRng = context.rng;
  final events = <PsdkBattleEvent>[];
  var changed = false;
  for (final owner in _orderedSlots(nextState)) {
    final result = nextState.battlerAt(owner).effects.dispatchPostStatusChange(
          BattleEffectStatusChangeContext(
            state: nextState,
            rng: nextRng,
            turn: context.turn,
            owner: owner,
            user: context.user,
            target: target,
            status: status,
            cured: cured,
            moveId: moveId,
            move: move,
          ),
        );
    nextState = result.state;
    nextRng = result.rng;
    events.addAll(result.events);
    changed = changed || result.applied || result.events.isNotEmpty;
  }
  return BattleEffectStatusChangeResult(
    state: nextState,
    rng: nextRng,
    events: events,
    applied: changed,
  );
}

List<PsdkBattleSlotRef> _orderedSlots(PsdkBattleState state) {
  final slots = state.combatants.keys.toList();
  slots.sort(_compareSlots);
  return slots;
}

int _compareSlots(PsdkBattleSlotRef a, PsdkBattleSlotRef b) {
  final bank = a.bank.compareTo(b.bank);
  return bank != 0 ? bank : a.position.compareTo(b.position);
}

final class BattleStatusUserPreventionResult {
  const BattleStatusUserPreventionResult({
    required this.state,
    required this.rng,
    required this.prevented,
    required this.reason,
    this.events = const <PsdkBattleEvent>[],
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final bool prevented;
  final BattleMoveFailureReason reason;
  final List<PsdkBattleEvent> events;
}

BattleStatusUserPreventionResult _resolveParalysisPrevention(
  BattleHandlerContext context,
  PsdkBattleSlotRef user,
) {
  final roll = context.rng.generic.nextChance(numerator: 1, denominator: 4);
  final rng = context.rng.copyWith(generic: roll.next);
  return BattleStatusUserPreventionResult(
    state: context.state,
    rng: rng,
    prevented: roll.didOccur,
    reason: BattleMoveFailureReason.unusableByUser,
  );
}

BattleStatusUserPreventionResult _resolveSleepPrevention(
  BattleHandlerContext context,
  PsdkBattleSlotRef user,
  BattleMoveDefinition move,
) {
  final battler = context.state.battlerAt(user);
  if (battler.sleepTurns >= 2) {
    return BattleStatusUserPreventionResult(
      state: context.state.updateBattler(
        user,
        (current) => current.copyWith(
          clearMajorStatus: true,
          sleepTurns: 0,
          effects: current.effects.remove('sleep'),
        ),
      ),
      rng: context.rng,
      prevented: false,
      reason: BattleMoveFailureReason.unusableByUser,
    );
  }

  final nextState = context.state.updateBattler(
    user,
    (current) => current.copyWith(sleepTurns: current.sleepTurns + 1),
  );
  return BattleStatusUserPreventionResult(
    state: nextState,
    rng: context.rng,
    prevented: !_isSleepUsableMove(move.dbSymbol),
    reason: BattleMoveFailureReason.unusableByUser,
  );
}

BattleStatusUserPreventionResult _resolveFreezePrevention(
  BattleHandlerContext context,
  PsdkBattleSlotRef user,
) {
  final roll = context.rng.generic.nextChance(numerator: 1, denominator: 5);
  final rng = context.rng.copyWith(generic: roll.next);
  if (roll.didOccur) {
    return BattleStatusUserPreventionResult(
      state: context.state.updateBattler(
        user,
        (current) => current.copyWith(
          clearMajorStatus: true,
          effects: current.effects.remove('freeze'),
        ),
      ),
      rng: rng,
      prevented: false,
      reason: BattleMoveFailureReason.unusableByUser,
    );
  }
  return BattleStatusUserPreventionResult(
    state: context.state,
    rng: rng,
    prevented: true,
    reason: BattleMoveFailureReason.unusableByUser,
  );
}

bool _isStatusImmune(
  BattleHandlerContext context,
  PsdkBattleSlotRef target,
  PsdkBattleCombatant battler,
  PsdkBattleMajorStatus status,
) {
  final abilityContext = BattleAbilityStatusContext(
    status: status,
    target: battler,
  );
  if (battler.abilityEffects.any(
    (effect) => effect.preventsStatus(abilityContext),
  )) {
    return true;
  }
  if (target != context.user &&
      _bankHasEffect(context.state, target.bank, 'safeguard') &&
      context.state.battlerAt(context.user).abilityId != 'infiltrator') {
    return true;
  }
  if (_isStatusPreventedByTerrain(
    context: context,
    target: target,
    status: status,
  )) {
    return true;
  }
  return switch (status) {
    PsdkBattleMajorStatus.burn => battler.hasType('fire'),
    PsdkBattleMajorStatus.poison ||
    PsdkBattleMajorStatus.toxic =>
      battler.hasType('poison') || battler.hasType('steel'),
    PsdkBattleMajorStatus.paralysis => battler.hasType('electric'),
    PsdkBattleMajorStatus.freeze => battler.hasType('ice'),
    PsdkBattleMajorStatus.sleep => false,
  };
}

bool _bankHasEffect(PsdkBattleState state, int bank, String effectId) {
  return state.combatants.values.any(
    (combatant) => combatant.effects.effects.any((effect) {
      if (effect.id != effectId) {
        return false;
      }
      final scope = effect.scope;
      if (scope is BankBattleEffectScope) {
        return scope.bank == bank;
      }
      if (scope is BattlerBattleEffectScope) {
        return scope.slot.bank == bank;
      }
      return false;
    }),
  );
}

bool _isStatusPreventedByTerrain({
  required BattleHandlerContext context,
  required PsdkBattleSlotRef target,
  required PsdkBattleMajorStatus status,
}) {
  final terrainId = context.state.field.terrain?.id;
  final grounded = const BattleGroundingResolver().isGrounded(
    context.state.battlerAt(target),
  );
  if (!grounded) {
    return false;
  }
  return switch (terrainId) {
    PsdkBattleTerrainId.electricTerrain =>
      status == PsdkBattleMajorStatus.sleep,
    PsdkBattleTerrainId.mistyTerrain => true,
    _ => false,
  };
}

int _endTurnDamage(
  PsdkBattleCombatant battler,
  PsdkBattleMajorStatus status, {
  required int toxicCounter,
}) {
  if (battler.abilityId == 'magic_guard') {
    return 0;
  }
  final damage = switch (status) {
    PsdkBattleMajorStatus.burn => _residualDamage(battler.maxHp, 8),
    PsdkBattleMajorStatus.poison => _residualDamage(battler.maxHp, 8),
    PsdkBattleMajorStatus.toxic =>
      ((battler.maxHp * toxicCounter) / 16).floor().clamp(1, battler.currentHp),
    _ => 0,
  };
  if (status == PsdkBattleMajorStatus.burn &&
      battler.abilityId == 'heatproof' &&
      damage > 1) {
    return (damage / 2).floor().clamp(1, battler.currentHp);
  }
  return damage.clamp(0, battler.currentHp).toInt();
}

int _residualDamage(int maxHp, int denominator) {
  return (maxHp / denominator).floor().clamp(1, maxHp).toInt();
}

bool _isSleepUsableMove(String dbSymbol) {
  return dbSymbol == 'snore' || dbSymbol == 'sleep_talk';
}
