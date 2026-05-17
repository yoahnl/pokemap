import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_item_change_handler.dart';
import '../../move/battle_move_prevention.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'item_effect.dart';

final class FocusSashEffect extends BattleItemEffect {
  const FocusSashEffect({
    required BattleEffectScope scope,
  }) : super(itemId: 'focus_sash', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return this;
  }

  @override
  BattleEffectDamagePreventionResult? onDamagePrevention(
    BattleEffectDamagePreventionContext context,
  ) {
    final owner = this.owner;
    if (owner == null || context.owner != owner || context.target != owner) {
      return null;
    }
    final target = context.state.battlerAt(owner);
    if (!_canApply(target) ||
        context.user == owner ||
        target.currentHp != target.maxHp ||
        context.damage < target.currentHp) {
      return null;
    }

    final damage = target.currentHp - 1;
    final damagedTarget = target
        .recordDamage(
          turn: context.turn,
          source: context.user,
          moveId: context.move.id,
          damage: damage,
          remainingHp: 1,
          moveCategory: context.move.category,
        )
        .copyWith(currentHp: 1);
    final damagedState = context.state.replaceBattler(owner, damagedTarget);
    final consumed = const BattleItemChangeHandler().consumeHeldItem(
      context: BattleHandlerContext(
        state: damagedState,
        rng: context.rng,
        turn: context.turn,
        user: context.user,
      ),
      target: owner,
    );

    return BattleEffectDamagePreventionResult(
      state: consumed.applied ? consumed.state : damagedState,
      rng: consumed.rng,
      prevented: true,
      reason: BattleMoveFailureReason.immunity,
      amount: damage,
      events: <PsdkBattleEvent>[
        PsdkBattleDamageEvent(
          user: context.user,
          target: owner,
          moveId: context.move.id,
          damage: damage,
          remainingHp: 1,
        ),
        ...consumed.events,
      ],
    );
  }
}

final class FocusBandEffect extends BattleItemEffect {
  const FocusBandEffect({
    required BattleEffectScope scope,
  }) : super(itemId: 'focus_band', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return this;
  }

  @override
  BattleEffectDamagePreventionResult? onDamagePrevention(
    BattleEffectDamagePreventionContext context,
  ) {
    final owner = this.owner;
    if (owner == null || context.owner != owner || context.target != owner) {
      return null;
    }
    final target = context.state.battlerAt(owner);
    if (!_canApply(target) ||
        context.user == owner ||
        context.damage < target.currentHp) {
      return null;
    }

    final roll = context.rng.generic.nextChance(numerator: 1, denominator: 10);
    if (!roll.didOccur) {
      return null;
    }
    final nextRng = context.rng.copyWith(generic: roll.next);
    final damage = target.currentHp - 1;
    final damagedTarget = target
        .recordDamage(
          turn: context.turn,
          source: context.user,
          moveId: context.move.id,
          damage: damage,
          remainingHp: 1,
          moveCategory: context.move.category,
        )
        .copyWith(currentHp: 1);
    return BattleEffectDamagePreventionResult(
      state: context.state.replaceBattler(owner, damagedTarget),
      rng: nextRng,
      prevented: true,
      reason: BattleMoveFailureReason.immunity,
      amount: damage,
      events: <PsdkBattleEvent>[
        PsdkBattleDamageEvent(
          user: context.user,
          target: owner,
          moveId: context.move.id,
          damage: damage,
          remainingHp: 1,
        ),
      ],
    );
  }
}

bool _canApply(PsdkBattleCombatant battler) {
  return !battler.isFainted &&
      battler.heldItemId != null &&
      !battler.itemConsumed &&
      !battler.itemEffectsSuppressed;
}
