import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('PokemonBattleRules', () {
    final rules = PokemonBattleRules.fromProfile(
      PokemonRulesetProfile.pokeMapBetaV1,
    );

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
