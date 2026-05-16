import '../../../psdk/domain/psdk_battle_move.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import '../../move/battle_move_prevention.dart';
import 'status_effect_registry.dart';

final class ParalysisEffect extends BattleMajorStatusEffect {
  const ParalysisEffect({
    required BattleEffectScope scope,
  }) : super(id: 'paralysis', scope: scope);

  @override
  PsdkBattleMajorStatus get status => PsdkBattleMajorStatus.paralysis;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return ParalysisEffect(scope: scope);
  }

  @override
  BattleEffectUserMovePreventionResult? onUserMovePrevention(
    BattleEffectUserMovePreventionContext context,
  ) {
    final battler = context.state.battlerAt(context.user);
    if (battler.majorStatus != status) {
      return null;
    }

    final roll = context.rng.generic.nextChance(numerator: 1, denominator: 4);
    return BattleEffectUserMovePreventionResult(
      state: context.state,
      rng: context.rng.copyWith(generic: roll.next),
      prevented: roll.didOccur,
      reason: BattleMoveFailureReason.unusableByUser,
    );
  }
}
