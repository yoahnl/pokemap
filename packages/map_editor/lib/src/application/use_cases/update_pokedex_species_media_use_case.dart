import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/pokemon_read_repository.dart';
import '../ports/pokemon_write_repository.dart';
import '../ports/project_workspace.dart';

/// Surface d'édition locale du lot 43.
class UpdatePokedexSpeciesMediaRequest {
  const UpdatePokedexSpeciesMediaRequest({
    required this.speciesId,
    required this.defaultFormId,
    required this.variants,
  });

  final String speciesId;
  final String defaultFormId;
  final Map<String, PokemonMediaVariant> variants;
}

typedef PokedexSpeciesMediaSaver = Future<PokemonMediaFile> Function(
  ProjectWorkspace workspace,
  UpdatePokedexSpeciesMediaRequest request,
);

/// Réécrit les références média locales d'une espèce.
///
/// Le lot 43 reste fidèle au contrat courant :
/// - uniquement des chemins/références ;
/// - aucune validation disque ;
/// - aucune génération d'asset ;
/// - aucune image binaire inline.
class UpdatePokedexSpeciesMediaUseCase {
  const UpdatePokedexSpeciesMediaUseCase({
    required this.readRepository,
    required this.writeRepository,
  });

  final PokemonReadRepository readRepository;
  final PokemonWriteRepository writeRepository;

  Future<PokemonMediaFile> execute(
    ProjectWorkspace workspace,
    UpdatePokedexSpeciesMediaRequest request,
  ) async {
    final speciesId = request.speciesId.trim();
    if (speciesId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon species id cannot be empty',
      );
    }

    final currentSpecies = await readRepository.readSpeciesById(
      workspace,
      speciesId,
    );
    final mediaRef = currentSpecies.refs.media.trim();
    if (mediaRef.isEmpty) {
      throw const EditorValidationException(
        'Pokemon species media ref cannot be empty',
      );
    }

    final media = PokemonMediaFile(
      speciesId: mediaRef,
      defaultFormId: request.defaultFormId.trim(),
      variants: _normalizeVariants(request.variants),
    );

    _validateMedia(media);
    await writeRepository.saveMedia(workspace, media);
    return media;
  }

  Map<String, PokemonMediaVariant> _normalizeVariants(
    Map<String, PokemonMediaVariant> values,
  ) {
    final normalized = <String, PokemonMediaVariant>{};

    // On garde l'ordre d'insertion fourni par l'appelant.
    // Cela rend l'affichage UI et les snapshots JSON prévisibles sans
    // imposer ici un tri arbitraire supplémentaire.
    for (final entry in values.entries) {
      final variantId = entry.key.trim();
      if (variantId.isEmpty) {
        continue;
      }

      final variant = entry.value;
      normalized[variantId] = PokemonMediaVariant(
        frontStatic: _normalizeOptionalText(variant.frontStatic),
        backStatic: _normalizeOptionalText(variant.backStatic),
        frontShinyStatic: _normalizeOptionalText(variant.frontShinyStatic),
        backShinyStatic: _normalizeOptionalText(variant.backShinyStatic),
        icon: _normalizeOptionalText(variant.icon),
        party: _normalizeOptionalText(variant.party),
        overworld: _normalizeOptionalText(variant.overworld),
        portrait: _normalizeOptionalText(variant.portrait),
        cry: _normalizeOptionalText(variant.cry),
        animations: _normalizeAnimations(variant.animations),
      );
    }

    return normalized;
  }

  Map<String, PokemonMediaAnimationRef> _normalizeAnimations(
    Map<String, PokemonMediaAnimationRef> values,
  ) {
    final normalized = <String, PokemonMediaAnimationRef>{};
    for (final entry in values.entries) {
      final key = entry.key.trim();
      if (key.isEmpty) {
        continue;
      }

      normalized[key] = PokemonMediaAnimationRef(
        sheet: entry.value.sheet.trim(),
        animationId: entry.value.animationId.trim(),
      );
    }
    return normalized;
  }

  void _validateMedia(PokemonMediaFile media) {
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

  String? _normalizeOptionalText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
