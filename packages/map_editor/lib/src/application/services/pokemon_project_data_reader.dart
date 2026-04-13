import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../errors/application_errors.dart';
import '../models/pokemon_database_index.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/project_workspace.dart';

/// Lecteur local des donnees Pokemon stockees dans le workspace projet.
///
/// Invariants de cette couche :
/// - toutes les lectures passent par [ProjectWorkspace.projectRoot]
/// - aucun fallback implicite vers `Directory.current`
/// - aucune lecture depuis la racine du monorepo
/// - les erreurs doivent etre explicites pour que les prochains lots UI
///   puissent les afficher proprement
class PokemonProjectDataReader {
  const PokemonProjectDataReader();

  Future<PokemonDataManifest> readManifest(ProjectWorkspace workspace) async {
    final json = await _readJsonFile(
      workspace,
      await _pokemonDataManifestRelativePath(workspace),
      label: 'Pokemon data manifest',
    );
    return PokemonDataManifest.fromJson(json);
  }

  Future<PokemonCatalogFile> readCatalogByKey(
    ProjectWorkspace workspace,
    String catalogKey,
  ) async {
    // The local Pokemon bootstrap manifest is useful when it exists, but it is
    // not the only source of truth in real projects. The editor already uses
    // `project.json -> pokemon.*` to index species, so guided moves/items must
    // honor that same config instead of failing just because the optional
    // bootstrap manifest is absent.
    final pokemonConfig = await _readProjectPokemonConfig(workspace);

    String? relativePath;
    try {
      final manifest = await readManifest(workspace);
      final declaredPath = manifest.catalogFiles[catalogKey]?.trim();
      if (declaredPath != null && declaredPath.isNotEmpty) {
        relativePath = _resolvePathWithinPokemonDataRoot(
          pokemonConfig: pokemonConfig,
          rawRelativePath: declaredPath,
        );
      }
    } on EditorNotFoundException {
      // Real projects can still be fully authorable with `project.json`
      // storage paths even when the bootstrap manifest has not been created.
      relativePath = null;
    }

    if (relativePath == null) {
      final configuredPath = pokemonConfig.catalogFiles[catalogKey]?.trim();
      if (configuredPath != null && configuredPath.isNotEmpty) {
        relativePath = p.normalize(configuredPath);
      }
    }

    if (relativePath == null || relativePath.trim().isEmpty) {
      throw EditorNotFoundException(
        'Pokemon catalog not declared in project manifest or project config: '
        '$catalogKey',
      );
    }
    final json = await _readJsonFile(
      workspace,
      relativePath,
      label: 'Pokemon catalog "$catalogKey"',
    );
    return PokemonCatalogFile.fromJson(json);
  }

  Future<PokemonSpeciesFile> readSpeciesById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    final trimmedId = speciesId.trim();
    if (trimmedId.isEmpty) {
      throw const EditorValidationException(
          'Pokemon species id cannot be empty');
    }

    final speciesPathEntry =
        await _resolveSpeciesIndexEntryById(workspace, trimmedId);
    final species = await _readSpeciesAtRelativePath(
      workspace,
      speciesPathEntry.relativePath,
    );
    if (species.id != trimmedId) {
      throw EditorPersistenceException(
        'Pokemon species file id mismatch for "$trimmedId": '
        '${speciesPathEntry.relativePath} contains "${species.id}"',
      );
    }
    return species;
  }

  Future<PokemonLearnsetFile> readLearnsetById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    final trimmedId = speciesId.trim();
    if (trimmedId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon learnset id cannot be empty',
      );
    }
    final learnsetsDirectory = await _learnsetsDirectoryRelativePath(workspace);
    final json = await _readJsonFile(
      workspace,
      p.join(learnsetsDirectory, '$trimmedId.json'),
      label: 'Pokemon learnset "$trimmedId"',
    );
    return PokemonLearnsetFile.fromJson(json);
  }

  Future<PokemonEvolutionFile> readEvolutionById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    final trimmedId = speciesId.trim();
    if (trimmedId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon evolution id cannot be empty',
      );
    }
    final evolutionsDirectory =
        await _evolutionsDirectoryRelativePath(workspace);
    final json = await _readJsonFile(
      workspace,
      p.join(evolutionsDirectory, '$trimmedId.json'),
      label: 'Pokemon evolution "$trimmedId"',
    );
    return PokemonEvolutionFile.fromJson(json);
  }

  Future<PokemonMediaFile> readMediaById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    final trimmedId = speciesId.trim();
    if (trimmedId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon media id cannot be empty',
      );
    }
    final mediaDirectory = await _mediaDirectoryRelativePath(workspace);
    final json = await _readJsonFile(
      workspace,
      p.join(mediaDirectory, '$trimmedId.json'),
      label: 'Pokemon media "$trimmedId"',
    );
    return PokemonMediaFile.fromJson(json);
  }

  Future<List<String>> listSpeciesFiles(ProjectWorkspace workspace) async {
    final speciesDirectory = await _speciesDirectoryRelativePath(workspace);
    return _listJsonRelativePaths(
      workspace,
      speciesDirectory,
      label: 'Pokemon species directory',
    );
  }

  Future<List<PokemonSpeciesIndexEntry>> listSpeciesIndexEntries(
    ProjectWorkspace workspace,
  ) async {
    return _buildSpeciesIndexEntries(workspace);
  }

  Future<List<PokemonDatabaseIndexEntry>> listDatabaseIndexEntries(
    ProjectWorkspace workspace, {
    required String speciesDirectoryRelativePath,
  }) async {
    final trimmedDirectory = speciesDirectoryRelativePath.trim();
    if (trimmedDirectory.isEmpty) {
      throw const EditorValidationException(
        'Pokemon species directory cannot be empty',
      );
    }

    final entries = <PokemonDatabaseIndexEntry>[];
    for (final relativePath in await _listJsonRelativePaths(
      workspace,
      trimmedDirectory,
      label: 'Pokemon species directory',
    )) {
      final species = await _readSpeciesAtRelativePath(
        workspace,
        relativePath,
      );
      final speciesIndexEntry = PokemonSpeciesIndexEntry.fromSpeciesFile(
        species,
        relativePath: relativePath,
      );

      // Le lot 11 ne doit plus accepter silencieusement une espèce parseable
      // mais inutilisable pour la future liste. On vérifie donc ici le contrat
      // minimal exact de l'index local.
      _validateSpeciesForDatabaseIndex(
        species: species,
        speciesIndexEntry: speciesIndexEntry,
        relativePath: relativePath,
      );

      // Le portrait de liste reste volontairement best effort :
      // - si le média local n'existe pas, la liste ne casse pas ;
      // - si le `media.json` est invalide, on n'empêche pas l'espèce de
      //   remonter dans l'éditeur ;
      // - si le fichier portrait n'existe plus sur disque, on omet
      //   simplement l'image décorative.
      //
      // Cela permet d'embellir la liste sans transformer l'index léger en
      // seconde fiche détail ni faire de l'UI une lectrice JSON parallèle.
      final portraitRelativePath = await _resolveOptionalPortraitRelativePath(
        workspace,
        species,
      );

      entries.add(
        PokemonDatabaseIndexEntry.fromSpeciesEntry(
          speciesIndexEntry: speciesIndexEntry,
          species: species,
          portraitRelativePath: portraitRelativePath,
        ),
      );
    }

    entries.sort((left, right) {
      final dexCompare = left.nationalDex.compareTo(right.nationalDex);
      if (dexCompare != 0) return dexCompare;
      return left.id.compareTo(right.id);
    });

    return entries;
  }

  Future<String?> _resolveOptionalPortraitRelativePath(
    ProjectWorkspace workspace,
    PokemonSpeciesFile species,
  ) async {
    final mediaId = species.refs.media.trim();
    if (mediaId.isEmpty) {
      return null;
    }

    try {
      final media = await readMediaById(workspace, mediaId);
      final defaultVariant = media.variants[media.defaultFormId];
      final portraitRelativePath = defaultVariant?.portrait?.trim();
      if (portraitRelativePath == null || portraitRelativePath.isEmpty) {
        return null;
      }

      final exists = await workspace.fileExists(
        workspace.resolveProjectRelativePath(portraitRelativePath),
      );
      return exists ? portraitRelativePath : null;
    } on EditorApplicationException {
      // Important : le portrait de liste est décoratif.
      // Une erreur média locale ne doit pas rendre la liste Pokédex inutilisable
      // si l'espèce elle-même reste lisible et indexable.
      return null;
    } catch (_) {
      // Même philosophie ici : on ne masque pas un problème plus loin dans la
      // stack, mais on n'échoue pas non plus la liste pour un portrait.
      return null;
    }
  }

  Future<PokemonSpeciesFile> readSpeciesByRelativePath(
    ProjectWorkspace workspace,
    String relativePath,
  ) {
    return _readSpeciesAtRelativePath(workspace, relativePath);
  }

  Future<List<String>> listLearnsetIds(ProjectWorkspace workspace) async {
    final learnsetsDirectory = await _learnsetsDirectoryRelativePath(workspace);
    return _listJsonFileStemIds(
      workspace,
      learnsetsDirectory,
      label: 'Pokemon learnsets directory',
    );
  }

  Future<List<String>> listEvolutionIds(ProjectWorkspace workspace) async {
    final evolutionsDirectory =
        await _evolutionsDirectoryRelativePath(workspace);
    return _listJsonFileStemIds(
      workspace,
      evolutionsDirectory,
      label: 'Pokemon evolutions directory',
    );
  }

  Future<List<String>> listMediaIds(ProjectWorkspace workspace) async {
    final mediaDirectory = await _mediaDirectoryRelativePath(workspace);
    return _listJsonFileStemIds(
      workspace,
      mediaDirectory,
      label: 'Pokemon media directory',
    );
  }

  Future<String?> resolveSpeciesRelativePathById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    final trimmedId = speciesId.trim();
    if (trimmedId.isEmpty) {
      throw const EditorValidationException(
          'Pokemon species id cannot be empty');
    }

    final speciesDir = await _speciesDirectory(workspace);
    if (!await speciesDir.exists()) {
      return null;
    }

    final matches = <String>[];

    await for (final entity in speciesDir.list(recursive: false)) {
      if (entity is! File) continue;
      if (p.extension(entity.path).toLowerCase() != '.json') continue;
      final relativePath =
          p.normalize(p.relative(entity.path, from: workspace.projectRoot));

      // Le basename ne suffit pas ici : un fichier peut s'appeler
      // `9999-bulbasaur.json` tout en déclarant en réalité `"id": "ivysaur"`.
      // Pour la résolution d'un overwrite species, la seule source de vérité
      // acceptable est donc l'id réellement stocké dans le JSON.
      //
      // On choisit volontairement la correction la plus sûre :
      // - on lit chaque JSON species ;
      // - on ignore silencieusement les fichiers invalides / non objets /
      //   sans `id` exploitable ;
      // - on ne compte comme match que les fichiers qui déclarent exactement
      //   l'id demandé.
      //
      // Cette approche évite les faux positifs de basename et garde le writer
      // ainsi que l'import externe cohérents avec la merge policy annoncée.
      final declaredId = await _readDeclaredSpeciesId(entity);
      if (declaredId == trimmedId) {
        matches.add(relativePath);
      }
    }

    matches.sort();
    final uniqueMatches = matches.toSet().toList(growable: false)..sort();

    if (uniqueMatches.length > 1) {
      throw EditorConflictException(
        'Multiple Pokemon species files match the id "$trimmedId": '
        '${uniqueMatches.join(', ')}',
      );
    }

    if (uniqueMatches.isEmpty) {
      return null;
    }

    return uniqueMatches.single;
  }

  Future<List<PokemonSpeciesIndexEntry>> _buildSpeciesIndexEntries(
    ProjectWorkspace workspace,
  ) async {
    final entries = <PokemonSpeciesIndexEntry>[];
    for (final relativePath in await listSpeciesFiles(workspace)) {
      final species = await _readSpeciesAtRelativePath(workspace, relativePath);
      entries.add(
        PokemonSpeciesIndexEntry.fromSpeciesFile(
          species,
          relativePath: relativePath,
        ),
      );
    }
    entries.sort((left, right) {
      final dexCompare = left.nationalDex.compareTo(right.nationalDex);
      if (dexCompare != 0) return dexCompare;
      return left.id.compareTo(right.id);
    });
    return entries;
  }

  Future<PokemonSpeciesFile> _readSpeciesAtRelativePath(
    ProjectWorkspace workspace,
    String relativePath,
  ) async {
    final json = await _readJsonFile(
      workspace,
      relativePath,
      label: 'Pokemon species file',
    );
    return PokemonSpeciesFile.fromJson(json);
  }

  void _validateSpeciesForDatabaseIndex({
    required PokemonSpeciesFile species,
    required PokemonSpeciesIndexEntry speciesIndexEntry,
    required String relativePath,
  }) {
    // Cette validation reste volontairement petite. Elle ne remplace pas le
    // validateur Pokémon global : elle protège seulement le contrat minimal
    // exigé par l'index local du lot 11.
    if (speciesIndexEntry.id.trim().isEmpty) {
      throw EditorPersistenceException(
        'Pokemon species index file must define a non-empty id: $relativePath',
      );
    }

    if (speciesIndexEntry.nationalDex <= 0) {
      throw EditorPersistenceException(
        'Pokemon species index file must define nationalDex > 0: $relativePath',
      );
    }

    if (speciesIndexEntry.primaryName.trim().isEmpty) {
      throw EditorPersistenceException(
        'Pokemon species index file must define an exploitable primary name: '
        '$relativePath',
      );
    }

    _validateDatabaseIndexRef(
      value: species.refs.learnset,
      refName: 'refs.learnset',
      relativePath: relativePath,
    );
    _validateDatabaseIndexRef(
      value: species.refs.evolution,
      refName: 'refs.evolution',
      relativePath: relativePath,
    );
    _validateDatabaseIndexRef(
      value: species.refs.media,
      refName: 'refs.media',
      relativePath: relativePath,
    );
  }

  void _validateDatabaseIndexRef({
    required String value,
    required String refName,
    required String relativePath,
  }) {
    if (value.trim().isEmpty) {
      throw EditorPersistenceException(
        'Pokemon species index file must define a non-empty $refName: '
        '$relativePath',
      );
    }
  }

  Future<PokemonSpeciesIndexEntry> _resolveSpeciesIndexEntryById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    final matches = (await _buildSpeciesIndexEntries(workspace))
        .where((entry) => entry.id == speciesId)
        .toList(growable: false);
    if (matches.isEmpty) {
      throw EditorNotFoundException('Pokemon species not found: $speciesId');
    }
    if (matches.length > 1) {
      throw EditorConflictException(
        'Multiple Pokemon species files share the same id "$speciesId": '
        '${matches.map((entry) => entry.relativePath).join(', ')}',
      );
    }
    return matches.single;
  }

  Future<Directory> _speciesDirectory(ProjectWorkspace workspace) async {
    final speciesDirectory = await _speciesDirectoryRelativePath(workspace);
    return Directory(
      workspace.resolveProjectRelativePath(speciesDirectory),
    );
  }

  Future<String> _pokemonDataManifestRelativePath(
    ProjectWorkspace workspace,
  ) async {
    final pokemonConfig = await _readProjectPokemonConfig(workspace);
    final dataRoot = _normalizeConfiguredRelativePath(
      pokemonConfig.dataRoot,
      fallback: 'data/pokemon',
    );
    return p.normalize(p.join(dataRoot, 'pokemon_data_manifest.json'));
  }

  Future<String> _speciesDirectoryRelativePath(
    ProjectWorkspace workspace,
  ) async {
    final pokemonConfig = await _readProjectPokemonConfig(workspace);
    return _normalizeConfiguredRelativePath(
      pokemonConfig.speciesDir,
      fallback: 'data/pokemon/species',
    );
  }

  Future<String> _learnsetsDirectoryRelativePath(
    ProjectWorkspace workspace,
  ) async {
    final pokemonConfig = await _readProjectPokemonConfig(workspace);
    return _normalizeConfiguredRelativePath(
      pokemonConfig.learnsetsDir,
      fallback: 'data/pokemon/learnsets',
    );
  }

  Future<String> _evolutionsDirectoryRelativePath(
    ProjectWorkspace workspace,
  ) async {
    final pokemonConfig = await _readProjectPokemonConfig(workspace);
    return _normalizeConfiguredRelativePath(
      pokemonConfig.evolutionsDir,
      fallback: 'data/pokemon/evolutions',
    );
  }

  Future<String> _mediaDirectoryRelativePath(
    ProjectWorkspace workspace,
  ) async {
    final pokemonConfig = await _readProjectPokemonConfig(workspace);
    return _normalizeConfiguredRelativePath(
      pokemonConfig.mediaDir,
      fallback: 'data/pokemon/media',
    );
  }

  Future<ProjectPokemonConfig> _readProjectPokemonConfig(
    ProjectWorkspace workspace,
  ) async {
    final manifestPath = workspace.projectManifestPath;
    try {
      // Real projects always have `project.json`, but a few lightweight tests
      // and temporary workspaces still seed only the Pokemon files. Falling
      // back to the historical default layout keeps those fixtures working
      // while still honoring project-specific paths whenever the manifest is
      // present.
      if (!await workspace.fileExists(manifestPath)) {
        return const ProjectPokemonConfig();
      }

      final raw = await workspace.readTextFile(manifestPath);
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw EditorPersistenceException(
          'Project manifest is not a JSON object: $manifestPath',
        );
      }
      final project = ProjectManifest.fromJson(decoded);
      return project.pokemon;
    } on EditorPersistenceException {
      rethrow;
    } on FileSystemException catch (error) {
      throw EditorPersistenceException(
        'Failed to read project manifest at $manifestPath: $error',
      );
    } on FormatException catch (error) {
      throw EditorPersistenceException(
        'Invalid JSON in project manifest at $manifestPath: $error',
      );
    } catch (error) {
      throw EditorPersistenceException(
        'Invalid project manifest at $manifestPath: $error',
      );
    }
  }

  String _normalizeConfiguredRelativePath(
    String rawRelativePath, {
    required String fallback,
  }) {
    final trimmed = rawRelativePath.trim();
    return p.normalize(trimmed.isEmpty ? fallback : trimmed);
  }

  String _resolvePathWithinPokemonDataRoot({
    required ProjectPokemonConfig pokemonConfig,
    required String rawRelativePath,
  }) {
    final normalizedPath = p.normalize(rawRelativePath.trim());
    final dataRoot = _normalizeConfiguredRelativePath(
      pokemonConfig.dataRoot,
      fallback: 'data/pokemon',
    );
    if (normalizedPath == dataRoot || normalizedPath.startsWith('$dataRoot/')) {
      return normalizedPath;
    }
    return p.normalize(p.join(dataRoot, normalizedPath));
  }

  Future<List<String>> _listJsonRelativePaths(
    ProjectWorkspace workspace,
    String relativeDirectory, {
    required String label,
  }) async {
    final directory = Directory(
      workspace.resolveProjectRelativePath(relativeDirectory),
    );
    if (!await directory.exists()) {
      throw EditorNotFoundException('$label not found in project workspace');
    }

    final relativePaths = <String>[];
    await for (final entity in directory.list(recursive: false)) {
      if (entity is! File) continue;
      if (p.extension(entity.path).toLowerCase() != '.json') continue;
      relativePaths.add(
        p.normalize(p.relative(entity.path, from: workspace.projectRoot)),
      );
    }
    relativePaths.sort();
    return relativePaths;
  }

  Future<List<String>> _listJsonFileStemIds(
    ProjectWorkspace workspace,
    String relativeDirectory, {
    required String label,
  }) async {
    final relativePaths = await _listJsonRelativePaths(
      workspace,
      relativeDirectory,
      label: label,
    );
    return relativePaths
        .map((relativePath) => p.basenameWithoutExtension(relativePath))
        .toList(growable: false);
  }

  Future<String?> _readDeclaredSpeciesId(File file) async {
    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final declaredId = decoded['id'];
      if (declaredId is! String) {
        return null;
      }

      final trimmedId = declaredId.trim();
      if (trimmedId.isEmpty) {
        return null;
      }

      // Un fichier mal formé ou non concerné ne doit pas bloquer la résolution
      // d'une autre espèce. On remonte seulement les vrais doublons d'id.
      return trimmedId;
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
  }

  Future<Map<String, dynamic>> _readJsonFile(
    ProjectWorkspace workspace,
    String relativePath, {
    required String label,
  }) async {
    final absolutePath = workspace.resolveProjectRelativePath(relativePath);
    final file = File(absolutePath);
    if (!await file.exists()) {
      throw EditorNotFoundException('$label not found: $relativePath');
    }

    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw EditorPersistenceException(
          '$label is not a JSON object: $relativePath',
        );
      }
      return decoded;
    } on EditorPersistenceException {
      rethrow;
    } on FileSystemException catch (error) {
      throw EditorPersistenceException(
        'Failed to read $label at $relativePath: $error',
      );
    } on FormatException catch (error) {
      throw EditorPersistenceException(
        'Invalid JSON in $label at $relativePath: $error',
      );
    }
  }
}
