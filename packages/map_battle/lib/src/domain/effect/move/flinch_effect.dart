import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../move/battle_move_prevention.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

final class FlinchEffect extends BattleEffect {
  const FlinchEffect({
    required BattleEffectScope scope,
  }) : super(
          id: 'flinch',
          scope: scope,
          remainingTurns: 0,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return FlinchEffect(scope: scope);
  }

  @override
  BattleEffectUserMovePreventionResult? onUserMovePrevention(
    BattleEffectUserMovePreventionContext context,
  ) {
    if (!_appliesTo(context.user)) {
      return null;
    }

    return BattleEffectUserMovePreventionResult(
      state: context.state,
      rng: context.rng,
      prevented: true,
      reason: BattleMoveFailureReason.unusableByUser,
    );
  }

  bool _appliesTo(PsdkBattleSlotRef user) {
    final scope = this.scope;
    return scope is! BattlerBattleEffectScope || scope.slot == user;
  }
}
