import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_status_change_handler.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

/// PSDK `BeakBlast` preparation effect.
///
/// Ruby installs this before normal attacks, then burns contact attackers that
/// hit the preparing Pokemon before Beak Blast itself has been attempted. The
/// effect stays turn-scoped so end-turn cleanup remains handled by the generic
/// lifecycle instead of inventing a second one-action timer here.
final class BeakBlastEffect extends BattleEffect {
  const BeakBlastEffect({
    required BattleEffectScope scope,
    int remainingTurns = 0,
  }) : super(
          id: 'beak_blast',
          scope: scope,
          remainingTurns: remainingTurns,
        );

  @override
  bool get preparingAttack => true;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return BeakBlastEffect(
      scope: scope,
      remainingTurns: remainingTurns,
    );
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (!_appliesTo(context.owner) ||
        context.owner != context.target ||
        context.user == context.owner ||
        context.damage <= 0 ||
        !context.move.flags.contact ||
        _ownerAlreadyAttemptedMove(context)) {
      return null;
    }

    final attacker = context.state.battlerAt(context.user);
    if (attacker.isFainted) {
      return null;
    }

    final status = const BattleStatusChangeHandler().applyMajorStatus(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.owner,
      ),
      target: context.user,
      moveId: 'effect:beak_blast',
      status: PsdkBattleMajorStatus.burn,
      move: context.move,
    );
    if (!status.applied) {
      return null;
    }
    return BattleEffectPostDamageResult(
      state: status.state,
      rng: status.rng,
      events: status.events,
    );
  }

  bool _appliesTo(PsdkBattleSlotRef owner) {
    final effectScope = scope;
    return effectScope is! BattlerBattleEffectScope ||
        effectScope.slot == owner;
  }

  bool _ownerAlreadyAttemptedMove(BattleEffectPostDamageContext context) {
    return context.state.battlerAt(context.owner).moveHistory.attempts.any(
          (entry) => entry.turn == context.turn,
        );
  }
}
