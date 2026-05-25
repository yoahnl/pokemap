import '../../../psdk/domain/psdk_battle_slots.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

final class GrudgeEffect extends BattleEffect {
  const GrudgeEffect({
    required BattleEffectScope scope,
    int remainingTurns = 0,
  }) : super(
          id: 'grudge',
          scope: scope,
          remainingTurns: remainingTurns,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return GrudgeEffect(
      scope: scope,
      remainingTurns: remainingTurns,
    );
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(BattleEffectPostDamageContext context) {
    if (!_appliesTo(context.owner) ||
        context.owner != context.target ||
        !context.targetFainted ||
        context.user == context.owner ||
        context.user.bank == context.owner.bank ||
        context.move.id.startsWith('effect:') ||
        context.state.battlerAt(context.owner).moveHistory.lastSuccessfulMoveId !=
            'grudge') {
      return null;
    }

    final launcher = context.state.battlerAt(context.user);
    final moveIndex = launcher.moves.indexWhere(
      (move) => move.id == context.move.id,
    );
    var nextState = context.state.updateBattler(
      context.owner,
      (battler) => battler.copyWith(effects: battler.effects.remove(id)),
    );
    if (moveIndex < 0) {
      return BattleEffectPostDamageResult(
        state: nextState,
        rng: context.rng,
      );
    }

    nextState = nextState.updateBattler(
      context.user,
      (battler) => battler.replaceMoveAt(
        moveIndex,
        battler.moves[moveIndex].copyWith(currentPp: 0),
      ),
    );
    return BattleEffectPostDamageResult(
      state: nextState,
      rng: context.rng,
    );
  }

  bool _appliesTo(PsdkBattleSlotRef owner) {
    final effectScope = scope;
    return effectScope is! BattlerBattleEffectScope || effectScope.slot == owner;
  }
}
