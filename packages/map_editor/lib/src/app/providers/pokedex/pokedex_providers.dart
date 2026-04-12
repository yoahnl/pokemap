import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../application/ports/pokemon_read_repository.dart';
import '../../../application/ports/pokemon_external_source_repository.dart';
import '../../../application/ports/pokemon_write_repository.dart';
import '../../../application/services/pokemon_database_index.dart';
import '../../../application/use_cases/import_external_pokemon_use_cases.dart';
import '../../../application/use_cases/import_pokemon_evolution_json_use_case.dart';
import '../../../application/use_cases/import_pokemon_json_bundle_use_case.dart';
import '../../../application/use_cases/import_pokemon_learnset_json_use_case.dart';
import '../../../application/use_cases/import_pokemon_media_json_use_case.dart';
import '../../../application/use_cases/import_pokemon_species_json_use_case.dart';
import '../../../application/use_cases/load_pokedex_species_detail_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_evolution_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_forms_classification_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_learnset_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_metadata_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_media_use_case.dart';
import '../../../infrastructure/external/pokeapi_live_source.dart';
import '../../../infrastructure/external/showdown_snapshot_source.dart';
import '../../../infrastructure/repositories/http_pokemon_external_source_repository.dart';
import '../../../infrastructure/repositories/file_repositories.dart';
import '../../../ui/canvas/pokedex_workspace_loader.dart';
import '../core/repository_providers.dart';

/// Wiring Pokédex local minimal.
///
/// Ce fichier reste volontairement petit et thématique :
/// - le workspace Pokédex n'instancie plus l'infrastructure directement ;
/// - on réutilise les repositories/services existants ;
/// - on ne crée pas un nouveau notifier ni une couche "future-proof" inutile.
final pokemonReadRepositoryProvider = Provider<PokemonReadRepository>((ref) {
  return const FilePokemonReadRepository();
});

final pokemonWriteRepositoryProvider = Provider<PokemonWriteRepository>((ref) {
  return const FilePokemonWriteRepository();
});

final pokemonExternalHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final pokeApiLiveSourceProvider = Provider<PokeApiLiveSource>((ref) {
  return PokeApiLiveSource(
    client: ref.watch(pokemonExternalHttpClientProvider),
  );
});

final showdownSnapshotSourceProvider = Provider<ShowdownSnapshotSource>((ref) {
  return ShowdownSnapshotSource(
    client: ref.watch(pokemonExternalHttpClientProvider),
  );
});

final pokemonExternalSourceRepositoryProvider =
    Provider<PokemonExternalSourceRepository>((ref) {
  return HttpPokemonExternalSourceRepository(
    pokeApiSource: ref.watch(pokeApiLiveSourceProvider),
    showdownSource: ref.watch(showdownSnapshotSourceProvider),
  );
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

final pokedexListProvider = Provider<PokedexEntryLoader>((ref) {
  return ref.watch(pokedexEntryLoaderProvider);
});

final loadPokedexSpeciesDetailUseCaseProvider =
    Provider<LoadPokedexSpeciesDetailUseCase>((ref) {
  return LoadPokedexSpeciesDetailUseCase(
    ref.watch(pokemonReadRepositoryProvider),
  );
});

final pokedexSpeciesDetailLoaderProvider =
    Provider<PokedexSpeciesDetailLoader>((ref) {
  final useCase = ref.watch(loadPokedexSpeciesDetailUseCaseProvider);
  return (workspace, speciesId) => useCase.execute(workspace, speciesId);
});

final importPokemonSpeciesJsonUseCaseProvider =
    Provider<ImportPokemonSpeciesJsonUseCase>((ref) {
  return ImportPokemonSpeciesJsonUseCase(
    ref.watch(pokemonWriteRepositoryProvider),
  );
});

final importPokemonLearnsetJsonUseCaseProvider =
    Provider<ImportPokemonLearnsetJsonUseCase>((ref) {
  return ImportPokemonLearnsetJsonUseCase(
    ref.watch(pokemonWriteRepositoryProvider),
  );
});

final importPokemonEvolutionJsonUseCaseProvider =
    Provider<ImportPokemonEvolutionJsonUseCase>((ref) {
  return ImportPokemonEvolutionJsonUseCase(
    ref.watch(pokemonWriteRepositoryProvider),
  );
});

final importPokemonMediaJsonUseCaseProvider =
    Provider<ImportPokemonMediaJsonUseCase>((ref) {
  return ImportPokemonMediaJsonUseCase(
    ref.watch(pokemonWriteRepositoryProvider),
  );
});

final importPokemonJsonBundleUseCaseProvider =
    Provider<ImportPokemonJsonBundleUseCase>((ref) {
  return ImportPokemonJsonBundleUseCase(
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
    speciesImportUseCase: ref.watch(importPokemonSpeciesJsonUseCaseProvider),
    learnsetImportUseCase: ref.watch(importPokemonLearnsetJsonUseCaseProvider),
    evolutionImportUseCase:
        ref.watch(importPokemonEvolutionJsonUseCaseProvider),
    mediaImportUseCase: ref.watch(importPokemonMediaJsonUseCaseProvider),
  );
});

final pokedexImportPreviewerProvider = Provider<PokedexImportPreviewer>((ref) {
  final useCase = ref.watch(importPokemonJsonBundleUseCaseProvider);
  return (workspace, absoluteSpeciesSourcePath) => useCase.preview(
        workspace,
        absoluteSpeciesSourcePath: absoluteSpeciesSourcePath,
      );
});

final pokedexImporterProvider = Provider<PokedexImporter>((ref) {
  final useCase = ref.watch(importPokemonJsonBundleUseCaseProvider);
  return (workspace, absoluteSpeciesSourcePath) => useCase.execute(
        workspace,
        absoluteSpeciesSourcePath: absoluteSpeciesSourcePath,
      );
});

final importExternalPokemonSpeciesUseCaseProvider =
    Provider<ImportExternalPokemonSpeciesUseCase>((ref) {
  return ImportExternalPokemonSpeciesUseCase(
    externalSourceRepository:
        ref.watch(pokemonExternalSourceRepositoryProvider),
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
  );
});

final batchImportExternalPokemonSpeciesUseCaseProvider =
    Provider<BatchImportExternalPokemonSpeciesUseCase>((ref) {
  return BatchImportExternalPokemonSpeciesUseCase(
    ref.watch(importExternalPokemonSpeciesUseCaseProvider),
  );
});

final pokedexExternalImportPreviewerProvider =
    Provider<PokedexExternalImportPreviewer>((ref) {
  final useCase = ref.watch(importExternalPokemonSpeciesUseCaseProvider);
  return (workspace, speciesQuery) => useCase.execute(
        workspace,
        speciesId: speciesQuery,
        dryRun: true,
      );
});

final pokedexExternalImporterProvider =
    Provider<PokedexExternalImporter>((ref) {
  final useCase = ref.watch(importExternalPokemonSpeciesUseCaseProvider);
  return (workspace, speciesQuery) => useCase.execute(
        workspace,
        speciesId: speciesQuery,
      );
});

final updatePokedexSpeciesMetadataUseCaseProvider =
    Provider<UpdatePokedexSpeciesMetadataUseCase>((ref) {
  return UpdatePokedexSpeciesMetadataUseCase(
    readRepository: ref.watch(pokemonReadRepositoryProvider),
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
  );
});

final pokedexSpeciesMetadataSaverProvider =
    Provider<PokedexSpeciesMetadataSaver>((ref) {
  final useCase = ref.watch(updatePokedexSpeciesMetadataUseCaseProvider);
  return (workspace, request) => useCase.execute(workspace, request);
});

final updatePokedexSpeciesFormsClassificationUseCaseProvider =
    Provider<UpdatePokedexSpeciesFormsClassificationUseCase>((ref) {
  return UpdatePokedexSpeciesFormsClassificationUseCase(
    readRepository: ref.watch(pokemonReadRepositoryProvider),
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
  );
});

final pokedexSpeciesFormsClassificationSaverProvider =
    Provider<PokedexSpeciesFormsClassificationSaver>((ref) {
  final useCase = ref.watch(
    updatePokedexSpeciesFormsClassificationUseCaseProvider,
  );
  return (workspace, request) => useCase.execute(workspace, request);
});

final updatePokedexSpeciesLearnsetUseCaseProvider =
    Provider<UpdatePokedexSpeciesLearnsetUseCase>((ref) {
  return UpdatePokedexSpeciesLearnsetUseCase(
    readRepository: ref.watch(pokemonReadRepositoryProvider),
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
  );
});

final pokedexSpeciesLearnsetSaverProvider =
    Provider<PokedexSpeciesLearnsetSaver>((ref) {
  final useCase = ref.watch(updatePokedexSpeciesLearnsetUseCaseProvider);
  return (workspace, request) => useCase.execute(workspace, request);
});

final updatePokedexSpeciesEvolutionUseCaseProvider =
    Provider<UpdatePokedexSpeciesEvolutionUseCase>((ref) {
  return UpdatePokedexSpeciesEvolutionUseCase(
    readRepository: ref.watch(pokemonReadRepositoryProvider),
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
  );
});

final pokedexSpeciesEvolutionSaverProvider =
    Provider<PokedexSpeciesEvolutionSaver>((ref) {
  final useCase = ref.watch(updatePokedexSpeciesEvolutionUseCaseProvider);
  return (workspace, request) => useCase.execute(workspace, request);
});

final updatePokedexSpeciesMediaUseCaseProvider =
    Provider<UpdatePokedexSpeciesMediaUseCase>((ref) {
  return UpdatePokedexSpeciesMediaUseCase(
    readRepository: ref.watch(pokemonReadRepositoryProvider),
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
  );
});

final pokedexSpeciesMediaSaverProvider =
    Provider<PokedexSpeciesMediaSaver>((ref) {
  final useCase = ref.watch(updatePokedexSpeciesMediaUseCaseProvider);
  return (workspace, request) => useCase.execute(workspace, request);
});
