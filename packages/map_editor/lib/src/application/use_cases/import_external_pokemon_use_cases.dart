import 'dart:async';

import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/pokemon_external_source_repository.dart';
import '../ports/pokemon_write_repository.dart';
import '../ports/project_workspace.dart';
import '../services/pokeapi_pokemon_evolution_converter.dart';
import '../services/pokeapi_pokemon_learnset_converter.dart';
import '../services/pokeapi_pokemon_species_enricher.dart';
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

/// Disponibilité d'un bloc de données avant import.
///
/// Ce modèle sert à la preview applicative :
/// - il reste volontairement lisible pour le wizard ;
/// - il ne confond pas "artefact source trouvé" et "fichier local écrit" ;
/// - il permet de montrer honnêtement les morceaux best-effort.
class PokemonExternalImportPreviewArtifact {
  const PokemonExternalImportPreviewArtifact({
    required this.label,
    required this.isAvailable,
    this.message,
  });

  final String label;
  final bool isAvailable;
  final String? message;
}

/// Preview applicative d'un import externe.
///
/// Cette preview est produite par le `dryRun` du use case existant.
/// On évite ainsi une seconde logique d'aperçu parallèle dans les providers ou
/// dans l'UI.
class PokemonExternalImportPreview {
  const PokemonExternalImportPreview({
    required this.speciesId,
    required this.nationalDex,
    required this.primaryName,
    required this.types,
    required this.learnset,
    required this.evolution,
    required this.media,
    required this.cries,
  });

  final String speciesId;
  final int nationalDex;
  final String primaryName;
  final List<String> types;
  final PokemonExternalImportPreviewArtifact learnset;
  final PokemonExternalImportPreviewArtifact evolution;
  final PokemonExternalImportPreviewArtifact media;
  final PokemonExternalImportPreviewArtifact cries;
}

/// Rapport d'un asset best-effort téléchargé ou tenté.
///
/// Les images et cries n'entrent pas dans la mécanique de conflit bloquante des
/// quatre JSON métier. On les suit donc séparément, avec un résultat plus
/// explicite pour la QA et le report final.
class PokemonExternalAssetDownloadResult {
  const PokemonExternalAssetDownloadResult({
    required this.label,
    required this.relativePath,
    required this.sourceUrl,
    required this.wasWritten,
    this.existedBefore = false,
    this.contentType,
    this.message,
  });

  final String label;
  final String relativePath;
  final String sourceUrl;
  final bool wasWritten;
  final bool existedBefore;
  final String? contentType;
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
    required this.preview,
    required this.dryRun,
    required this.mergePolicy,
    required this.artifacts,
    this.downloadedAssets = const <PokemonExternalAssetDownloadResult>[],
    this.warnings = const <String>[],
  });

  final String requestedSpeciesId;
  final String importedSpeciesId;
  final PokemonExternalImportPreview preview;
  final bool dryRun;
  final PokemonExternalImportMergePolicy mergePolicy;
  final List<PokemonExternalImportArtifactResult> artifacts;
  final List<PokemonExternalAssetDownloadResult> downloadedAssets;
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

  bool get importedSpecies => _hasAppliedArtifact(
        PokemonExternalImportArtifactKind.species,
      );

  bool get importedLearnset => _hasAppliedArtifact(
        PokemonExternalImportArtifactKind.learnset,
      );

  bool get importedEvolution => _hasAppliedArtifact(
        PokemonExternalImportArtifactKind.evolution,
      );

  bool get importedMedia => _hasAppliedArtifact(
        PokemonExternalImportArtifactKind.media,
      );

  int get downloadedAssetCount =>
      downloadedAssets.where((asset) => asset.wasWritten).length;

  bool _hasAppliedArtifact(PokemonExternalImportArtifactKind kind) {
    return artifacts.any(
      (artifact) =>
          artifact.kind == kind &&
          (artifact.action == PokemonExternalImportArtifactAction.create ||
              artifact.action == PokemonExternalImportArtifactAction.overwrite),
    );
  }
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
    this.speciesEnricher = const PokeApiPokemonSpeciesEnricher(),
    this.learnsetConverter = const PokeApiPokemonLearnsetConverter(),
    this.evolutionConverter = const PokeApiPokemonEvolutionConverter(),
    this.mediaStubGenerator = const PokemonMediaStubGenerator(),
    this.dataReader = const PokemonProjectDataReader(),
  });

  final PokemonExternalSourceRepository externalSourceRepository;
  final PokemonWriteRepository writeRepository;
  final ShowdownPokemonSpeciesConverter speciesConverter;
  final PokeApiPokemonSpeciesEnricher speciesEnricher;
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

    // La stratégie source de la phase 11A est explicite :
    // - `pokemon-species` sert d'abord à résoudre l'identité canonique ;
    // - Showdown complète ensuite le core species structuré ;
    // - `/pokemon` et `evolution-chain` restent best-effort pour le learnset,
    //   les médias et les évolutions locales.
    final pokeApiSpeciesPayload = await externalSourceRepository
        .fetchPokeApiPokemonSpeciesPayload(requestedSpeciesId);
    final canonicalSpeciesId =
        _resolveCanonicalSpeciesIdFromSpeciesPayload(pokeApiSpeciesPayload);
    final fallbackGeneration =
        _readGenerationNumberFromSpeciesPayload(pokeApiSpeciesPayload);
    final showdownPayload = await externalSourceRepository
        .fetchShowdownSpeciesPayload(canonicalSpeciesId);
    final pokemonPayloadRead = await _tryReadOptionalPayload(
      () => externalSourceRepository.fetchPokeApiPokemonPayload(
        canonicalSpeciesId,
      ),
      warningContext:
          'Learnset and media payload unavailable for "$canonicalSpeciesId"',
    );
    final evolutionPayloadRead = await _tryReadOptionalPayload(
      () => externalSourceRepository.fetchPokeApiEvolutionChainPayload(
        canonicalSpeciesId,
      ),
      warningContext: 'Evolution chain unavailable for "$canonicalSpeciesId"',
    );

    final species = speciesEnricher.enrich(
      species: speciesConverter.convert(
        showdownPayload,
        fallbackGeneration: fallbackGeneration,
      ),
      pokemonSpeciesPayload: pokeApiSpeciesPayload,
      pokemonPayload: pokemonPayloadRead.payload,
    );
    final learnset = await _tryConvertOptional<PokemonLearnsetFile>(
      () => learnsetConverter.convert(
        speciesId: species.id,
        payload: pokemonPayloadRead.payload!,
      ),
      isEnabled: pokemonPayloadRead.payload != null,
      warningContext: 'Learnset conversion skipped for "${species.id}"',
    );
    final evolution = await _tryConvertOptional<PokemonEvolutionFile>(
      () => evolutionConverter.convert(
        speciesId: species.id,
        payload: evolutionPayloadRead.payload!,
      ),
      isEnabled: evolutionPayloadRead.payload != null,
      warningContext: 'Evolution conversion skipped for "${species.id}"',
    );
    final media = mediaStubGenerator.createStub(species);
    final assetCandidates = _resolveAssetCandidates(
      species: species,
      media: media,
      pokemonPayload: pokemonPayloadRead.payload,
    );

    final artifactPlans = await _planArtifacts(
      workspace,
      species: species,
      learnset: learnset,
      evolution: evolution,
      media: media,
      mergePolicy: mergePolicy,
    );

    final warnings = <String>[
      ...pokemonPayloadRead.warnings,
      ...evolutionPayloadRead.warnings,
      ...learnset.warnings,
      ...evolution.warnings,
    ];
    if (species.id != requestedSpeciesId.trim().toLowerCase()) {
      warnings.add(
        'Requested species "$requestedSpeciesId" resolved to '
        '"${species.id}" from source payload.',
      );
    }
    final result = _buildResult(
      requestedSpeciesId: requestedSpeciesId,
      species: species,
      dryRun: dryRun,
      mergePolicy: mergePolicy,
      artifactPlans: artifactPlans,
      warnings: warnings,
      assetCandidates: assetCandidates,
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

    final assetBatch = await _downloadBestEffortAssets(
      workspace,
      mergePolicy: mergePolicy,
      candidates: assetCandidates,
    );

    return _buildResult(
      requestedSpeciesId: requestedSpeciesId,
      species: species,
      dryRun: false,
      mergePolicy: mergePolicy,
      artifactPlans: artifactPlans,
      warnings: <String>[
        ...warnings,
        ...assetBatch.warnings,
      ],
      assetCandidates: assetCandidates,
      downloadedAssets: assetBatch.results,
    );
  }

  Future<List<_PlannedArtifactWrite>> _planArtifacts(
    ProjectWorkspace workspace, {
    required PokemonSpeciesFile species,
    required _OptionalValue<PokemonLearnsetFile> learnset,
    required _OptionalValue<PokemonEvolutionFile> evolution,
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
      if (learnset.value != null)
        await _planArtifact(
          workspace,
          kind: PokemonExternalImportArtifactKind.learnset,
          relativePath:
              'data/pokemon/learnsets/${learnset.value!.speciesId}.json',
          mergePolicy: mergePolicy,
          write: (workspace, repository) =>
              repository.saveLearnset(workspace, learnset.value!),
        ),
      if (evolution.value != null)
        await _planArtifact(
          workspace,
          kind: PokemonExternalImportArtifactKind.evolution,
          relativePath:
              'data/pokemon/evolutions/${evolution.value!.speciesId}.json',
          mergePolicy: mergePolicy,
          write: (workspace, repository) =>
              repository.saveEvolution(workspace, evolution.value!),
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

  String _resolveCanonicalSpeciesIdFromSpeciesPayload(
    Map<String, dynamic> payload,
  ) {
    final name = payload['name'];
    if (name is! String || name.trim().isEmpty) {
      throw const EditorPersistenceException(
        'PokeAPI pokemon-species payload must expose a non-empty name',
      );
    }
    return name.trim().toLowerCase();
  }

  int? _readGenerationNumberFromSpeciesPayload(Map<String, dynamic> payload) {
    final rawGeneration = payload['generation'];
    if (rawGeneration is! Map) {
      return null;
    }

    final generationName =
        (rawGeneration['name'] as String?)?.trim().toLowerCase();
    return switch (generationName) {
      'generation-i' => 1,
      'generation-ii' => 2,
      'generation-iii' => 3,
      'generation-iv' => 4,
      'generation-v' => 5,
      'generation-vi' => 6,
      'generation-vii' => 7,
      'generation-viii' => 8,
      'generation-ix' => 9,
      _ => null,
    };
  }

  Future<_OptionalPayload<Map<String, dynamic>>> _tryReadOptionalPayload(
    Future<Map<String, dynamic>> Function() action, {
    required String warningContext,
  }) async {
    try {
      return _OptionalPayload<Map<String, dynamic>>(payload: await action());
    } on EditorApplicationException catch (error) {
      return _OptionalPayload<Map<String, dynamic>>(
        warnings: <String>['$warningContext: ${error.message}'],
      );
    } catch (error) {
      return _OptionalPayload<Map<String, dynamic>>(
        warnings: <String>['$warningContext: $error'],
      );
    }
  }

  Future<_OptionalValue<T>> _tryConvertOptional<T>(
    FutureOr<T> Function() action, {
    required bool isEnabled,
    required String warningContext,
  }) async {
    if (!isEnabled) {
      return _OptionalValue<T>();
    }

    try {
      return _OptionalValue<T>(value: await action());
    } on EditorApplicationException catch (error) {
      return _OptionalValue<T>(
        warnings: <String>['$warningContext: ${error.message}'],
      );
    } catch (error) {
      return _OptionalValue<T>(
        warnings: <String>['$warningContext: $error'],
      );
    }
  }

  PokemonExternalImportResult _buildResult({
    required String requestedSpeciesId,
    required PokemonSpeciesFile species,
    required bool dryRun,
    required PokemonExternalImportMergePolicy mergePolicy,
    required List<_PlannedArtifactWrite> artifactPlans,
    required List<String> warnings,
    required _PokemonExternalAssetCandidateBundle assetCandidates,
    List<PokemonExternalAssetDownloadResult> downloadedAssets =
        const <PokemonExternalAssetDownloadResult>[],
  }) {
    return PokemonExternalImportResult(
      requestedSpeciesId: requestedSpeciesId,
      importedSpeciesId: species.id,
      preview: PokemonExternalImportPreview(
        speciesId: species.id,
        nationalDex: species.nationalDex,
        primaryName: _resolvePrimaryName(species),
        types: _normalizeTypes(species.typing.types),
        learnset: PokemonExternalImportPreviewArtifact(
          label: 'Learnset',
          isAvailable: artifactPlans.any(
            (plan) => plan.kind == PokemonExternalImportArtifactKind.learnset,
          ),
        ),
        evolution: PokemonExternalImportPreviewArtifact(
          label: 'Évolutions',
          isAvailable: artifactPlans.any(
            (plan) => plan.kind == PokemonExternalImportArtifactKind.evolution,
          ),
        ),
        media: PokemonExternalImportPreviewArtifact(
          label: 'Médias',
          isAvailable: assetCandidates.hasMediaSource,
        ),
        cries: PokemonExternalImportPreviewArtifact(
          label: 'Cri',
          isAvailable: assetCandidates.hasCrySource,
        ),
      ),
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
      downloadedAssets: downloadedAssets,
      warnings: warnings,
    );
  }

  String _resolvePrimaryName(PokemonSpeciesFile species) {
    final english = species.names['en']?.trim();
    if (english != null && english.isNotEmpty) {
      return english;
    }
    final french = species.names['fr']?.trim();
    if (french != null && french.isNotEmpty) {
      return french;
    }
    for (final value in species.names.values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return species.id;
  }

  List<String> _normalizeTypes(List<String> values) {
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  _PokemonExternalAssetCandidateBundle _resolveAssetCandidates({
    required PokemonSpeciesFile species,
    required PokemonMediaFile media,
    required Map<String, dynamic>? pokemonPayload,
  }) {
    final defaultVariant = media.variants[media.defaultFormId];
    if (defaultVariant == null || pokemonPayload == null) {
      return const _PokemonExternalAssetCandidateBundle();
    }

    final portraitUrl = _readNestedString(
          pokemonPayload,
          const <String>[
            'sprites',
            'other',
            'official-artwork',
            'front_default'
          ],
        ) ??
        _readNestedString(
          pokemonPayload,
          const <String>['sprites', 'other', 'home', 'front_default'],
        ) ??
        _readNestedString(
          pokemonPayload,
          const <String>['sprites', 'front_default'],
        );
    final frontUrl = _readNestedString(
      pokemonPayload,
      const <String>['sprites', 'front_default'],
    );
    final backUrl = _readNestedString(
      pokemonPayload,
      const <String>['sprites', 'back_default'],
    );
    final frontShinyUrl = _readNestedString(
      pokemonPayload,
      const <String>['sprites', 'front_shiny'],
    );
    final backShinyUrl = _readNestedString(
      pokemonPayload,
      const <String>['sprites', 'back_shiny'],
    );
    final cryUrl = _readNestedString(
          pokemonPayload,
          const <String>['cries', 'latest'],
        ) ??
        _readNestedString(
          pokemonPayload,
          const <String>['cries', 'legacy'],
        );

    return _PokemonExternalAssetCandidateBundle(
      candidates: <_PokemonExternalAssetCandidate>[
        if (defaultVariant.portrait?.trim().isNotEmpty == true)
          _PokemonExternalAssetCandidate(
            label: 'Portrait',
            relativePath: defaultVariant.portrait!.trim(),
            sourceUrl: portraitUrl,
          ),
        if (defaultVariant.frontStatic?.trim().isNotEmpty == true)
          _PokemonExternalAssetCandidate(
            label: 'Sprite face',
            relativePath: defaultVariant.frontStatic!.trim(),
            sourceUrl: frontUrl,
          ),
        if (defaultVariant.backStatic?.trim().isNotEmpty == true)
          _PokemonExternalAssetCandidate(
            label: 'Sprite dos',
            relativePath: defaultVariant.backStatic!.trim(),
            sourceUrl: backUrl,
          ),
        if (defaultVariant.frontShinyStatic?.trim().isNotEmpty == true)
          _PokemonExternalAssetCandidate(
            label: 'Sprite shiny face',
            relativePath: defaultVariant.frontShinyStatic!.trim(),
            sourceUrl: frontShinyUrl,
          ),
        if (defaultVariant.backShinyStatic?.trim().isNotEmpty == true)
          _PokemonExternalAssetCandidate(
            label: 'Sprite shiny dos',
            relativePath: defaultVariant.backShinyStatic!.trim(),
            sourceUrl: backShinyUrl,
          ),
        if (defaultVariant.cry?.trim().isNotEmpty == true)
          _PokemonExternalAssetCandidate(
            label: 'Cri',
            relativePath: defaultVariant.cry!.trim(),
            sourceUrl: cryUrl,
          ),
      ],
      speciesId: species.id,
    );
  }

  Future<_DownloadedAssetBatch> _downloadBestEffortAssets(
    ProjectWorkspace workspace, {
    required PokemonExternalImportMergePolicy mergePolicy,
    required _PokemonExternalAssetCandidateBundle candidates,
  }) async {
    final warnings = <String>[];
    final results = <PokemonExternalAssetDownloadResult>[];

    for (final candidate in candidates.candidates) {
      final sourceUrl = candidate.sourceUrl?.trim();
      if (sourceUrl == null || sourceUrl.isEmpty) {
        continue;
      }
      if (_looksLikeGif(sourceUrl)) {
        final message =
            '${candidate.label} ignored because GIF assets are explicitly excluded.';
        warnings.add(message);
        results.add(
          PokemonExternalAssetDownloadResult(
            label: candidate.label,
            relativePath: candidate.relativePath,
            sourceUrl: sourceUrl,
            wasWritten: false,
            message: message,
          ),
        );
        continue;
      }

      final existedBefore = await workspace.fileExists(
        workspace.resolveProjectRelativePath(candidate.relativePath),
      );
      if (existedBefore &&
          mergePolicy != PokemonExternalImportMergePolicy.overwriteExisting) {
        final message =
            '${candidate.label} left untouched because the local asset already exists.';
        results.add(
          PokemonExternalAssetDownloadResult(
            label: candidate.label,
            relativePath: candidate.relativePath,
            sourceUrl: sourceUrl,
            wasWritten: false,
            existedBefore: true,
            message: message,
          ),
        );
        warnings.add(message);
        continue;
      }

      try {
        final asset =
            await externalSourceRepository.fetchBinaryAsset(sourceUrl);
        if (asset.bytes.isEmpty) {
          final message =
              '${candidate.label} download returned no bytes and was skipped.';
          warnings.add(message);
          results.add(
            PokemonExternalAssetDownloadResult(
              label: candidate.label,
              relativePath: candidate.relativePath,
              sourceUrl: sourceUrl,
              wasWritten: false,
              existedBefore: existedBefore,
              contentType: asset.contentType,
              message: message,
            ),
          );
          continue;
        }
        if (_looksLikeGif(asset.sourceUrl) ||
            _isGifContentType(asset.contentType)) {
          final message =
              '${candidate.label} ignored because GIF assets are not allowed in local media.';
          warnings.add(message);
          results.add(
            PokemonExternalAssetDownloadResult(
              label: candidate.label,
              relativePath: candidate.relativePath,
              sourceUrl: sourceUrl,
              wasWritten: false,
              existedBefore: existedBefore,
              contentType: asset.contentType,
              message: message,
            ),
          );
          continue;
        }

        await writeRepository.saveBinaryAsset(
          workspace,
          relativePath: candidate.relativePath,
          bytes: asset.bytes,
        );
        results.add(
          PokemonExternalAssetDownloadResult(
            label: candidate.label,
            relativePath: candidate.relativePath,
            sourceUrl: sourceUrl,
            wasWritten: true,
            existedBefore: existedBefore,
            contentType: asset.contentType,
          ),
        );
      } on EditorApplicationException catch (error) {
        final message = '${candidate.label} download failed: ${error.message}';
        warnings.add(message);
        results.add(
          PokemonExternalAssetDownloadResult(
            label: candidate.label,
            relativePath: candidate.relativePath,
            sourceUrl: sourceUrl,
            wasWritten: false,
            existedBefore: existedBefore,
            message: message,
          ),
        );
      } catch (error) {
        final message = '${candidate.label} download failed: $error';
        warnings.add(message);
        results.add(
          PokemonExternalAssetDownloadResult(
            label: candidate.label,
            relativePath: candidate.relativePath,
            sourceUrl: sourceUrl,
            wasWritten: false,
            existedBefore: existedBefore,
            message: message,
          ),
        );
      }
    }

    return _DownloadedAssetBatch(
      results: results,
      warnings: warnings,
    );
  }

  String? _readNestedString(
    Map<String, dynamic> payload,
    List<String> path,
  ) {
    Object? current = payload;
    for (final segment in path) {
      if (current is! Map) {
        return null;
      }
      current = current[segment];
    }
    final value = current as String?;
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  bool _looksLikeGif(String url) {
    return url.toLowerCase().contains('.gif');
  }

  bool _isGifContentType(String? contentType) {
    final normalized = contentType?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return false;
    }
    return normalized.contains('image/gif');
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

class _OptionalPayload<T> {
  const _OptionalPayload({
    this.payload,
    this.warnings = const <String>[],
  });

  final T? payload;
  final List<String> warnings;
}

class _OptionalValue<T> {
  const _OptionalValue({
    this.value,
    this.warnings = const <String>[],
  });

  final T? value;
  final List<String> warnings;
}

class _PokemonExternalAssetCandidate {
  const _PokemonExternalAssetCandidate({
    required this.label,
    required this.relativePath,
    required this.sourceUrl,
  });

  final String label;
  final String relativePath;
  final String? sourceUrl;
}

class _PokemonExternalAssetCandidateBundle {
  const _PokemonExternalAssetCandidateBundle({
    this.candidates = const <_PokemonExternalAssetCandidate>[],
    this.speciesId,
  });

  final List<_PokemonExternalAssetCandidate> candidates;
  final String? speciesId;

  bool get hasMediaSource => candidates.any(
        (candidate) =>
            candidate.label != 'Cri' &&
            candidate.sourceUrl?.trim().isNotEmpty == true,
      );

  bool get hasCrySource => candidates.any(
        (candidate) =>
            candidate.label == 'Cri' &&
            candidate.sourceUrl?.trim().isNotEmpty == true,
      );
}

class _DownloadedAssetBatch {
  const _DownloadedAssetBatch({
    required this.results,
    required this.warnings,
  });

  final List<PokemonExternalAssetDownloadResult> results;
  final List<String> warnings;
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
