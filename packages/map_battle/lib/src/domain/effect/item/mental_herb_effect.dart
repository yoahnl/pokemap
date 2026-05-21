import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_item_change_handler.dart';
import '../../rng/battle_rng_streams.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'item_effect.dart';

final class MentalHerbEffect extends BattleItemEffect {
  const MentalHerbEffect({
    required BattleEffectScope scope,
  }) : super(itemId: 'mental_herb', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return this;
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final owner = this.owner;
    if (owner == null || context.owner != owner) {
      return null;
    }
    return _consumeAndRemoveFirstMentalEffect(
      state: context.state,
      rng: context.rng,
      turn: context.turn,
      owner: owner,
    );
  }

  @override
  BattleEffectVolatileStatusChangeResult? onPostVolatileStatusChange(
    BattleEffectVolatileStatusChangeContext context,
  ) {
    final owner = this.owner;
    if (owner == null ||
        context.owner != owner ||
        context.target != owner ||
        context.cured ||
        !_mentalEffectIds.contains(context.effectId)) {
      return null;
    }
    final result = _consumeAndRemoveFirstMentalEffect(
      state: context.state,
      rng: context.rng,
      turn: context.turn,
      owner: owner,
    );
    if (result == null) {
      return null;
    }
    return BattleEffectVolatileStatusChangeResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
      applied: result.applied,
    );
  }

  BattleEffectEndTurnResult? _consumeAndRemoveFirstMentalEffect({
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required int turn,
    required PsdkBattleSlotRef owner,
  }) {
    final battler = state.battlerAt(owner);
    if (battler.isFainted ||
        battler.heldItemId != itemId ||
        battler.itemConsumed ||
        battler.itemEffectsSuppressed) {
      return null;
    }
    final effectId = _firstMentalEffectId(battler.effects.values);
    if (effectId == null) {
      return null;
    }

    final consumed = const BattleItemChangeHandler().consumeHeldItem(
      context: BattleHandlerContext(
        state: state,
        rng: rng,
        turn: turn,
        user: owner,
      ),
      target: owner,
    );
    if (!consumed.applied) {
      return null;
    }

    return BattleEffectEndTurnResult(
      state: consumed.state.updateBattler(
        owner,
        (current) => current.copyWith(
          effects: current.effects.remove(effectId),
        ),
      ),
      rng: consumed.rng,
      events: <PsdkBattleEvent>[
        ...consumed.events,
        PsdkBattleEffectEvent.removed(
          turn: turn,
          target: owner,
          effectId: effectId,
          reason: 'item:$itemId',
        ),
      ],
    );
  }
}

String? _firstMentalEffectId(Iterable<String> effectIds) {
  for (final effectId in _mentalEffectIds) {
    if (effectIds.contains(effectId)) {
      return effectId;
    }
  }
  return null;
}

const _mentalEffectIds = <String>{
  'attract',
  'encore',
  'taunt',
  'torment',
  'heal_block',
  'disable',
};
