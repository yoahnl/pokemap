import '../../battle_type_chart.dart';
import '../../battle_typing.dart';
import '../../psdk/domain/psdk_battle_combatant.dart';

final class BattleMoveTypeProcessor {
  const BattleMoveTypeProcessor();

  double resolveStabMultiplier({
    required String moveType,
    required PsdkBattleTypes userTypes,
    Iterable<String> extraUserTypes = const <String>[],
  }) {
    final multiplier = BattleTypeChart.resolveStabMultiplier(
      moveType: moveType,
      attackerTyping: _typingSnapshot(userTypes),
    );
    if (multiplier > 1) {
      return multiplier;
    }
    final normalizedMoveType = moveType.trim().toLowerCase();
    return extraUserTypes.any(
      (type) => type.trim().toLowerCase() == normalizedMoveType,
    )
        ? 1.5
        : multiplier;
  }

  BattleTypeEffectivenessResult resolveEffectiveness({
    required String moveType,
    required PsdkBattleTypes targetTypes,
    Iterable<String> extraTargetTypes = const <String>[],
    bool forceGrounded = false,
    bool foresight = false,
    bool miracleEye = false,
  }) {
    final multiplier = _resolveEffectivenessMultiplier(
      moveType: moveType,
      targetTypes: targetTypes,
      extraTargetTypes: extraTargetTypes,
      forceGrounded: forceGrounded,
      foresight: foresight,
      miracleEye: miracleEye,
    );
    return BattleTypeEffectivenessResult(multiplier: multiplier);
  }
}

double _resolveEffectivenessMultiplier({
  required String moveType,
  required PsdkBattleTypes targetTypes,
  required Iterable<String> extraTargetTypes,
  required bool forceGrounded,
  required bool foresight,
  required bool miracleEye,
}) {
  final normalizedMoveType = moveType.toLowerCase();
  var multiplier = 1.0;
  for (final type in <String>[
    targetTypes.primary,
    if (targetTypes.secondary != null) targetTypes.secondary!,
    ...extraTargetTypes,
  ]) {
    final normalized = type.toLowerCase();
    final overwrite = _singleTypeMultiplierOverwrite(
      moveType: normalizedMoveType,
      targetType: normalized,
      forceGrounded: forceGrounded,
      foresight: foresight,
      miracleEye: miracleEye,
    );
    if (overwrite != null) {
      multiplier *= overwrite;
      continue;
    }
    multiplier *= BattleTypeChart.resolveEffectivenessMultiplier(
      moveType: normalizedMoveType,
      defenderTyping: BattleTypingSnapshot(primaryType: normalized),
    );
  }
  return multiplier;
}

double? _singleTypeMultiplierOverwrite({
  required String moveType,
  required String targetType,
  required bool forceGrounded,
  required bool foresight,
  required bool miracleEye,
}) {
  if (forceGrounded && moveType == 'ground' && targetType == 'flying') {
    return 1;
  }
  if (foresight &&
      targetType == 'ghost' &&
      (moveType == 'normal' || moveType == 'fighting')) {
    return 1;
  }
  if (miracleEye && targetType == 'dark' && moveType == 'psychic') {
    return 1;
  }
  return null;
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
