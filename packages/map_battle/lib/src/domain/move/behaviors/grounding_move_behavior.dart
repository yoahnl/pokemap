import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../battler/battle_grounding_resolver.dart';
import '../../effect/battle_effect_scope.dart';
import '../../effect/move/smack_down_effect.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

final class GroundingMoveBehavior implements BattleMoveBehavior {
  const GroundingMoveBehavior.smackDown() : battleEngineMethod = 's_smack_down';

  @override
  final String battleEngineMethod;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: user,
        target: target,
        move: context.move,
        rng: prepared.rng,
      ),
    );
    if (damageResult.damage <= 0) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: damageResult.rng,
        events: prepared.events,
      );
    }

    final applied = applyDirectDamage(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      rng: damageResult.rng,
      turn: context.turn,
      amount: damageResult.damage,
    );
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: applied.state,
      rng: applied.rng,
      user: context.user,
      target: targetSlot,
      move: context.move,
      turn: context.turn,
    );
    final nextState = _applySmackDownEffect(
      state: secondary.state,
      targetSlot: targetSlot,
    );

    return BattleMoveBehaviorResolution(
      state: nextState,
      rng: secondary.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        if (applied.event != null) applied.event!,
        ...secondary.events,
      ],
    );
  }
}

PsdkBattleState _applySmackDownEffect({
  required PsdkBattleState state,
  required PsdkBattleSlotRef targetSlot,
}) {
  final target = state.battlerAt(targetSlot);
  if (target.isFainted ||
      target.effects.contains('smack_down') ||
      target.effects.contains('ingrain') ||
      target.heldItemId == 'iron_ball' ||
      const BattleGroundingResolver().isGrounded(target)) {
    return state;
  }

  return state.updateBattler(
    targetSlot,
    (battler) => battler.copyWith(
      effects: battler.effects.addEffect(
        SmackDownEffect(scope: BattlerBattleEffectScope(targetSlot)),
      ),
    ),
  );
}
