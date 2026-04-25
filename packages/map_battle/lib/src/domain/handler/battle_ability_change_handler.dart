import '../../psdk/domain/psdk_battle_slots.dart';
import 'battle_handler_context.dart';
import 'battle_handler_result.dart';

final class BattleAbilityChangeHandler {
  const BattleAbilityChangeHandler();

  BattleHandlerResult changeAbility({
    required BattleHandlerContext context,
    required PsdkBattleSlotRef target,
    required String? abilityId,
  }) {
    return BattleHandlerResult(
      state: context.state.updateBattler(
        target,
        (battler) => battler
            .copyWith(abilityId: abilityId)
            .withAbilityEffect(target),
      ),
      rng: context.rng,
    );
  }
}
