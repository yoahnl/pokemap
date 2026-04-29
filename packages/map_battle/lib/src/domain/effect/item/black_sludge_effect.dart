import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_damage_handler.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_heal_handler.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'item_effect.dart';

final class BlackSludgeEffect extends BattleItemEffect {
  const BlackSludgeEffect({
    required BattleEffectScope scope,
  }) : super(itemId: 'black_sludge', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return BlackSludgeEffect(scope: scope);
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final owner = context.owner;
    if (!isOwnedBy(owner)) {
      return null;
    }

    final battler = context.state.battlerAt(owner);
    if (battler.isFainted ||
        battler.heldItemId != itemId ||
        battler.itemConsumed ||
        battler.itemEffectsSuppressed) {
      return null;
    }

    if (battler.hasType('poison')) {
      return _heal(context);
    }
    if (battler.abilityId == 'magic_guard') {
      return null;
    }
    return _damage(context);
  }

  BattleEffectEndTurnResult? _heal(BattleEffectEndTurnContext context) {
    final owner = context.owner;
    final battler = context.state.battlerAt(owner);
    if (battler.currentHp >= battler.maxHp) {
      return null;
    }

    final amount = (battler.maxHp ~/ 16).clamp(1, battler.maxHp).toInt();
    final result = const BattleHealHandler().heal(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: owner,
      ),
      target: owner,
      amount: amount,
    );
    if (!result.applied) {
      return null;
    }

    final healed = result.state.battlerAt(owner);
    return BattleEffectEndTurnResult(
      state: result.state,
      rng: result.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleHealEvent(
          user: owner,
          target: owner,
          moveId: 'item:black_sludge',
          amount: result.amount,
          remainingHp: healed.currentHp,
        ),
      ],
    );
  }

  BattleEffectEndTurnResult? _damage(BattleEffectEndTurnContext context) {
    final owner = context.owner;
    final battler = context.state.battlerAt(owner);
    final amount = (battler.maxHp ~/ 8).clamp(1, battler.currentHp).toInt();
    final result = const BattleDamageHandler().applyDamage(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: owner,
      ),
      target: owner,
      moveId: 'item:black_sludge',
      rawDamage: amount,
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
