import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../battle/battle_slot.dart';
import '../../rng/battle_rng_streams.dart';
import '../../timeline/battle_timeline_builder.dart';
import '../battle_accuracy_resolver.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_execution.dart';
import '../battle_move_prevention.dart';
import 'battle_move_behavior_support.dart';

/// Pokemon SDK `DragonDarts` port.
///
/// PSDK is unusual here: the move is still a two-hit attack, but in double
/// battles the second dart may target one ally of the selected foe. This
/// behavior keeps that target split local to Dragon Darts so the generic
/// multi-hit behavior remains a simple same-target loop.
final class DragonDartsMoveBehavior implements BattleMoveBehavior {
  const DragonDartsMoveBehavior();

  @override
  String get battleEngineMethod => 's_dragon_darts';

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = _preparePrimaryTarget(context);
    if (!prepared.shouldExecuteBehavior || prepared.psdkTargets.isEmpty) {
      return prepared.toResolution();
    }

    final firstTarget = prepared.psdkTargets.first;
    final plan = _resolveHitPlan(
      context: context,
      prepared: prepared,
      firstTarget: firstTarget,
    );
    var state = prepared.state;
    var rng = plan.rng;
    final events = <PsdkBattleEvent>[...prepared.events];

    for (var hitIndex = 0; hitIndex < _dragonDartsHitCount; hitIndex += 1) {
      final target = plan.targets[hitIndex % plan.targets.length];
      final user = state.battlerAt(context.user);
      final targetBattler = state.combatants[target];

      // PSDK stops producing meaningful hit work once either side is no longer
      // alive. Keeping this guard per hit avoids a second Dart damaging a
      // target that the first Dart has already knocked out.
      if (user.isFainted) {
        break;
      }
      if (targetBattler == null || targetBattler.isFainted) {
        continue;
      }

      // The common procedure emitted the first animation cue. PSDK plays the
      // animation again for extra Dragon Darts hits, so only add cues from hit
      // two onward.
      if (hitIndex > 0) {
        events.add(
          PsdkBattleAnimationCueEvent(
            user: context.user,
            target: target,
            moveId: context.move.id,
          ),
        );
      }

      if (hitIndex > 0 && plan.targetsRequiringPrecheck.contains(target)) {
        final precheck = _precheckExtraTarget(
          context: context,
          state: state,
          rng: rng,
          target: target,
        );
        rng = precheck.rng;
        events.addAll(precheck.events);
        if (!precheck.canHit) {
          break;
        }
      }

      final damage = const BattleMoveDamageCalculator().calculate(
        BattleMoveDamageContext(
          user: user,
          target: targetBattler,
          move: context.move,
          rng: rng,
          field: state.field,
          state: state,
          userSlot: context.user,
          targetSlot: target,
          isLastActionOfTurn: context.isLastActionOfTurn,
        ),
      );
      rng = damage.rng;
      if (damage.damage <= 0) {
        continue;
      }

      final applied = applyDirectDamage(
        state: state,
        user: context.user,
        target: target,
        moveId: context.move.id,
        rng: rng,
        turn: context.turn,
        amount: damage.damage,
        moveCategory: context.move.category,
        move: context.move,
        criticalHit: damage.isCritical,
      );
      state = applied.state;
      rng = applied.rng;
      events.addAll(applied.events);
    }

    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
    );
  }

  PreparedBattleMove _preparePrimaryTarget(
    BattleMoveBehaviorContext context,
  ) {
    final prepared = prepareBattleMove(context);
    if (prepared.shouldExecuteBehavior || !_canFallbackToFoeAlly(context)) {
      return prepared;
    }
    if (prepared.failureReason case final reason?
        when !_fallbackReasons.contains(reason)) {
      return prepared;
    }

    final fallback = _sampleTarget(
      candidates: context.state.alliesOf(context.target),
      rng: prepared.rng,
    );
    if (fallback.target == null) {
      return prepared;
    }

    // PSDK retries Dragon Darts against an ally of the selected foe when the
    // chosen foe cannot be used and is not attracting attention. The failed
    // first precheck is intentionally discarded so the observable result is the
    // successful fallback attempt, not a false failure followed by damage.
    return prepareBattleMove(
      _contextWithTarget(
        context,
        target: fallback.target!,
        rng: fallback.rng,
      ),
    );
  }

  bool _canFallbackToFoeAlly(BattleMoveBehaviorContext context) {
    if (context.target.bank == context.user.bank) {
      return false;
    }
    final selected = context.state.combatants[context.target];
    if (selected != null &&
        selected.effects.contains(PsdkBattleEffectIds.centerOfAttention)) {
      return false;
    }
    return context.state.alliesOf(context.target).isNotEmpty;
  }

  _DragonDartsHitPlan _resolveHitPlan({
    required BattleMoveBehaviorContext context,
    required PreparedBattleMove prepared,
    required PsdkBattleSlotRef firstTarget,
  }) {
    if (firstTarget.bank == context.user.bank ||
        prepared.state
            .battlerAt(firstTarget)
            .effects
            .contains(PsdkBattleEffectIds.centerOfAttention)) {
      return _DragonDartsHitPlan(
        targets: <PsdkBattleSlotRef>[firstTarget],
        rng: prepared.rng,
        targetsRequiringPrecheck: const <PsdkBattleSlotRef>{},
      );
    }

    final ally = _sampleTarget(
      candidates: prepared.state.alliesOf(firstTarget),
      rng: prepared.rng,
    );
    if (ally.target == null) {
      return _DragonDartsHitPlan(
        targets: <PsdkBattleSlotRef>[firstTarget],
        rng: ally.rng,
        targetsRequiringPrecheck: const <PsdkBattleSlotRef>{},
      );
    }
    return _DragonDartsHitPlan(
      targets: <PsdkBattleSlotRef>[firstTarget, ally.target!],
      rng: ally.rng,
      targetsRequiringPrecheck: <PsdkBattleSlotRef>{ally.target!},
    );
  }

  _DragonDartsExtraTargetPrecheck _precheckExtraTarget({
    required BattleMoveBehaviorContext context,
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required PsdkBattleSlotRef target,
  }) {
    final timeline = BattleTimelineBuilder();
    final targetPosition = battlePositionFromPsdkSlot(target);
    final execution = BattleMoveProcedureExecution(
      context: _contextWithTarget(
        context,
        state: state,
        target: target,
        rng: rng,
      ),
      timeline: timeline,
      user: battlePositionFromPsdkSlot(context.user),
      move: context.move,
      requestedTarget: targetPosition,
    );
    final accuracy = const BattleAccuracyResolver().resolve(
      execution: execution,
      targets: <BattlePositionRef>[targetPosition],
    );
    final events = <PsdkBattleEvent>[
      for (final missedTarget in accuracy.missedTargets)
        PsdkBattleMissEvent(
          user: context.user,
          target: psdkSlotFromBattlePosition(missedTarget),
          moveId: context.move.id,
        ),
    ];
    if (accuracy.hitTargets.isEmpty) {
      return _DragonDartsExtraTargetPrecheck(
        canHit: false,
        rng: accuracy.rng,
        events: events,
      );
    }

    final precheck = precheckTypeImmunityAndProtect(
      execution,
      accuracy.hitTargets,
    );
    events.addAll(timeline.build().psdkTimeline.events);

    return _DragonDartsExtraTargetPrecheck(
      canHit: precheck.targets.contains(targetPosition),
      rng: accuracy.rng,
      events: events,
    );
  }
}

const _dragonDartsHitCount = 2;

const _fallbackReasons = <BattleMoveFailureReason>{
  BattleMoveFailureReason.noTarget,
  BattleMoveFailureReason.accuracy,
  BattleMoveFailureReason.immunity,
  BattleMoveFailureReason.protected,
};

BattleMoveBehaviorContext _contextWithTarget(
  BattleMoveBehaviorContext context, {
  PsdkBattleState? state,
  required PsdkBattleSlotRef target,
  required BattleRngStreams rng,
}) {
  return BattleMoveBehaviorContext(
    state: state ?? context.state,
    rng: rng,
    turn: context.turn,
    user: context.user,
    target: target,
    move: context.move,
    canFlee: context.canFlee,
    moveSlot: context.moveSlot,
    isLastActionOfTurn: context.isLastActionOfTurn,
    moveProcedureHooks: context.moveProcedureHooks,
    announcedMoveFor: context.announcedMoveFor,
  );
}

_SampledTarget _sampleTarget({
  required List<PsdkBattleSlotRef> candidates,
  required BattleRngStreams rng,
}) {
  if (candidates.isEmpty) {
    return _SampledTarget(target: null, rng: rng);
  }
  if (candidates.length == 1) {
    return _SampledTarget(target: candidates.single, rng: rng);
  }
  final roll = rng.generic.nextIntInclusive(
    min: 0,
    max: candidates.length - 1,
  );
  return _SampledTarget(
    target: candidates[roll.value],
    rng: rng.copyWith(generic: roll.next),
  );
}

final class _DragonDartsHitPlan {
  const _DragonDartsHitPlan({
    required this.targets,
    required this.rng,
    required this.targetsRequiringPrecheck,
  });

  final List<PsdkBattleSlotRef> targets;
  final BattleRngStreams rng;
  final Set<PsdkBattleSlotRef> targetsRequiringPrecheck;
}

final class _DragonDartsExtraTargetPrecheck {
  const _DragonDartsExtraTargetPrecheck({
    required this.canHit,
    required this.rng,
    required this.events,
  });

  final bool canHit;
  final BattleRngStreams rng;
  final List<PsdkBattleEvent> events;
}

final class _SampledTarget {
  const _SampledTarget({
    required this.target,
    required this.rng,
  });

  final PsdkBattleSlotRef? target;
  final BattleRngStreams rng;
}
