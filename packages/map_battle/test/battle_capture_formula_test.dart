import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('BattleCaptureFormula', () {
    test('uses the documented exact HP/rate rational with one RNG draw', () {
      final result = const BattleCaptureFormula().attempt(
        targetCurrentHp: 100,
        targetMaxHp: 100,
        catchRate: 1,
        ballId: canonicalPokeBallItemId,
        status: BattleCaptureStatus.none,
        rng: const BattleScriptedRng(<int>[1]),
      );

      expect(result.chanceNumerator, 100);
      expect(result.chanceDenominator, 76500);
      expect(result.caught, isTrue);
      expect((result.nextRng as BattleScriptedRng).index, 1);
    });

    test('low HP improves capture without floating-point rounding', () {
      final result = const BattleCaptureFormula().attempt(
        targetCurrentHp: 1,
        targetMaxHp: 100,
        catchRate: 255,
        ballId: canonicalPokeBallItemId,
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
      const base = <String, Object>{
        'targetCurrentHp': 50,
        'targetMaxHp': 100,
        'catchRate': 100,
      };
      BattleCaptureAttemptResult attempt(BattleCaptureStatus status) {
        return formula.attempt(
          targetCurrentHp: base['targetCurrentHp']! as int,
          targetMaxHp: base['targetMaxHp']! as int,
          catchRate: base['catchRate']! as int,
          ballId: canonicalPokeBallItemId,
          status: status,
          rng: const BattleScriptedRng(<int>[1]),
        );
      }

      final none = attempt(BattleCaptureStatus.none);
      final burned = attempt(BattleCaptureStatus.burn);
      final asleep = attempt(BattleCaptureStatus.sleep);

      expect(burned.chanceNumerator * none.chanceDenominator,
          greaterThan(none.chanceNumerator * burned.chanceDenominator));
      expect(asleep.chanceNumerator * burned.chanceDenominator,
          greaterThan(burned.chanceNumerator * asleep.chanceDenominator));
      expect(attempt(BattleCaptureStatus.freeze).chanceNumerator,
          asleep.chanceNumerator);
      expect(attempt(BattleCaptureStatus.poison).chanceNumerator,
          burned.chanceNumerator);
      expect(attempt(BattleCaptureStatus.paralysis).chanceNumerator,
          burned.chanceNumerator);
    });

    test('a guaranteed chance still advances RNG exactly once', () {
      final result = const BattleCaptureFormula().attempt(
        targetCurrentHp: 1,
        targetMaxHp: 100,
        catchRate: 255,
        ballId: canonicalPokeBallItemId,
        status: BattleCaptureStatus.sleep,
        rng: const BattleScriptedRng(<int>[76500]),
      );

      expect(result.caught, isTrue);
      expect(result.chanceNumerator, result.chanceDenominator);
      expect((result.nextRng as BattleScriptedRng).index, 1);
    });

    test('rejects unsupported balls and invalid target inputs before RNG', () {
      const rng = BattleScriptedRng(<int>[1]);
      const formula = BattleCaptureFormula();

      expect(
        () => formula.attempt(
          targetCurrentHp: 10,
          targetMaxHp: 10,
          catchRate: 45,
          ballId: 'great-ball',
          status: BattleCaptureStatus.none,
          rng: rng,
        ),
        throwsArgumentError,
      );
      expect(
        () => formula.attempt(
          targetCurrentHp: 0,
          targetMaxHp: 10,
          catchRate: 45,
          ballId: canonicalPokeBallItemId,
          status: BattleCaptureStatus.none,
          rng: rng,
        ),
        throwsArgumentError,
      );
      expect(
        () => formula.attempt(
          targetCurrentHp: 10,
          targetMaxHp: 10,
          catchRate: 0,
          ballId: canonicalPokeBallItemId,
          status: BattleCaptureStatus.none,
          rng: rng,
        ),
        throwsArgumentError,
      );
      expect(rng.index, 0);
    });
  });
}
