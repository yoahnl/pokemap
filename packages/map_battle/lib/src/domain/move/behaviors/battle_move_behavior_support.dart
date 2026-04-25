import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../battle/battle_slot.dart';
import '../../handler/battle_damage_handler.dart';
import '../../handler/battle_heal_handler.dart';
import '../../handler/battle_handler_context.dart';
import '../../rng/battle_rng_streams.dart';
import '../../timeline/battle_timeline_builder.dart';
import '../battle_move_behavior.dart';
import '../battle_move_execution.dart';
import '../battle_move_immunity_resolver.dart';
import '../battle_move_prevention.dart';
import '../battle_move_procedure.dart';

/// Shared PSDK move pipeline used by concrete move families.
///
/// PSDK move classes often override only the "damage/effect" body while still
/// going through the same declaration, target, accuracy, Protect and immunity
/// checks. This helper keeps that contract in one place so Lot 16 families do
/// not fork subtly different pre-hit behavior.
PreparedBattleMove prepareBattleMove(BattleMoveBehaviorContext context) {
  final timeline = BattleTimelineBuilder();
  final execution = BattleMoveProcedureExecution(
    context: context,
    timeline: timeline,
    user: battlePositionFromPsdkSlot(context.user),
    move: context.move,
    requestedTarget: battlePositionFromPsdkSlot(context.target),
  );
  final result = BattleMoveProcedure(
    hooks: context.moveProcedureHooks,
    targetPrecheck: precheckTypeImmunityAndProtect,
  ).prepare(execution);
  return PreparedBattleMove(
    state: context.state,
    rng: result.rng,
    events: timeline.build().psdkTimeline.events,
    targets: result.targets,
    failureReason: result.reason,
    shouldExecuteBehavior: result.shouldExecuteBehavior,
  );
}

/// Applies HP damage without invoking the normal damage formula.
///
/// Fixed-damage PSDK moves explicitly disable critical hits and type
/// effectiveness after the shared immunity precheck. Keeping this helper small
/// makes that boundary visible and prevents accidental damage RNG consumption.
BattleDirectDamageResult applyDirectDamage({
  required PsdkBattleState state,
  required PsdkBattleSlotRef user,
  required PsdkBattleSlotRef target,
  required String moveId,
  required BattleRngStreams rng,
  required int turn,
  required int amount,
}) {
  final result = const BattleDamageHandler().applyDamage(
    context: BattleHandlerContext(
      state: state,
      rng: rng,
      turn: turn,
      user: user,
    ),
    target: target,
    moveId: moveId,
    rawDamage: amount,
  );
  final damageEvents = result.events.whereType<PsdkBattleDamageEvent>();
  return BattleDirectDamageResult(
    state: result.state,
    rng: result.rng,
    damage: result.amount,
    target: result.state.battlerAt(target),
    event: damageEvents.isEmpty ? null : damageEvents.single,
  );
}

BattleDirectHealResult applyDirectHeal({
  required PsdkBattleState state,
  required PsdkBattleSlotRef user,
  required PsdkBattleSlotRef target,
  required String moveId,
  required BattleRngStreams rng,
  required int turn,
  required int amount,
}) {
  final result = const BattleHealHandler().heal(
    context: BattleHandlerContext(
      state: state,
      rng: rng,
      turn: turn,
      user: user,
    ),
    target: target,
    amount: amount,
  );
  final healedBattler = result.state.battlerAt(target);
  return BattleDirectHealResult(
    state: result.state,
    rng: result.rng,
    amount: result.amount,
    target: healedBattler,
    event: result.applied
        ? PsdkBattleHealEvent(
            user: user,
            target: target,
            moveId: moveId,
            amount: result.amount,
            remainingHp: healedBattler.currentHp,
          )
        : null,
  );
}

BattleMoveTargetPrecheckResult precheckTypeImmunityAndProtect(
  BattleMoveProcedureExecution execution,
  List<BattlePositionRef> targets,
) {
  return const BattleMoveImmunityResolver().precheck(execution, targets);
}

BattlePositionRef battlePositionFromPsdkSlot(PsdkBattleSlotRef slot) {
  return BattlePositionRef(bank: slot.bank, position: slot.position);
}

PsdkBattleSlotRef psdkSlotFromBattlePosition(BattlePositionRef slot) {
  return PsdkBattleSlotRef(bank: slot.bank, position: slot.position);
}

final class PreparedBattleMove {
  const PreparedBattleMove({
    required this.state,
    required this.rng,
    required this.events,
    required this.targets,
    required this.failureReason,
    required this.shouldExecuteBehavior,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final List<PsdkBattleEvent> events;
  final List<BattlePositionRef> targets;
  final BattleMoveFailureReason? failureReason;
  final bool shouldExecuteBehavior;

  List<PsdkBattleSlotRef> get psdkTargets {
    return targets.map(psdkSlotFromBattlePosition).toList(growable: false);
  }

  BattleMoveBehaviorResolution toResolution({bool successful = false}) {
    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
      successful: successful,
    );
  }
}

final class BattleDirectDamageResult {
  const BattleDirectDamageResult({
    required this.state,
    required this.rng,
    required this.damage,
    required this.target,
    this.event,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final int damage;
  final PsdkBattleCombatant target;
  final PsdkBattleDamageEvent? event;
}

final class BattleDirectHealResult {
  const BattleDirectHealResult({
    required this.state,
    required this.rng,
    required this.amount,
    required this.target,
    this.event,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final int amount;
  final PsdkBattleCombatant target;
  final PsdkBattleHealEvent? event;
}
