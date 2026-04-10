import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/ports/pokemon_read_repository.dart';
import '../../application/services/pokemon_database_index.dart';
import '../../infrastructure/repositories/file_repositories.dart';
import '../../ui/canvas/pokedex_workspace_loader.dart';
import 'core_providers.dart';

/// Wiring Pokédex local minimal.
///
/// Ce fichier reste volontairement petit et thématique :
/// - le workspace Pokédex n'instancie plus l'infrastructure directement ;
/// - on réutilise les repositories/services existants ;
/// - on ne crée pas un nouveau notifier ni une couche "future-proof" inutile.

final pokemonReadRepositoryProvider = Provider<PokemonReadRepository>((ref) {
  return const FilePokemonReadRepository();
});

final pokemonDatabaseIndexProvider = Provider<PokemonDatabaseIndex>((ref) {
  return PokemonDatabaseIndex(
    projectRepository: ref.watch(projectRepositoryProvider),
    pokemonReadRepository: ref.watch(pokemonReadRepositoryProvider),
  );
});

final pokedexEntryLoaderProvider = Provider<PokedexEntryLoader>((ref) {
  return createPokedexEntryLoader(
    projectRepository: ref.watch(projectRepositoryProvider),
    databaseIndex: ref.watch(pokemonDatabaseIndexProvider),
  );
});
