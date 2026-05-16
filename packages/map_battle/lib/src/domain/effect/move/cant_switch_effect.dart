import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../effect/battle_effect.dart';
import '../../effect/battle_effect_hooks.dart';
import '../../effect/battle_effect_scope.dart';

final class CantSwitchEffect extends BattleEffect {
  const CantSwitchEffect({
    required BattleEffectScope scope,
    required this.origin,
  }) : super(
          id: PsdkBattleEffectIds.cantSwitch,
          scope: scope,
        );

  final PsdkBattleSlotRef origin;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return CantSwitchEffect(scope: scope, origin: origin);
  }

  @override
  BattleEffect? onBatonPassTransfer(BattleEffectBatonPassContext context) {
    return CantSwitchEffect(
      scope: BattlerBattleEffectScope(context.target),
      origin: origin,
    );
  }

  @override
  String? onSwitchPrevention(BattleEffectSwitchPreventionContext context) {
    final originBattler = context.state.combatants[origin];
    if (originBattler == null || originBattler.isFainted) {
      return null;
    }
    return PsdkBattleEffectIds.cantSwitch;
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final originBattler = context.state.combatants[origin];
    if (originBattler != null && !originBattler.isFainted) {
      return null;
    }
    return BattleEffectEndTurnResult(
      state: context.state.updateBattler(
        context.owner,
        (battler) => battler.copyWith(effects: battler.effects.remove(id)),
      ),
      rng: context.rng,
    );
  }
}
