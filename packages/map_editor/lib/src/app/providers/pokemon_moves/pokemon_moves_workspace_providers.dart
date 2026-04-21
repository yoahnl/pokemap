import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/errors/application_errors.dart';
import '../core/repository_providers.dart';
import '../pokedex/pokedex_providers.dart';
import '../../../application/use_cases/sync_pokemon_moves_catalog_use_case.dart';

typedef PokemonMovesCatalogWorkspaceLoader =
    Future<PokemonMovesCatalogView> Function(String? projectRootPath);

typedef PokemonMovesCatalogWorkspaceSyncer =
    Future<PokemonMovesCatalogSyncResult> Function(
  String? projectRootPath, {
  bool dryRun,
});

final pokemonMovesCatalogWorkspaceLoaderProvider =
    Provider<PokemonMovesCatalogWorkspaceLoader>((ref) {
  return (projectRootPath) async {
    if (projectRootPath == null || projectRootPath.trim().isEmpty) {
      return const PokemonMovesCatalogView(
        entries: <PokemonMoveCatalogEntryView>[],
        isAvailable: false,
        description: 'Catalogue local des attaques indisponible.',
        loadState: PokemonMovesCatalogLoadState.noProject,
      );
    }

    final workspace = ref.read(projectWorkspaceFactoryProvider).create(
          projectRootPath,
        );
    final useCase = ref.read(loadPokemonMovesCatalogUseCaseProvider);
    return useCase.execute(workspace);
  };
});

final pokemonMovesCatalogWorkspaceSyncerProvider =
    Provider<PokemonMovesCatalogWorkspaceSyncer>((ref) {
  return (
    projectRootPath, {
    bool dryRun = false,
  }) async {
    if (projectRootPath == null || projectRootPath.trim().isEmpty) {
      throw const EditorValidationException(
        'Aucun projet ouvert pour synchroniser le catalogue des moves.',
      );
    }

    final workspace = ref.read(projectWorkspaceFactoryProvider).create(
          projectRootPath,
        );
    final useCase = ref.read(syncExternalPokemonMovesCatalogUseCaseProvider);
    return useCase.execute(
      workspace,
      dryRun: dryRun,
    );
  };
});
