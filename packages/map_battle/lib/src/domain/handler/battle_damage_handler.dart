import '../../psdk/domain/psdk_battle_state.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_timeline.dart';
import 'battle_handler_context.dart';
import 'battle_handler_result.dart';
import 'battle_stat_change_handler.dart';

final class BattleDamageHandler {
  const BattleDamageHandler();

  BattleHandlerResult applyDamage({
    required BattleHandlerContext context,
    required PsdkBattleSlotRef target,
    required String moveId,
    required int rawDamage,
  }) {
    final targetBattler = context.state.battlerAt(target);
    final incomingDamage = rawDamage.clamp(0, targetBattler.currentHp).toInt();
    final damage = targetBattler.effects.contains('endure') &&
            incomingDamage >= targetBattler.currentHp
        ? (targetBattler.currentHp - 1)
            .clamp(0, targetBattler.currentHp)
            .toInt()
        : incomingDamage;
    if (damage <= 0) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: 'zero_damage',
      );
    }

    final remainingHp = targetBattler.currentHp - damage;
    final nextTarget = targetBattler
        .recordDamage(
          turn: context.turn,
          source: context.user,
          moveId: moveId,
          damage: damage,
          remainingHp: remainingHp,
        )
        .copyWith(currentHp: remainingHp);

    final damagedState = context.state.replaceBattler(target, nextTarget);
    final damageEvent = PsdkBattleDamageEvent(
      user: context.user,
      target: target,
      moveId: moveId,
      damage: damage,
      remainingHp: nextTarget.currentHp,
    );
    final rageResult = _applyRageCounterIfNeeded(
      context: context,
      state: damagedState,
      target: target,
    );

    return BattleHandlerResult(
      state: rageResult.state,
      rng: context.rng,
      amount: damage,
      events: <PsdkBattleEvent>[
        damageEvent,
        ...rageResult.events,
      ],
    );
  }

  BattleHandlerResult _applyRageCounterIfNeeded({
    required BattleHandlerContext context,
    required PsdkBattleState state,
    required PsdkBattleSlotRef target,
  }) {
    if (context.user.bank == target.bank) {
      return BattleHandlerResult(state: state, rng: context.rng);
    }

    final targetBattler = state.battlerAt(target);
    if (!targetBattler.effects.contains('rage')) {
      return BattleHandlerResult(state: state, rng: context.rng);
    }

    return const BattleStatChangeHandler().applyStatChange(
      context: BattleHandlerContext(
        state: state,
        rng: context.rng,
        turn: context.turn,
        user: context.user,
      ),
      target: target,
      stat: 'attack',
      stages: 1,
    );
  }
}
