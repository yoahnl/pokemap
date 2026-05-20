import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_item_change_handler.dart';
import '../../handler/battle_stat_change_handler.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import '../move/confusion_effect.dart';
import 'item_effect.dart';

final class BerserkGeneEffect extends BattleItemEffect {
  const BerserkGeneEffect({
    required BattleEffectScope scope,
  }) : super(itemId: 'berserk_gene', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return this;
  }

  @override
  BattleEffectSwitchEventResult? onSwitchEvent(
    BattleEffectSwitchEventContext context,
  ) {
    final owner = this.owner;
    if (owner == null ||
        context.owner != owner ||
        context.replacement != owner) {
      return null;
    }
    final holder = context.state.battlerAt(owner);
    if (holder.isFainted ||
        holder.heldItemId != itemId ||
        holder.itemConsumed ||
        holder.itemEffectsSuppressed) {
      return null;
    }

    final raised = const BattleStatChangeHandler().applyStatChange(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: owner,
      ),
      target: owner,
      stat: 'attack',
      stages: 2,
    );
    final consumed = const BattleItemChangeHandler().consumeHeldItem(
      context: BattleHandlerContext(
        state: raised.state,
        rng: raised.rng,
        turn: context.turn,
        user: owner,
      ),
      target: owner,
    );
    if (!consumed.applied) {
      return null;
    }

    var nextState = consumed.state;
    final events = <PsdkBattleEvent>[
      ...raised.events,
      ...consumed.events,
    ];
    if (!nextState.battlerAt(owner).effects.contains('confusion')) {
      nextState = nextState.updateBattler(
        owner,
        (current) => current.copyWith(
          effects: current.effects.addEffect(
            ConfusionEffect(
              scope: BattlerBattleEffectScope(owner),
              remainingConfusionTurns: 256,
            ),
          ),
        ),
      );
      events.add(
        PsdkBattleEffectEvent.added(
          turn: context.turn,
          target: owner,
          effectId: 'confusion',
          reason: 'item:berserk_gene',
        ),
      );
    }

    return BattleEffectSwitchEventResult(
      state: nextState,
      rng: consumed.rng,
      events: events,
      applied: raised.applied || consumed.applied,
    );
  }
}
