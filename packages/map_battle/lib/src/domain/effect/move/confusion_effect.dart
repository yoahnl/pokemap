import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../handler/battle_damage_handler.dart';
import '../../handler/battle_handler_context.dart';
import '../../move/battle_move_prevention.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

/// PSDK Confusion volatile effect.
///
/// This ports the Pokemon SDK user-prevention core: the volatile counter ticks
/// before the move, the last turn clears without rolling, and a 50% failure
/// roll deals typeless 40-power self damage.
final class ConfusionEffect extends BattleEffect {
  const ConfusionEffect({
    required BattleEffectScope scope,
    this.remainingConfusionTurns = 2,
  }) : super(
          id: 'confusion',
          scope: scope,
        );

  final int remainingConfusionTurns;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return ConfusionEffect(
      scope: scope,
      remainingConfusionTurns: remainingTurns,
    );
  }

  @override
  BattleEffectUserMovePreventionResult? onUserMovePrevention(
    BattleEffectUserMovePreventionContext context,
  ) {
    if (!_appliesTo(context.user)) {
      return null;
    }

    final user = context.state.battlerAt(context.user);
    if (user.isFainted) {
      return null;
    }

    if (remainingConfusionTurns <= 1) {
      return BattleEffectUserMovePreventionResult(
        state: context.state.updateBattler(
          context.user,
          (battler) => battler.copyWith(
            effects: battler.effects.remove(id),
          ),
        ),
        rng: context.rng,
        prevented: false,
        reason: BattleMoveFailureReason.unusableByUser,
      );
    }

    final roll = context.rng.generic.nextChance(
      numerator: 1,
      denominator: 2,
    );
    final nextRng = context.rng.copyWith(generic: roll.next);
    final nextEffect = ConfusionEffect(
      scope: scope,
      remainingConfusionTurns: remainingConfusionTurns - 1,
    );
    final tickedState = context.state.updateBattler(
      context.user,
      (battler) => battler.copyWith(
        effects: battler.effects.addEffect(nextEffect),
      ),
    );

    if (!roll.didOccur) {
      return BattleEffectUserMovePreventionResult(
        state: tickedState,
        rng: nextRng,
        prevented: false,
        reason: BattleMoveFailureReason.unusableByUser,
      );
    }

    final levelFactor = (user.level * 2 ~/ 5) + 2;
    final attack = user.effectiveStat('attack');
    final defense = user.effectiveStat('defense').clamp(1, 1 << 30).toInt();
    final damage = (levelFactor * 40 * attack / defense / 50).floor();
    final damaged = const BattleDamageHandler().applyDamage(
      context: BattleHandlerContext(
        state: tickedState,
        rng: nextRng,
        turn: context.turn,
        user: context.user,
      ),
      target: context.user,
      moveId: 'effect:confusion',
      rawDamage: damage,
    );

    return BattleEffectUserMovePreventionResult(
      state: damaged.state,
      rng: damaged.rng,
      prevented: true,
      reason: BattleMoveFailureReason.unusableByUser,
      events: damaged.events,
    );
  }

  bool _appliesTo(PsdkBattleSlotRef user) {
    final scope = this.scope;
    return scope is! BattlerBattleEffectScope || scope.slot == user;
  }
}
