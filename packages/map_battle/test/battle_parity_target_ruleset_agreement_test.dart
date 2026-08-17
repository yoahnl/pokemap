import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('BETA-BAT-001 parity target agrees with the project ruleset', () {
    const target = BattleParityTarget.canonicalV1;
    const profile = PokemonRulesetProfile.pokeMapBetaV1;

    test('every shared axis names the same rule as the ruleset policy', () {
      // Ces deux déclarations décrivaient les mêmes règles sans jamais se
      // confronter : elles s'accordaient à la main. Le jour où l'une bougeait,
      // rien ne le disait. Le ticket BETA-BAT-001 exige une résolution unique ;
      // à défaut d'avoir encore fusionné les deux, on interdit au moins la
      // dérive silencieuse.
      expect(
        target.axis(BattleParityAxis.criticalHits).ruleId,
        profile.criticalHitPolicyId,
      );
      expect(
        target.axis(BattleParityAxis.speedTies).ruleId,
        profile.speedTiePolicyId,
      );
      expect(
        target.axis(BattleParityAxis.experience).ruleId,
        profile.experiencePolicyId,
      );
      expect(
        target.axis(BattleParityAxis.capture).ruleId,
        profile.capturePolicyId,
      );
    });

    test('the critical axis states the rate the engine actually applies', () {
      final rules = PokemonBattleRules.fromProfile(profile);
      final stageZero = rules.criticalHitRule(1);
      final summary = target.axis(BattleParityAxis.criticalHits).summary;

      // Le résumé est ce qu'un relecteur lit pour décider si le moteur est
      // conforme. Il annonçait 1/16, le taux des générations 2 à 5, alors que
      // le moteur applique 1/24 comme la Gen 9 déclarée : l'audit de parité
      // aurait validé la mauvaise règle.
      expect(stageZero.numerator, 1);
      expect(stageZero.denominator, 24);
      expect(
        summary,
        contains('1/${stageZero.denominator}'),
        reason: 'the summary must quote the rate the engine computes',
      );
      expect(
        summary,
        isNot(contains('1/16')),
        reason: '1/16 is the Gen 2-5 rate, not the declared Gen 9 one',
      );
      expect(
        summary,
        contains('${stageZero.damageMultiplier}'),
      );
    });

    test('an axis claiming alignment may not contradict the engine', () {
      final rules = PokemonBattleRules.fromProfile(profile);
      final critical = target.axis(BattleParityAxis.criticalHits);

      expect(critical.alignment, BattleParityAlignment.aligned);
      for (final entry in <int, int>{1: 24, 2: 8, 3: 2}.entries) {
        final rule = rules.criticalHitRule(entry.key);
        expect(rule.numerator, 1);
        expect(
          rule.denominator,
          entry.value,
          reason: 'stage ${entry.key} must match the summarised progression',
        );
        expect(
          critical.summary,
          contains('1/${entry.value}'),
          reason: 'an aligned axis must summarise every stage it claims',
        );
      }
    });
  });
}
