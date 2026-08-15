import '../rng/battle_rng_streams.dart';
import '../../pokemon_battle_rules.dart';
import 'battle_move_data.dart';

final class BattleMoveCriticalResolver {
  const BattleMoveCriticalResolver();

  BattleMoveCriticalResult resolve({
    required BattleMoveDefinition move,
    required BattleRngStreams rng,
    required PokemonBattleRules rules,
    int? criticalRate,
  }) {
    final chance = rules.criticalHitRule(criticalRate ?? move.criticalRate);
    if (chance.denominator == 1) {
      return BattleMoveCriticalResult(
        rng: rng,
        isCritical: chance.numerator == 1,
        multiplier: chance.numerator == 1 ? chance.damageMultiplier : 1.0,
      );
    }

    final roll = rng.moveCritical.nextChance(
      numerator: chance.numerator,
      denominator: chance.denominator,
    );
    return BattleMoveCriticalResult(
      rng: rng.copyWith(moveCritical: roll.next),
      isCritical: roll.didOccur,
      multiplier: roll.didOccur ? chance.damageMultiplier : 1.0,
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
