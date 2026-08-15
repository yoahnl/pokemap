import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  group('PokemonGameplayRules', () {
    final rules = PokemonGameplayRules.fromProfile(
      PokemonRulesetProfile.pokeMapBetaV1,
    );

    test('resolves progression and authored policy bounds', () {
      expect(rules.reference, PokemonRulesetProfile.pokeMapBetaV1Reference);
      expect(rules.maxLevel, 100);
      expect(
        rules.experienceForDefeatedPokemon(
          level: 10,
          baseExperience: 64,
          trainerBattle: false,
        ),
        91,
      );
      expect(
        rules.experienceForDefeatedPokemon(
          level: 10,
          baseExperience: 64,
          trainerBattle: true,
        ),
        137,
      );
      expect(rules.validatedFriendship(0), 0);
      expect(rules.validatedFriendship(255), 255);
      expect(() => rules.validatedFriendship(256), throwsRangeError);
    });

    test('allows beta TM and evolution mechanics through one authority', () {
      expect(
        () => rules.requireMoveMachineSupported(),
        returnsNormally,
      );
      expect(
        () => rules.requireEvolutionSupported(),
        returnsNormally,
      );
    });

    test('refuses disabled project features explicitly', () {
      expect(
        () => rules.requireFeatureEnabled(PokemonDisabledFeature.breeding),
        throwsA(isA<PokemonGameplayFeatureDisabledError>()),
      );
    });
  });
}
