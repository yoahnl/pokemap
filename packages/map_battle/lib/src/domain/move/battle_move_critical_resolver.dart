import '../rng/battle_rng_streams.dart';
import 'battle_move_data.dart';

const double _criticalDamageMultiplier = 1.5;

final class BattleMoveCriticalResolver {
  const BattleMoveCriticalResolver();

  BattleMoveCriticalResult resolve({
    required BattleMoveDefinition move,
    required BattleRngStreams rng,
  }) {
    final chance = _criticalChance(move.criticalRate);
    if (chance.denominator == 1) {
      return BattleMoveCriticalResult(
        rng: rng,
        isCritical: chance.numerator == 1,
        multiplier: chance.numerator == 1 ? _criticalDamageMultiplier : 1.0,
      );
    }

    final roll = rng.moveCritical.nextChance(
      numerator: chance.numerator,
      denominator: chance.denominator,
    );
    return BattleMoveCriticalResult(
      rng: rng.copyWith(moveCritical: roll.next),
      isCritical: roll.didOccur,
      multiplier: roll.didOccur ? _criticalDamageMultiplier : 1.0,
    );
  }
}

final class BattleMoveCriticalResult {
  const BattleMoveCriticalResult({
    required this.rng,
    required this.isCritical,
    required this.multiplier,
  });

  final BattleRngStreams rng;
  final bool isCritical;
  final double multiplier;
}

({int numerator, int denominator}) _criticalChance(int criticalRate) {
  if (criticalRate <= 0) {
    return (numerator: 0, denominator: 1);
  }
  return switch (criticalRate) {
    1 => (numerator: 6250, denominator: 100000),
    2 => (numerator: 12500, denominator: 100000),
    3 => (numerator: 50000, denominator: 100000),
    _ => (numerator: 1, denominator: 1),
  };
}
