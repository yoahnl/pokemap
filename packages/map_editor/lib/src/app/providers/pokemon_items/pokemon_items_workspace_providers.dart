import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/repository_providers.dart';
import '../pokedex/pokedex_providers.dart';
import '../../../application/errors/application_errors.dart';
import '../../../application/use_cases/load_pokemon_items_catalog_use_case.dart';
import '../../../application/use_cases/sync_pokemon_items_catalog_use_case.dart';

typedef PokemonItemsCatalogWorkspaceLoader =
    Future<PokemonItemsCatalogView> Function(String? projectRootPath);

typedef PokemonItemsCatalogWorkspaceSyncer =
    Future<PokemonItemsCatalogSyncResult> Function(
  String? projectRootPath, {
  bool dryRun,
  bool downloadSprites,
  bool overwriteSprites,
});

final pokemonItemsCatalogWorkspaceLoaderProvider =
    Provider<PokemonItemsCatalogWorkspaceLoader>((ref) {
  return (projectRootPath) async {
    if (projectRootPath == null || projectRootPath.trim().isEmpty) {
      return const PokemonItemsCatalogView(
        entries: <PokemonItemCatalogEntryView>[],
        isAvailable: false,
        description: 'Catalogue local des objets indisponible.',
        loadState: PokemonItemsCatalogLoadState.noProject,
      );
    }

    final workspace = ref.read(projectWorkspaceFactoryProvider).create(
          projectRootPath,
        );
    final useCase = ref.read(loadPokemonItemsCatalogUseCaseProvider);
    return useCase.execute(workspace);
  };
});

final pokemonItemsCatalogWorkspaceSyncerProvider =
    Provider<PokemonItemsCatalogWorkspaceSyncer>((ref) {
  return (
    projectRootPath, {
    bool dryRun = false,
    bool downloadSprites = false,
    bool overwriteSprites = false,
  }) async {
    if (projectRootPath == null || projectRootPath.trim().isEmpty) {
      throw const EditorValidationException(
        'Aucun projet ouvert pour synchroniser le catalogue des items.',
      );
    }

    final workspace = ref.read(projectWorkspaceFactoryProvider).create(
          projectRootPath,
        );
    final useCase = ref.read(syncExternalPokemonItemsCatalogUseCaseProvider);
    return useCase.execute(
      workspace,
      dryRun: dryRun,
      downloadSprites: downloadSprites,
      overwriteSprites: overwriteSprites,
    );
  };
});
