import 'dart:convert';

import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/pokemon_write_repository.dart';
import '../ports/project_workspace.dart';

/// Importe un fichier d'évolution Pokémon déjà au format JSON interne.
///
/// Le lot 25 reste volontairement petit :
/// - un seul fichier source ;
/// - parsing direct vers [PokemonEvolutionFile] ;
/// - validation structurelle minimale ;
/// - écriture via le repository local existant.
///
/// Non-objectifs assumés :
/// - pas d'UI ;
/// - pas de batch ;
/// - pas de merge policy ;
/// - pas de dry-run ;
/// - pas de validation croisée riche avec toutes les espèces du projet ;
/// - pas d'import learnset, média ou catalogue.
class ImportPokemonEvolutionJsonUseCase {
  const ImportPokemonEvolutionJsonUseCase(this.writeRepository);

  final PokemonWriteRepository writeRepository;

  Future<PokemonEvolutionFile> execute(
    ProjectWorkspace workspace, {
    required String absoluteSourcePath,
  }) async {
    final sourcePath = absoluteSourcePath.trim();
    if (sourcePath.isEmpty) {
      throw const EditorValidationException(
        'Pokemon evolution source path cannot be empty',
      );
    }
    if (!await workspace.fileExists(sourcePath)) {
      throw const EditorValidationException(
        'Pokemon evolution source file not found',
      );
    }
    if (!sourcePath.toLowerCase().endsWith('.json')) {
      throw const EditorValidationException(
        'Pokemon evolution import expects a .json file',
      );
    }

    final raw = await workspace.readTextFile(sourcePath);
    final decoded = _decodeJsonRoot(raw);
    final evolution = _parseEvolution(decoded);
    _validateEvolution(evolution);

    await writeRepository.saveEvolution(workspace, evolution);
    return evolution;
  }

  Map<String, dynamic> _decodeJsonRoot(String raw) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (error) {
      throw EditorPersistenceException(
        'Pokemon evolution JSON is invalid: ${error.message}',
      );
    }

    if (decoded is! Map) {
      throw const EditorPersistenceException(
        'Pokemon evolution JSON root must be an object',
      );
    }

    return decoded.cast<String, dynamic>();
  }

  PokemonEvolutionFile _parseEvolution(Map<String, dynamic> decoded) {
    try {
      return PokemonEvolutionFile.fromJson(decoded);
    } catch (error) {
      throw EditorPersistenceException(
        'Pokemon evolution JSON structure is invalid: $error',
      );
    }
  }

  void _validateEvolution(PokemonEvolutionFile evolution) {
    // On garde une validation volontairement locale.
    // Le but de ce lot est seulement d'écarter les fichiers d'évolution
    // inutilisables dès l'import, sans ouvrir le chantier d'une validation
    // Pokédex globale plus riche.
    final speciesId = evolution.speciesId.trim();
    if (speciesId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon evolution speciesId cannot be empty',
      );
    }

    final hasPreEvolution = evolution.preEvolution != null &&
        evolution.preEvolution!.trim().isNotEmpty;
    if (!hasPreEvolution && evolution.evolutions.isEmpty) {
      throw const EditorValidationException(
        'Pokemon evolution must define preEvolution or evolutions',
      );
    }

    for (final entry in evolution.evolutions) {
      final targetSpeciesId = entry.targetSpeciesId.trim();
      if (targetSpeciesId.isEmpty) {
        throw const EditorValidationException(
          'Pokemon evolution targetSpeciesId cannot be empty',
        );
      }
      if (targetSpeciesId == speciesId) {
        throw const EditorValidationException(
          'Pokemon evolution cannot target itself',
        );
      }
      if (entry.method.trim().isEmpty) {
        throw const EditorValidationException(
          'Pokemon evolution method cannot be empty',
        );
      }

      // On n'interprète pas toutes les méthodes dans ce lot.
      // On encode juste la règle minimale déjà cohérente avec le validateur
      // projet : un `level_up` avec `minLevel` renseigné doit rester positif.
      if (entry.method.trim() == 'level_up' &&
          entry.minLevel != null &&
          entry.minLevel! <= 0) {
        throw const EditorValidationException(
          'Pokemon evolution minLevel must be positive for level_up',
        );
      }
    }
  }
}
