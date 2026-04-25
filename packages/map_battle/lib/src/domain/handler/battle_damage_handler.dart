import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_timeline.dart';
import 'battle_handler_context.dart';
import 'battle_handler_result.dart';

final class BattleDamageHandler {
  const BattleDamageHandler();

  BattleHandlerResult applyDamage({
    required BattleHandlerContext context,
    required PsdkBattleSlotRef target,
    required String moveId,
    required int rawDamage,
  }) {
    final targetBattler = context.state.battlerAt(target);
    final damage = rawDamage.clamp(0, targetBattler.currentHp).toInt();
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

    return BattleHandlerResult(
      state: context.state.replaceBattler(target, nextTarget),
      rng: context.rng,
      amount: damage,
      events: <PsdkBattleEvent>[
        PsdkBattleDamageEvent(
          user: context.user,
          target: target,
          moveId: moveId,
          damage: damage,
          remainingHp: nextTarget.currentHp,
        ),
      ],
    );
  }
}
