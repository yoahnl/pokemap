import '../../../psdk/domain/psdk_battle_move.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_status_change_handler.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

final class SynchronizeEffect extends BattleAbilityEffect {
  const SynchronizeEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'synchronize', scope: scope);

  static const _synchronizedStatuses = <PsdkBattleMajorStatus>{
    PsdkBattleMajorStatus.burn,
    PsdkBattleMajorStatus.paralysis,
    PsdkBattleMajorStatus.poison,
    PsdkBattleMajorStatus.toxic,
  };

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return SynchronizeEffect(scope: scope);
  }

  @override
  BattleEffectStatusChangeResult? onPostStatusChange(
    BattleEffectStatusChangeContext context,
  ) {
    if (context.cured ||
        context.owner != context.target ||
        context.user == context.target ||
        !_synchronizedStatuses.contains(context.status)) {
      return null;
    }
    final user = context.state.battlerAt(context.user);
    if (user.isFainted || user.majorStatus == context.status) {
      return null;
    }

    final result = const BattleStatusChangeHandler().applyMajorStatus(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.owner,
      ),
      target: context.user,
      moveId: 'ability:synchronize',
      status: context.status,
    );
    if (!result.applied && result.events.isEmpty) {
      return null;
    }
    return BattleEffectStatusChangeResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
    );
  }
}
