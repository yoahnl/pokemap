import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_heal_handler.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import '../item/item_effect.dart';

final class IngrainEffect extends BattleEffect {
  const IngrainEffect({
    required BattleEffectScope scope,
  }) : super(
          id: 'ingrain',
          scope: scope,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return IngrainEffect(scope: scope);
  }

  @override
  BattleEffect? onBatonPassTransfer(BattleEffectBatonPassContext context) {
    return IngrainEffect(scope: BattlerBattleEffectScope(context.target));
  }

  @override
  String? onSwitchPrevention(BattleEffectSwitchPreventionContext context) {
    return 'ingrain';
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final owner = context.owner;
    final battler = context.state.battlerAt(owner);
    if (battler.isFainted || battler.currentHp >= battler.maxHp) {
      return null;
    }

    var healAmount = battler.maxHp ~/ 16;
    if (healAmount < 1) {
      healAmount = 1;
    }
    healAmount = _itemAdjustedHealAmount(battler, healAmount);

    final result = const BattleHealHandler().heal(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: owner,
      ),
      target: owner,
      amount: healAmount,
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
          moveId: 'effect:ingrain',
          amount: result.amount,
          remainingHp: healed.currentHp,
        ),
      ],
    );
  }
}

int _itemAdjustedHealAmount(PsdkBattleCombatant battler, int healAmount) {
  var multiplier = 1.0;
  for (final effect in battler.activeItemEffects) {
    multiplier *= effect.drainHealMultiplier(
      BattleItemDrainModifierContext(
        user: battler,
        target: battler,
        move: null,
        baseHealAmount: healAmount,
      ),
    );
  }
  final adjusted = (healAmount * multiplier).floor();
  return adjusted < 1 ? 1 : adjusted;
}
