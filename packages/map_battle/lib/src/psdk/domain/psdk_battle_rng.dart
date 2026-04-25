/// Seeds for the independent PSDK-style random streams.
///
/// PSDK separates damage, critical, accuracy and generic randomness. This first
/// tranche only consumes damage, accuracy and generic, but keeps the critical
/// seed present so the public setup shape will not change when critical hits
/// are ported.
class PsdkBattleRngSeeds {
  const PsdkBattleRngSeeds({
    required this.moveDamage,
    required this.moveCritical,
    required this.moveAccuracy,
    required this.generic,
  });

  final int moveDamage;
  final int moveCritical;
  final int moveAccuracy;
  final int generic;
}

class PsdkBattleRngStreams {
  const PsdkBattleRngStreams({
    required this.moveDamage,
    required this.moveCritical,
    required this.moveAccuracy,
    required this.generic,
  });

  factory PsdkBattleRngStreams.fromSeeds(PsdkBattleRngSeeds seeds) {
    return PsdkBattleRngStreams(
      moveDamage: PsdkBattleRngStream(seed: seeds.moveDamage),
      moveCritical: PsdkBattleRngStream(seed: seeds.moveCritical),
      moveAccuracy: PsdkBattleRngStream(seed: seeds.moveAccuracy),
      generic: PsdkBattleRngStream(seed: seeds.generic),
    );
  }

  final PsdkBattleRngStream moveDamage;
  final PsdkBattleRngStream moveCritical;
  final PsdkBattleRngStream moveAccuracy;
  final PsdkBattleRngStream generic;

  PsdkBattleRngStreams copyWith({
    PsdkBattleRngStream? moveDamage,
    PsdkBattleRngStream? moveCritical,
    PsdkBattleRngStream? moveAccuracy,
    PsdkBattleRngStream? generic,
  }) {
    return PsdkBattleRngStreams(
      moveDamage: moveDamage ?? this.moveDamage,
      moveCritical: moveCritical ?? this.moveCritical,
      moveAccuracy: moveAccuracy ?? this.moveAccuracy,
      generic: generic ?? this.generic,
    );
  }
}

class PsdkBattleRngStream {
  const PsdkBattleRngStream({
    required this.seed,
  });

  final int seed;

  PsdkBattleRngRoll nextPercent() {
    return PsdkBattleRngRoll(
      value: (seed.abs() % 100) + 1,
      next: PsdkBattleRngStream(seed: _nextSeed(seed)),
    );
  }

  PsdkBattleRngRoll nextDamagePercent() {
    final roll = nextPercent();
    return PsdkBattleRngRoll(
      value: 85 + (roll.value % 16),
      next: roll.next,
    );
  }
}

class PsdkBattleRngRoll {
  const PsdkBattleRngRoll({
    required this.value,
    required this.next,
  });

  final int value;
  final PsdkBattleRngStream next;
}

int _nextSeed(int seed) {
  return (1664525 * seed + 1013904223) & 0x7FFFFFFF;
}
