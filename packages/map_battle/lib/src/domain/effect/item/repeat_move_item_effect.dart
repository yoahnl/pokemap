import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'item_effect.dart';

final class MetronomeHeldItemEffect extends BattleItemEffect {
  const MetronomeHeldItemEffect({
    required BattleEffectScope scope,
  }) : super(itemId: 'metronome', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return this;
  }

  @override
  double damageFinalMultiplier(BattleItemDamageModifierContext context) {
    final user = context.user;
    if (user.heldItemId != itemId ||
        user.itemConsumed ||
        user.itemEffectsSuppressed) {
      return 1;
    }

    final consecutiveUseCount = _consecutiveSuccessfulUses(
      moveId: context.move.id,
      moveDbSymbol: context.move.dbSymbol,
      successfulMoveIds: user.moveHistory.successfulMoveIds,
    );
    if (consecutiveUseCount == 0) {
      return 1;
    }
    if (consecutiveUseCount >= 10) {
      return 2;
    }
    return 1 + consecutiveUseCount / 10.0;
  }
}

int _consecutiveSuccessfulUses({
  required String moveId,
  required String moveDbSymbol,
  required List<String> successfulMoveIds,
}) {
  var count = 0;
  for (final previousMoveId in successfulMoveIds.reversed) {
    if (!_sameMove(previousMoveId, moveId, moveDbSymbol)) {
      break;
    }
    count += 1;
  }
  return count;
}

bool _sameMove(String previousMoveId, String moveId, String moveDbSymbol) {
  final previous = _normalizedMoveId(previousMoveId);
  return previous == _normalizedMoveId(moveId) ||
      previous == _normalizedMoveId(moveDbSymbol);
}

String _normalizedMoveId(String moveId) {
  return moveId.trim().toLowerCase().replaceAll('-', '_');
}
