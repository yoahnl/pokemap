import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../ability/mental_immunity_ability_effect.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import '../move/flinch_effect.dart';
import 'item_effect.dart';

final class FlinchItemEffect extends BattleItemEffect {
  const FlinchItemEffect({
    required String itemId,
    required BattleEffectScope scope,
  }) : super(itemId: itemId, scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return FlinchItemEffect(itemId: itemId, scope: scope);
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (context.owner != context.user ||
        context.user == context.target ||
        context.damage <= 0 ||
        context.targetFainted ||
        !context.move.flags.kingRockUtility) {
      return null;
    }

    final user = context.state.battlerAt(context.user);
    if (user.heldItemId != itemId ||
        user.itemConsumed ||
        user.itemEffectsSuppressed) {
      return null;
    }

    final roll = context.rng.generic.nextChance(
      numerator: user.abilityId == 'serene_grace' ? 2 : 1,
      denominator: 10,
    );
    final nextRng = context.rng.copyWith(generic: roll.next);
    if (!roll.didOccur ||
        battleMentalAbilityBlocksEffect(
          state: context.state,
          user: context.user,
          target: context.target,
          effectId: 'flinch',
        )) {
      return BattleEffectPostDamageResult(
        state: context.state,
        rng: nextRng,
        applied: false,
      );
    }

    final result = applyFlinchEffect(
      state: context.state,
      rng: nextRng,
      turn: context.turn,
      target: context.target,
      reason: 'item:$itemId',
      move: context.move,
    );
    return BattleEffectPostDamageResult(
      state: result.state,
      rng: result.rng,
      events: <PsdkBattleEvent>[...result.events],
    );
  }
}
