import 'dart:io';

import '../../application/models/pokemon_database_index.dart';
import '../../application/ports/project_workspace.dart';
import '../../application/services/pokemon_database_index.dart';
import '../../infrastructure/repositories/file_repositories.dart';

typedef PokedexEntryLoader = Future<List<PokemonDatabaseIndexEntry>> Function(
  ProjectWorkspace workspace,
);

/// Charge les entrées minimales de liste Pokédex pour le workspace courant.
///
/// Ce helper reste volontairement local au lot 13 :
/// - il évite que le widget UI principal instancie directement toute
///   l'infrastructure ;
/// - il ne crée pas pour autant un nouveau provider, notifier ou framework
///   d'injection ;
/// - il garde la composition concrète dans un endroit unique, reviewable et
///   facile à remplacer dans les tests.
///
/// Important :
/// - la logique "species absent => liste vide" est traitée ici de façon
///   explicite, avant l'appel au service ;
/// - on ne dépend donc plus d'un `contains(...)` sur le message d'une
///   exception ;
/// - on conserve le service applicatif du lot 11 tel quel, sans le transformer
///   en usine à gaz juste pour ce mini-fix.
Future<List<PokemonDatabaseIndexEntry>> loadPokedexEntriesForWorkspace(
  ProjectWorkspace workspace,
) async {
  final projectRepository = FileProjectRepository();
  const pokemonReadRepository = FilePokemonReadRepository();
  final project =
      await projectRepository.loadProject(workspace.projectManifestPath);
  final speciesDirectoryRelativePath = project.pokemon.speciesDir.trim();

  // On garde volontairement la validation "speciesDir vide" au niveau du
  // service du lot 11. Ici, on ne pré-traite qu'un seul cas produit très
  // précis du lot 13 : un dossier `species/` simplement absent dans un projet
  // encore vide doit rendre un état vide honnête, pas une erreur technique.
  if (speciesDirectoryRelativePath.isNotEmpty) {
    final speciesDirectoryPath = workspace.resolveProjectRelativePath(
      speciesDirectoryRelativePath,
    );
    if (!await Directory(speciesDirectoryPath).exists()) {
      return const <PokemonDatabaseIndexEntry>[];
    }
  }

  final service = PokemonDatabaseIndex(
    projectRepository: projectRepository,
    pokemonReadRepository: pokemonReadRepository,
  );
  return service.build(workspace);
}
