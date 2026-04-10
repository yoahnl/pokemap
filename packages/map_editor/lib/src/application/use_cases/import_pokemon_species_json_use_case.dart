import 'dart:convert';

import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/pokemon_write_repository.dart';
import '../ports/project_workspace.dart';

/// Importe une espèce Pokémon déjà au format JSON interne du projet.
///
/// Le contrat reste volontairement petit pour le lot 23 :
/// - on lit un seul fichier JSON source ;
/// - on parse directement vers [PokemonSpeciesFile] ;
/// - on valide seulement les champs structurels indispensables avant écriture ;
/// - on délègue ensuite l'écriture au repository local existant.
///
/// On n'introduit ici :
/// - ni merge policy avancée ;
/// - ni import learnset/évolution/média ;
/// - ni orchestration batch ;
/// - ni logique UI.
class ImportPokemonSpeciesJsonUseCase {
  const ImportPokemonSpeciesJsonUseCase(this.writeRepository);

  final PokemonWriteRepository writeRepository;

  Future<PokemonSpeciesFile> execute(
    ProjectWorkspace workspace, {
    required String absoluteSourcePath,
  }) async {
    final sourcePath = absoluteSourcePath.trim();
    if (sourcePath.isEmpty) {
      throw const EditorValidationException(
        'Pokemon species source path cannot be empty',
      );
    }
    if (!await workspace.fileExists(sourcePath)) {
      throw const EditorValidationException(
        'Pokemon species source file not found',
      );
    }
    if (!sourcePath.toLowerCase().endsWith('.json')) {
      throw const EditorValidationException(
        'Pokemon species import expects a .json file',
      );
    }

    final raw = await workspace.readTextFile(sourcePath);
    final decoded = _decodeJsonRoot(raw);
    final species = _parseSpecies(decoded);
    _validateSpecies(species);

    await writeRepository.saveSpecies(workspace, species);
    return species;
  }

  Map<String, dynamic> _decodeJsonRoot(String raw) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (error) {
      throw EditorPersistenceException(
        'Pokemon species JSON is invalid: ${error.message}',
      );
    }

    if (decoded is! Map) {
      throw const EditorPersistenceException(
        'Pokemon species JSON root must be an object',
      );
    }

    return decoded.cast<String, dynamic>();
  }

  PokemonSpeciesFile _parseSpecies(Map<String, dynamic> decoded) {
    try {
      return PokemonSpeciesFile.fromJson(decoded);
    } catch (error) {
      throw EditorPersistenceException(
        'Pokemon species JSON structure is invalid: $error',
      );
    }
  }

  void _validateSpecies(PokemonSpeciesFile species) {
    // On reste volontairement sur une validation structurelle minimale.
    // Le but de ce lot n'est pas de reconstruire tout le validateur Pokédex,
    // mais de refuser immédiatement les espèces qui ne peuvent pas alimenter
    // le pipeline actuel de manière sûre et prévisible.
    //
    // Les contrôles catalogue/références croisées plus riches vivent déjà dans
    // le validateur projet dédié et ne doivent pas être dupliqués ici.
    if (species.id.trim().isEmpty) {
      throw const EditorValidationException(
        'Pokemon species id cannot be empty',
      );
    }
    if (species.slug.trim().isEmpty) {
      throw const EditorValidationException(
        'Pokemon species slug cannot be empty',
      );
    }
    if (species.nationalDex <= 0) {
      throw const EditorValidationException(
        'Pokemon species nationalDex must be positive',
      );
    }
    // Le pipeline Pokédex courant s'appuie déjà sur la génération introduite
    // pour les filtres et la présentation. Une valeur nulle ou négative rend
    // l'entrée structurellement inutilisable dès l'import.
    if (species.genIntroduced <= 0) {
      throw const EditorValidationException(
        'Pokemon species genIntroduced must be positive',
      );
    }
    final hasName =
        species.names.values.any((value) => value.trim().isNotEmpty);
    if (!hasName) {
      throw const EditorValidationException(
        'Pokemon species names cannot be empty',
      );
    }
    final typeIds =
        species.typing.types.where((value) => value.trim().isNotEmpty);
    if (typeIds.isEmpty) {
      throw const EditorValidationException(
        'Pokemon species must declare at least one type',
      );
    }

    // Contrairement au chargement tolérant des annexes dans la vue détail,
    // ce lot d'import doit refuser une espèce "orpheline" dès l'entrée.
    // Les trois refs sont obligatoires ici parce que le pipeline Pokédex
    // actuel attend une espèce directement raccordable à ses fichiers annexes.
    // On reste volontairement local : on vérifie seulement que les refs
    // existent textuellement, sans ouvrir le chantier de validation croisée.
    if (species.refs.learnset.trim().isEmpty) {
      throw const EditorValidationException(
        'Pokemon species refs.learnset cannot be empty',
      );
    }
    if (species.refs.evolution.trim().isEmpty) {
      throw const EditorValidationException(
        'Pokemon species refs.evolution cannot be empty',
      );
    }
    if (species.refs.media.trim().isEmpty) {
      throw const EditorValidationException(
        'Pokemon species refs.media cannot be empty',
      );
    }
  }
}
