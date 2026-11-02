import '../../battle_typing.dart';
import '../effect/ability/ability_effect.dart';
import '../../pokemon_battle_rules.dart';
import '../../psdk/domain/psdk_battle_combatant.dart';

final class BattleMoveTypeProcessor {
  const BattleMoveTypeProcessor();

  String resolveHiddenPowerType(PsdkBattleCombatant user) {
    var index = 0;
    final bits = <int>[
      user.ivHp & 1,
      user.ivAttack & 1,
      user.ivDefense & 1,
      user.ivSpeed & 1,
      user.ivSpecialAttack & 1,
      user.ivSpecialDefense & 1,
    ];
    for (var i = 0; i < bits.length; i++) {
      index += bits[i] << i;
    }
    final tableIndex = (index * (_hiddenPowerTypes.length - 1) / 63).floor();
    return _hiddenPowerTypes[tableIndex];
  }

  double resolveStabMultiplier({
    required PokemonBattleRules rules,
    required String moveType,
    required PsdkBattleTypes userTypes,
    PsdkBattleCombatant? user,
    Iterable<String> extraUserTypes = const <String>[],
  }) {
    final multiplier = rules.resolveStabMultiplier(
      moveType: moveType,
      attackerTyping: _typingSnapshot(userTypes),
    );
    final sameTypeMultiplier = user?.abilityEffects.fold(
          1.5,
          (current, effect) => effect.sameTypeAttackMultiplier > current
              ? effect.sameTypeAttackMultiplier
              : current,
        ) ??
        1.5;
    if (multiplier > 1) {
      return sameTypeMultiplier;
    }
    final normalizedMoveType = moveType.trim().toLowerCase();
    return extraUserTypes.any(
      (type) => type.trim().toLowerCase() == normalizedMoveType,
    )
        ? sameTypeMultiplier
        : multiplier;
  }

  BattleTypeEffectivenessResult resolveEffectiveness({
    required PokemonBattleRules rules,
    required String moveType,
    required PsdkBattleTypes targetTypes,
    PsdkBattleCombatant? user,
    Iterable<String> extraTargetTypes = const <String>[],
    bool forceGrounded = false,
    bool foresight = false,
    bool miracleEye = false,
    bool neutralizeFlyingWeaknesses = false,
  }) {
    final multiplier = _resolveEffectivenessMultiplier(
      moveType: moveType,
      targetTypes: targetTypes,
      extraTargetTypes: extraTargetTypes,
      forceGrounded: forceGrounded,
      foresight: foresight ||
          (user?.abilityEffects
                  .any((effect) => effect.ignoresGhostTypeImmunity) ??
              false),
      miracleEye: miracleEye,
      neutralizeFlyingWeaknesses: neutralizeFlyingWeaknesses,
      rules: rules,
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
  required bool neutralizeFlyingWeaknesses,
  required PokemonBattleRules rules,
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
      neutralizeFlyingWeaknesses: neutralizeFlyingWeaknesses,
    );
    if (overwrite != null) {
      multiplier *= overwrite;
      continue;
    }
    multiplier *= rules.resolveEffectivenessMultiplier(
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
  required bool neutralizeFlyingWeaknesses,
}) {
  if (neutralizeFlyingWeaknesses &&
      targetType == 'flying' &&
      _flyingWeaknessTypes.contains(moveType)) {
    return 1;
  }
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

const _flyingWeaknessTypes = <String>{'electric', 'ice', 'rock'};

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

const _hiddenPowerTypes = <String>[
  'fighting',
  'flying',
  'poison',
  'ground',
  'rock',
  'bug',
  'ghost',
  'steel',
  'fire',
  'water',
  'grass',
  'electric',
  'psychic',
  'ice',
  'dragon',
  'dark',
];
