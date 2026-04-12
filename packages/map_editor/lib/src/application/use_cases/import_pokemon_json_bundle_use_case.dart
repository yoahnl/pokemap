import 'package:path/path.dart' as p;

import '../models/pokemon_project_data_models.dart';
import '../ports/pokemon_write_repository.dart';
import '../ports/project_workspace.dart';
import 'import_pokemon_evolution_json_use_case.dart';
import 'import_pokemon_learnset_json_use_case.dart';
import 'import_pokemon_media_json_use_case.dart';
import 'import_pokemon_species_json_use_case.dart';

enum PokemonImportPreviewStatus {
  found,
  missing,
}

class PokemonImportArtifactPreview {
  const PokemonImportArtifactPreview({
    required this.label,
    required this.refId,
    required this.status,
    this.absoluteSourcePath,
  });

  final String label;
  final String refId;
  final PokemonImportPreviewStatus status;
  final String? absoluteSourcePath;

  bool get isFound => status == PokemonImportPreviewStatus.found;
}

class PokemonJsonImportPreview {
  const PokemonJsonImportPreview({
    required this.speciesId,
    required this.nationalDex,
    required this.primaryName,
    required this.types,
    required this.learnset,
    required this.evolution,
    required this.media,
  });

  final String speciesId;
  final int nationalDex;
  final String primaryName;
  final List<String> types;
  final PokemonImportArtifactPreview learnset;
  final PokemonImportArtifactPreview evolution;
  final PokemonImportArtifactPreview media;
}

class PokemonJsonImportResult {
  const PokemonJsonImportResult({
    required this.preview,
    required this.importedSpecies,
    required this.importedLearnset,
    required this.importedEvolution,
    required this.importedMedia,
  });

  final PokemonJsonImportPreview preview;
  final bool importedSpecies;
  final bool importedLearnset;
  final bool importedEvolution;
  final bool importedMedia;
}

class ImportPokemonJsonBundleUseCase {
  const ImportPokemonJsonBundleUseCase({
    required this.writeRepository,
    required this.speciesImportUseCase,
    required this.learnsetImportUseCase,
    required this.evolutionImportUseCase,
    required this.mediaImportUseCase,
  });

  final PokemonWriteRepository writeRepository;
  final ImportPokemonSpeciesJsonUseCase speciesImportUseCase;
  final ImportPokemonLearnsetJsonUseCase learnsetImportUseCase;
  final ImportPokemonEvolutionJsonUseCase evolutionImportUseCase;
  final ImportPokemonMediaJsonUseCase mediaImportUseCase;

  /// Le preview de l’éditeur ne lit jamais les JSON dans l’UI :
  /// - le widget fournit juste un chemin absolu choisi par file picker ;
  /// - l’application relit et valide le fichier espèce ;
  /// - elle projette ensuite une synthèse légère pour le modal.
  ///
  /// Pour garder le comportement honnête et prévisible, la détection des
  /// fichiers compagnons reste volontairement petite :
  /// - si le JSON sélectionné vient d’un dossier `species/`, on cherche les
  ///   compagnons dans les dossiers frères `learnsets/`, `evolutions/` et
  ///   `media/` avec le `refId` correspondant ;
  /// - sinon, on n’invente pas de convention supplémentaire.
  Future<PokemonJsonImportPreview> preview(
    ProjectWorkspace workspace, {
    required String absoluteSpeciesSourcePath,
  }) async {
    final prepared = await _prepareBundle(
      workspace,
      absoluteSpeciesSourcePath: absoluteSpeciesSourcePath,
      validateCompanions: false,
    );
    return prepared.preview;
  }

  /// L’import bundle garde un contrat très simple :
  /// - l’espèce source est toujours requise ;
  /// - les annexes sont optionnelles ;
  /// - on valide tout ce qui est détecté avant le premier write ;
  /// - on réutilise ensuite le writer existant, sans nouveau pipeline parallèle.
  Future<PokemonJsonImportResult> execute(
    ProjectWorkspace workspace, {
    required String absoluteSpeciesSourcePath,
  }) async {
    final prepared = await _prepareBundle(
      workspace,
      absoluteSpeciesSourcePath: absoluteSpeciesSourcePath,
      validateCompanions: true,
    );

    await writeRepository.saveSpecies(workspace, prepared.species);
    if (prepared.learnset != null) {
      await writeRepository.saveLearnset(workspace, prepared.learnset!);
    }
    if (prepared.evolution != null) {
      await writeRepository.saveEvolution(workspace, prepared.evolution!);
    }
    if (prepared.media != null) {
      await writeRepository.saveMedia(workspace, prepared.media!);
    }

    return PokemonJsonImportResult(
      preview: prepared.preview,
      importedSpecies: true,
      importedLearnset: prepared.learnset != null,
      importedEvolution: prepared.evolution != null,
      importedMedia: prepared.media != null,
    );
  }

  Future<_PreparedPokemonJsonBundle> _prepareBundle(
    ProjectWorkspace workspace, {
    required String absoluteSpeciesSourcePath,
    required bool validateCompanions,
  }) async {
    final species = await speciesImportUseCase.readValidatedSource(
      workspace,
      absoluteSourcePath: absoluteSpeciesSourcePath,
    );

    final learnsetSourcePath = await _resolveCompanionSourcePath(
      workspace,
      absoluteSpeciesSourcePath: absoluteSpeciesSourcePath,
      siblingFolderName: 'learnsets',
      refId: species.refs.learnset,
    );
    final evolutionSourcePath = await _resolveCompanionSourcePath(
      workspace,
      absoluteSpeciesSourcePath: absoluteSpeciesSourcePath,
      siblingFolderName: 'evolutions',
      refId: species.refs.evolution,
    );
    final mediaSourcePath = await _resolveCompanionSourcePath(
      workspace,
      absoluteSpeciesSourcePath: absoluteSpeciesSourcePath,
      siblingFolderName: 'media',
      refId: species.refs.media,
    );

    final learnset = validateCompanions && learnsetSourcePath != null
        ? await learnsetImportUseCase.readValidatedSource(
            workspace,
            absoluteSourcePath: learnsetSourcePath,
          )
        : null;
    final evolution = validateCompanions && evolutionSourcePath != null
        ? await evolutionImportUseCase.readValidatedSource(
            workspace,
            absoluteSourcePath: evolutionSourcePath,
          )
        : null;
    final media = validateCompanions && mediaSourcePath != null
        ? await mediaImportUseCase.readValidatedSource(
            workspace,
            absoluteSourcePath: mediaSourcePath,
          )
        : null;

    return _PreparedPokemonJsonBundle(
      species: species,
      learnset: learnset,
      evolution: evolution,
      media: media,
      preview: PokemonJsonImportPreview(
        speciesId: species.id,
        nationalDex: species.nationalDex,
        primaryName: _resolvePrimaryName(species),
        types: _normalizeTypes(species.typing.types),
        learnset: PokemonImportArtifactPreview(
          label: 'Learnset',
          refId: species.refs.learnset,
          status: learnsetSourcePath != null
              ? PokemonImportPreviewStatus.found
              : PokemonImportPreviewStatus.missing,
          absoluteSourcePath: learnsetSourcePath,
        ),
        evolution: PokemonImportArtifactPreview(
          label: 'Évolutions',
          refId: species.refs.evolution,
          status: evolutionSourcePath != null
              ? PokemonImportPreviewStatus.found
              : PokemonImportPreviewStatus.missing,
          absoluteSourcePath: evolutionSourcePath,
        ),
        media: PokemonImportArtifactPreview(
          label: 'Médias',
          refId: species.refs.media,
          status: mediaSourcePath != null
              ? PokemonImportPreviewStatus.found
              : PokemonImportPreviewStatus.missing,
          absoluteSourcePath: mediaSourcePath,
        ),
      ),
    );
  }

  Future<String?> _resolveCompanionSourcePath(
    ProjectWorkspace workspace, {
    required String absoluteSpeciesSourcePath,
    required String siblingFolderName,
    required String refId,
  }) async {
    final normalizedRefId = refId.trim();
    if (normalizedRefId.isEmpty) {
      return null;
    }

    final speciesDirectoryPath = p.dirname(absoluteSpeciesSourcePath);
    if (p.basename(speciesDirectoryPath).toLowerCase() != 'species') {
      return null;
    }

    final siblingDirectoryPath = p.join(
      p.dirname(speciesDirectoryPath),
      siblingFolderName,
    );
    final candidatePath =
        p.normalize(p.join(siblingDirectoryPath, '$normalizedRefId.json'));

    if (!await workspace.fileExists(candidatePath)) {
      return null;
    }
    return candidatePath;
  }

  String _resolvePrimaryName(PokemonSpeciesFile species) {
    final preferredEnglish = species.names['en']?.trim();
    if (preferredEnglish != null && preferredEnglish.isNotEmpty) {
      return preferredEnglish;
    }

    final preferredFrench = species.names['fr']?.trim();
    if (preferredFrench != null && preferredFrench.isNotEmpty) {
      return preferredFrench;
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
}

class _PreparedPokemonJsonBundle {
  const _PreparedPokemonJsonBundle({
    required this.species,
    required this.learnset,
    required this.evolution,
    required this.media,
    required this.preview,
  });

  final PokemonSpeciesFile species;
  final PokemonLearnsetFile? learnset;
  final PokemonEvolutionFile? evolution;
  final PokemonMediaFile? media;
  final PokemonJsonImportPreview preview;
}
