import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/pokemon_external_source_repository.dart';
import '../ports/pokemon_write_repository.dart';
import '../ports/project_workspace.dart';
import '../services/pokeapi_pokemon_evolution_converter.dart';
import '../services/pokeapi_pokemon_learnset_converter.dart';
import '../services/pokemon_media_stub_generator.dart';
import '../services/pokemon_project_data_reader.dart';
import '../services/showdown_pokemon_species_converter.dart';

/// Politique minimale de gestion des fichiers déjà présents dans le workspace.
///
/// On garde exactement trois comportements, parce que c'est le minimum
/// raisonnable demandé pour rendre l'import exploitable sans le transformer en
/// framework de synchronisation :
/// - `failOnConflict` : aucun artefact n'est écrit si au moins une cible existe ;
/// - `skipExisting` : les cibles existantes sont laissées intactes ;
/// - `overwriteExisting` : les cibles existantes sont remplacées explicitement.
enum PokemonExternalImportMergePolicy {
  failOnConflict,
  skipExisting,
  overwriteExisting,
}

/// Type d'artefact local produit par un import externe d'espèce.
///
/// L'ordre de déclaration est aussi l'ordre de reporting utilisé par les
/// résultats, pour garder des sorties lisibles et stables.
enum PokemonExternalImportArtifactKind {
  species,
  learnset,
  evolution,
  media,
}

/// Action retenue pour un artefact donné.
///
/// On reste volontairement sur les quatre états réellement utiles au lot :
/// - créer ;
/// - skip ;
/// - overwrite ;
/// - signaler un conflit.
enum PokemonExternalImportArtifactAction {
  create,
  skip,
  overwrite,
  conflict,
}

/// Résultat détaillé pour un artefact local.
///
/// Chaque artefact expose :
/// - son type ;
/// - le chemin relatif ciblé ;
/// - l'action retenue par la merge policy ;
/// - si un fichier existait déjà ;
/// - un message optionnel si une explication locale aide la review.
class PokemonExternalImportArtifactResult {
  const PokemonExternalImportArtifactResult({
    required this.kind,
    required this.relativePath,
    required this.action,
    required this.existedBefore,
    this.message,
  });

  final PokemonExternalImportArtifactKind kind;
  final String relativePath;
  final PokemonExternalImportArtifactAction action;
  final bool existedBefore;
  final String? message;
}

/// Résultat détaillé d'un import externe unitaire.
///
/// Le résultat est pensé pour être lisible directement en logs, tests ou futur
/// rapport d'import :
/// - l'espèce réellement produite ;
/// - la merge policy appliquée ;
/// - l'information dry-run ;
/// - les artefacts concernés ;
/// - d'éventuels warnings non bloquants.
class PokemonExternalImportResult {
  const PokemonExternalImportResult({
    required this.requestedSpeciesId,
    required this.importedSpeciesId,
    required this.dryRun,
    required this.mergePolicy,
    required this.artifacts,
    this.warnings = const <String>[],
  });

  final String requestedSpeciesId;
  final String importedSpeciesId;
  final bool dryRun;
  final PokemonExternalImportMergePolicy mergePolicy;
  final List<PokemonExternalImportArtifactResult> artifacts;
  final List<String> warnings;

  bool get hasConflicts => artifacts.any(
        (artifact) =>
            artifact.action == PokemonExternalImportArtifactAction.conflict,
      );

  bool get hasSkips => artifacts.any(
        (artifact) =>
            artifact.action == PokemonExternalImportArtifactAction.skip,
      );

  bool get hasWritesApplied =>
      !dryRun &&
      artifacts.any(
        (artifact) =>
            artifact.action == PokemonExternalImportArtifactAction.create ||
            artifact.action == PokemonExternalImportArtifactAction.overwrite,
      );

  bool get isFullySkipped =>
      artifacts.isNotEmpty &&
      artifacts.every(
        (artifact) =>
            artifact.action == PokemonExternalImportArtifactAction.skip,
      );
}

/// Résultat unitaire ou erreur pour une espèce dans un batch.
///
/// On ne masque pas les erreurs : chaque entrée porte soit un résultat détaillé
/// d'import, soit un message d'erreur lisible. Le batch peut ainsi continuer
/// sans perdre la granularité par espèce.
class PokemonExternalBatchImportEntryResult {
  const PokemonExternalBatchImportEntryResult({
    required this.speciesId,
    this.result,
    this.errorMessage,
  });

  final String speciesId;
  final PokemonExternalImportResult? result;
  final String? errorMessage;

  bool get isFailed => errorMessage != null;

  bool get isConflict => !isFailed && (result?.hasConflicts ?? false);

  bool get isSkipped => !isFailed && (result?.isFullySkipped ?? false);

  bool get isSuccessful => !isFailed && !isConflict;
}

/// Résultat global d'un import batch.
///
/// Le résultat reste volontairement compact :
/// - paramètres communs du batch ;
/// - résultats détaillés par espèce ;
/// - compteurs résumés.
class PokemonExternalBatchImportResult {
  const PokemonExternalBatchImportResult({
    required this.dryRun,
    required this.mergePolicy,
    required this.entries,
  });

  final bool dryRun;
  final PokemonExternalImportMergePolicy mergePolicy;
  final List<PokemonExternalBatchImportEntryResult> entries;

  int get successfulCount =>
      entries.where((entry) => entry.isSuccessful && !entry.isSkipped).length;

  int get skippedCount => entries.where((entry) => entry.isSkipped).length;

  int get conflictCount => entries.where((entry) => entry.isConflict).length;

  int get failedCount => entries.where((entry) => entry.isFailed).length;
}

/// Use case d'orchestration pour importer une seule espèce depuis les sources
/// externes déjà convertibles.
///
/// Ce use case est la couche applicative des lots 34 et 36 :
/// - il récupère les payloads externes via un port minimal ;
/// - il réutilise strictement les convertisseurs 28 à 33 ;
/// - il applique une merge policy simple ;
/// - il supporte un vrai dry-run sans écrire quoi que ce soit ;
/// - il délègue toute écriture réelle au repository local existant.
///
/// Non-objectifs assumés :
/// - pas d'UI ;
/// - pas de réseau concret ;
/// - pas de lot 37+ ;
/// - pas de stratégie de fusion "intelligente" par champ ;
/// - pas de validation croisée globale du Pokédex.
class ImportExternalPokemonSpeciesUseCase {
  ImportExternalPokemonSpeciesUseCase({
    required this.externalSourceRepository,
    required this.writeRepository,
    this.speciesConverter = const ShowdownPokemonSpeciesConverter(),
    this.learnsetConverter = const PokeApiPokemonLearnsetConverter(),
    this.evolutionConverter = const PokeApiPokemonEvolutionConverter(),
    this.mediaStubGenerator = const PokemonMediaStubGenerator(),
    this.dataReader = const PokemonProjectDataReader(),
  });

  final PokemonExternalSourceRepository externalSourceRepository;
  final PokemonWriteRepository writeRepository;
  final ShowdownPokemonSpeciesConverter speciesConverter;
  final PokeApiPokemonLearnsetConverter learnsetConverter;
  final PokeApiPokemonEvolutionConverter evolutionConverter;
  final PokemonMediaStubGenerator mediaStubGenerator;
  final PokemonProjectDataReader dataReader;

  Future<PokemonExternalImportResult> execute(
    ProjectWorkspace workspace, {
    required String speciesId,
    PokemonExternalImportMergePolicy mergePolicy =
        PokemonExternalImportMergePolicy.failOnConflict,
    bool dryRun = false,
  }) async {
    final requestedSpeciesId = speciesId.trim();
    if (requestedSpeciesId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon external import speciesId cannot be empty',
      );
    }

    // Les payloads sont lus d'abord. Le dry-run doit effectuer toute la
    // résolution et toute la conversion, donc rien n'est "court-circuité".
    final showdownPayload = await externalSourceRepository
        .fetchShowdownSpeciesPayload(requestedSpeciesId);
    final pokeApiPokemonPayload = await externalSourceRepository
        .fetchPokeApiPokemonPayload(requestedSpeciesId);
    final evolutionChainPayload = await externalSourceRepository
        .fetchPokeApiEvolutionChainPayload(requestedSpeciesId);

    final species = speciesConverter.convert(showdownPayload);
    final learnset = learnsetConverter.convert(
      speciesId: species.id,
      payload: pokeApiPokemonPayload,
    );
    final evolution = evolutionConverter.convert(
      speciesId: species.id,
      payload: evolutionChainPayload,
    );
    final media = mediaStubGenerator.createStub(species);

    final artifactPlans = await _planArtifacts(
      workspace,
      species: species,
      learnset: learnset,
      evolution: evolution,
      media: media,
      mergePolicy: mergePolicy,
    );

    final warnings = <String>[];
    if (species.id != requestedSpeciesId) {
      warnings.add(
        'Requested species "$requestedSpeciesId" resolved to '
        '"${species.id}" from source payload.',
      );
    }

    final result = PokemonExternalImportResult(
      requestedSpeciesId: requestedSpeciesId,
      importedSpeciesId: species.id,
      dryRun: dryRun,
      mergePolicy: mergePolicy,
      artifacts: artifactPlans
          .map(
            (plan) => PokemonExternalImportArtifactResult(
              kind: plan.kind,
              relativePath: plan.relativePath,
              action: plan.action,
              existedBefore: plan.existedBefore,
              message: plan.message,
            ),
          )
          .toList(growable: false),
      warnings: warnings,
    );

    // Dry-run : tout a été converti et planifié, mais aucune écriture locale
    // n'est autorisée. Le résultat sert alors de rapport d'actions prévues.
    if (dryRun) {
      return result;
    }

    // La politique fail-on-conflict est volontairement atomique au niveau
    // d'une espèce : si un artefact est en conflit, on n'écrit rien pour
    // éviter une importation partielle ambiguë.
    if (result.hasConflicts) {
      return result;
    }

    for (final plan in artifactPlans) {
      switch (plan.action) {
        case PokemonExternalImportArtifactAction.create:
        case PokemonExternalImportArtifactAction.overwrite:
          await plan.write(workspace, writeRepository);
          break;
        case PokemonExternalImportArtifactAction.skip:
        case PokemonExternalImportArtifactAction.conflict:
          break;
      }
    }

    return result;
  }

  Future<List<_PlannedArtifactWrite>> _planArtifacts(
    ProjectWorkspace workspace, {
    required PokemonSpeciesFile species,
    required PokemonLearnsetFile learnset,
    required PokemonEvolutionFile evolution,
    required PokemonMediaFile media,
    required PokemonExternalImportMergePolicy mergePolicy,
  }) async {
    final speciesRelativePath = await _resolveSpeciesRelativePath(
      workspace,
      species,
    );

    return <_PlannedArtifactWrite>[
      await _planArtifact(
        workspace,
        kind: PokemonExternalImportArtifactKind.species,
        relativePath: speciesRelativePath,
        mergePolicy: mergePolicy,
        write: (workspace, repository) =>
            repository.saveSpecies(workspace, species),
      ),
      await _planArtifact(
        workspace,
        kind: PokemonExternalImportArtifactKind.learnset,
        relativePath: 'data/pokemon/learnsets/${learnset.speciesId}.json',
        mergePolicy: mergePolicy,
        write: (workspace, repository) =>
            repository.saveLearnset(workspace, learnset),
      ),
      await _planArtifact(
        workspace,
        kind: PokemonExternalImportArtifactKind.evolution,
        relativePath: 'data/pokemon/evolutions/${evolution.speciesId}.json',
        mergePolicy: mergePolicy,
        write: (workspace, repository) =>
            repository.saveEvolution(workspace, evolution),
      ),
      await _planArtifact(
        workspace,
        kind: PokemonExternalImportArtifactKind.media,
        relativePath: 'data/pokemon/media/${media.speciesId}.json',
        mergePolicy: mergePolicy,
        write: (workspace, repository) =>
            repository.saveMedia(workspace, media),
      ),
    ];
  }

  Future<_PlannedArtifactWrite> _planArtifact(
    ProjectWorkspace workspace, {
    required PokemonExternalImportArtifactKind kind,
    required String relativePath,
    required PokemonExternalImportMergePolicy mergePolicy,
    required Future<void> Function(
      ProjectWorkspace workspace,
      PokemonWriteRepository repository,
    ) write,
  }) async {
    final absolutePath = workspace.resolveProjectRelativePath(relativePath);
    final existedBefore = await workspace.fileExists(absolutePath);
    final action = _resolveAction(
      existedBefore: existedBefore,
      mergePolicy: mergePolicy,
    );

    final message = switch (action) {
      PokemonExternalImportArtifactAction.conflict =>
        'Target already exists and merge policy is fail_on_conflict.',
      PokemonExternalImportArtifactAction.skip =>
        'Target already exists and merge policy is skip_existing.',
      PokemonExternalImportArtifactAction.overwrite =>
        'Target already exists and will be overwritten.',
      PokemonExternalImportArtifactAction.create => null,
    };

    return _PlannedArtifactWrite(
      kind: kind,
      relativePath: relativePath,
      existedBefore: existedBefore,
      action: action,
      message: message,
      writeDelegate: write,
    );
  }

  PokemonExternalImportArtifactAction _resolveAction({
    required bool existedBefore,
    required PokemonExternalImportMergePolicy mergePolicy,
  }) {
    if (!existedBefore) {
      return PokemonExternalImportArtifactAction.create;
    }

    return switch (mergePolicy) {
      PokemonExternalImportMergePolicy.failOnConflict =>
        PokemonExternalImportArtifactAction.conflict,
      PokemonExternalImportMergePolicy.skipExisting =>
        PokemonExternalImportArtifactAction.skip,
      PokemonExternalImportMergePolicy.overwriteExisting =>
        PokemonExternalImportArtifactAction.overwrite,
    };
  }

  Future<String> _resolveSpeciesRelativePath(
    ProjectWorkspace workspace,
    PokemonSpeciesFile species,
  ) async {
    // On reste aligné sur le repository d'écriture existant :
    // - si l'espèce existe déjà, on réutilise son vrai chemin courant ;
    // - sinon on génère le nom canonique `<dex>-<slug>.json`.
    final existingRelativePath =
        await dataReader.resolveSpeciesRelativePathById(workspace, species.id);
    if (existingRelativePath != null) {
      return existingRelativePath;
    }

    return 'data/pokemon/species/${_speciesFileName(species)}';
  }

  String _speciesFileName(PokemonSpeciesFile species) {
    final dex = species.nationalDex.toString().padLeft(4, '0');
    final slug = _sanitizeFileSegment(
      species.slug.isNotEmpty ? species.slug : species.id,
    );
    return '$dex-$slug.json';
  }

  String _sanitizeFileSegment(String value) {
    final normalized = value.trim().toLowerCase();
    final safe = normalized.replaceAll(RegExp(r'[^a-z0-9_-]+'), '_');
    final collapsed = safe.replaceAll(RegExp(r'_+'), '_');
    final trimmed = collapsed.replaceAll(RegExp(r'^_|_$'), '');
    return trimmed.isEmpty ? 'pokemon' : trimmed;
  }
}

/// Use case batch pour importer plusieurs espèces.
///
/// Ce lot 35 se contente d'enchaîner proprement l'import unitaire :
/// - l'ordre d'exécution est stabilisé ;
/// - chaque espèce garde son résultat détaillé ;
/// - les erreurs par espèce ne cassent pas le reste du batch.
class BatchImportExternalPokemonSpeciesUseCase {
  const BatchImportExternalPokemonSpeciesUseCase(this.singleImportUseCase);

  final ImportExternalPokemonSpeciesUseCase singleImportUseCase;

  Future<PokemonExternalBatchImportResult> execute(
    ProjectWorkspace workspace, {
    required List<String> speciesIds,
    PokemonExternalImportMergePolicy mergePolicy =
        PokemonExternalImportMergePolicy.failOnConflict,
    bool dryRun = false,
  }) async {
    final normalizedSpeciesIds = speciesIds
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false)
      ..sort();

    if (normalizedSpeciesIds.isEmpty) {
      throw const EditorValidationException(
        'Pokemon external batch speciesIds cannot be empty',
      );
    }

    final entryResults = <PokemonExternalBatchImportEntryResult>[];
    for (final speciesId in normalizedSpeciesIds) {
      try {
        final result = await singleImportUseCase.execute(
          workspace,
          speciesId: speciesId,
          mergePolicy: mergePolicy,
          dryRun: dryRun,
        );
        entryResults.add(
          PokemonExternalBatchImportEntryResult(
            speciesId: speciesId,
            result: result,
          ),
        );
      } on EditorApplicationException catch (error) {
        entryResults.add(
          PokemonExternalBatchImportEntryResult(
            speciesId: speciesId,
            errorMessage: error.message,
          ),
        );
      } catch (error) {
        entryResults.add(
          PokemonExternalBatchImportEntryResult(
            speciesId: speciesId,
            errorMessage: 'Unexpected batch import error: $error',
          ),
        );
      }
    }

    return PokemonExternalBatchImportResult(
      dryRun: dryRun,
      mergePolicy: mergePolicy,
      entries: entryResults,
    );
  }
}

class _PlannedArtifactWrite {
  const _PlannedArtifactWrite({
    required this.kind,
    required this.relativePath,
    required this.existedBefore,
    required this.action,
    required this.writeDelegate,
    this.message,
  });

  final PokemonExternalImportArtifactKind kind;
  final String relativePath;
  final bool existedBefore;
  final PokemonExternalImportArtifactAction action;
  final String? message;
  final Future<void> Function(
    ProjectWorkspace workspace,
    PokemonWriteRepository repository,
  ) writeDelegate;

  Future<void> write(
    ProjectWorkspace workspace,
    PokemonWriteRepository repository,
  ) {
    return writeDelegate(workspace, repository);
  }
}
