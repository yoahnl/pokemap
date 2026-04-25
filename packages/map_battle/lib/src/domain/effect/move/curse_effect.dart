import '../../handler/battle_damage_handler.dart';
import '../../handler/battle_handler_context.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

final class CurseEffect extends BattleEffect {
  const CurseEffect({
    required BattleEffectScope scope,
  }) : super(
          id: 'curse',
          scope: scope,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return CurseEffect(scope: scope);
  }

  @override
  BattleEffect? onBatonPassTransfer(BattleEffectBatonPassContext context) {
    return CurseEffect(scope: BattlerBattleEffectScope(context.target));
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final owner = context.owner;
    final battler = context.state.battlerAt(owner);
    if (battler.isFainted || battler.abilityId == 'magic_guard') {
      return null;
    }

    final damage = (battler.maxHp ~/ 4).clamp(1, battler.currentHp).toInt();
    final result = const BattleDamageHandler().applyDamage(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: owner,
      ),
      target: owner,
      moveId: 'effect:curse',
      rawDamage: damage,
    );
    if (!result.applied) {
      return null;
    }
    return BattleEffectEndTurnResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
    );
  }
}
