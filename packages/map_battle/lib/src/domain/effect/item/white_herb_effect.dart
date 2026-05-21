import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_item_change_handler.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'item_effect.dart';

final class WhiteHerbEffect extends BattleItemEffect {
  const WhiteHerbEffect({
    required BattleEffectScope scope,
  }) : super(itemId: 'white_herb', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return this;
  }

  @override
  BattleEffectStatChangePostResult? onStatChangePost(
    BattleEffectStatChangeContext context,
  ) {
    final owner = this.owner;
    if (owner == null || context.owner != owner || context.target != owner) {
      return null;
    }

    final battler = context.state.battlerAt(owner);
    if (battler.isFainted ||
        battler.heldItemId != itemId ||
        battler.itemConsumed ||
        battler.itemEffectsSuppressed ||
        !_hasNegativeStage(battler)) {
      return null;
    }

    final resetState = context.state.updateBattler(
      owner,
      (current) => current.copyWith(
        statStages: _withoutNegativeStages(current.statStages),
      ),
    );
    final consumed = const BattleItemChangeHandler().consumeHeldItem(
      context: BattleHandlerContext(
        state: resetState,
        rng: context.rng,
        turn: context.turn,
        user: owner,
      ),
      target: owner,
    );
    if (!consumed.applied) {
      return null;
    }

    return BattleEffectStatChangePostResult(
      state: consumed.state,
      rng: consumed.rng,
      events: <PsdkBattleEvent>[...consumed.events],
    );
  }
}

bool _hasNegativeStage(PsdkBattleCombatant battler) {
  return battler.statStages.values.values.any((stage) => stage < 0);
}

PsdkBattleStatStages _withoutNegativeStages(PsdkBattleStatStages stages) {
  return PsdkBattleStatStages(
    values: <String, int>{
      for (final entry in stages.values.entries)
        entry.key: entry.value < 0 ? 0 : entry.value,
    },
  );
}
