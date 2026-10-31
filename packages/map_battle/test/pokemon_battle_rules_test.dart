import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('historical profiles reject contextual selection before random draws', () {
    for (final profile in [PokemonRulesetProfile.pokeMapBetaV1, PokemonRulesetProfile.standardV1]) {
      expect(() => PokemonBattleRules.fromProfile(profile).validateCaptureSelection(
        targetCurrentHp: 10, targetMaxHp: 10, catchRate: 45, ballId: 'synthetic-orb',
        ballRateNumerator: 1, ballRateDenominator: 1,
        contextualPolicy: ProjectContextualCapturePolicy(),
        captureContext: BattleCaptureContext()), throwsStateError);
    }
  });
  group('PokemonBattleRules', () {
    final rules = PokemonBattleRules.fromProfile(
      PokemonRulesetProfile.pokeMapBetaV1,
    );

    test('contextual capture uses current species catch rate after Morphing',
        () {
      final selected = PokemonBattleRules.fromProfile(PokemonRulesetProfile.contextualV1).resolveCapture(
        attemptId: 'morphing-1',
        targetCurrentHp: 100,
        targetMaxHp: 100,
        catchRate: 1,
        ballId: 'friend',
        ballRateNumerator: 1,
        ballRateDenominator: 1,
        status: BattleCaptureStatus.none,
        rng: const BattleScriptedRng([1]),
        contextualPolicy: ProjectContextualCapturePolicy(rateRules: []),
        captureContext: BattleCaptureContext(targetBaseCatchRate: 255),
      );
      expect(selected.contextualReceipt!.calculation.rate.beforeClamp, 255);
      expect(selected.attempt.chanceNumerator, 85);
      final historical = rules.resolveCapture(
        attemptId: 'historical-1',
        targetCurrentHp: 100,
        targetMaxHp: 100,
        catchRate: 1,
        ballId: 'friend',
        ballRateNumerator: 1,
        ballRateDenominator: 1,
        status: BattleCaptureStatus.none,
        rng: const BattleScriptedRng([1]),
      );
      expect(historical.attempt.chanceNumerator, 100);
      expect(historical.attempt.chanceDenominator, 76500);
    });

    test('resolves canonical type, critical and capture policies', () {
      expect(rules.reference, PokemonRulesetProfile.pokeMapBetaV1Reference);
      expect(
        rules.resolveEffectivenessMultiplier(
          moveType: 'fire',
          defenderTyping: const BattleTypingSnapshot(primaryType: 'grass'),
        ),
        2,
      );
      expect(rules.criticalHitRule(1).numerator, 1);
      expect(rules.criticalHitRule(1).denominator, 24);
      expect(rules.criticalHitRule(1).damageMultiplier, 1.5);

      final capture = rules.attemptCapture(
        targetCurrentHp: 1,
        targetMaxHp: 100,
        catchRate: 255,
        ballId: 'plain-orb',
        ballRateNumerator: 1,
        ballRateDenominator: 1,
        status: BattleCaptureStatus.sleep,
        rng: const BattleScriptedRng(<int>[76500]),
      );

      expect(capture.caught, isTrue);
      expect((capture.nextRng as BattleScriptedRng).index, 1);
    });

    test(
        'selection without policy preserves exact historical chance, RNG and shakes',
        () {
      for (final status in BattleCaptureStatus.values) {
        for (final rate in [1, 45, 255]) {
          final historical = rules.attemptCapture(
              targetCurrentHp: 77,
              targetMaxHp: 101,
              catchRate: rate,
              ballId: 'synthetic-orb',
              ballRateNumerator: 15,
              ballRateDenominator: 10,
              status: status,
              rng: const BattleSeededRng(state: 47));
          final selected = PokemonBattleRules.fromProfile(PokemonRulesetProfile.contextualV1).resolveCapture(
              attemptId: 'capture-attempt-1',
              targetCurrentHp: 77,
              targetMaxHp: 101,
              catchRate: rate,
              ballId: 'synthetic-orb',
              ballRateNumerator: 15,
              ballRateDenominator: 10,
              status: status,
              rng: const BattleSeededRng(state: 47));
          expect(selected.contextualReceipt, isNull);
          expect(selected.attempt.caught, historical.caught);
          expect(selected.attempt.shakes, historical.shakes);
          expect(selected.attempt.chanceNumerator, historical.chanceNumerator);
          expect(
              selected.attempt.chanceDenominator, historical.chanceDenominator);
          expect((selected.attempt.nextRng as BattleSeededRng).state,
              (historical.nextRng as BattleSeededRng).state);
        }
      }
    });

    test(
        'selection preserves contextual staged floors and consumes exactly one draw',
        () {
      final selected = PokemonBattleRules.fromProfile(PokemonRulesetProfile.contextualV1).resolveCapture(
          attemptId: 'capture-attempt-17',
          targetCurrentHp: 77,
          targetMaxHp: 101,
          catchRate: 190,
          ballId: 'synthetic-orb',
          ballRateNumerator: 15,
          ballRateDenominator: 10,
          status: BattleCaptureStatus.paralysis,
          rng: const BattleScriptedRng([255]),
          contextualPolicy: ProjectContextualCapturePolicy(rateRules: [
            ProjectCaptureRateRule(
                when: const ProjectCaptureAlwaysCondition(),
                adjustment:
                    ProjectCaptureRateMultiply(numerator: 4, denominator: 1))
          ]),
          captureContext: BattleCaptureContext());
      final receipt = selected.contextualReceipt!;
      expect(receipt.attemptId, 'capture-attempt-17');
      expect(receipt.calculation.rate.beforeClamp, 760);
      expect(receipt.calculation.afterBallMultiplier, 382);
      expect(receipt.calculation.afterHp, 187);
      expect(receipt.calculation.afterStatus, 280);
      expect(selected.attempt.caught, isTrue);
      expect((selected.attempt.nextRng as BattleScriptedRng).index, 1);
    });

    test('seeded speed ties are replayable and consume exactly one draw', () {
      final first = rules.resolveLegacySpeedTie(
        const BattleSeededRng(state: 0),
      );
      final replay = rules.resolveLegacySpeedTie(
        const BattleSeededRng(state: 0),
      );
      final opposite = rules.resolveLegacySpeedTie(
        const BattleSeededRng(state: 1),
      );

      expect(first.firstActsFirst, replay.firstActsFirst);
      expect(first.nextRng, isA<BattleSeededRng>());
      expect((first.nextRng as BattleSeededRng).state, 1013904223);
      expect(opposite.firstActsFirst, isNot(first.firstActsFirst));
    });

    test('legacy and PSDK ties share the same seeded decision', () {
      for (final seed in <int>[0, 1]) {
        final legacy = rules.resolveLegacySpeedTie(
          BattleSeededRng(state: seed),
        );
        final psdk = rules.resolvePsdkSpeedTie(
          BattleRngStreams.fromSeeds(
            moveDamageSeed: 10,
            moveCriticalSeed: 20,
            moveAccuracySeed: 30,
            genericSeed: seed,
          ),
        );

        expect(psdk.firstActsFirst, legacy.firstActsFirst);
        expect(
          psdk.nextRng.generic.seed,
          (legacy.nextRng as BattleSeededRng).state,
        );
        expect(psdk.nextRng.moveDamage.seed, 10);
        expect(psdk.nextRng.moveCritical.seed, 20);
        expect(psdk.nextRng.moveAccuracy.seed, 30);
      }
    });

    test('disabled mechanics fail explicitly', () {
      expect(
        () => rules.requireFeatureEnabled(
          PokemonDisabledFeature.modernGimmicks,
        ),
        throwsA(isA<PokemonRulesetFeatureDisabledError>()),
      );
    });
  });
}
