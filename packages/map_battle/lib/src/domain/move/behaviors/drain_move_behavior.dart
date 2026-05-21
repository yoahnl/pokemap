import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../battle/battle_slot.dart';
import '../../effect/item/item_effect.dart';
import '../../timeline/battle_timeline_event.dart';
import '../battle_move_behavior.dart';
import '../battle_move_data.dart';
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
/// The local port mirrors PSDK's damage-first drain process: damage dealt
/// drives the heal amount, Big Root boosts that amount, Heal Block prevents
/// only the recovery, and Liquid Ooze turns the recovery into damage.
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

    var state = prepared.state;
    var rng = prepared.rng;
    final events = <PsdkBattleEvent>[...prepared.events];
    final successfulTargets = <PsdkBattleSlotRef>[];

    for (final targetSlot in prepared.psdkTargets) {
      final user = state.battlerAt(context.user);
      final target = state.battlerAt(targetSlot);
      final damageResult = const BattleMoveDamageCalculator().calculate(
        BattleMoveDamageContext(
          user: user,
          target: target,
          move: context.move,
          rng: rng,
          field: state.field,
          state: state,
          userSlot: context.user,
          targetSlot: targetSlot,
        ),
      );
      rng = damageResult.rng;
      if (damageResult.damage <= 0) {
        continue;
      }

      final damage = applyDirectDamage(
        state: state,
        user: context.user,
        target: targetSlot,
        moveId: context.move.id,
        rng: rng,
        turn: context.turn,
        amount: damageResult.damage,
      );
      state = damage.state;
      rng = damage.rng;
      if (damage.event != null) {
        events.add(damage.event!);
      }
      if (damage.damage <= 0) {
        continue;
      }
      successfulTargets.add(targetSlot);

      final healAmount = _drainHealAmount(
        damage: damage.damage,
        dbSymbol: context.move.dbSymbol,
        user: user,
        target: target,
        move: context.move,
      );
      PsdkBattleEvent? drainEvent;
      if (_hasLiquidOoze(target)) {
        final liquidOozeDamage = applyDirectDamage(
          state: state,
          user: context.user,
          target: context.user,
          moveId: context.move.id,
          rng: rng,
          turn: context.turn,
          amount: healAmount,
        );
        state = liquidOozeDamage.state;
        rng = liquidOozeDamage.rng;
        drainEvent = liquidOozeDamage.event;
      } else if (!_isHealBlocked(user)) {
        final heal = applyDirectHeal(
          state: state,
          user: context.user,
          target: context.user,
          moveId: context.move.id,
          rng: rng,
          turn: context.turn,
          amount: healAmount,
        );
        state = heal.state;
        rng = heal.rng;
        drainEvent = heal.event;
      }
      if (drainEvent != null) {
        events.add(drainEvent);
      }
    }

    for (final targetSlot in successfulTargets) {
      final secondary = const BattleMoveSecondaryEffectResolver().resolve(
        state: state,
        rng: rng,
        user: context.user,
        target: targetSlot,
        move: context.move,
        turn: context.turn,
      );
      state = secondary.state;
      rng = secondary.rng;
      events.addAll(secondary.events);
    }

    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
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
  required PsdkBattleCombatant target,
  required BattleMoveDefinition move,
}) {
  final drainFactor =
      dbSymbol == 'draining_kiss' || dbSymbol == 'oblivion_wing' ? 4 / 3 : 2;
  final multiplier = _drainHealMultiplier(
    user: user,
    target: target,
    move: move,
    baseHealAmount: (damage / drainFactor).floor(),
  );
  final healed = (damage * multiplier / drainFactor).floor();
  return healed < 1 ? 1 : healed;
}

double _drainHealMultiplier({
  required PsdkBattleCombatant user,
  required PsdkBattleCombatant target,
  required BattleMoveDefinition move,
  required int baseHealAmount,
}) {
  var multiplier = 1.0;
  for (final effect in user.activeItemEffects) {
    multiplier *= effect.drainHealMultiplier(
      BattleItemDrainModifierContext(
        user: user,
        target: target,
        move: move,
        baseHealAmount: baseHealAmount,
      ),
    );
  }
  return multiplier;
}

bool _hasLiquidOoze(PsdkBattleCombatant target) {
  return target.abilityId == 'liquid_ooze';
}

bool _isHealBlocked(PsdkBattleCombatant user) {
  return user.effects.contains('heal_block');
}
