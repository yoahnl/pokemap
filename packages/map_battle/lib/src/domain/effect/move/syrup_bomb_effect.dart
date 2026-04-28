import '../../handler/battle_handler_context.dart';
import '../../handler/battle_stat_change_handler.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

final class SyrupBombEffect extends BattleEffect {
  const SyrupBombEffect({
    required BattleEffectScope scope,
    this.remainingDrops = 3,
  }) : super(
          id: 'syrup_bomb',
          scope: scope,
          remainingTurns: remainingDrops,
        );

  final int remainingDrops;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return SyrupBombEffect(scope: scope, remainingDrops: remainingTurns);
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final owner = context.owner;
    final battler = context.state.battlerAt(owner);
    if (battler.isFainted) {
      return BattleEffectEndTurnResult(
        state: context.state.updateBattler(
          owner,
          (current) => current.copyWith(
            effects: current.effects.remove(id),
          ),
        ),
        rng: context.rng,
      );
    }

    final stat = const BattleStatChangeHandler().applyStatChange(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: owner,
      ),
      target: owner,
      stat: 'speed',
      stages: -1,
    );
    final nextTurns = remainingDrops - 1;
    final nextState = stat.state.updateBattler(
      owner,
      (current) => current.copyWith(
        effects: nextTurns <= 0
            ? current.effects.remove(id)
            : current.effects.addEffect(copyWithRemainingTurns(nextTurns)),
      ),
    );
    return BattleEffectEndTurnResult(
      state: nextState,
      rng: stat.rng,
      events: stat.events,
    );
  }
}
