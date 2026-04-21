import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/repository_providers.dart';
import '../pokedex/pokedex_providers.dart';
import '../../../application/use_cases/sync_pokemon_moves_catalog_use_case.dart';

typedef PokemonMovesCatalogWorkspaceLoader =
    Future<PokemonMovesCatalogView> Function(String? projectRootPath);

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
