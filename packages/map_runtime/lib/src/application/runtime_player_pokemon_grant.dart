import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'runtime_player_pokemon_progression_hydrator.dart';
import 'runtime_pokemon_species_loader.dart';

Future<GameState> applyRuntimePlayerPokemonGrant({
  required GameState gameState,
  required PlayerPokemon pokemon,
  required String grantOperationId,
  required String projectRootDirectory,
  required ProjectPokemonConfig pokemonConfig,
  bool preventDuplicateSpecies = false,
  RuntimePlayerPokemonProgressionCatalogLoader? catalogLoader,
  void Function(PlayerPokemonHydrationDiagnostic diagnostic)? onDiagnostic,
}) async {
  final normalizedOperationId = grantOperationId.trim();
  if (normalizedOperationId.isEmpty) {
    throw ArgumentError.value(
      grantOperationId,
      'grantOperationId',
      'must not be empty',
    );
  }
  if (gameState.appliedPokemonGrantOperationIds
      .contains(normalizedOperationId)) {
    return gameState;
  }
  final catalogState = gameState.copyWith(
    party: gameState.party.copyWith(
      members: <PlayerPokemon>[...gameState.party.members, pokemon],
    ),
  );
  RuntimePlayerPokemonProgressionCatalogs catalogs;
  try {
    catalogs =
        await (catalogLoader ?? loadRuntimePlayerPokemonProgressionCatalogs)(
      gameState: catalogState,
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
    );
  } on RuntimePokemonSpeciesNotFoundException catch (error) {
    throw RuntimePlayerPokemonProgressionHydrationException(
      diagnostic: PlayerPokemonHydrationDiagnostic(
        code: PlayerPokemonHydrationDiagnosticCode.unknownSpecies,
        severity: PlayerPokemonHydrationDiagnosticSeverity.error,
        message:
            'Pokemon species "${error.speciesId}" is absent from the project catalog.',
        speciesId: error.speciesId,
      ),
    );
  }
  final hydrated = hydrateRuntimePlayerPokemon(
    pokemon: pokemon,
    catalogs: catalogs.shared,
    ruleset: pokemonConfig.ruleset,
    origin: _grantOrigin(pokemon),
    onDiagnostic: onDiagnostic,
  );
  return const GameStateMutations().givePokemonOnce(
    gameState,
    grantOperationId: normalizedOperationId,
    pokemon: hydrated,
    preventDuplicateSpecies: preventDuplicateSpecies,
  );
}

PlayerPokemonHydrationOrigin _grantOrigin(PlayerPokemon pokemon) {
  return switch (pokemon.provenance?.kind) {
    PlayerPokemonOriginKind.starter => PlayerPokemonHydrationOrigin.starter,
    PlayerPokemonOriginKind.captured => PlayerPokemonHydrationOrigin.capture,
    PlayerPokemonOriginKind.scripted => PlayerPokemonHydrationOrigin.scripted,
    PlayerPokemonOriginKind.gift ||
    PlayerPokemonOriginKind.trade ||
    PlayerPokemonOriginKind.unknown ||
    null =>
      PlayerPokemonHydrationOrigin.gift,
  };
}
