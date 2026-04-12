import 'package:path/path.dart' as p;

import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/pokemon_read_repository.dart';
import '../ports/project_workspace.dart';
import '../services/pokemon_project_data_reader.dart';

/// Callback UI minimal pour supprimer une espèce locale depuis le workspace.
///
/// La UI n'a pas à connaître :
/// - quels fichiers JSON sont supprimés ;
/// - quels assets sont dérivés du `media.json` ;
/// - comment retrouver le vrai chemin disque du fichier espèce.
///
/// Elle déclenche seulement l'intention utilisateur "supprimer cette espèce".
typedef PokedexSpeciesDeleter = Future<DeletedPokedexSpeciesResult> Function(
  ProjectWorkspace workspace,
  String speciesId,
);

/// Résultat applicatif minimal d'une suppression Pokédex locale.
///
/// On retourne volontairement peu d'informations :
/// - le `speciesId` pour le suivi technique ;
/// - le `primaryName` pour un feedback humain lisible ;
/// - la liste des chemins supprimés pour les tests ciblés et le debug.
///
/// On ne crée pas de second événement domaine ni de couche de reporting.
class DeletedPokedexSpeciesResult {
  const DeletedPokedexSpeciesResult({
    required this.speciesId,
    required this.primaryName,
    required this.deletedRelativePaths,
  });

  final String speciesId;
  final String primaryName;
  final List<String> deletedRelativePaths;
}

/// Supprime une espèce Pokédex locale et les fichiers explicitement liés.
///
/// Intention de ce use case :
/// - enlever l'espèce de la source de vérité locale, donc de la liste Pokédex ;
/// - retirer les sidecars optionnels (`learnset`, `evolution`, `media`) ;
/// - retirer les assets référencés par `media.json` quand ce fichier existe ;
/// - ne jamais toucher à `project.json`.
///
/// Invariants :
/// - pas de refonte d'architecture ;
/// - pas de nouvelle table d'index ;
/// - pas de logique UI ici ;
/// - aucune hypothèse cachée sur le nom de fichier espèce, car le repo peut
///   déjà contenir des chemins non canoniques qu'il faut quand même supprimer.
///
/// Non-objectifs assumés :
/// - on ne tente pas de nettoyer des assets orphelins non référencés ;
/// - on ne réécrit pas les autres espèces qui pourraient théoriquement
///   partager un même asset ;
/// - on ne modifie pas le manifeste projet.
class DeletePokedexSpeciesUseCase {
  const DeletePokedexSpeciesUseCase({
    required this.readRepository,
    this.dataReader = const PokemonProjectDataReader(),
  });

  final PokemonReadRepository readRepository;
  final PokemonProjectDataReader dataReader;

  Future<DeletedPokedexSpeciesResult> execute(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    final normalizedSpeciesId = speciesId.trim();
    if (normalizedSpeciesId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon species id cannot be empty',
      );
    }

    // On relit toujours l'espèce réelle avant suppression.
    //
    // Pourquoi :
    // - la UI peut montrer un état périmé ;
    // - le vrai nom principal utile au feedback vit dans le JSON actuel ;
    // - les refs vers learnset/evolution/media viennent de ce fichier.
    final species = await readRepository.readSpeciesById(
      workspace,
      normalizedSpeciesId,
    );
    final speciesRelativePath = await dataReader.resolveSpeciesRelativePathById(
      workspace,
      normalizedSpeciesId,
    );
    if (speciesRelativePath == null) {
      throw EditorNotFoundException(
        'Pokemon species file not found for id: $normalizedSpeciesId',
      );
    }

    // La suppression d'une espèce doit rester robuste même si certains
    // compagnons sont absents. On lit donc `media.json` en best effort :
    // - présent => on en déduit les assets à retirer ;
    // - absent => on n'invente rien, on supprime seulement les JSON connus.
    final media = await _readOptionalMedia(workspace, species);

    final relativePathsToDelete = <String>{
      speciesRelativePath,
      _companionRelativePath(
        folderName: 'learnsets',
        referenceId: species.refs.learnset,
        fallbackSpeciesId: normalizedSpeciesId,
      ),
      _companionRelativePath(
        folderName: 'evolutions',
        referenceId: species.refs.evolution,
        fallbackSpeciesId: normalizedSpeciesId,
      ),
      _companionRelativePath(
        folderName: 'media',
        referenceId: species.refs.media,
        fallbackSpeciesId: normalizedSpeciesId,
      ),
      ..._extractReferencedAssetPaths(media),
    }..removeWhere((value) => value.trim().isEmpty);

    final deletedRelativePaths = <String>[];
    for (final relativePath in relativePathsToDelete) {
      final normalizedPath = p.posix.normalize(relativePath.trim());
      final absolutePath = workspace.resolveProjectRelativePath(normalizedPath);
      final existedBefore = await workspace.fileExists(absolutePath);
      await workspace.deleteRelativeFile(normalizedPath);
      if (existedBefore) {
        deletedRelativePaths.add(normalizedPath);
      }
    }

    return DeletedPokedexSpeciesResult(
      speciesId: normalizedSpeciesId,
      primaryName: _resolvePrimaryName(species),
      deletedRelativePaths: deletedRelativePaths..sort(),
    );
  }

  Future<PokemonMediaFile?> _readOptionalMedia(
    ProjectWorkspace workspace,
    PokemonSpeciesFile species,
  ) async {
    final mediaRef = species.refs.media.trim();
    final resolvedMediaId = mediaRef.isEmpty ? species.id.trim() : mediaRef;
    if (resolvedMediaId.isEmpty) {
      return null;
    }

    try {
      return await readRepository.readMediaById(workspace, resolvedMediaId);
    } on EditorNotFoundException {
      return null;
    }
  }

  String _companionRelativePath({
    required String folderName,
    required String referenceId,
    required String fallbackSpeciesId,
  }) {
    final resolvedId = referenceId.trim().isEmpty
        ? fallbackSpeciesId.trim()
        : referenceId.trim();
    return 'data/pokemon/$folderName/$resolvedId.json';
  }

  Set<String> _extractReferencedAssetPaths(PokemonMediaFile? media) {
    if (media == null) {
      return const <String>{};
    }

    final relativePaths = <String>{};

    // Point d'attention important :
    // on ne supprime que les assets explicitement référencés par `media.json`.
    //
    // Cela garantit deux choses :
    // - la suppression reste cohérente avec la source de vérité locale ;
    // - on évite de transformer ce bouton en "garbage collector" agressif
    //   capable d'effacer d'autres fichiers que l'espèce courante.
    for (final variant in media.variants.values) {
      _addIfNotEmpty(relativePaths, variant.frontStatic);
      _addIfNotEmpty(relativePaths, variant.backStatic);
      _addIfNotEmpty(relativePaths, variant.frontShinyStatic);
      _addIfNotEmpty(relativePaths, variant.backShinyStatic);
      _addIfNotEmpty(relativePaths, variant.icon);
      _addIfNotEmpty(relativePaths, variant.party);
      _addIfNotEmpty(relativePaths, variant.overworld);
      _addIfNotEmpty(relativePaths, variant.portrait);
      _addIfNotEmpty(relativePaths, variant.cry);
      for (final animation in variant.animations.values) {
        _addIfNotEmpty(relativePaths, animation.sheet);
      }
    }

    return relativePaths;
  }

  void _addIfNotEmpty(Set<String> target, String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return;
    }
    target.add(normalized);
  }

  String _resolvePrimaryName(PokemonSpeciesFile species) {
    for (final preferredLocale in const <String>['fr', 'en']) {
      final localized = species.names[preferredLocale]?.trim();
      if (localized != null && localized.isNotEmpty) {
        return localized;
      }
    }
    for (final localized in species.names.values) {
      final normalized = localized.trim();
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }
    return species.id;
  }
}
