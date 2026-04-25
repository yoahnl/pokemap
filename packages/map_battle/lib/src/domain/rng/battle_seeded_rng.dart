/// Deterministic RNG stream used by the clean PSDK battle lane.
///
/// The legacy engine already exports `BattleSeededRng` from `src/battle_rng.dart`.
/// This type is intentionally named `BattleRngStream` so the migration can add
/// PSDK-style streams without shadowing the old public RNG seam.
final class BattleRngStream {
  const BattleRngStream({
    required this.seed,
  });

  final int seed;

  BattleRngStreamRoll nextPercent() {
    return BattleRngStreamRoll(
      value: (seed.abs() % 100) + 1,
      next: BattleRngStream(seed: _nextSeed(seed)),
    );
  }

  BattleRngStreamRoll nextDamagePercent() {
    final roll = nextPercent();
    return BattleRngStreamRoll(
      value: 85 + (roll.value % 16),
      next: roll.next,
    );
  }

  BattleRngStreamRoll nextIntInclusive({
    required int min,
    required int max,
  }) {
    if (max < min) {
      throw RangeError.range(max, min, null, 'max');
    }
    final span = max - min + 1;
    return BattleRngStreamRoll(
      value: min + (seed.abs() % span),
      next: BattleRngStream(seed: _nextSeed(seed)),
    );
  }

  BattleRngChanceRoll nextChance({
    required int numerator,
    required int denominator,
  }) {
    if (denominator < 1 || numerator < 0 || numerator > denominator) {
      throw RangeError(
        'Invalid battle RNG chance contract: $numerator/$denominator.',
      );
    }
    final roll = nextIntInclusive(min: 1, max: denominator);
    return BattleRngChanceRoll(
      didOccur: roll.value <= numerator,
      next: roll.next,
    );
  }
}

final class BattleRngStreamRoll {
  const BattleRngStreamRoll({
    required this.value,
    required this.next,
  });

  final int value;
  final BattleRngStream next;
}

final class BattleRngChanceRoll {
  const BattleRngChanceRoll({
    required this.didOccur,
    required this.next,
  });

  final bool didOccur;
  final BattleRngStream next;
}

int _nextSeed(int seed) {
  return (1664525 * seed + 1013904223) & 0x7FFFFFFF;
}
