import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../handler/battle_damage_handler.dart';
import '../../handler/battle_handler_context.dart';
import '../../move/battle_move_damage_calculator.dart';
import '../../move/battle_move_data.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

final class DelayedMoveEffect extends BattleEffect {
  const DelayedMoveEffect({
    required String id,
    required BattleEffectScope scope,
    required this.origin,
    required this.move,
    required int remainingTurns,
  }) : super(id: id, scope: scope, remainingTurns: remainingTurns);

  final PsdkBattleSlotRef origin;
  final BattleMoveDefinition move;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return DelayedMoveEffect(
      id: id,
      scope: scope,
      origin: origin,
      move: move,
      remainingTurns: remainingTurns,
    );
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final turns = remainingTurns;
    if (turns == null) {
      return null;
    }

    if (turns > 1) {
      final nextEffects = context.state
          .battlerAt(context.owner)
          .effects
          .addEffect(copyWithRemainingTurns(turns - 1));
      return BattleEffectEndTurnResult(
        state: context.state.updateBattler(
          context.owner,
          (battler) => battler.copyWith(effects: nextEffects),
        ),
        rng: context.rng,
      );
    }

    final clearedState = context.state.updateBattler(
      context.owner,
      (battler) => battler.copyWith(effects: battler.effects.remove(id)),
    );
    final targetBattler = clearedState.battlerAt(context.owner);
    final originBattler = clearedState.combatants[origin];
    if (targetBattler.isFainted || originBattler == null) {
      return BattleEffectEndTurnResult(state: clearedState, rng: context.rng);
    }

    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: originBattler,
        target: targetBattler,
        move: move,
        rng: context.rng,
        field: clearedState.field,
      ),
    );
    if (damageResult.damage <= 0) {
      return BattleEffectEndTurnResult(
        state: clearedState,
        rng: damageResult.rng,
      );
    }

    final damaged = const BattleDamageHandler().applyDamage(
      context: BattleHandlerContext(
        state: clearedState,
        rng: damageResult.rng,
        turn: context.turn,
        user: origin,
      ),
      target: context.owner,
      moveId: move.id,
      rawDamage: damageResult.damage,
      moveCategory: move.category,
    );
    return BattleEffectEndTurnResult(
      state: damaged.state,
      rng: damaged.rng,
      events: damaged.events,
    );
  }
}
