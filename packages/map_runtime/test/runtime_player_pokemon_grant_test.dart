import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  const config = ProjectPokemonConfig(
    ruleset: PokemonRulesetProfile.pokeMapBetaV1,
  );

  PlayerPokemon candidate({
    String speciesId = 'bulbasaur',
    int currentHp = 999,
  }) {
    return PlayerPokemon(
      speciesId: speciesId,
      natureId: 'hardy',
      abilityId: 'overgrow',
      level: 5,
      knownMoveIds: const <String>['tackle'],
      currentPpByMoveId: const <String, int>{'tackle': 999},
      currentHp: currentHp,
    );
  }

  test('hydrates, commits, and makes the same operation a no-op', () async {
    var catalogLoads = 0;
    Future<RuntimePlayerPokemonProgressionCatalogs> loadCatalogs({
      required GameState gameState,
      required String projectRootDirectory,
      required ProjectPokemonConfig pokemonConfig,
    }) async {
      catalogLoads += 1;
      expect(gameState.party.members.single.speciesId, 'bulbasaur');
      return _catalogs;
    }

    final first = await applyRuntimePlayerPokemonGrant(
      gameState: const GameState(saveId: 'grant'),
      pokemon: candidate(),
      grantOperationId: 'scenario:run:gift',
      projectRootDirectory: '/project',
      pokemonConfig: config,
      catalogLoader: loadCatalogs,
    );
    final replay = await applyRuntimePlayerPokemonGrant(
      gameState: first,
      pokemon: candidate(),
      grantOperationId: 'scenario:run:gift',
      projectRootDirectory: '/project',
      pokemonConfig: config,
      catalogLoader: loadCatalogs,
    );

    expect(first.party.members, hasLength(1));
    expect(first.party.members.single.currentHp, 19);
    expect(
      first.party.members.single.currentPpByMoveId,
      <String, int>{'tackle': 35},
    );
    expect(replay, first);
    expect(catalogLoads, 1);
  });

  test('two executions of one template create two individuals', () async {
    final first = await applyRuntimePlayerPokemonGrant(
      gameState: const GameState(saveId: 'grant'),
      pokemon: candidate(),
      grantOperationId: 'scenario:run-a:gift',
      projectRootDirectory: '/project',
      pokemonConfig: config,
      catalogLoader: _loadCatalogs,
    );
    final second = await applyRuntimePlayerPokemonGrant(
      gameState: first,
      pokemon: candidate(),
      grantOperationId: 'scenario:run-b:gift',
      projectRootDirectory: '/project',
      pokemonConfig: config,
      catalogLoader: _loadCatalogs,
    );

    expect(second.party.members, hasLength(2));
    expect(
      second.party.members.map((pokemon) => pokemon.individualId).toSet(),
      hasLength(2),
    );
  });

  test('hydration failure records neither Pokemon nor operation', () async {
    const state = GameState(saveId: 'grant');

    await expectLater(
      applyRuntimePlayerPokemonGrant(
        gameState: state,
        pokemon: candidate(speciesId: 'missing'),
        grantOperationId: 'scenario:broken:gift',
        projectRootDirectory: '/project',
        pokemonConfig: config,
        catalogLoader: _loadCatalogs,
      ),
      throwsA(
        isA<RuntimePlayerPokemonProgressionHydrationException>().having(
          (error) => error.code,
          'code',
          PlayerPokemonHydrationDiagnosticCode.unknownSpecies,
        ),
      ),
    );
    expect(state.party.members, isEmpty);
    expect(state.appliedPokemonGrantOperationIds, isEmpty);
  });

  test('maps a real species lookup miss to unknownSpecies', () async {
    Future<RuntimePlayerPokemonProgressionCatalogs> missingSpecies({
      required GameState gameState,
      required String projectRootDirectory,
      required ProjectPokemonConfig pokemonConfig,
    }) {
      throw const RuntimePokemonSpeciesNotFoundException('missing');
    }

    await expectLater(
      applyRuntimePlayerPokemonGrant(
        gameState: const GameState(saveId: 'grant'),
        pokemon: candidate(speciesId: 'missing'),
        grantOperationId: 'scenario:missing:gift',
        projectRootDirectory: '/project',
        pokemonConfig: config,
        catalogLoader: missingSpecies,
      ),
      throwsA(
        isA<RuntimePlayerPokemonProgressionHydrationException>().having(
          (error) => error.code,
          'code',
          PlayerPokemonHydrationDiagnosticCode.unknownSpecies,
        ),
      ),
    );
  });

  test('emits clamp diagnostics before committing canonical values', () async {
    final diagnostics = <PlayerPokemonHydrationDiagnostic>[];

    final state = await applyRuntimePlayerPokemonGrant(
      gameState: const GameState(saveId: 'grant'),
      pokemon: candidate(),
      grantOperationId: 'scene:run:gift',
      projectRootDirectory: '/project',
      pokemonConfig: config,
      catalogLoader: _loadCatalogs,
      onDiagnostic: diagnostics.add,
    );

    expect(state.party.members.single.currentHp, 19);
    expect(
      diagnostics.map((diagnostic) => diagnostic.code),
      containsAll(<PlayerPokemonHydrationDiagnosticCode>[
        PlayerPokemonHydrationDiagnosticCode.currentPpClampedToMaximum,
        PlayerPokemonHydrationDiagnosticCode.currentHpClampedToMaximum,
      ]),
    );
  });
}

Future<RuntimePlayerPokemonProgressionCatalogs> _loadCatalogs({
  required GameState gameState,
  required String projectRootDirectory,
  required ProjectPokemonConfig pokemonConfig,
}) async {
  return _catalogs;
}

const _catalogs = RuntimePlayerPokemonProgressionCatalogs(
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
      abilityIds: <String>['overgrow'],
      growthRateId: 'medium_slow',
    ),
  },
  maxPpByMoveId: <String, int>{'tackle': 35},
);
