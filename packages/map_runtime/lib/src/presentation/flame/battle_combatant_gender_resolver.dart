final class BattleCombatantGenderResolver {
  const BattleCombatantGenderResolver({
    this.playerLineupGenderIdsByIndex = const <int, String>{},
    this.enemyLineupGenderIdsByIndex = const <int, String>{},
  });

  final Map<int, String> playerLineupGenderIdsByIndex;
  final Map<int, String> enemyLineupGenderIdsByIndex;

  String? resolveGenderId({
    required bool isPlayerSide,
    required int lineupIndex,
  }) {
    final rawGenderId = (isPlayerSide
            ? playerLineupGenderIdsByIndex
            : enemyLineupGenderIdsByIndex)[lineupIndex];
    return normalizeBattleGenderId(rawGenderId);
  }

  String? resolveGenderSymbol({
    required bool isPlayerSide,
    required int lineupIndex,
  }) {
    return battleGenderSymbolFor(
      resolveGenderId(
        isPlayerSide: isPlayerSide,
        lineupIndex: lineupIndex,
      ),
    );
  }
}

String? normalizeBattleGenderId(String? rawGenderId) {
  final normalized = rawGenderId?.trim().toLowerCase() ?? '';
  return switch (normalized) {
    'male' || 'm' || '♂' => 'male',
    'female' || 'f' || '♀' => 'female',
    'genderless' || 'neutral' || 'none' || '∅' => 'genderless',
    _ => null,
  };
}

String? battleGenderSymbolFor(String? genderId) {
  return switch (normalizeBattleGenderId(genderId)) {
    'male' => '♂',
    'female' => '♀',
    'genderless' => '∅',
    _ => null,
  };
}

String? resolveBattleGenderIdFromRatios({
  required double? maleRatio,
  required double? femaleRatio,
  String? stableSeed,
}) {
  final safeMaleRatio = maleRatio ?? 0.0;
  final safeFemaleRatio = femaleRatio ?? 0.0;
  final ratioTotal = safeMaleRatio + safeFemaleRatio;
  if (ratioTotal <= 0) {
    return 'genderless';
  }
  if (safeMaleRatio > 0 && safeFemaleRatio <= 0) {
    return 'male';
  }
  if (safeFemaleRatio > 0 && safeMaleRatio <= 0) {
    return 'female';
  }
  if (stableSeed == null || stableSeed.trim().isEmpty) {
    return null;
  }
  final normalizedMaleRatio = safeMaleRatio / ratioTotal;
  return _stableUnitInterval(stableSeed) < normalizedMaleRatio
      ? 'male'
      : 'female';
}

double _stableUnitInterval(String seed) {
  var hash = 0;
  for (final codeUnit in seed.codeUnits) {
    hash = ((hash * 31) + codeUnit) & 0x7fffffff;
  }
  return (hash % 10000) / 10000.0;
}
