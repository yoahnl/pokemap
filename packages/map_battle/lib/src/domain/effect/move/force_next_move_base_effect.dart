import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../move/battle_move_prevention.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

final class ForceNextMoveBaseEffect extends BattleEffect {
  const ForceNextMoveBaseEffect({
    required BattleEffectScope scope,
    this.forcedMoveId,
    this.confuseOnRelease = false,
    int? remainingTurns,
  }) : super(
          id: PsdkBattleEffectIds.forceNextMoveBase,
          scope: scope,
          remainingTurns: remainingTurns,
        );

  const ForceNextMoveBaseEffect.locked({
    required BattleEffectScope scope,
    required String forcedMoveId,
    required int remainingTurns,
    bool confuseOnRelease = true,
  }) : this(
          scope: scope,
          forcedMoveId: forcedMoveId,
          confuseOnRelease: confuseOnRelease,
          remainingTurns: remainingTurns,
        );

  final String? forcedMoveId;
  final bool confuseOnRelease;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return ForceNextMoveBaseEffect(
      scope: scope,
      forcedMoveId: forcedMoveId,
      confuseOnRelease: confuseOnRelease,
      remainingTurns: remainingTurns,
    );
  }

  @override
  BattleEffectUserMovePreventionResult? onUserMovePrevention(
    BattleEffectUserMovePreventionContext context,
  ) {
    final forcedMove = forcedMoveId;
    if (forcedMove != null) {
      if (context.move.id == forcedMove) {
        return null;
      }
      return BattleEffectUserMovePreventionResult(
        state: context.state,
        rng: context.rng,
        prevented: true,
        reason: BattleMoveFailureReason.unusableByUser,
      );
    }

    return BattleEffectUserMovePreventionResult(
      state: context.state.updateBattler(
        context.user,
        (battler) => battler.copyWith(
          effects: battler.effects.remove(id),
        ),
      ),
      rng: context.rng,
      prevented: true,
      reason: BattleMoveFailureReason.unusableByUser,
      recordAttempt: false,
    );
  }

  @override
  BattleMoveSelectionPreventionResult? onMoveSelectionPrevention(
    BattleMoveSelectionPreventionContext context,
  ) {
    final forcedMove = forcedMoveId;
    if (forcedMove == null ||
        !_appliesTo(context.user) ||
        context.move.id == forcedMove) {
      return null;
    }

    return const BattleMoveSelectionPreventionResult(
      reason: BattleMoveFailureReason.unusableByUser,
    );
  }

  bool _appliesTo(PsdkBattleSlotRef user) {
    final scope = this.scope;
    return scope is! BattlerBattleEffectScope || scope.slot == user;
  }
}
