import 'dart:convert';

import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/pokemon_write_repository.dart';
import '../ports/project_workspace.dart';

/// Importe un learnset Pokémon déjà au format JSON interne du projet.
///
/// Ce use case reste volontairement petit pour le lot 24 :
/// - on lit un seul fichier JSON source ;
/// - on parse directement vers [PokemonLearnsetFile] ;
/// - on applique seulement une validation structurelle minimale ;
/// - on délègue ensuite l'écriture au repository local existant.
///
/// Non-objectifs explicites de ce lot :
/// - pas d'UI ;
/// - pas de batch import ;
/// - pas de merge policy ;
/// - pas de dry-run ;
/// - pas de validation catalogue croisée complète ;
/// - pas de pipeline générique "pour préparer la suite".
class ImportPokemonLearnsetJsonUseCase {
  const ImportPokemonLearnsetJsonUseCase(this.writeRepository);

  final PokemonWriteRepository writeRepository;

  Future<PokemonLearnsetFile> execute(
    ProjectWorkspace workspace, {
    required String absoluteSourcePath,
  }) async {
    final sourcePath = absoluteSourcePath.trim();
    if (sourcePath.isEmpty) {
      throw const EditorValidationException(
        'Pokemon learnset source path cannot be empty',
      );
    }
    if (!await workspace.fileExists(sourcePath)) {
      throw const EditorValidationException(
        'Pokemon learnset source file not found',
      );
    }
    if (!sourcePath.toLowerCase().endsWith('.json')) {
      throw const EditorValidationException(
        'Pokemon learnset import expects a .json file',
      );
    }

    final raw = await workspace.readTextFile(sourcePath);
    final decoded = _decodeJsonRoot(raw);
    final learnset = _parseLearnset(decoded);
    _validateLearnset(learnset);

    await writeRepository.saveLearnset(workspace, learnset);
    return learnset;
  }

  Map<String, dynamic> _decodeJsonRoot(String raw) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (error) {
      throw EditorPersistenceException(
        'Pokemon learnset JSON is invalid: ${error.message}',
      );
    }

    if (decoded is! Map) {
      throw const EditorPersistenceException(
        'Pokemon learnset JSON root must be an object',
      );
    }

    return decoded.cast<String, dynamic>();
  }

  PokemonLearnsetFile _parseLearnset(Map<String, dynamic> decoded) {
    try {
      return PokemonLearnsetFile.fromJson(decoded);
    } catch (error) {
      throw EditorPersistenceException(
        'Pokemon learnset JSON structure is invalid: $error',
      );
    }
  }

  void _validateLearnset(PokemonLearnsetFile learnset) {
    // On reste sur une validation structurelle minimale.
    // Le but est de refuser les learnsets inutilisables dès l'import, sans
    // réimplémenter ici tout le validateur projet plus riche.
    if (learnset.speciesId.trim().isEmpty) {
      throw const EditorValidationException(
        'Pokemon learnset speciesId cannot be empty',
      );
    }

    // Un learnset totalement vide serait techniquement sérialisable, mais il
    // n'apporte rien au pipeline Pokédex actuel. On le refuse donc dès ce lot
    // pour garder un import unitaire utile et prévisible.
    final hasAnySection = learnset.startingMoves.isNotEmpty ||
        learnset.relearnMoves.isNotEmpty ||
        learnset.levelUp.isNotEmpty ||
        learnset.tm.isNotEmpty ||
        learnset.tutor.isNotEmpty ||
        learnset.egg.isNotEmpty ||
        learnset.event.isNotEmpty ||
        learnset.transfer.isNotEmpty;
    if (!hasAnySection) {
      throw const EditorValidationException(
        'Pokemon learnset must contain at least one move section',
      );
    }

    for (final moveId in learnset.startingMoves) {
      if (moveId.trim().isEmpty) {
        throw const EditorValidationException(
          'Pokemon learnset startingMoves cannot contain empty move ids',
        );
      }
    }

    for (final moveId in learnset.relearnMoves) {
      if (moveId.trim().isEmpty) {
        throw const EditorValidationException(
          'Pokemon learnset relearnMoves cannot contain empty move ids',
        );
      }
    }

    // Les entrées level-up sont les plus structurées du modèle courant.
    // On exige donc explicitement leurs champs minimaux au lieu de laisser
    // passer des objets partiellement vides qui casseraient ensuite l'affichage.
    for (final entry in learnset.levelUp) {
      if (entry.moveId.trim().isEmpty) {
        throw const EditorValidationException(
          'Pokemon learnset levelUp moveId cannot be empty',
        );
      }
      if (entry.level <= 0) {
        throw const EditorValidationException(
          'Pokemon learnset levelUp level must be positive',
        );
      }
      if (entry.source.trim().isEmpty) {
        throw const EditorValidationException(
          'Pokemon learnset levelUp source cannot be empty',
        );
      }
      if (entry.versionGroup.trim().isEmpty) {
        throw const EditorValidationException(
          'Pokemon learnset levelUp versionGroup cannot be empty',
        );
      }
    }

    // Les autres familles partagent un format plus simple : move + versionGroup.
    // On reste donc très local et on valide seulement ces deux champs.
    void validateMoveEntries(
      List<PokemonLearnsetMoveEntry> entries,
      String label,
    ) {
      for (final entry in entries) {
        if (entry.moveId.trim().isEmpty) {
          throw EditorValidationException(
            'Pokemon learnset $label moveId cannot be empty',
          );
        }
        if (entry.versionGroup.trim().isEmpty) {
          throw EditorValidationException(
            'Pokemon learnset $label versionGroup cannot be empty',
          );
        }
      }
    }

    validateMoveEntries(learnset.tm, 'tm');
    validateMoveEntries(learnset.tutor, 'tutor');
    validateMoveEntries(learnset.egg, 'egg');
    validateMoveEntries(learnset.event, 'event');
    validateMoveEntries(learnset.transfer, 'transfer');
  }
}
