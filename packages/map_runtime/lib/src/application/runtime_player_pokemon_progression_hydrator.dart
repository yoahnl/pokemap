import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'runtime_move_catalog_loader.dart';

/// IDs canoniques réellement produits par les importeurs Pokémon du projet.
///
/// Le loader d'espèce et l'hydrateur legacy partagent cette liste afin de ne
/// jamais accepter un profil que la courbe d'XP runtime ne saurait calculer.
const runtimeSupportedPokemonGrowthRateIds = <String>{
  'fast',
  'fast_then_very_slow',
  'medium',
  'medium_fast',
  'medium_slow',
  'slow',
  'slow_then_very_fast',
};

/// Machine-readable failures raised before a persisted Pokemon becomes
/// playable.
///
/// Catalogue-aware validation belongs in `map_runtime`, not `map_core`: the
/// save model owns only structural invariants and never reads project data.
enum RuntimePlayerPokemonProgressionHydrationErrorCode {
  negativeExperience,
  negativeCurrentPp,
  emptyMoveId,
  unknownMove,
  ppForUnlearnedMove,
  missingGrowthRate,
  unsupportedGrowthRate,
  invalidCatalogData,
}

/// Explicit hydration failure with enough context for a runtime load error.
final class RuntimePlayerPokemonProgressionHydrationException
    implements Exception {
  const RuntimePlayerPokemonProgressionHydrationException({
    required this.code,
    required this.message,
    required this.speciesId,
    this.moveId,
  });

  final RuntimePlayerPokemonProgressionHydrationErrorCode code;
  final String message;
  final String speciesId;
  final String? moveId;

  @override
  String toString() {
    final moveDetails = moveId == null ? '' : ', moveId=$moveId';
    return 'RuntimePlayerPokemonProgressionHydrationException('
        'code=${code.name}, speciesId=$speciesId$moveDetails): $message';
  }
}

/// The catalogue projection needed by the pure progression hydrator.
///
/// Keeping this projection as two maps prevents the save model from learning
/// about project files and prevents Flame components from owning migration
/// rules. The application layer loads these values before invoking [hydrateRuntimePlayerPokemonProgression].
final class RuntimePlayerPokemonProgressionCatalogs {
  const RuntimePlayerPokemonProgressionCatalogs({
    required this.growthRateIdBySpeciesId,
    required this.maxPpByMoveId,
  });

  final Map<String, String> growthRateIdBySpeciesId;
  final Map<String, int> maxPpByMoveId;
}

/// Async catalogue boundary injected into [PlayableMapGame] tests and used by
/// production boot/load orchestration.
typedef RuntimePlayerPokemonProgressionCatalogLoader
    = Future<RuntimePlayerPokemonProgressionCatalogs> Function({
  required GameState gameState,
  required String projectRootDirectory,
  required ProjectPokemonConfig pokemonConfig,
});

/// Loads only the catalogue projection required by legacy hydration.
///
/// This IO boundary intentionally stays separate from the pure hydrator. Move
/// PP comes from the canonical move catalogue. Growth rate ids come from the
/// canonical species records because the current growth-rate catalogue only
/// names curves and does not duplicate each species assignment.
Future<RuntimePlayerPokemonProgressionCatalogs>
    loadRuntimePlayerPokemonProgressionCatalogs({
  required GameState gameState,
  required String projectRootDirectory,
  required ProjectPokemonConfig pokemonConfig,
}) async {
  final pokemon = <PlayerPokemon>[
    ...gameState.party.members,
    ...gameState.pokemonStorage.storedPokemon,
  ];
  if (pokemon.isEmpty) {
    return const RuntimePlayerPokemonProgressionCatalogs(
      growthRateIdBySpeciesId: <String, String>{},
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
    final moveCatalog = await RuntimeMoveCatalogLoader().load(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
    );
    for (final moveId in requiredMoveIds) {
      final move = moveCatalog.lookup(moveId);
      if (move != null) maxPpByMoveId[moveId] = move.pp;
    }
  }

  final speciesNeedingGrowthRate = <String>{
    for (final member in pokemon)
      if (member.experience == null) member.speciesId.trim(),
  }..remove('');
  final growthRateIdBySpeciesId = speciesNeedingGrowthRate.isEmpty
      ? const <String, String>{}
      : await _loadGrowthRateIds(
          projectRootDirectory: projectRootDirectory,
          pokemonConfig: pokemonConfig,
          speciesIds: speciesNeedingGrowthRate,
        );

  return RuntimePlayerPokemonProgressionCatalogs(
    growthRateIdBySpeciesId:
        Map<String, String>.unmodifiable(growthRateIdBySpeciesId),
    maxPpByMoveId: Map<String, int>.unmodifiable(maxPpByMoveId),
  );
}

Future<Map<String, String>> _loadGrowthRateIds({
  required String projectRootDirectory,
  required ProjectPokemonConfig pokemonConfig,
  required Set<String> speciesIds,
}) async {
  final configuredSpeciesDirectory = pokemonConfig.speciesDir.trim().isEmpty
      ? 'data/pokemon/species'
      : pokemonConfig.speciesDir.trim();
  final speciesDirectory = Directory(
    p.isAbsolute(configuredSpeciesDirectory)
        ? p.normalize(configuredSpeciesDirectory)
        : p.normalize(
            p.join(projectRootDirectory, configuredSpeciesDirectory),
          ),
  );
  if (!await speciesDirectory.exists()) {
    throw RuntimePlayerPokemonProgressionHydrationException(
      code:
          RuntimePlayerPokemonProgressionHydrationErrorCode.invalidCatalogData,
      message: 'Pokemon species directory is missing.',
      speciesId: speciesIds.first,
    );
  }

  final jsonFiles = await speciesDirectory
      .list(recursive: false)
      .where((entity) => entity is File && p.extension(entity.path) == '.json')
      .cast<File>()
      .toList();
  final growthRateIds = <String, String>{};
  final parsedPaths = <String>{};

  Future<void> parseCandidate(File file) async {
    if (!parsedPaths.add(file.path)) return;
    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('JSON object expected');
      }
      json = decoded;
    } catch (error) {
      throw RuntimePlayerPokemonProgressionHydrationException(
        code: RuntimePlayerPokemonProgressionHydrationErrorCode
            .invalidCatalogData,
        message: 'Invalid Pokemon species catalogue file: ${file.path} '
            '($error)',
        speciesId: speciesIds.first,
      );
    }
    final speciesId = (json['id'] as String?)?.trim() ?? '';
    if (!speciesIds.contains(speciesId)) return;
    final progression = (json['progression'] as Map?)?.cast<String, dynamic>();
    final growthRateId =
        (progression?['growthRateId'] as String?)?.trim() ?? '';
    if (growthRateId.isNotEmpty) growthRateIds[speciesId] = growthRateId;
  }

  // Canonical files usually use either `<id>.json` or `<dex>-<id>.json`.
  // Parsing these candidates first avoids scanning every species at boot.
  for (final speciesId in speciesIds) {
    for (final file in jsonFiles) {
      final basename = p.basenameWithoutExtension(file.path);
      if (basename == speciesId || basename.endsWith('-$speciesId')) {
        await parseCandidate(file);
      }
    }
  }
  if (!growthRateIds.keys.toSet().containsAll(speciesIds)) {
    for (final file in jsonFiles) {
      await parseCandidate(file);
      if (growthRateIds.keys.toSet().containsAll(speciesIds)) break;
    }
  }

  return growthRateIds;
}

/// Hydrates legacy Pokemon progression sentinels and validates catalogue refs.
///
/// This function is deliberately synchronous and side-effect free. File IO
/// and catalogue caching remain runtime orchestration concerns. Both party and
/// storage are covered because either collection can later feed a battle.
GameState hydrateRuntimePlayerPokemonProgression({
  required GameState gameState,
  required RuntimePlayerPokemonProgressionCatalogs catalogs,
}) {
  PlayerPokemon hydrate(PlayerPokemon pokemon) {
    final speciesId = pokemon.speciesId.trim();
    final persistedExperience = pokemon.experience;
    if (persistedExperience != null && persistedExperience < 0) {
      throw RuntimePlayerPokemonProgressionHydrationException(
        code: RuntimePlayerPokemonProgressionHydrationErrorCode
            .negativeExperience,
        message: 'Pokemon experience must be non-negative.',
        speciesId: speciesId,
      );
    }

    final knownMoveIds = <String>[];
    for (final rawMoveId in pokemon.knownMoveIds) {
      final moveId = rawMoveId.trim();
      if (moveId.isEmpty) {
        throw RuntimePlayerPokemonProgressionHydrationException(
          code: RuntimePlayerPokemonProgressionHydrationErrorCode.emptyMoveId,
          message: 'Known move ids must not be empty.',
          speciesId: speciesId,
          moveId: rawMoveId,
        );
      }
      if (!catalogs.maxPpByMoveId.containsKey(moveId)) {
        throw RuntimePlayerPokemonProgressionHydrationException(
          code: RuntimePlayerPokemonProgressionHydrationErrorCode.unknownMove,
          message: 'Known move is absent from the runtime move catalogue.',
          speciesId: speciesId,
          moveId: moveId,
        );
      }
      knownMoveIds.add(moveId);
    }

    final persistedPp = pokemon.currentPpByMoveId;
    if (persistedPp != null) {
      for (final entry in persistedPp.entries) {
        final moveId = entry.key.trim();
        if (moveId.isEmpty) {
          throw RuntimePlayerPokemonProgressionHydrationException(
            code: RuntimePlayerPokemonProgressionHydrationErrorCode.emptyMoveId,
            message: 'Current PP move ids must not be empty.',
            speciesId: speciesId,
            moveId: entry.key,
          );
        }
        if (entry.value < 0) {
          throw RuntimePlayerPokemonProgressionHydrationException(
            code: RuntimePlayerPokemonProgressionHydrationErrorCode
                .negativeCurrentPp,
            message: 'Current PP values must be non-negative.',
            speciesId: speciesId,
            moveId: moveId,
          );
        }
        if (!catalogs.maxPpByMoveId.containsKey(moveId)) {
          throw RuntimePlayerPokemonProgressionHydrationException(
            code: RuntimePlayerPokemonProgressionHydrationErrorCode.unknownMove,
            message:
                'Current PP references a move absent from the runtime catalogue.',
            speciesId: speciesId,
            moveId: moveId,
          );
        }
        if (!knownMoveIds.contains(moveId)) {
          throw RuntimePlayerPokemonProgressionHydrationException(
            code: RuntimePlayerPokemonProgressionHydrationErrorCode
                .ppForUnlearnedMove,
            message: 'Current PP references a move the Pokemon does not know.',
            speciesId: speciesId,
            moveId: moveId,
          );
        }
      }
    }

    final experience = persistedExperience ??
        _minimumExperienceForLevel(
          level: pokemon.level,
          speciesId: speciesId,
          growthRateId: catalogs.growthRateIdBySpeciesId[speciesId],
        );
    final currentPpByMoveId = persistedPp ??
        <String, int>{
          for (final moveId in knownMoveIds)
            moveId: catalogs.maxPpByMoveId[moveId]!,
        };

    // A non-null persisted value is never recomputed here. Hydration is a
    // one-way legacy migration, not a heal operation or battle write-back.
    return pokemon.copyWith(
      experience: experience,
      currentPpByMoveId: currentPpByMoveId,
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

int _minimumExperienceForLevel({
  required int level,
  required String speciesId,
  required String? growthRateId,
}) {
  final normalizedGrowthRateId = growthRateId?.trim().toLowerCase();
  if (normalizedGrowthRateId == null || normalizedGrowthRateId.isEmpty) {
    throw RuntimePlayerPokemonProgressionHydrationException(
      code: RuntimePlayerPokemonProgressionHydrationErrorCode.missingGrowthRate,
      message: 'Species growth rate is required to hydrate legacy experience.',
      speciesId: speciesId,
    );
  }

  final cubed = level * level * level;
  final experience = switch (normalizedGrowthRateId) {
    'fast' => (4 * cubed) ~/ 5,
    'medium' || 'medium_fast' => cubed,
    'medium_slow' =>
      ((6 * cubed) ~/ 5) - (15 * level * level) + (100 * level) - 140,
    'slow' => (5 * cubed) ~/ 4,
    // Repository catalog ids follow the PokeAPI curve names. These aliases
    // are kept explicit so a future gameplay XP service can replace this
    // migration-only calculation without changing persisted data.
    'slow_then_very_fast' => _erraticExperience(level, cubed),
    'fast_then_very_slow' => _fluctuatingExperience(level, cubed),
    _ => throw RuntimePlayerPokemonProgressionHydrationException(
        code: RuntimePlayerPokemonProgressionHydrationErrorCode
            .unsupportedGrowthRate,
        message: 'Unsupported Pokemon growth rate "$normalizedGrowthRateId".',
        speciesId: speciesId,
      ),
  };

  // The classic medium-slow formula is negative at level one; persisted total
  // experience remains non-negative by contract.
  return experience < 0 ? 0 : experience;
}

int _erraticExperience(int level, int cubed) {
  if (level <= 50) return (cubed * (100 - level)) ~/ 50;
  if (level <= 68) return (cubed * (150 - level)) ~/ 100;
  if (level <= 98) {
    return (cubed * ((1911 - (10 * level)) ~/ 3)) ~/ 500;
  }
  return (cubed * (160 - level)) ~/ 100;
}

int _fluctuatingExperience(int level, int cubed) {
  if (level <= 15) {
    return (cubed * (((level + 1) ~/ 3) + 24)) ~/ 50;
  }
  if (level <= 35) return (cubed * (level + 14)) ~/ 50;
  return (cubed * ((level ~/ 2) + 32)) ~/ 50;
}
