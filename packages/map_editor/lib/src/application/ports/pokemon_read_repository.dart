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

  Future<PokemonSpeciesFile> readSpeciesById(
    ProjectWorkspace workspace,
    String speciesId,
  );

  Future<PokemonLearnsetFile> readLearnsetById(
    ProjectWorkspace workspace,
    String speciesId,
  );

  Future<PokemonEvolutionFile> readEvolutionById(
    ProjectWorkspace workspace,
    String speciesId,
  );
}
