import 'package:map_core/map_core.dart';

import '../../domain/repositories/repositories.dart';
import '../errors/application_errors.dart';
import '../models/pokemon_database_index.dart';
import '../ports/pokemon_read_repository.dart';
import '../ports/project_workspace.dart';

/// Service applicatif d'indexation locale des espèces Pokémon.
///
/// Rôle exact du lot 11 :
/// - lire la configuration projet Pokemon depuis `project.json` ;
/// - retrouver le dossier `species` declare par le projet ;
/// - demander au repository de lecture une projection legere des especes ;
/// - ne charger ni learnsets, ni evolutions, ni media detaillé.
///
/// Ce service reste volontairement petit et lisible :
/// - pas de cache ;
/// - pas de watcher ;
/// - pas d'UI ;
/// - pas de recherche ;
/// - pas de validation metier avancée.
class PokemonDatabaseIndex {
  const PokemonDatabaseIndex({
    required this.projectRepository,
    required this.pokemonReadRepository,
  });

  final ProjectRepository projectRepository;
  final PokemonReadRepository pokemonReadRepository;

  /// Indexes the species declared by [workspace].
  ///
  /// Pass [project] when the manifest was already read for this workspace:
  /// loading it again costs a full project snapshot under the manifest write
  /// lock, for a configuration string the caller already holds.
  Future<List<PokemonDatabaseIndexEntry>> build(
    ProjectWorkspace workspace, {
    ProjectManifest? project,
  }) async {
    final manifest =
        project ??
        await projectRepository.loadProject(workspace.projectManifestPath);

    final speciesDirectory = manifest.pokemon.speciesDir.trim();
    if (speciesDirectory.isEmpty) {
      throw const EditorValidationException(
        'Project pokemon speciesDir cannot be empty',
      );
    }

    // Le lot 11 reste strict :
    // on se sert uniquement de la config declarative du projet pour localiser
    // les species, puis on demande une projection legere.
    //
    // On ne lit volontairement pas les autres repertoires Pokemon ici.
    return pokemonReadRepository.listDatabaseIndexEntries(
      workspace,
      speciesDirectoryRelativePath: speciesDirectory,
    );
  }
}
