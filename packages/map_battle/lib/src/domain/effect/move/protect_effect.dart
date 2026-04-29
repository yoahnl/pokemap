import '../../move/battle_move_prevention.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

/// PSDK Protect effect object.
///
/// This ports only the common Protect target-prevention hook. PSDK variants
/// such as Spiky Shield, King's Shield, Baneful Bunker, Mat Block, Unseen Fist
/// bypass and success-rate decay remain explicit future lots.
final class ProtectEffect extends BattleEffect {
  const ProtectEffect({
    required BattleEffectScope scope,
  }) : super(
          id: 'protect',
          scope: scope,
          remainingTurns: 0,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return ProtectEffect(scope: scope);
  }

  @override
  BattleMoveFailureReason? onMovePreventionTarget(
    BattleEffectMoveContext context,
  ) {
    if (context.user == context.target || !context.move.flags.protectable) {
      return null;
    }

    final scope = this.scope;
    if (scope is BattlerBattleEffectScope) {
      final protectedSlot = scope.slot;
      if (protectedSlot.bank != context.target.bank ||
          protectedSlot.position != context.target.position) {
        return null;
      }
    }

    return BattleMoveFailureReason.protected;
  }
}
