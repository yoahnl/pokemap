import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_item_change_handler.dart';
import '../../rng/battle_rng_streams.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'berry_item_effect.dart';
import 'item_effect.dart';

final class LansatBerryEffect extends BattleItemEffect {
  const LansatBerryEffect({
    required BattleEffectScope scope,
  }) : super(itemId: 'lansat_berry', scope: scope);

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
    return _trigger(
      state: context.state,
      rng: context.rng,
      turn: context.turn,
      owner: owner,
    );
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    final owner = this.owner;
    if (owner == null ||
        context.owner != owner ||
        context.target != owner ||
        context.damage <= 0) {
      return null;
    }
    final triggered = _trigger(
      state: context.state,
      rng: context.rng,
      turn: context.turn,
      owner: owner,
    );
    return triggered == null
        ? null
        : BattleEffectPostDamageResult(
            state: triggered.state,
            rng: triggered.rng,
            events: triggered.events,
            applied: triggered.applied,
          );
  }

  BattleEffectEndTurnResult? _trigger({
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required int turn,
    required PsdkBattleSlotRef owner,
  }) {
    final battler = state.battlerAt(owner);
    if (!_canConsume(state: state, owner: owner, battler: battler) ||
        !_isAtThreshold(battler) ||
        battler.effects.contains('lansat_berry')) {
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

    final nextState = consumed.state.updateBattler(
      owner,
      (current) =>
          current.copyWith(effects: current.effects.add('lansat_berry')),
    );
    return BattleEffectEndTurnResult(
      state: nextState,
      rng: consumed.rng,
      events: <PsdkBattleEvent>[
        ...consumed.events,
        PsdkBattleEffectEvent.added(
          turn: turn,
          target: owner,
          effectId: 'lansat_berry',
          reason: 'item:lansat_berry',
        ),
      ],
    );
  }

  bool _canConsume({
    required PsdkBattleState state,
    required PsdkBattleSlotRef owner,
    required PsdkBattleCombatant battler,
  }) {
    return !battler.isFainted &&
        battler.heldItemId == itemId &&
        !battler.itemConsumed &&
        !battler.itemEffectsSuppressed &&
        !psdkBerryBlockedByOpposingUnnerve(state: state, owner: owner);
  }

  bool _isAtThreshold(PsdkBattleCombatant battler) {
    final threshold = battler.abilityId == 'gluttony' ? 0.5 : 0.25;
    return battler.currentHp / battler.maxHp <= threshold;
  }
}

final class MicleBerryEffect extends BattleItemEffect {
  const MicleBerryEffect({
    required BattleEffectScope scope,
  }) : super(itemId: 'micle_berry', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return this;
  }

  @override
  double accuracyMultiplier(BattleItemAccuracyContext context) {
    final user = context.user;
    if (user.heldItemId != itemId ||
        user.itemConsumed ||
        user.itemEffectsSuppressed ||
        !_isAtThreshold(user)) {
      return 1;
    }
    return 1.5;
  }

  bool _isAtThreshold(PsdkBattleCombatant battler) {
    final threshold = battler.abilityId == 'gluttony' ? 0.5 : 0.25;
    return battler.currentHp / battler.maxHp <= threshold;
  }
}

final class LeppaBerryEffect extends BattleItemEffect {
  const LeppaBerryEffect({
    required BattleEffectScope scope,
  }) : super(itemId: 'leppa_berry', scope: scope);

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
    final battler = context.state.battlerAt(owner);
    if (!psdkCanConsumeBerry(state: context.state, owner: owner)) {
      return null;
    }

    final moveIndex = battler.moves.indexWhere((move) => move.currentPp == 0);
    if (moveIndex < 0) {
      return null;
    }

    final move = battler.moves[moveIndex];
    final restoredMove = move.copyWith(
      currentPp: (move.currentPp + 10).clamp(0, move.pp).toInt(),
    );
    final restoredState = context.state.updateBattler(
      owner,
      (current) => current.replaceMoveAt(moveIndex, restoredMove),
    );
    final consumed = const BattleItemChangeHandler().consumeHeldItem(
      context: BattleHandlerContext(
        state: restoredState,
        rng: context.rng,
        turn: context.turn,
        user: owner,
      ),
      target: owner,
    );
    if (!consumed.applied) {
      return null;
    }

    return BattleEffectEndTurnResult(
      state: consumed.state,
      rng: consumed.rng,
      events: consumed.events,
    );
  }
}
