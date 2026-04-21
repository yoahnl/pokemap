import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/repository_providers.dart';
import '../pokedex/pokedex_providers.dart';
import '../../../application/use_cases/load_pokemon_items_catalog_use_case.dart';

typedef PokemonItemsCatalogWorkspaceLoader =
    Future<PokemonItemsCatalogView> Function(String? projectRootPath);

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
