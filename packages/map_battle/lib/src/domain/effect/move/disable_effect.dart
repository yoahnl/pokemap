import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../move/battle_move_data.dart';
import '../../move/battle_move_prevention.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

final class DisableEffect extends BattleEffect {
  const DisableEffect({
    required BattleEffectScope scope,
    required this.disabledMoveId,
    int remainingTurns = 4,
  }) : super(
          id: 'disable',
          scope: scope,
          remainingTurns: remainingTurns,
        );

  final String disabledMoveId;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return DisableEffect(
      scope: scope,
      disabledMoveId: disabledMoveId,
      remainingTurns: remainingTurns,
    );
  }

  @override
  BattleEffectUserMovePreventionResult? onUserMovePrevention(
    BattleEffectUserMovePreventionContext context,
  ) {
    if (!_prevents(user: context.user, move: context.move)) {
      return null;
    }

    return BattleEffectUserMovePreventionResult(
      state: context.state,
      rng: context.rng,
      prevented: true,
      reason: BattleMoveFailureReason.unusableByUser,
    );
  }

  @override
  BattleMoveSelectionPreventionResult? onMoveSelectionPrevention(
    BattleMoveSelectionPreventionContext context,
  ) {
    if (!_prevents(user: context.user, move: context.move)) {
      return null;
    }

    return const BattleMoveSelectionPreventionResult(
      reason: BattleMoveFailureReason.unusableByUser,
    );
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final turns = remainingTurns;
    if (turns == null) {
      return null;
    }
    final nextEffects = turns <= 1
        ? context.state.battlerAt(context.owner).effects.remove(id)
        : context.state
            .battlerAt(context.owner)
            .effects
            .addEffect(copyWithRemainingTurns(turns - 1));
    return BattleEffectEndTurnResult(
      state: context.state.updateBattler(
        context.owner,
        (battler) => battler.copyWith(effects: nextEffects),
      ),
      rng: context.rng,
    );
  }

  bool _appliesTo(PsdkBattleSlotRef user) {
    final scope = this.scope;
    return scope is! BattlerBattleEffectScope || scope.slot == user;
  }

  bool _prevents({
    required PsdkBattleSlotRef user,
    required BattleMoveDefinition move,
  }) {
    return _appliesTo(user) && move.id == disabledMoveId;
  }
}
