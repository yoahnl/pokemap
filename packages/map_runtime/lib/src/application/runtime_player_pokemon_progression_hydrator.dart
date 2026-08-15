import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'runtime_move_catalog_loader.dart';
import 'runtime_pokemon_species_loader.dart';

const runtimeSupportedPokemonGrowthRateIds =
    PokemonExperienceCurve.supportedIds;

final class RuntimePlayerPokemonProgressionHydrationException
    implements Exception {
  const RuntimePlayerPokemonProgressionHydrationException({
    required this.diagnostic,
  });

  final PlayerPokemonHydrationDiagnostic diagnostic;

  PlayerPokemonHydrationDiagnosticCode get code => diagnostic.code;
  String get message => diagnostic.message;
  String get speciesId => diagnostic.speciesId;
  String? get moveId => diagnostic.moveId;

  @override
  String toString() {
    final moveDetails = moveId == null ? '' : ', moveId=$moveId';
    return 'RuntimePlayerPokemonProgressionHydrationException('
        'code=${code.name}, speciesId=$speciesId$moveDetails): $message';
  }
}

final class RuntimePlayerPokemonProgressionCatalogs {
  const RuntimePlayerPokemonProgressionCatalogs({
    required this.speciesById,
    required this.maxPpByMoveId,
  });

  final Map<String, PlayerPokemonHydrationSpecies> speciesById;
  final Map<String, int> maxPpByMoveId;

  Map<String, String> get growthRateIdBySpeciesId =>
      Map<String, String>.unmodifiable(<String, String>{
        for (final entry in speciesById.entries)
          entry.key: entry.value.growthRateId,
      });

  PlayerPokemonHydrationCatalogs get shared => PlayerPokemonHydrationCatalogs(
        speciesById: speciesById,
        maxPpByMoveId: maxPpByMoveId,
      );
}

typedef RuntimePlayerPokemonProgressionCatalogLoader
    = Future<RuntimePlayerPokemonProgressionCatalogs> Function({
  required GameState gameState,
  required String projectRootDirectory,
  required ProjectPokemonConfig pokemonConfig,
});

Future<RuntimePlayerPokemonProgressionCatalogs>
    loadRuntimePlayerPokemonProgressionCatalogs({
  required GameState gameState,
  required String projectRootDirectory,
  required ProjectPokemonConfig pokemonConfig,
  RuntimeMoveCatalogLoader? moveCatalogLoader,
  RuntimePokemonSpeciesLoader? speciesLoader,
}) async {
  final pokemon = <PlayerPokemon>[
    ...gameState.party.members,
    ...gameState.pokemonStorage.storedPokemon,
  ];
  if (pokemon.isEmpty) {
    return const RuntimePlayerPokemonProgressionCatalogs(
      speciesById: <String, PlayerPokemonHydrationSpecies>{},
      maxPpByMoveId: <String, int>{},
    );
  }

  final requiredMoveIds = <String>{
    for (final member in pokemon)
      ...member.knownMoveIds.map((moveId) => moveId.trim()),
    for (final member in pokemon)
      ...?member.currentPpByMoveId?.keys.map((moveId) => moveId.trim()),
  }..remove('');
  final maxPpByMoveId = <String, int>{};
  if (requiredMoveIds.isNotEmpty) {
    final moveCatalog =
        await (moveCatalogLoader ?? RuntimeMoveCatalogLoader()).load(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
    );
    for (final moveId in requiredMoveIds) {
      final move = moveCatalog.lookup(moveId);
      if (move != null) maxPpByMoveId[moveId] = move.pp;
    }
  }

  final requiredSpeciesIds = <String>{
    for (final member in pokemon) member.speciesId.trim(),
  }..remove('');
  final sortedSpeciesIds = requiredSpeciesIds.toList(growable: false)..sort();
  final loader = speciesLoader ?? RuntimePokemonSpeciesLoader();
  final speciesRows = await Future.wait(
    <Future<RuntimePokemonSpecies>>[
      for (final speciesId in sortedSpeciesIds)
        loader.loadById(
          projectRootDirectory: projectRootDirectory,
          pokemonConfig: pokemonConfig,
          speciesId: speciesId,
        ),
    ],
  );
  final speciesById = <String, PlayerPokemonHydrationSpecies>{
    for (final species in speciesRows)
      species.id: PlayerPokemonHydrationSpecies(
        id: species.id,
        baseStats: PokemonBaseStats(
          hp: species.baseHp,
          attack: species.baseAttack,
          defense: species.baseDefense,
          specialAttack: species.baseSpecialAttack,
          specialDefense: species.baseSpecialDefense,
          speed: species.baseSpeed,
        ),
        primaryAbilityId: species.primaryAbilityId,
        abilityIds: List<String>.unmodifiable(species.abilityIds),
        growthRateId: species.growthRateId,
      ),
  };

  return RuntimePlayerPokemonProgressionCatalogs(
    speciesById: Map<String, PlayerPokemonHydrationSpecies>.unmodifiable(
      speciesById,
    ),
    maxPpByMoveId: Map<String, int>.unmodifiable(maxPpByMoveId),
  );
}

GameState hydrateRuntimePlayerPokemonProgression({
  required GameState gameState,
  required RuntimePlayerPokemonProgressionCatalogs catalogs,
  required PokemonRulesetProfile ruleset,
  PlayerPokemonHydrationOrigin defaultOrigin =
      PlayerPokemonHydrationOrigin.legacySave,
  void Function(PlayerPokemonHydrationDiagnostic diagnostic)? onDiagnostic,
}) {
  PlayerPokemon hydrate(PlayerPokemon pokemon) {
    return hydrateRuntimePlayerPokemon(
      pokemon: pokemon,
      catalogs: catalogs.shared,
      ruleset: ruleset,
      origin: _hydrationOriginFor(pokemon, defaultOrigin),
      onDiagnostic: onDiagnostic,
    );
  }

  return gameState.copyWith(
    party: gameState.party.copyWith(
      members: gameState.party.members.map(hydrate).toList(growable: false),
    ),
    pokemonStorage: gameState.pokemonStorage.copyWith(
      storedPokemon: gameState.pokemonStorage.storedPokemon
          .map(hydrate)
          .toList(growable: false),
    ),
  );
}

PlayerPokemon hydrateRuntimePlayerPokemon({
  required PlayerPokemon pokemon,
  required PlayerPokemonHydrationCatalogs catalogs,
  required PokemonRulesetProfile ruleset,
  required PlayerPokemonHydrationOrigin origin,
  void Function(PlayerPokemonHydrationDiagnostic diagnostic)? onDiagnostic,
}) {
  final result = const PlayerPokemonHydrator().hydrate(
    pokemon: pokemon,
    catalogs: catalogs,
    ruleset: ruleset,
    origin: origin,
  );
  for (final diagnostic in result.diagnostics) {
    onDiagnostic?.call(diagnostic);
  }
  if (result.hasErrors) {
    throw RuntimePlayerPokemonProgressionHydrationException(
      diagnostic: result.diagnostics.firstWhere(
        (diagnostic) =>
            diagnostic.severity ==
            PlayerPokemonHydrationDiagnosticSeverity.error,
      ),
    );
  }
  return result.pokemon!;
}

PlayerPokemonHydrationOrigin _hydrationOriginFor(
  PlayerPokemon pokemon,
  PlayerPokemonHydrationOrigin fallback,
) {
  return switch (pokemon.provenance?.kind) {
    PlayerPokemonOriginKind.captured => PlayerPokemonHydrationOrigin.capture,
    PlayerPokemonOriginKind.gift => PlayerPokemonHydrationOrigin.gift,
    PlayerPokemonOriginKind.starter => PlayerPokemonHydrationOrigin.starter,
    PlayerPokemonOriginKind.trade => PlayerPokemonHydrationOrigin.gift,
    PlayerPokemonOriginKind.scripted => PlayerPokemonHydrationOrigin.scripted,
    PlayerPokemonOriginKind.unknown || null => fallback,
  };
}
