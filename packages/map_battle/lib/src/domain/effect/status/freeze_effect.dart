import '../../../psdk/domain/psdk_battle_move.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import '../../move/battle_move_prevention.dart';
import 'status_effect_registry.dart';

final class FreezeEffect extends BattleMajorStatusEffect {
  const FreezeEffect({
    required BattleEffectScope scope,
  }) : super(id: 'freeze', scope: scope);

  @override
  PsdkBattleMajorStatus get status => PsdkBattleMajorStatus.freeze;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return FreezeEffect(scope: scope);
  }

  @override
  BattleEffectUserMovePreventionResult? onUserMovePrevention(
    BattleEffectUserMovePreventionContext context,
  ) {
    final battler = context.state.battlerAt(context.user);
    if (battler.majorStatus != status) {
      return null;
    }

    final roll = context.rng.generic.nextChance(numerator: 1, denominator: 5);
    final rng = context.rng.copyWith(generic: roll.next);
    if (roll.didOccur) {
      return BattleEffectUserMovePreventionResult(
        state: context.state.updateBattler(
          context.user,
          (current) => current.copyWith(
            clearMajorStatus: true,
            effects: current.effects.remove('freeze'),
          ),
        ),
        rng: rng,
        prevented: false,
        reason: BattleMoveFailureReason.unusableByUser,
      );
    }

    return BattleEffectUserMovePreventionResult(
      state: context.state,
      rng: rng,
      prevented: true,
      reason: BattleMoveFailureReason.unusableByUser,
    );
  }
}
