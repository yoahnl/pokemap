import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_item_change_handler.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

final class BallFetchEffect extends BattleAbilityEffect {
  const BallFetchEffect({required BattleEffectScope scope})
      : super(abilityId: 'ball_fetch', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return BallFetchEffect(scope: scope);
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    if (!isOwnedBy(context.owner)) {
      return null;
    }
    final battler = context.state.battlerAt(context.owner);
    final ballId = context.state.field.lastBallUsedId;
    final eligibleSlots = context.state.field.ballFetchEligibleSlots;
    if (battler.abilityId != abilityId ||
        battler.isFainted ||
        battler.heldItemId != null ||
        ballId == null ||
        eligibleSlots.isEmpty ||
        eligibleSlots.first != context.owner) {
      return null;
    }

    final restored = const BattleItemChangeHandler().changeHeldItem(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.owner,
      ),
      target: context.owner,
      heldItemId: ballId,
    );
    final nextState = restored.state.copyWith(
      field: restored.state.field.clearBallFetch(),
    );
    return BattleEffectEndTurnResult(
      state: nextState,
      rng: restored.rng,
      events: <PsdkBattleEvent>[
        ...restored.events,
      ],
      applied: true,
    );
  }
}
