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

    test('projects supported policies to a typed beta mechanics contract', () {
      final mechanics = PokemonRulesetProfile.pokeMapBetaV1.mechanics;

      expect(mechanics.reference, PokemonRulesetProfile.pokeMapBetaV1Reference);
      expect(mechanics.typeChart, PokemonTypeChartPolicy.mainlineModernV1);
      expect(mechanics.experience, PokemonExperiencePolicy.pokeMapSimpleV1);
      expect(mechanics.capture, PokemonCapturePolicy.pokeMapMvpV1);
      expect(
        mechanics.moveMachine,
        PokemonMoveMachinePolicy.authoredConsumabilityV1,
      );
      expect(mechanics.criticalHit, PokemonCriticalHitPolicy.mainlineGen9);
      expect(
        mechanics.speedTie,
        PokemonSpeedTiePolicy.mainlineGen9SeededRandom,
      );
      expect(mechanics.friendship, PokemonFriendshipPolicy.mainline0255V1);
      expect(mechanics.evolution, PokemonEvolutionPolicy.pokeMapBetaV1);
      expect(mechanics.maxLevel, 100);
    });

    test('a new project config writes the explicit beta profile', () {
      const config = ProjectPokemonConfig(
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
      );

      expect(config.ruleset, PokemonRulesetProfile.pokeMapBetaV1);
      expect(
        config.toJson()['ruleset'],
        PokemonRulesetProfile.pokeMapBetaV1.toJson(),
      );
    });

    test('rejects an existing project without an explicit ruleset', () {
      final manifest = const ProjectManifest(
        name: 'Ruleset fixture',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
      ).toJson();
      final pokemon = Map<String, dynamic>.from(
        manifest['pokemon']! as Map<String, dynamic>,
      )..remove('ruleset');

      expect(
        () => ProjectManifest.fromJson(<String, dynamic>{
          ...manifest,
          'pokemon': pokemon,
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains(r'$.pokemon.ruleset'),
          ),
        ),
      );
    });

    test('rejects an existing project without Pokemon configuration', () {
      final manifest = const ProjectManifest(
        name: 'Ruleset fixture',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
      ).toJson()..remove('pokemon');

      expect(
        () => ProjectManifest.fromJson(manifest),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains(r'$.pokemon.ruleset'),
          ),
        ),
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
