import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../move/battle_move_data.dart';
import '../../move/battle_move_prevention.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

final class RolloutEffect extends BattleEffect {
  const RolloutEffect({
    required BattleEffectScope scope,
    required this.forcedMoveId,
    required int remainingTurns,
    required this.successiveUses,
  }) : super(
          id: 'rollout',
          scope: scope,
          remainingTurns: remainingTurns,
        );

  final String forcedMoveId;
  final int successiveUses;

  int get remainingTurnsAfterCurrent => remainingTurns ?? 0;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return RolloutEffect(
      scope: scope,
      forcedMoveId: forcedMoveId,
      remainingTurns: remainingTurns,
      successiveUses: successiveUses,
    );
  }

  RolloutEffect afterSuccessfulUse() {
    return RolloutEffect(
      scope: scope,
      forcedMoveId: forcedMoveId,
      remainingTurns: remainingTurnsAfterCurrent - 1,
      successiveUses: successiveUses + 1,
    );
  }

  @override
  BattleEffectUserMovePreventionResult? onUserMovePrevention(
    BattleEffectUserMovePreventionContext context,
  ) {
    if (!_appliesTo(context.user) || _sameMove(context.move)) {
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
    if (!_appliesTo(context.user) || _sameMove(context.move)) {
      return null;
    }
    return const BattleMoveSelectionPreventionResult(
      reason: BattleMoveFailureReason.unusableByUser,
    );
  }

  bool _sameMove(BattleMoveDefinition move) {
    final forced = _normalizedId(forcedMoveId);
    return _normalizedId(move.id) == forced ||
        _normalizedId(move.dbSymbol) == forced;
  }

  bool _appliesTo(PsdkBattleSlotRef user) {
    final scope = this.scope;
    return scope is! BattlerBattleEffectScope || scope.slot == user;
  }
}

String _normalizedId(String? id) {
  return id?.trim().toLowerCase().replaceAll('-', '_') ?? '';
}
