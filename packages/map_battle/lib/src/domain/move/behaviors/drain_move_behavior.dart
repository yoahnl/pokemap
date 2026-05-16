import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../battle/battle_slot.dart';
import '../../timeline/battle_timeline_event.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_execution.dart';
import '../battle_move_prevention.dart';
import '../battle_move_procedure.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _DrainMoveKind {
  absorb,
  dreamEater,
}

/// Ports the PSDK drain family (`s_absorb` and `s_dream_eater`) for the common
/// HP-transfer path.
///
/// The local port mirrors PSDK's damage-first drain process for single targets:
/// damage dealt drives the heal amount, Big Root boosts that amount, Heal Block
/// prevents only the recovery, and Liquid Ooze turns the recovery into damage.
final class DrainMoveBehavior implements BattleMoveBehavior {
  const DrainMoveBehavior.absorb()
      : battleEngineMethod = 's_absorb',
        _kind = _DrainMoveKind.absorb;

  const DrainMoveBehavior.dreamEater()
      : battleEngineMethod = 's_dream_eater',
        _kind = _DrainMoveKind.dreamEater;

  @override
  final String battleEngineMethod;
  final _DrainMoveKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(
      context,
      targetPrecheck: _kind == _DrainMoveKind.dreamEater
          ? _precheckDreamEaterTarget
          : precheckTypeImmunityAndProtect,
    );
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final target = prepared.state.battlerAt(targetSlot);
    final user = prepared.state.battlerAt(context.user);
    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: user,
        target: target,
        move: context.move,
        rng: prepared.rng,
      ),
    );
    if (damageResult.damage <= 0) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: damageResult.rng,
        events: prepared.events,
      );
    }

    final damage = applyDirectDamage(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      rng: damageResult.rng,
      turn: context.turn,
      amount: damageResult.damage,
    );
    final healAmount = _drainHealAmount(
      damage: damage.damage,
      dbSymbol: context.move.dbSymbol,
      user: user,
    );
    var stateAfterDrain = damage.state;
    var rngAfterDrain = damage.rng;
    PsdkBattleEvent? drainEvent;
    if (_hasLiquidOoze(target)) {
      final liquidOozeDamage = applyDirectDamage(
        state: damage.state,
        user: context.user,
        target: context.user,
        moveId: context.move.id,
        rng: damage.rng,
        turn: context.turn,
        amount: healAmount,
      );
      stateAfterDrain = liquidOozeDamage.state;
      rngAfterDrain = liquidOozeDamage.rng;
      drainEvent = liquidOozeDamage.event;
    } else if (!_isHealBlocked(user)) {
      final heal = applyDirectHeal(
        state: damage.state,
        user: context.user,
        target: context.user,
        moveId: context.move.id,
        rng: damage.rng,
        turn: context.turn,
        amount: healAmount,
      );
      stateAfterDrain = heal.state;
      rngAfterDrain = heal.rng;
      drainEvent = heal.event;
    }
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: stateAfterDrain,
      rng: rngAfterDrain,
      user: context.user,
      target: targetSlot,
      move: context.move,
      turn: context.turn,
    );

    return BattleMoveBehaviorResolution(
      state: secondary.state,
      rng: secondary.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        if (damage.event != null) damage.event!,
        if (drainEvent != null) drainEvent,
        ...secondary.events,
      ],
    );
  }
}

BattleMoveTargetPrecheckResult _precheckDreamEaterTarget(
  BattleMoveProcedureExecution execution,
  List<BattlePositionRef> targets,
) {
  final base = precheckTypeImmunityAndProtect(execution, targets);
  final affectedTargets = <BattlePositionRef>[];
  var reason = base.reason;

  for (final targetRef in base.targets) {
    final target = execution.context.state.battlerAt(
      psdkSlotFromBattlePosition(targetRef),
    );
    if (!_canDreamEaterAffect(target)) {
      reason = BattleMoveFailureReason.immunity;
      execution.timeline.add(
        BattleMoveImmuneTimelineEvent(
          turn: execution.turn,
          user: execution.actualUser,
          target: targetRef,
          moveId: execution.move.id,
        ),
      );
      continue;
    }

    affectedTargets.add(targetRef);
  }

  return BattleMoveTargetPrecheckResult(
    targets: affectedTargets,
    reason: reason,
  );
}

bool _canDreamEaterAffect(PsdkBattleCombatant target) {
  return target.majorStatus == PsdkBattleMajorStatus.sleep ||
      target.abilityId == 'comatose';
}

int _drainHealAmount({
  required int damage,
  required String dbSymbol,
  required PsdkBattleCombatant user,
}) {
  final drainFactor =
      dbSymbol == 'draining_kiss' || dbSymbol == 'oblivion_wing' ? 4 / 3 : 2;
  final multiplier = _hasBigRoot(user) ? 1.3 : 1.0;
  final healed = (damage * multiplier / drainFactor).floor();
  return healed < 1 ? 1 : healed;
}

bool _hasBigRoot(PsdkBattleCombatant user) {
  return user.heldItemId == 'big_root' && !user.itemConsumed;
}

bool _hasLiquidOoze(PsdkBattleCombatant target) {
  return target.abilityId == 'liquid_ooze';
}

bool _isHealBlocked(PsdkBattleCombatant user) {
  return user.effects.contains('heal_block');
}
