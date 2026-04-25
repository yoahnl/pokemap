import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../battle/battle_slot.dart';
import '../../rng/battle_rng_streams.dart';
import '../../timeline/battle_timeline_builder.dart';
import '../../timeline/battle_timeline_event.dart';
import '../battle_move_behavior.dart';
import '../battle_move_execution.dart';
import '../battle_move_prevention.dart';
import '../battle_move_procedure.dart';
import '../battle_move_type_processor.dart';

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
  required int amount,
}) {
  final targetBattler = state.battlerAt(target);
  final damage = amount.clamp(0, targetBattler.currentHp).toInt();
  if (damage <= 0) {
    return BattleDirectDamageResult(
      state: state,
      damage: 0,
      target: targetBattler,
    );
  }

  final nextTarget = targetBattler.copyWith(
    currentHp: targetBattler.currentHp - damage,
  );
  return BattleDirectDamageResult(
    state: state.replaceBattler(target, nextTarget),
    damage: damage,
    target: nextTarget,
    event: PsdkBattleDamageEvent(
      user: user,
      target: target,
      moveId: moveId,
      damage: damage,
      remainingHp: nextTarget.currentHp,
    ),
  );
}

BattleMoveTargetPrecheckResult precheckTypeImmunityAndProtect(
  BattleMoveProcedureExecution execution,
  List<BattlePositionRef> targets,
) {
  final unblockedTargets = <BattlePositionRef>[];
  var failureReason = BattleMoveFailureReason.immunity;
  const typeProcessor = BattleMoveTypeProcessor();
  final shouldCheckTypeImmunity =
      execution.move.category != PsdkBattleMoveCategory.status &&
          execution.move.power > 0;

  for (final targetRef in targets) {
    if (_isBlockedByProtect(execution, targetRef)) {
      failureReason = BattleMoveFailureReason.protected;
      execution.timeline.add(
        BattleMoveFailedTimelineEvent(
          turn: execution.turn,
          user: execution.user,
          target: targetRef,
          moveId: execution.move.id,
          reason: BattleMoveFailureReason.protected.jsonName,
        ),
      );
      continue;
    }
    if (shouldCheckTypeImmunity) {
      final target = execution.context.state.battlerAt(
        psdkSlotFromBattlePosition(targetRef),
      );
      final effectiveness = typeProcessor.resolveEffectiveness(
        moveType: execution.move.type,
        targetTypes: target.types,
      );
      if (effectiveness.isImmune) {
        execution.timeline.add(
          BattleMoveImmuneTimelineEvent(
            turn: execution.turn,
            user: execution.user,
            target: targetRef,
            moveId: execution.move.id,
          ),
        );
        continue;
      }
    }
    unblockedTargets.add(targetRef);
  }

  return BattleMoveTargetPrecheckResult(
    targets: unblockedTargets,
    reason: failureReason,
  );
}

BattlePositionRef battlePositionFromPsdkSlot(PsdkBattleSlotRef slot) {
  return BattlePositionRef(bank: slot.bank, position: slot.position);
}

PsdkBattleSlotRef psdkSlotFromBattlePosition(BattlePositionRef slot) {
  return PsdkBattleSlotRef(bank: slot.bank, position: slot.position);
}

bool _isBlockedByProtect(
  BattleMoveProcedureExecution execution,
  BattlePositionRef targetRef,
) {
  if (targetRef == execution.user || !execution.move.flags.protectable) {
    return false;
  }
  final target = execution.context.state.battlerAt(
    psdkSlotFromBattlePosition(targetRef),
  );
  return target.effects.contains(PsdkBattleEffectIds.protect);
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
    required this.damage,
    required this.target,
    this.event,
  });

  final PsdkBattleState state;
  final int damage;
  final PsdkBattleCombatant target;
  final PsdkBattleDamageEvent? event;
}
