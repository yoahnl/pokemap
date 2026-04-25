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
  }) {
    final multiplier = BattleTypeChart.resolveEffectivenessMultiplier(
      moveType: moveType,
      defenderTyping: _typingSnapshot(targetTypes),
    );
    return BattleTypeEffectivenessResult(multiplier: multiplier);
  }
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
