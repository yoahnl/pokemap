import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../move/battle_move_prevention.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

final class ImprisonEffect extends BattleEffect {
  ImprisonEffect({
    required BattleEffectScope scope,
    Iterable<String> imprisonedMoveIds = const <String>[],
  })  : _imprisonedMoveIds = Set<String>.unmodifiable(imprisonedMoveIds),
        super(
          id: 'imprison',
          scope: scope,
        );

  final Set<String> _imprisonedMoveIds;

  Set<String> get imprisonedMoveIds => _imprisonedMoveIds;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return ImprisonEffect(
      scope: scope,
      imprisonedMoveIds: _imprisonedMoveIds,
    );
  }

  @override
  BattleEffectUserMovePreventionResult? onUserMovePrevention(
    BattleEffectUserMovePreventionContext context,
  ) {
    if (!_prevents(user: context.user, moveId: context.move.id)) {
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
    if (!_prevents(user: context.user, moveId: context.move.id)) {
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

  bool _prevents({
    required PsdkBattleSlotRef user,
    required String moveId,
  }) {
    return _appliesTo(user) &&
        moveId != 'struggle' &&
        _imprisonedMoveIds.contains(moveId);
  }
}
