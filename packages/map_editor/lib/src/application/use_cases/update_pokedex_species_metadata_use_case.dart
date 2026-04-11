import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/pokemon_read_repository.dart';
import '../ports/pokemon_write_repository.dart';
import '../ports/project_workspace.dart';

/// Représente la seule surface d'édition Pokédex autorisée en phase 8A.
///
/// Le périmètre est volontairement serré :
/// - `classification.isEnabledInProject` pour le lot 37 ;
/// - quelques métadonnées simples pour le lot 39 ;
/// - aucun learnset ;
/// - aucune évolution ;
/// - aucun média ;
/// - aucune ref locale ;
/// - aucune forme riche ;
/// - aucune classification avancée hors du flag `isEnabledInProject`.
class UpdatePokedexSpeciesMetadataRequest {
  const UpdatePokedexSpeciesMetadataRequest({
    required this.speciesId,
    required this.isEnabledInProject,
    required this.names,
    required this.flavorText,
    required this.starterEligible,
    required this.giftOnly,
    required this.tradeOnly,
  });

  final String speciesId;
  final bool isEnabledInProject;
  final Map<String, String> names;
  final String? flavorText;
  final bool starterEligible;
  final bool giftOnly;
  final bool tradeOnly;
}

typedef PokedexSpeciesMetadataSaver = Future<PokemonSpeciesFile> Function(
  ProjectWorkspace workspace,
  UpdatePokedexSpeciesMetadataRequest request,
);

/// Réécrit une espèce locale en ne touchant qu'aux métadonnées simples déjà
/// supportées par le modèle courant.
///
/// Pourquoi un use case dédié :
/// - la UI ne doit pas reconstruire elle-même un `PokemonSpeciesFile` complet ;
/// - l'espèce locale reste la source de vérité unique ;
/// - on relit l'espèce existante puis on ne remplace que les champs autorisés ;
/// - on délègue l'écriture au repository existant pour préserver le vrai chemin
///   du fichier espèce déjà présent.
class UpdatePokedexSpeciesMetadataUseCase {
  const UpdatePokedexSpeciesMetadataUseCase({
    required this.readRepository,
    required this.writeRepository,
  });

  final PokemonReadRepository readRepository;
  final PokemonWriteRepository writeRepository;

  Future<PokemonSpeciesFile> execute(
    ProjectWorkspace workspace,
    UpdatePokedexSpeciesMetadataRequest request,
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

    // On ne reconstruit jamais l'espèce "depuis zéro" dans la UI.
    // Le but est précisément de préserver :
    // - les refs ;
    // - les formes ;
    // - la classification lourde ;
    // - les stats et autres blocs hors périmètre.
    final updatedSpecies = PokemonSpeciesFile(
      id: currentSpecies.id,
      slug: currentSpecies.slug,
      nationalDex: currentSpecies.nationalDex,
      names: _normalizeLocalizedValues(request.names),
      speciesName: currentSpecies.speciesName,
      genIntroduced: currentSpecies.genIntroduced,
      typing: currentSpecies.typing,
      baseStats: currentSpecies.baseStats,
      abilities: currentSpecies.abilities,
      breeding: currentSpecies.breeding,
      progression: currentSpecies.progression,
      forms: currentSpecies.forms,
      classification: PokemonSpeciesClassification(
        // Lot 37 : c'est l'unique source de vérité du statut projet.
        isEnabledInProject: request.isEnabledInProject,
        isObtainable: currentSpecies.classification.isObtainable,
        isLegendary: currentSpecies.classification.isLegendary,
        isMythical: currentSpecies.classification.isMythical,
        isBaby: currentSpecies.classification.isBaby,
      ),
      // On préserve les refs à l'identique : lot 39 ne doit pas casser
      // learnset / évolution / média au passage.
      refs: currentSpecies.refs,
      dexContent: PokemonSpeciesDexContent(
        heightM: currentSpecies.dexContent.heightM,
        weightKg: currentSpecies.dexContent.weightKg,
        color: currentSpecies.dexContent.color,
        flavorText: _normalizeOptionalText(request.flavorText),
      ),
      gameplayFlags: PokemonSpeciesGameplayFlags(
        starterEligible: request.starterEligible,
        giftOnly: request.giftOnly,
        tradeOnly: request.tradeOnly,
      ),
      sourceMeta: currentSpecies.sourceMeta,
    );

    await writeRepository.saveSpecies(workspace, updatedSpecies);
    return updatedSpecies;
  }

  Map<String, String> _normalizeLocalizedValues(Map<String, String> values) {
    final normalized = <String, String>{};

    // On reste volontairement permissif ici :
    // - pas de nouvelle règle métier sur les locales ;
    // - pas de suppression implicite d'une clé ;
    // - on trim seulement les clés et valeurs pour éviter de persister du bruit.
    //
    // La UI de la phase 8A n'ajoute ni ne retire de locales ; elle ne modifie
    // que les valeurs déjà présentes. Cette normalisation minimale suffit donc.
    for (final entry in values.entries) {
      final locale = entry.key.trim();
      if (locale.isEmpty) {
        continue;
      }
      normalized[locale] = entry.value.trim();
    }

    return normalized;
  }

  String? _normalizeOptionalText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
