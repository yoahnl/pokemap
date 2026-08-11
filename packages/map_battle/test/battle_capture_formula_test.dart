import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('BattleCaptureFormula', () {
    test('uses the documented exact HP/rate rational with one RNG draw', () {
      final result = const BattleCaptureFormula().attempt(
        targetCurrentHp: 100,
        targetMaxHp: 100,
        catchRate: 1,
        ballId: 'plain-orb',
        ballRateNumerator: 1,
        ballRateDenominator: 1,
        status: BattleCaptureStatus.none,
        rng: const BattleScriptedRng(<int>[1]),
      );

      expect(result.chanceNumerator, 100);
      expect(result.chanceDenominator, 76500);
      expect(result.caught, isTrue);
      expect((result.nextRng as BattleScriptedRng).index, 1);
    });

    test('applies a selected synthetic ball ratio without knowing its id', () {
      const formula = BattleCaptureFormula();
      final plain = formula.attempt(
        targetCurrentHp: 100,
        targetMaxHp: 100,
        catchRate: 1,
        ballId: 'plain-orb',
        ballRateNumerator: 1,
        ballRateDenominator: 1,
        status: BattleCaptureStatus.none,
        rng: const BattleScriptedRng(<int>[1]),
      );
      final boosted = formula.attempt(
        targetCurrentHp: 100,
        targetMaxHp: 100,
        catchRate: 1,
        ballId: 'aurora-orb',
        ballRateNumerator: 5,
        ballRateDenominator: 2,
        status: BattleCaptureStatus.none,
        rng: const BattleScriptedRng(<int>[1]),
      );

      expect(
        boosted.chanceNumerator * plain.chanceDenominator,
        greaterThan(plain.chanceNumerator * boosted.chanceDenominator),
      );
    });

    test('low HP improves capture without floating-point rounding', () {
      final result = const BattleCaptureFormula().attempt(
        targetCurrentHp: 1,
        targetMaxHp: 100,
        catchRate: 255,
        ballId: 'plain-orb',
        ballRateNumerator: 1,
        ballRateDenominator: 1,
        status: BattleCaptureStatus.none,
        rng: const BattleScriptedRng(<int>[76000]),
      );

      expect(result.chanceNumerator, 75990);
      expect(result.chanceDenominator, 76500);
      expect(result.caught, isFalse);
    });

    test('sleep and freeze have a stronger bonus than other major statuses',
        () {
      const formula = BattleCaptureFormula();
      BattleCaptureAttemptResult attempt(BattleCaptureStatus status) {
        return formula.attempt(
          targetCurrentHp: 50,
          targetMaxHp: 100,
          catchRate: 100,
          ballId: 'plain-orb',
          ballRateNumerator: 1,
          ballRateDenominator: 1,
          status: status,
          rng: const BattleScriptedRng(<int>[1]),
        );
      }

      final none = attempt(BattleCaptureStatus.none);
      final burned = attempt(BattleCaptureStatus.burn);
      final asleep = attempt(BattleCaptureStatus.sleep);

      expect(
        burned.chanceNumerator * none.chanceDenominator,
        greaterThan(none.chanceNumerator * burned.chanceDenominator),
      );
      expect(
        asleep.chanceNumerator * burned.chanceDenominator,
        greaterThan(burned.chanceNumerator * asleep.chanceDenominator),
      );
      expect(
        attempt(BattleCaptureStatus.freeze).chanceNumerator,
        asleep.chanceNumerator,
      );
      expect(
        attempt(BattleCaptureStatus.poison).chanceNumerator,
        burned.chanceNumerator,
      );
      expect(
        attempt(BattleCaptureStatus.paralysis).chanceNumerator,
        burned.chanceNumerator,
      );
    });

    test('a guaranteed chance still advances RNG exactly once', () {
      final result = const BattleCaptureFormula().attempt(
        targetCurrentHp: 1,
        targetMaxHp: 100,
        catchRate: 255,
        ballId: 'plain-orb',
        ballRateNumerator: 1,
        ballRateDenominator: 1,
        status: BattleCaptureStatus.sleep,
        rng: const BattleScriptedRng(<int>[76500]),
      );

      expect(result.caught, isTrue);
      expect(result.chanceNumerator, result.chanceDenominator);
      expect((result.nextRng as BattleScriptedRng).index, 1);
    });

    test('rejects invalid ball metadata and target inputs before RNG', () {
      const rng = BattleScriptedRng(<int>[1]);
      const formula = BattleCaptureFormula();

      BattleCaptureAttemptResult attempt({
        String ballId = 'plain-orb',
        int ballRateNumerator = 1,
        int ballRateDenominator = 1,
        int currentHp = 10,
        int catchRate = 45,
      }) {
        return formula.attempt(
          targetCurrentHp: currentHp,
          targetMaxHp: 10,
          catchRate: catchRate,
          ballId: ballId,
          ballRateNumerator: ballRateNumerator,
          ballRateDenominator: ballRateDenominator,
          status: BattleCaptureStatus.none,
          rng: rng,
        );
      }

      expect(() => attempt(ballId: ''), throwsArgumentError);
      expect(() => attempt(ballRateNumerator: 0), throwsArgumentError);
      expect(() => attempt(ballRateDenominator: 0), throwsArgumentError);
      expect(() => attempt(currentHp: 0), throwsArgumentError);
      expect(() => attempt(catchRate: 0), throwsArgumentError);
      expect(rng.index, 0);
    });
  });
}
