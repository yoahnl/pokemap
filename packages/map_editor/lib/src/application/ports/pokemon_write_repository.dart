import '../models/pokemon_project_data_models.dart';
import 'project_workspace.dart';

/// Contrat d'écriture des données Pokémon locales d'un projet utilisateur.
///
/// Cette frontière garde les use cases applicatifs découplés de `dart:io`
/// et du layout concret du workspace. Le contrat reste volontairement petit :
/// il couvre uniquement les fichiers JSON déjà stabilisés à ce stade.
abstract class PokemonWriteRepository {
  /// Écrit un catalogue global dans `data/pokemon/catalogs/...`.
  ///
  /// Le `catalogKey` représente la clé logique utilisée dans le manifeste
  /// local (`moves`, `abilities`, `types`, etc.).
  Future<void> saveCatalogByKey(
    ProjectWorkspace workspace,
    String catalogKey,
    PokemonCatalogFile catalog,
  );

  /// Écrit une espèce Pokémon dans `data/pokemon/species/...`.
  ///
  /// Le fichier cible suit la convention déjà présente dans le projet :
  /// `<nationalDex sur 4 chiffres>-<slug ou id>.json`.
  Future<void> saveSpecies(
    ProjectWorkspace workspace,
    PokemonSpeciesFile species,
  );

  /// Écrit un learnset dans `data/pokemon/learnsets/<speciesId>.json`.
  Future<void> saveLearnset(
    ProjectWorkspace workspace,
    PokemonLearnsetFile learnset,
  );

  /// Écrit une évolution dans `data/pokemon/evolutions/<speciesId>.json`.
  Future<void> saveEvolution(
    ProjectWorkspace workspace,
    PokemonEvolutionFile evolution,
  );
}
