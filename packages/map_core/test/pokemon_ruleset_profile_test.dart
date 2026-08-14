import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('PokemonRulesetProfile', () {
    test('round-trips the complete canonical beta profile', () {
      const profile = PokemonRulesetProfile.pokeMapBetaV1;

      final decoded = PokemonRulesetProfile.fromJson(profile.toJson());

      expect(decoded, profile);
      expect(decoded.reference.profileId, 'pokemap-beta-v1');
      expect(decoded.reference.schemaVersion, 1);
      expect(decoded.maxLevel, 100);
      expect(decoded.disabledFeatures, <String>[
        'breeding',
        'double-battles',
        'modern-gimmicks',
        'online',
      ]);
    });

    test('defaults a new project Pokemon config to the beta profile', () {
      const config = ProjectPokemonConfig();

      expect(config.ruleset, PokemonRulesetProfile.pokeMapBetaV1);
      expect(
        config.toJson()['ruleset'],
        PokemonRulesetProfile.pokeMapBetaV1.toJson(),
      );
    });

    test('rejects an unknown profile', () {
      final json = PokemonRulesetProfile.pokeMapBetaV1.toJson()
        ..['profileId'] = 'unknown-profile';

      expect(
        () => PokemonRulesetProfile.fromJson(json),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('profileId'),
          ),
        ),
      );
    });

    test('rejects a future schema version', () {
      final json = PokemonRulesetProfile.pokeMapBetaV1.toJson()
        ..['schemaVersion'] = 2;

      expect(
        () => PokemonRulesetProfile.fromJson(json),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('schemaVersion'),
          ),
        ),
      );
    });

    test('rejects an incomplete profile', () {
      final json = PokemonRulesetProfile.pokeMapBetaV1.toJson()
        ..remove('capturePolicyId');

      expect(
        () => PokemonRulesetProfile.fromJson(json),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('capturePolicyId'),
          ),
        ),
      );
    });

    test('rejects an unknown rules policy', () {
      final json = PokemonRulesetProfile.pokeMapBetaV1.toJson()
        ..['speedTiePolicyId'] = 'mainline-gen4-fixed-order';

      expect(
        () => PokemonRulesetProfile.fromJson(json),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('speedTiePolicyId'),
          ),
        ),
      );
    });
  });
}
