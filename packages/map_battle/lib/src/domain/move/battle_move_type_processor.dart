import '../../battle_type_chart.dart';
import '../../battle_typing.dart';
import '../../psdk/domain/psdk_battle_combatant.dart';

final class BattleMoveTypeProcessor {
  const BattleMoveTypeProcessor();

  double resolveStabMultiplier({
    required String moveType,
    required PsdkBattleTypes userTypes,
  }) {
    return BattleTypeChart.resolveStabMultiplier(
      moveType: moveType,
      attackerTyping: _typingSnapshot(userTypes),
    );
  }

  BattleTypeEffectivenessResult resolveEffectiveness({
    required String moveType,
    required PsdkBattleTypes targetTypes,
    bool forceGrounded = false,
  }) {
    final multiplier = forceGrounded && moveType.toLowerCase() == 'ground'
        ? _resolveGroundedGroundEffectiveness(targetTypes)
        : BattleTypeChart.resolveEffectivenessMultiplier(
            moveType: moveType,
            defenderTyping: _typingSnapshot(targetTypes),
          );
    return BattleTypeEffectivenessResult(multiplier: multiplier);
  }
}

double _resolveGroundedGroundEffectiveness(PsdkBattleTypes targetTypes) {
  var multiplier = 1.0;
  for (final type in <String>[
    targetTypes.primary,
    if (targetTypes.secondary != null) targetTypes.secondary!,
  ]) {
    final normalized = type.toLowerCase();
    if (normalized == 'flying') {
      continue;
    }
    multiplier *= BattleTypeChart.resolveEffectivenessMultiplier(
      moveType: 'ground',
      defenderTyping: BattleTypingSnapshot(primaryType: normalized),
    );
  }
  return multiplier;
}

final class BattleTypeEffectivenessResult {
  const BattleTypeEffectivenessResult({
    required this.multiplier,
  });

  final double multiplier;

  bool get isImmune => multiplier == 0.0;
}

BattleTypingSnapshot _typingSnapshot(PsdkBattleTypes types) {
  return BattleTypingSnapshot(
    primaryType: types.primary,
    secondaryType: types.secondary,
  );
}
