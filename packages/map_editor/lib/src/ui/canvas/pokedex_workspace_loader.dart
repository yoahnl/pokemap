import 'dart:io';

import '../../application/models/pokemon_database_index.dart';
import '../../application/models/pokemon_external_species_search_result.dart';
import '../../application/models/pokedex_species_detail.dart';
import '../../application/ports/project_workspace.dart';
import '../../application/use_cases/import_external_pokemon_use_cases.dart';
import '../../application/use_cases/import_pokemon_json_bundle_use_case.dart';
import '../../application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import '../../application/services/pokemon_database_index.dart';
import '../../domain/repositories/repositories.dart';

typedef PokedexEntryLoader = Future<List<PokemonDatabaseIndexEntry>> Function(
  ProjectWorkspace workspace,
);

typedef PokedexSpeciesDetailLoader = Future<PokedexSpeciesDetail> Function(
  ProjectWorkspace workspace,
  String speciesId,
);

typedef PokedexImportPreviewer = Future<PokemonJsonImportPreview> Function(
  ProjectWorkspace workspace,
  String absoluteSpeciesSourcePath,
);

typedef PokedexImporter = Future<PokemonJsonImportResult> Function(
  ProjectWorkspace workspace,
  String absoluteSpeciesSourcePath,
);

typedef PokedexExternalImportPreviewer = Future<PokemonExternalImportResult>
    Function(
  ProjectWorkspace workspace,
  String speciesQuery,
);

typedef PokedexExternalImporter = Future<PokemonExternalImportResult> Function(
  ProjectWorkspace workspace,
  String speciesQuery,
);

typedef PokedexExternalSpeciesSearcher
    = Future<PokemonExternalSpeciesSearchResult> Function(
  String rawQuery,
);

typedef PokedexMovesCatalogLoader = Future<PokemonMovesCatalogView> Function(
  ProjectWorkspace workspace,
);

typedef PokedexMovesCatalogPreviewer = Future<PokemonMovesCatalogSyncResult>
    Function(
  ProjectWorkspace workspace,
);

typedef PokedexMovesCatalogSyncer = Future<PokemonMovesCatalogSyncResult>
    Function(
  ProjectWorkspace workspace,
);

/// Construit un chargeur d'entrées Pokédex à partir de dépendances injectées.
///
/// Ce helper reste volontairement petit :
/// - l'UI ne compose plus directement l'infrastructure ;
/// - la logique produit locale du workspace Pokédex reste centralisée ;
/// - les tests peuvent injecter des dépendances concrètes ou fake sans devoir
///   reconstruire tout le wiring applicatif.
///
/// Important :
/// - la logique "species absent => liste vide" est traitée ici de façon
///   explicite, avant l'appel au service ;
/// - on ne dépend donc plus d'un `contains(...)` sur le message d'une
///   exception ;
/// - le service applicatif d'indexation garde sa responsabilité actuelle ;
/// - ce helper ne fait que l'adapter au besoin UI local.
PokedexEntryLoader createPokedexEntryLoader({
  required ProjectRepository projectRepository,
  required PokemonDatabaseIndex databaseIndex,
}) {
  return (ProjectWorkspace workspace) async {
    final project =
        await projectRepository.loadProject(workspace.projectManifestPath);
    final speciesDirectoryRelativePath = project.pokemon.speciesDir.trim();

    // On garde volontairement la validation "speciesDir vide" au niveau du
    // service du lot 11. Ici, on ne pré-traite qu'un seul cas produit très
    // précis du lot 13 : un dossier `species/` simplement absent dans un
    // projet encore vide doit rendre un état vide honnête, pas une erreur
    // technique.
    if (speciesDirectoryRelativePath.isNotEmpty) {
      final speciesDirectoryPath = workspace.resolveProjectRelativePath(
        speciesDirectoryRelativePath,
      );
      if (!await Directory(speciesDirectoryPath).exists()) {
        return const <PokemonDatabaseIndexEntry>[];
      }
    }

    return databaseIndex.build(workspace);
  };
}
