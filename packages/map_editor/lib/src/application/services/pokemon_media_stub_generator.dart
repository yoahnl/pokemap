import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';

/// Génère un [PokemonMediaFile] minimal cohérent à partir d'une espèce.
///
/// Ce générateur couvre uniquement le lot 33 :
/// - produire des références locales plausibles ;
/// - rester compatible avec le schéma média actuel ;
/// - ne jamais télécharger ni valider de vrais assets.
///
/// Non-objectifs explicites :
/// - pas de GIF ;
/// - pas de pipeline d'asset import ;
/// - pas de vérification disque ;
/// - pas d'enrichissement UI.
class PokemonMediaStubGenerator {
  const PokemonMediaStubGenerator();

  PokemonMediaFile createStub(PokemonSpeciesFile species) {
    final speciesId = species.id.trim();
    if (speciesId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon media stub speciesId cannot be empty',
      );
    }

    final assetSlug =
        (species.slug.trim().isNotEmpty ? species.slug : speciesId).trim();
    final explicitFormId = species.forms.formId.trim();
    final defaultFormId = explicitFormId.isEmpty ? 'base' : explicitFormId;

    final variantIds = <String>{defaultFormId};
    variantIds.addAll(
      species.forms.otherForms
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty),
    );

    final variants = <String, PokemonMediaVariant>{};
    for (final variantId in variantIds) {
      variants[variantId] = _buildVariant(
        assetSlug: assetSlug,
        variantId: variantId,
        usesRootPaths: variantId == defaultFormId,
      );
    }

    return PokemonMediaFile(
      speciesId: speciesId,
      defaultFormId: defaultFormId,
      variants: variants,
    );
  }

  PokemonMediaVariant _buildVariant({
    required String assetSlug,
    required String variantId,
    required bool usesRootPaths,
  }) {
    // Le stub par défaut pointe vers le dossier racine de l'espèce.
    // Les variantes supplémentaires reçoivent un sous-dossier dédié pour
    // permettre une curation future sans casser le schéma courant.
    final spriteRoot = usesRootPaths
        ? 'assets/pokemon/sprites/$assetSlug'
        : 'assets/pokemon/sprites/$assetSlug/$variantId';
    final portraitPath = usesRootPaths
        ? 'assets/pokemon/portraits/$assetSlug.png'
        : 'assets/pokemon/portraits/$assetSlug/$variantId.png';
    final cryPath = usesRootPaths
        ? 'assets/pokemon/cries/$assetSlug.ogg'
        : 'assets/pokemon/cries/$assetSlug/$variantId.ogg';

    return PokemonMediaVariant(
      frontStatic: '$spriteRoot/front.png',
      backStatic: '$spriteRoot/back.png',
      frontShinyStatic: '$spriteRoot/front_shiny.png',
      backShinyStatic: '$spriteRoot/back_shiny.png',
      icon: '$spriteRoot/icon.png',
      party: '$spriteRoot/party.png',
      overworld: '$spriteRoot/overworld.png',
      portrait: portraitPath,
      cry: cryPath,
      animations: <String, PokemonMediaAnimationRef>{
        'battleFront': PokemonMediaAnimationRef(
          sheet: '$spriteRoot/battle_front_sheet.png',
          animationId: 'battle_front',
        ),
        'battleBack': PokemonMediaAnimationRef(
          sheet: '$spriteRoot/battle_back_sheet.png',
          animationId: 'battle_back',
        ),
      },
    );
  }
}
