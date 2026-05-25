import '../../handler/battle_damage_handler.dart';
import '../../handler/battle_handler_context.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

final class PerishSongEffect extends BattleEffect {
  const PerishSongEffect({
    required BattleEffectScope scope,
    int remainingTurns = 3,
  }) : super(
          id: 'perish_song',
          scope: scope,
          remainingTurns: remainingTurns,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return PerishSongEffect(
      scope: scope,
      remainingTurns: remainingTurns,
    );
  }

  @override
  BattleEffect? onBatonPassTransfer(BattleEffectBatonPassContext context) {
    return PerishSongEffect(
      scope: BattlerBattleEffectScope(context.target),
      remainingTurns: remainingTurns ?? 3,
    );
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final owner = context.owner;
    final battler = context.state.battlerAt(owner);
    if (battler.isFainted) {
      return null;
    }

    final turns = remainingTurns ?? 3;
    if (turns > 1) {
      final nextTurns = turns - 1;
      final nextEffects = battler.effects.addEffect(
        copyWithRemainingTurns(nextTurns),
      );
      return BattleEffectEndTurnResult(
        state: context.state.updateBattler(
          owner,
          (current) => current.copyWith(effects: nextEffects),
        ),
        rng: context.rng,
      );
    }

    final clearedState = context.state.updateBattler(
      owner,
      (current) => current.copyWith(effects: current.effects.remove(id)),
    );
    final result = const BattleDamageHandler().applyDamage(
      context: BattleHandlerContext(
        state: clearedState,
        rng: context.rng,
        turn: context.turn,
        user: owner,
      ),
      target: owner,
      moveId: 'effect:perish_song',
      rawDamage: battler.maxHp,
    );
    if (!result.applied) {
      return BattleEffectEndTurnResult(
        state: clearedState,
        rng: context.rng,
      );
    }
    return BattleEffectEndTurnResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
    );
  }
}
