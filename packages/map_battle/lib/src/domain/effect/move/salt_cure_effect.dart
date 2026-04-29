import '../../handler/battle_damage_handler.dart';
import '../../handler/battle_handler_context.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

final class SaltCureEffect extends BattleEffect {
  const SaltCureEffect({
    required BattleEffectScope scope,
  }) : super(
          id: 'salt_cure',
          scope: scope,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return SaltCureEffect(scope: scope);
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final owner = context.owner;
    final battler = context.state.battlerAt(owner);
    if (battler.isFainted || battler.abilityId == 'magic_guard') {
      return null;
    }

    final divisor =
        battler.hasType('steel') || battler.hasType('water') ? 4 : 8;
    final damage = (battler.maxHp ~/ divisor).clamp(1, battler.currentHp);
    final result = const BattleDamageHandler().applyDamage(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: owner,
      ),
      target: owner,
      moveId: 'effect:salt_cure',
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
