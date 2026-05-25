import '../../handler/battle_handler_context.dart';
import '../../handler/battle_stat_change_handler.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

final class OpportunistEffect extends BattleAbilityEffect {
  const OpportunistEffect({required BattleEffectScope scope})
      : super(abilityId: 'opportunist', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return OpportunistEffect(scope: scope);
  }

  @override
  BattleEffectStatChangePostResult? onStatChangePost(
    BattleEffectStatChangeContext context,
  ) {
    if (!isOwnedBy(context.owner) ||
        context.owner.bank == context.target.bank ||
        context.stages <= 0 ||
        context.sourceAbilityId == abilityId) {
      return null;
    }
    final owner = context.state.battlerAt(context.owner);
    if (owner.abilityId != abilityId || owner.isFainted) {
      return null;
    }

    final copied = const BattleStatChangeHandler().applyStatChange(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.owner,
      ),
      target: context.owner,
      stat: context.stat,
      stages: context.stages,
      sourceAbilityId: abilityId,
    );
    if (!copied.applied) {
      return null;
    }
    return BattleEffectStatChangePostResult(
      state: copied.state,
      rng: copied.rng,
      events: copied.events,
    );
  }
}
