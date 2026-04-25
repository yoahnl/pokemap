import '../../psdk/domain/psdk_battle_combatant.dart';
import '../../psdk/domain/psdk_battle_move.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_state.dart';
import '../../psdk/domain/psdk_battle_timeline.dart';
import '../effect/ability/ability_effect.dart';
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
  }) {
    final targetBattler = context.state.battlerAt(target);
    if (targetBattler.majorStatus != null) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: 'already_statused',
      );
    }
    if (_isStatusImmune(targetBattler, status)) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: 'status_immune',
      );
    }

    return BattleHandlerResult(
      state: context.state.updateBattler(
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
      ),
      rng: context.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleStatusEvent(
          user: context.user,
          target: target,
          moveId: moveId,
          status: status,
        ),
      ],
    );
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

    return BattleHandlerResult(
      state: context.state.updateBattler(
        target,
        (battler) => battler.copyWith(
          clearMajorStatus: true,
          sleepTurns:
              status == PsdkBattleMajorStatus.sleep ? 0 : battler.sleepTurns,
          toxicCounter:
              status == PsdkBattleMajorStatus.toxic ? 0 : battler.toxicCounter,
          effects: battler.effects.remove(status.name),
        ),
      ),
      rng: context.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleStatusCureEvent(
          user: context.user,
          target: target,
          moveId: moveId,
          status: status,
        ),
      ],
    );
  }

  BattleStatusUserPreventionResult? resolveUserPrevention({
    required BattleHandlerContext context,
    required PsdkBattleSlotRef user,
    required BattleMoveDefinition move,
  }) {
    final battler = context.state.battlerAt(user);
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
