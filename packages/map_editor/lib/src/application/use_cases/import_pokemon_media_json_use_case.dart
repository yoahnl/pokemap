import 'dart:convert';

import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/pokemon_write_repository.dart';
import '../ports/project_workspace.dart';

/// Importe un fichier média Pokémon déjà au format JSON interne du projet.
///
/// Le lot 26 reste volontairement symétrique avec les lots 23, 24 et 25 :
/// - un seul fichier source ;
/// - parsing direct vers [PokemonMediaFile] ;
/// - validation structurelle minimale, locale et explicite ;
/// - écriture via le repository local existant.
///
/// Non-objectifs assumés :
/// - pas d'UI ;
/// - pas de batch ;
/// - pas de merge policy ;
/// - pas de dry-run ;
/// - pas de vérification disque des assets référencés ;
/// - pas de validation croisée riche avec les espèces, formes ou catalogues.
class ImportPokemonMediaJsonUseCase {
  const ImportPokemonMediaJsonUseCase(this.writeRepository);

  final PokemonWriteRepository writeRepository;

  Future<PokemonMediaFile> execute(
    ProjectWorkspace workspace, {
    required String absoluteSourcePath,
  }) async {
    final sourcePath = absoluteSourcePath.trim();
    if (sourcePath.isEmpty) {
      throw const EditorValidationException(
        'Pokemon media source path cannot be empty',
      );
    }
    if (!await workspace.fileExists(sourcePath)) {
      throw const EditorValidationException(
        'Pokemon media source file not found',
      );
    }
    if (!sourcePath.toLowerCase().endsWith('.json')) {
      throw const EditorValidationException(
        'Pokemon media import expects a .json file',
      );
    }

    final raw = await workspace.readTextFile(sourcePath);
    final decoded = _decodeJsonRoot(raw);
    final media = _parseMedia(decoded);
    _validateMedia(media);

    await writeRepository.saveMedia(workspace, media);
    return media;
  }

  Map<String, dynamic> _decodeJsonRoot(String raw) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (error) {
      throw EditorPersistenceException(
        'Pokemon media JSON is invalid: ${error.message}',
      );
    }

    if (decoded is! Map) {
      throw const EditorPersistenceException(
        'Pokemon media JSON root must be an object',
      );
    }

    return decoded.cast<String, dynamic>();
  }

  PokemonMediaFile _parseMedia(Map<String, dynamic> decoded) {
    try {
      return PokemonMediaFile.fromJson(decoded);
    } catch (error) {
      throw EditorPersistenceException(
        'Pokemon media JSON structure is invalid: $error',
      );
    }
  }

  void _validateMedia(PokemonMediaFile media) {
    // On reste volontairement sur une validation locale.
    // Le but est de rejeter les fichiers média inutilisables dès l'import,
    // sans transformer ce lot en validateur Pokédex global.
    final speciesId = media.speciesId.trim();
    if (speciesId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon media speciesId cannot be empty',
      );
    }

    final defaultFormId = media.defaultFormId.trim();
    if (defaultFormId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon media defaultFormId cannot be empty',
      );
    }

    if (media.variants.isEmpty) {
      throw const EditorValidationException(
        'Pokemon media must define at least one variant',
      );
    }

    // Le pipeline courant s'appuie sur une variante par défaut concrète.
    // On exige donc qu'elle soit bien présente dans la map des variantes.
    if (!media.variants.containsKey(defaultFormId)) {
      throw const EditorValidationException(
        'Pokemon media defaultFormId must exist in variants',
      );
    }

    var hasAnyUsableMediaReference = false;

    for (final entry in media.variants.entries) {
      final variantId = entry.key.trim();
      final variant = entry.value;

      if (variantId.isEmpty) {
        throw const EditorValidationException(
          'Pokemon media variant ids cannot be empty',
        );
      }

      for (final animationEntry in variant.animations.entries) {
        final animationKey = animationEntry.key.trim();
        final animation = animationEntry.value;

        // Une animation déclarée avec une clé vide n'est pas adressable
        // proprement par les vues ou le runtime ; on la refuse ici.
        if (animationKey.isEmpty) {
          throw const EditorValidationException(
            'Pokemon media animation keys cannot be empty',
          );
        }
        if (animation.sheet.trim().isEmpty) {
          throw const EditorValidationException(
            'Pokemon media animation sheet cannot be empty',
          );
        }
        if (animation.animationId.trim().isEmpty) {
          throw const EditorValidationException(
            'Pokemon media animationId cannot be empty',
          );
        }
      }

      if (_variantHasUsableData(variant)) {
        hasAnyUsableMediaReference = true;
      }
    }

    // On ne demande pas que chaque variante soit complète, seulement que le
    // fichier média apporte au moins une référence exploitable au pipeline.
    if (!hasAnyUsableMediaReference) {
      throw const EditorValidationException(
        'Pokemon media must contain at least one media reference',
      );
    }
  }

  bool _variantHasUsableData(PokemonMediaVariant variant) {
    return <String?>[
          variant.frontStatic,
          variant.backStatic,
          variant.frontShinyStatic,
          variant.backShinyStatic,
          variant.icon,
          variant.party,
          variant.overworld,
          variant.portrait,
          variant.cry,
        ].any((value) => value != null && value.trim().isNotEmpty) ||
        variant.animations.isNotEmpty;
  }
}
