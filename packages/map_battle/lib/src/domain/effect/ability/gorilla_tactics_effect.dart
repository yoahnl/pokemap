import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../move/battle_move_data.dart';
import '../../move/battle_move_prevention.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

final class GorillaTacticsEffect extends BattleAbilityEffect {
  const GorillaTacticsEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'gorilla_tactics', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return GorillaTacticsEffect(scope: scope);
  }

  @override
  BattleEffectUserMovePreventionResult? onUserMovePrevention(
    BattleEffectUserMovePreventionContext context,
  ) {
    final user = context.state.battlerAt(context.user);
    if (_canUseMove(user, context.move)) {
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
    final user = context.state.battlerAt(context.user);
    if (_canUseMove(user, context.move)) {
      return null;
    }
    return const BattleMoveSelectionPreventionResult(
      reason: BattleMoveFailureReason.unusableByUser,
    );
  }

  @override
  double statMultiplier(BattleAbilityStatContext context) {
    if (!_isOwner(context.battler) || context.stat != 'attack') {
      return 1;
    }
    return 1.5;
  }

  bool _canUseMove(PsdkBattleCombatant user, BattleMoveDefinition move) {
    if (!_isOwner(user)) {
      return true;
    }
    if (_isStruggle(move.id) || _isStruggle(move.dbSymbol)) {
      return true;
    }
    final lastMove = _lastNonStruggleAttempt(user);
    if (lastMove == null) {
      return true;
    }
    final lastSentTurn = user.lastSentTurn;
    if (lastSentTurn != null && lastMove.turn < lastSentTurn) {
      return true;
    }
    return _sameMove(lastMove.moveId, move);
  }

  bool _isOwner(PsdkBattleCombatant battler) {
    return battler.abilityId == abilityId &&
        !battler.effects.contains('ability_suppressed');
  }
}

PsdkBattleMoveHistoryEntry? _lastNonStruggleAttempt(
  PsdkBattleCombatant battler,
) {
  for (final entry in battler.moveHistory.attempts.reversed) {
    if (!_isStruggle(entry.moveId)) {
      return entry;
    }
  }
  return null;
}

bool _sameMove(String lockedMoveId, BattleMoveDefinition move) {
  final locked = _normalizedMoveId(lockedMoveId);
  return locked == _normalizedMoveId(move.id) ||
      locked == _normalizedMoveId(move.dbSymbol);
}

bool _isStruggle(String moveId) {
  return _normalizedMoveId(moveId) == 'struggle';
}

String _normalizedMoveId(String moveId) {
  return moveId.trim().toLowerCase().replaceAll('-', '_');
}
