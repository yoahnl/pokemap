import '../models/pokemon_database_index.dart';
import '../models/pokemon_project_data_models.dart';
import 'project_workspace.dart';

/// Contrat de lecture des données Pokémon locales d'un projet utilisateur.
///
/// Cette abstraction sert de frontière pour les use cases applicatifs :
/// ils n'ont pas à connaître la stratégie de lecture JSON ni le filesystem.
abstract class PokemonReadRepository {
  Future<PokemonDataManifest> readManifest(ProjectWorkspace workspace);

  Future<PokemonCatalogFile> readCatalogByKey(
    ProjectWorkspace workspace,
    String catalogKey,
  );

  Future<List<PokemonSpeciesIndexEntry>> listSpeciesIndexEntries(
    ProjectWorkspace workspace,
  );

  /// Construit un index leger oriente liste a partir du dossier species
  /// configure par le projet.
  ///
  /// Cette methode ne charge ni learnsets, ni evolutions, ni media detaille.
  /// Elle projette seulement les champs minimaux utiles a une future liste
  /// Pokédex locale.
  Future<List<PokemonDatabaseIndexEntry>> listDatabaseIndexEntries(
    ProjectWorkspace workspace, {
    required String speciesDirectoryRelativePath,
  });

  Future<List<String>> listSpeciesFiles(ProjectWorkspace workspace);

  Future<PokemonSpeciesFile> readSpeciesByRelativePath(
    ProjectWorkspace workspace,
    String relativePath,
  );

  Future<PokemonSpeciesFile> readSpeciesById(
    ProjectWorkspace workspace,
    String speciesId,
  );

  Future<List<String>> listLearnsetIds(ProjectWorkspace workspace);

  Future<PokemonLearnsetFile> readLearnsetById(
    ProjectWorkspace workspace,
    String speciesId,
  );

  Future<List<String>> listEvolutionIds(ProjectWorkspace workspace);

  Future<PokemonEvolutionFile> readEvolutionById(
    ProjectWorkspace workspace,
    String speciesId,
  );
}
