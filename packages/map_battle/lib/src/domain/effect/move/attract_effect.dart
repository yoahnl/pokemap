import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../move/battle_move_prevention.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

final class AttractEffect extends BattleEffect {
  const AttractEffect({
    required BattleEffectScope scope,
    this.attractedTo,
  }) : super(
          id: 'attract',
          scope: scope,
        );

  final PsdkBattleSlotRef? attractedTo;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return AttractEffect(
      scope: scope,
      attractedTo: attractedTo,
    );
  }

  @override
  BattleEffectUserMovePreventionResult? onUserMovePrevention(
    BattleEffectUserMovePreventionContext context,
  ) {
    final target = attractedTo;
    if (!_appliesTo(context.user) ||
        target == null ||
        context.target != target) {
      return null;
    }

    final roll = context.rng.generic.nextChance(
      numerator: 1,
      denominator: 2,
    );
    final nextRng = context.rng.copyWith(generic: roll.next);
    if (!roll.didOccur) {
      return BattleEffectUserMovePreventionResult(
        state: context.state,
        rng: nextRng,
        prevented: false,
        reason: BattleMoveFailureReason.unusableByUser,
      );
    }

    return BattleEffectUserMovePreventionResult(
      state: context.state,
      rng: nextRng,
      prevented: true,
      reason: BattleMoveFailureReason.unusableByUser,
    );
  }

  bool _appliesTo(PsdkBattleSlotRef user) {
    final scope = this.scope;
    return scope is! BattlerBattleEffectScope || scope.slot == user;
  }
}
