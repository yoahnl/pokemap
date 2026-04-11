import 'dart:convert';

import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/pokemon_write_repository.dart';
import '../ports/project_workspace.dart';

/// Importe un catalogue Pokémon global déjà au format JSON interne du projet.
///
/// Ce lot 27 reste volontairement très petit, comme les lots 23 à 26 :
/// - on lit un seul fichier JSON source ;
/// - on parse directement vers [PokemonCatalogFile] ;
/// - on applique seulement une validation structurelle minimale ;
/// - on délègue ensuite l'écriture au repository local existant.
///
/// Non-objectifs explicites :
/// - pas d'UI ;
/// - pas de batch import ;
/// - pas de merge policy ;
/// - pas de dry-run ;
/// - pas de validation croisée riche avec espèces, learnsets ou médias ;
/// - pas de pipeline générique "préparé pour la suite".
class ImportPokemonCatalogJsonUseCase {
  const ImportPokemonCatalogJsonUseCase(this.writeRepository);

  final PokemonWriteRepository writeRepository;

  Future<PokemonCatalogFile> execute(
    ProjectWorkspace workspace, {
    required String catalogKey,
    required String absoluteSourcePath,
  }) async {
    final trimmedCatalogKey = catalogKey.trim();
    if (trimmedCatalogKey.isEmpty) {
      throw const EditorValidationException(
        'Pokemon catalog key cannot be empty',
      );
    }

    final sourcePath = absoluteSourcePath.trim();
    if (sourcePath.isEmpty) {
      throw const EditorValidationException(
        'Pokemon catalog source path cannot be empty',
      );
    }
    if (!await workspace.fileExists(sourcePath)) {
      throw const EditorValidationException(
        'Pokemon catalog source file not found',
      );
    }
    if (!sourcePath.toLowerCase().endsWith('.json')) {
      throw const EditorValidationException(
        'Pokemon catalog import expects a .json file',
      );
    }

    final raw = await workspace.readTextFile(sourcePath);
    final decoded = _decodeJsonRoot(raw);
    final catalog = _parseCatalog(decoded);
    _validateCatalog(trimmedCatalogKey, catalog);

    await writeRepository.saveCatalogByKey(
        workspace, trimmedCatalogKey, catalog);
    return catalog;
  }

  Map<String, dynamic> _decodeJsonRoot(String raw) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (error) {
      throw EditorPersistenceException(
        'Pokemon catalog JSON is invalid: ${error.message}',
      );
    }

    if (decoded is! Map) {
      throw const EditorPersistenceException(
        'Pokemon catalog JSON root must be an object',
      );
    }

    return decoded.cast<String, dynamic>();
  }

  PokemonCatalogFile _parseCatalog(Map<String, dynamic> decoded) {
    try {
      return PokemonCatalogFile.fromJson(decoded);
    } catch (error) {
      throw EditorPersistenceException(
        'Pokemon catalog JSON structure is invalid: $error',
      );
    }
  }

  void _validateCatalog(String catalogKey, PokemonCatalogFile catalog) {
    // On reste volontairement sur une validation très locale.
    // Le but est de rejeter les catalogues qui sont immédiatement
    // inutilisables pour le storage Pokédex, sans dupliquer ici la logique
    // d'un validateur métier global sur tous les référentiels.
    if (catalog.schemaVersion <= 0) {
      throw const EditorValidationException(
        'Pokemon catalog schemaVersion must be positive',
      );
    }
    if (catalog.kind.trim().isEmpty) {
      throw const EditorValidationException(
        'Pokemon catalog kind cannot be empty',
      );
    }
    if (catalog.catalog.trim().isEmpty) {
      throw const EditorValidationException(
        'Pokemon catalog name cannot be empty',
      );
    }

    // Ce lot importe un catalogue interne déjà normalisé. On attend donc le
    // kind de catalogue actuellement utilisé dans le projet, sans commencer à
    // gérer ici d'autres familles de payloads.
    if (catalog.kind.trim() != 'pokemon_catalog') {
      throw const EditorValidationException(
        'Pokemon catalog kind must be pokemon_catalog',
      );
    }

    // Une incohérence simple entre la clé demandée et le contenu du fichier
    // est déjà une erreur structurelle exploitable en review. On la signale
    // ici avec le même message que le repository pour garder un comportement
    // stable et lisible côté tests.
    if (catalog.catalog.trim() != catalogKey) {
      throw EditorValidationException(
        'Pokemon catalog key mismatch: requested "$catalogKey" but payload is '
        '"${catalog.catalog.trim()}"',
      );
    }

    if (catalog.meta.description.trim().isEmpty) {
      throw const EditorValidationException(
        'Pokemon catalog meta.description cannot be empty',
      );
    }
    if (catalog.entries.isEmpty) {
      throw const EditorValidationException(
        'Pokemon catalog entries cannot be empty',
      );
    }

    // Les catalogues globaux existants du projet sont tous indexés par `id`.
    // On vérifie donc seulement ce contrat minimal, sans sur-typer chaque
    // forme d'entrée ni reconstruire ici la validation spécifique par catalogue.
    for (final entry in catalog.entries) {
      final id = (entry['id'] as String?)?.trim() ?? '';
      if (id.isEmpty) {
        throw const EditorValidationException(
          'Pokemon catalog entries must define a non-empty id',
        );
      }
    }
  }
}
