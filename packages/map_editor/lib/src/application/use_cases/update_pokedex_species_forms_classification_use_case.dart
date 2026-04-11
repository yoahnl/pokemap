import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/pokemon_read_repository.dart';
import '../ports/pokemon_write_repository.dart';
import '../ports/project_workspace.dart';

/// Surface d'édition locale du lot 40.
///
/// Le périmètre reste volontairement étroit :
/// - formes simples ;
/// - flags de classification déjà présents dans le modèle ;
/// - aucune ref ;
/// - aucun learnset ;
/// - aucune évolution ;
/// - aucun média ;
/// - aucun second flag "enabled", qui reste géré par le lot 37.
class UpdatePokedexSpeciesFormsClassificationRequest {
  const UpdatePokedexSpeciesFormsClassificationRequest({
    required this.speciesId,
    required this.baseFormId,
    required this.isBaseForm,
    required this.formId,
    required this.formName,
    required this.otherForms,
    required this.isObtainable,
    required this.isLegendary,
    required this.isMythical,
    required this.isBaby,
  });

  final String speciesId;
  final String baseFormId;
  final bool isBaseForm;
  final String formId;
  final String? formName;
  final List<String> otherForms;
  final bool isObtainable;
  final bool isLegendary;
  final bool isMythical;
  final bool isBaby;
}

typedef PokedexSpeciesFormsClassificationSaver = Future<PokemonSpeciesFile>
    Function(
  ProjectWorkspace workspace,
  UpdatePokedexSpeciesFormsClassificationRequest request,
);

/// Réécrit localement les formes et la classification simple d'une espèce.
///
/// Pourquoi un use case dédié :
/// - le lot 40 dépasse le petit périmètre "métadonnées overview" du lot 39 ;
/// - on veut préserver le reste de l'espèce sans laisser la UI reconstruire le
///   JSON complet ;
/// - on garde les validations localisées au point d'écriture applicatif.
class UpdatePokedexSpeciesFormsClassificationUseCase {
  const UpdatePokedexSpeciesFormsClassificationUseCase({
    required this.readRepository,
    required this.writeRepository,
  });

  final PokemonReadRepository readRepository;
  final PokemonWriteRepository writeRepository;

  Future<PokemonSpeciesFile> execute(
    ProjectWorkspace workspace,
    UpdatePokedexSpeciesFormsClassificationRequest request,
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
    final formId = request.formId.trim();
    if (formId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon species formId cannot be empty',
      );
    }

    // Si l'espèce est marquée comme forme de base, la seule vérité cohérente
    // est son propre id. On force donc cette valeur ici pour éviter que la UI
    // n'ait à dupliquer cette règle subtile.
    final baseFormId =
        request.isBaseForm ? currentSpecies.id : request.baseFormId.trim();
    if (baseFormId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon species baseFormId cannot be empty',
      );
    }

    final updatedSpecies = PokemonSpeciesFile(
      id: currentSpecies.id,
      slug: currentSpecies.slug,
      nationalDex: currentSpecies.nationalDex,
      names: currentSpecies.names,
      speciesName: currentSpecies.speciesName,
      genIntroduced: currentSpecies.genIntroduced,
      typing: currentSpecies.typing,
      baseStats: currentSpecies.baseStats,
      abilities: currentSpecies.abilities,
      breeding: currentSpecies.breeding,
      progression: currentSpecies.progression,
      forms: PokemonSpeciesForms(
        baseFormId: baseFormId,
        isBaseForm: request.isBaseForm,
        formId: formId,
        formName: _normalizeOptionalText(request.formName),
        otherForms: _normalizeOtherForms(
          request.otherForms,
          currentFormId: formId,
        ),
      ),
      classification: PokemonSpeciesClassification(
        // Le statut projet reste piloté par le lot 37 / overview.
        isEnabledInProject: currentSpecies.classification.isEnabledInProject,
        isObtainable: request.isObtainable,
        isLegendary: request.isLegendary,
        isMythical: request.isMythical,
        isBaby: request.isBaby,
      ),
      refs: currentSpecies.refs,
      dexContent: currentSpecies.dexContent,
      gameplayFlags: currentSpecies.gameplayFlags,
      sourceMeta: currentSpecies.sourceMeta,
    );

    await writeRepository.saveSpecies(workspace, updatedSpecies);
    return updatedSpecies;
  }

  List<String> _normalizeOtherForms(
    List<String> values, {
    required String currentFormId,
  }) {
    final normalized = <String>[];
    final seen = <String>{};

    // On nettoie seulement ce qui est clairement inutilisable :
    // - valeurs vides ;
    // - doublons exacts ;
    // - auto-référence vers la forme courante.
    //
    // On ne trie pas artificiellement : l'ordre affiché dans l'éditeur reste
    // alors l'ordre réellement choisi par la personne qui édite.
    for (final rawValue in values) {
      final value = rawValue.trim();
      if (value.isEmpty || value == currentFormId || !seen.add(value)) {
        continue;
      }
      normalized.add(value);
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
