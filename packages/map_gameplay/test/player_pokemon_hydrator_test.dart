import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const hydrator = PlayerPokemonHydrator();

  group('PlayerPokemonHydrator', () {
    test('hydrates starter, gift and captured Pokemon through one contract',
        () {
      for (final origin in <PlayerPokemonHydrationOrigin>{
        PlayerPokemonHydrationOrigin.starter,
        PlayerPokemonHydrationOrigin.gift,
        PlayerPokemonHydrationOrigin.capture,
      }) {
        final result = hydrator.hydrate(
          pokemon: const PlayerPokemon(
            speciesId: 'bulbasaur',
            natureId: 'hardy',
            abilityId: 'overgrow',
            level: 5,
            knownMoveIds: <String>['tackle', 'growl'],
            currentPpByMoveId: <String, int>{'tackle': 99},
            currentHp: 999,
          ),
          catalogs: _catalogs,
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
          origin: origin,
        );

        expect(result.hasErrors, isFalse, reason: origin.name);
        expect(result.pokemon?.experience, 135, reason: origin.name);
        expect(
          result.pokemon?.currentPpByMoveId,
          <String, int>{'growl': 40, 'tackle': 35},
          reason: origin.name,
        );
        expect(result.pokemon?.currentHp, 19, reason: origin.name);
      }
    });

    test('reports PP and HP clamps before returning canonical values', () {
      final result = hydrator.hydrate(
        pokemon: const PlayerPokemon(
          speciesId: 'bulbasaur',
          natureId: 'hardy',
          abilityId: 'overgrow',
          level: 5,
          knownMoveIds: <String>['tackle'],
          currentPpByMoveId: <String, int>{'tackle': 999},
          currentHp: 999,
        ),
        catalogs: _catalogs,
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        origin: PlayerPokemonHydrationOrigin.gift,
      );

      expect(result.hasErrors, isFalse);
      expect(result.pokemon?.currentPpByMoveId, <String, int>{'tackle': 35});
      expect(result.pokemon?.currentHp, 19);
      expect(
        result.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll(<PlayerPokemonHydrationDiagnosticCode>[
          PlayerPokemonHydrationDiagnosticCode.currentPpClampedToMaximum,
          PlayerPokemonHydrationDiagnosticCode.currentHpClampedToMaximum,
        ]),
      );
    });

    test('hydrates explicit legacy sentinels with typed diagnostics', () {
      final legacy = PlayerPokemon.fromJson(<String, dynamic>{
        'speciesId': 'bulbasaur',
        'level': 5,
        'knownMoveIds': <String>['tackle'],
        'isFainted': false,
      });

      final result = hydrator.hydrate(
        pokemon: legacy,
        catalogs: _catalogs,
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        origin: PlayerPokemonHydrationOrigin.legacySave,
      );

      expect(result.hasErrors, isFalse);
      expect(result.pokemon?.natureId, 'hardy');
      expect(result.pokemon?.abilityId, 'overgrow');
      expect(result.pokemon?.experience, 135);
      expect(result.pokemon?.currentPpByMoveId, <String, int>{'tackle': 35});
      expect(
        result.diagnostics.map((diagnostic) => diagnostic.code),
        contains(PlayerPokemonHydrationDiagnosticCode.abilityResolved),
      );
    });

    test('reports an explicit diagnostic when resolving a production sentinel',
        () {
      final result = hydrator.hydrate(
        pokemon: const PlayerPokemon(
          speciesId: 'bulbasaur',
          natureId: 'hardy',
          abilityId: 'unknown',
          level: 5,
        ),
        catalogs: _catalogs,
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        origin: PlayerPokemonHydrationOrigin.gift,
      );

      expect(result.hasErrors, isFalse);
      expect(result.pokemon?.abilityId, 'overgrow');
      expect(
        result.diagnostics.map((diagnostic) => diagnostic.code),
        contains(PlayerPokemonHydrationDiagnosticCode.abilityResolved),
      );
    });

    test('rejects broken species, move, nature and ability references', () {
      final unknownSpecies = hydrator.hydrate(
        pokemon: const PlayerPokemon(
          speciesId: 'missing',
          natureId: 'hardy',
          abilityId: 'overgrow',
        ),
        catalogs: _catalogs,
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        origin: PlayerPokemonHydrationOrigin.newGame,
      );
      final brokenReferences = hydrator.hydrate(
        pokemon: const PlayerPokemon(
          speciesId: 'bulbasaur',
          natureId: 'invented',
          abilityId: 'pressure',
          level: 5,
          knownMoveIds: <String>['missing_move'],
        ),
        catalogs: _catalogs,
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        origin: PlayerPokemonHydrationOrigin.newGame,
      );

      expect(
        unknownSpecies.diagnostics.map((diagnostic) => diagnostic.code),
        contains(PlayerPokemonHydrationDiagnosticCode.unknownSpecies),
      );
      expect(
        brokenReferences.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll(<PlayerPokemonHydrationDiagnosticCode>[
          PlayerPokemonHydrationDiagnosticCode.invalidNature,
          PlayerPokemonHydrationDiagnosticCode.invalidAbility,
          PlayerPokemonHydrationDiagnosticCode.unknownMove,
        ]),
      );
    });

    test('rejects duplicate or excessive moves and PP for an unlearned move',
        () {
      final result = hydrator.hydrate(
        pokemon: const PlayerPokemon(
          speciesId: 'bulbasaur',
          natureId: 'hardy',
          abilityId: 'overgrow',
          level: 5,
          knownMoveIds: <String>[
            'tackle',
            'growl',
            'vine_whip',
            'poison_powder',
            'tackle',
          ],
          currentPpByMoveId: <String, int>{'razor_leaf': 10},
        ),
        catalogs: _catalogs,
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        origin: PlayerPokemonHydrationOrigin.starter,
      );

      expect(
        result.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll(<PlayerPokemonHydrationDiagnosticCode>[
          PlayerPokemonHydrationDiagnosticCode.tooManyMoves,
          PlayerPokemonHydrationDiagnosticCode.duplicateMove,
          PlayerPokemonHydrationDiagnosticCode.ppForUnlearnedMove,
        ]),
      );
    });

    test('rejects experience that resolves to another level', () {
      final result = hydrator.hydrate(
        pokemon: const PlayerPokemon(
          speciesId: 'bulbasaur',
          natureId: 'hardy',
          abilityId: 'overgrow',
          level: 5,
          experience: 0,
        ),
        catalogs: _catalogs,
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        origin: PlayerPokemonHydrationOrigin.legacySave,
      );

      expect(
        result.diagnostics.map((diagnostic) => diagnostic.code),
        contains(PlayerPokemonHydrationDiagnosticCode.inconsistentExperience),
      );
    });

    test('is idempotent once the individual is canonical', () {
      final first = hydrator.hydrate(
        pokemon: const PlayerPokemon(
          speciesId: 'bulbasaur',
          natureId: 'hardy',
          abilityId: 'overgrow',
          level: 5,
          knownMoveIds: <String>['tackle'],
          currentHp: 999,
        ),
        catalogs: _catalogs,
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        origin: PlayerPokemonHydrationOrigin.starter,
      );
      final second = hydrator.hydrate(
        pokemon: first.pokemon!,
        catalogs: _catalogs,
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        origin: PlayerPokemonHydrationOrigin.starter,
      );

      expect(first.hasErrors, isFalse);
      expect(second.hasErrors, isFalse);
      expect(second.pokemon, first.pokemon);
      expect(second.diagnostics, isEmpty);
    });
  });
}

const _catalogs = PlayerPokemonHydrationCatalogs(
  speciesById: <String, PlayerPokemonHydrationSpecies>{
    'bulbasaur': PlayerPokemonHydrationSpecies(
      id: 'bulbasaur',
      baseStats: PokemonBaseStats(
        hp: 45,
        attack: 49,
        defense: 49,
        specialAttack: 65,
        specialDefense: 65,
        speed: 45,
      ),
      primaryAbilityId: 'overgrow',
      abilityIds: <String>['overgrow', 'chlorophyll'],
      growthRateId: 'medium_slow',
    ),
  },
  maxPpByMoveId: <String, int>{
    'tackle': 35,
    'growl': 40,
    'vine_whip': 25,
    'poison_powder': 35,
    'razor_leaf': 25,
  },
);
