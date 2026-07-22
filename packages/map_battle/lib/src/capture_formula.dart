import 'battle_rng.dart';

/// The only capture item supported by FG-049.
///
/// Other ball ids are rejected instead of being assigned an inferred bonus.
const String canonicalPokeBallItemId = 'poke-ball';

/// Stable identifier for one capture attempt inside a battle session.
String battleCaptureAttemptId(int sequence) {
  RangeError.checkValueInInterval(sequence, 1, 0x7fffffff, 'sequence');
  return 'capture-attempt-$sequence';
}

/// Major-status families consumed by the MVP capture formula.
enum BattleCaptureStatus {
  none,
  paralysis,
  burn,
  poison,
  sleep,
  freeze,
}

/// Immutable result of one valid capture attempt.
final class BattleCaptureAttemptResult {
  const BattleCaptureAttemptResult({
    required this.caught,
    required this.chanceNumerator,
    required this.chanceDenominator,
    required this.nextRng,
  });

  final bool caught;
  final int chanceNumerator;
  final int chanceDenominator;
  final BattleRng nextRng;
}

/// Deterministic integer-only capture formula used by both battle engines.
///
/// FG-049 deliberately implements one documented MVP rule, not a claim of
/// generation-specific Pokemon parity:
///
/// ```text
/// hpFactor = 3 * maxHp - 2 * currentHp
/// chance   = hpFactor * catchRate * statusBonus / (3 * maxHp * 255)
/// ```
///
/// Status bonuses are exact rationals:
/// - sleep/freeze: `2/1`;
/// - burn/poison/paralysis: `3/2`;
/// - no status: `1/1`.
///
/// The canonical `poke-ball` multiplier is exactly `1/1`. The numerator is
/// clamped to the denominator, so high-rate/low-HP/status combinations can be
/// guaranteed. Every valid attempt consumes exactly one [BattleRng.nextChance]
/// draw, including a guaranteed attempt. Invalid inputs consume none because
/// validation happens before the RNG call.
final class BattleCaptureFormula {
  const BattleCaptureFormula();

  BattleCaptureAttemptResult attempt({
    required int targetCurrentHp,
    required int targetMaxHp,
    required int catchRate,
    required String ballId,
    required BattleCaptureStatus status,
    required BattleRng rng,
  }) {
    if (ballId != canonicalPokeBallItemId) {
      throw ArgumentError.value(
        ballId,
        'ballId',
        'FG-049 only supports the canonical poke-ball item id.',
      );
    }
    if (targetMaxHp < 1) {
      throw ArgumentError.value(
        targetMaxHp,
        'targetMaxHp',
        'must be positive',
      );
    }
    if (targetCurrentHp < 1 || targetCurrentHp > targetMaxHp) {
      throw ArgumentError.value(
        targetCurrentHp,
        'targetCurrentHp',
        'must be within 1..targetMaxHp for a capturable target',
      );
    }
    if (catchRate < 1 || catchRate > 255) {
      throw ArgumentError.value(
        catchRate,
        'catchRate',
        'must be within 1..255',
      );
    }

    final (:numerator, :denominator) = switch (status) {
      BattleCaptureStatus.sleep || BattleCaptureStatus.freeze => (
          numerator: 2,
          denominator: 1
        ),
      BattleCaptureStatus.burn ||
      BattleCaptureStatus.poison ||
      BattleCaptureStatus.paralysis =>
        (numerator: 3, denominator: 2),
      BattleCaptureStatus.none => (numerator: 1, denominator: 1),
    };
    final chanceDenominator = 3 * targetMaxHp * 255 * denominator;
    final rawNumerator =
        (3 * targetMaxHp - 2 * targetCurrentHp) * catchRate * numerator;
    final chanceNumerator = rawNumerator.clamp(0, chanceDenominator);
    final roll = rng.nextChance(
      numerator: chanceNumerator,
      denominator: chanceDenominator,
    );

    return BattleCaptureAttemptResult(
      caught: roll.didOccur,
      chanceNumerator: chanceNumerator,
      chanceDenominator: chanceDenominator,
      nextRng: roll.next,
    );
  }
}
