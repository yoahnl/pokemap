import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_damage_handler.dart';
import '../../handler/battle_handler_context.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

sealed class PledgeFieldEffect extends BattleEffect {
  const PledgeFieldEffect({
    required String id,
    required BattleEffectScope scope,
    required int remainingTurns,
  }) : super(id: id, scope: scope, remainingTurns: remainingTurns);

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final turns = remainingTurns;
    if (turns == null) {
      return null;
    }
    final nextRemainingTurns = turns - 1;
    final nextEffects = nextRemainingTurns <= 0
        ? context.state.battlerAt(context.owner).effects.remove(id)
        : context.state
            .battlerAt(context.owner)
            .effects
            .addEffect(copyWithRemainingTurns(nextRemainingTurns));
    return BattleEffectEndTurnResult(
      state: context.state.updateBattler(
        context.owner,
        (battler) => battler.copyWith(effects: nextEffects),
      ),
      rng: context.rng,
      events: <PsdkBattleEvent>[
        if (nextRemainingTurns <= 0)
          PsdkBattleEffectEvent.removed(
            turn: context.turn,
            target: context.owner,
            effectId: id,
            remainingTurns: 0,
            reason: 'expired',
          )
        else
          PsdkBattleEffectEvent.ticked(
            turn: context.turn,
            target: context.owner,
            effectId: id,
            remainingTurns: nextRemainingTurns,
            reason: 'duration_tick',
          ),
      ],
    );
  }
}

final class RainbowPledgeEffect extends PledgeFieldEffect {
  const RainbowPledgeEffect({
    required BattleEffectScope scope,
    int remainingTurns = 4,
  }) : super(
          id: 'pledge_rainbow',
          scope: scope,
          remainingTurns: remainingTurns,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return RainbowPledgeEffect(
      scope: scope,
      remainingTurns: remainingTurns,
    );
  }
}

final class SeaOfFirePledgeEffect extends PledgeFieldEffect {
  const SeaOfFirePledgeEffect({
    required BattleEffectScope scope,
    int remainingTurns = 4,
  }) : super(
          id: 'pledge_sea_of_fire',
          scope: scope,
          remainingTurns: remainingTurns,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return SeaOfFirePledgeEffect(
      scope: scope,
      remainingTurns: remainingTurns,
    );
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    var nextState = context.state;
    var nextRng = context.rng;
    final events = <PsdkBattleEvent>[];
    var applied = false;

    final bank = _bankFor(scope);
    if (bank != null) {
      for (final slot in context.state.aliveSlots()) {
        if (slot.bank != bank) {
          continue;
        }
        final battler = nextState.battlerAt(slot);
        if (battler.isFainted ||
            battler.hasType('fire') ||
            battler.abilityId == 'magic_guard') {
          continue;
        }

        final damage = (battler.maxHp ~/ 8).clamp(1, battler.currentHp).toInt();
        final result = const BattleDamageHandler().applyDamage(
          context: BattleHandlerContext(
            state: nextState,
            rng: nextRng,
            turn: context.turn,
            user: slot,
          ),
          target: slot,
          moveId: 'effect:sea_of_fire',
          rawDamage: damage,
        );
        nextState = result.state;
        nextRng = result.rng;
        events.addAll(result.events);
        applied = applied || result.applied || result.events.isNotEmpty;
      }
    }

    final tick = super.onEndTurn(
      BattleEffectEndTurnContext(
        state: nextState,
        rng: nextRng,
        turn: context.turn,
        owner: context.owner,
      ),
    );
    if (tick != null) {
      nextState = tick.state;
      nextRng = tick.rng;
      events.addAll(tick.events);
      applied = applied || tick.applied || tick.events.isNotEmpty;
    }

    return BattleEffectEndTurnResult(
      state: nextState,
      rng: nextRng,
      events: events,
      applied: applied,
    );
  }
}

final class SwampPledgeEffect extends PledgeFieldEffect {
  const SwampPledgeEffect({
    required BattleEffectScope scope,
    int remainingTurns = 4,
  }) : super(
          id: 'pledge_swamp',
          scope: scope,
          remainingTurns: remainingTurns,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return SwampPledgeEffect(
      scope: scope,
      remainingTurns: remainingTurns,
    );
  }
}

int? _bankFor(BattleEffectScope scope) {
  return switch (scope) {
    BankBattleEffectScope(:final bank) => bank,
    BattlerBattleEffectScope(:final slot) => slot.bank,
    _ => null,
  };
}
