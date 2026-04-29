import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../handler/battle_damage_handler.dart';
import '../../handler/battle_handler_context.dart';
import '../../move/battle_move_prevention.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

final class PowderEffect extends BattleEffect {
  const PowderEffect({
    required BattleEffectScope scope,
    int remainingTurns = 0,
  }) : super(
          id: 'powder',
          scope: scope,
          remainingTurns: remainingTurns,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return PowderEffect(
      scope: scope,
      remainingTurns: remainingTurns,
    );
  }

  @override
  BattleEffectUserMovePreventionResult? onUserMovePrevention(
    BattleEffectUserMovePreventionContext context,
  ) {
    if (!_appliesTo(context.user) ||
        context.move.type.toLowerCase() != 'fire') {
      return null;
    }

    final user = context.state.battlerAt(context.user);
    final damage = (user.maxHp / 4).floor().clamp(1, user.maxHp).toInt();
    final result = const BattleDamageHandler().applyDamage(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.user,
      ),
      target: context.user,
      moveId: 'effect:powder',
      rawDamage: damage,
    );
    return BattleEffectUserMovePreventionResult(
      state: result.state,
      rng: result.rng,
      prevented: true,
      reason: BattleMoveFailureReason.unusableByUser,
      events: result.events,
    );
  }

  bool _appliesTo(PsdkBattleSlotRef user) {
    final scope = this.scope;
    return scope is! BattlerBattleEffectScope || scope.slot == user;
  }
}
