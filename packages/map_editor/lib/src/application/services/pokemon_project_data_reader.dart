import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../errors/application_errors.dart';
import '../models/pokemon_database_index.dart';
import '../ports/project_workspace.dart';

class PokemonSpeciesSnapshotMetrics {
  const PokemonSpeciesSnapshotMetrics();

  void onSnapshotBuildStarted(String projectRoot, String relativeDirectory) {}

  void onSpeciesDirectoryListed(String projectRoot, String relativeDirectory) {}

  void onSpeciesJsonRead(String projectRoot, String relativePath) {}
}

/// Lecteur local des donnees Pokemon stockees dans le workspace projet.
///
/// Invariants de cette couche :
/// - toutes les lectures passent par [ProjectWorkspace.projectRoot]
/// - aucun fallback implicite vers `Directory.current`
/// - aucune lecture depuis la racine du monorepo
/// - les erreurs doivent etre explicites pour que les prochains lots UI
///   puissent les afficher proprement
class PokemonProjectDataReader {
  static const _speciesSnapshotCacheKey = 'pokemon.species.snapshot.v1';

  PokemonProjectDataReader({
    this.snapshotMetrics = const PokemonSpeciesSnapshotMetrics(),
  });

  final PokemonSpeciesSnapshotMetrics snapshotMetrics;
  final Expando<Map<String, Future<_PokemonSpeciesSnapshot>>>
      _speciesSnapshots =
      Expando<Map<String, Future<_PokemonSpeciesSnapshot>>>();

  void invalidateSpeciesSnapshot(ProjectWorkspace workspace) {
    if (workspace is ProjectWorkspaceCache) {
      (workspace as ProjectWorkspaceCache).writeCachedValue(
        _speciesSnapshotCacheKey,
        null,
      );
    }
    _speciesSnapshots[workspace] = null;
  }

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
        'Pokemon species id cannot be empty',
      );
    }

    final snapshot = await _speciesSnapshot(workspace);
    final species = snapshot.speciesById[trimmedId];
    if (species == null) {
      throw EditorNotFoundException('Pokemon species not found: $trimmedId');
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
    final evolutionsDirectory = await _evolutionsDirectoryRelativePath(
      workspace,
    );
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
      throw const EditorValidationException('Pokemon media id cannot be empty');
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
    return (await _speciesSnapshot(workspace)).relativePaths;
  }

  Future<List<PokemonSpeciesIndexEntry>> listSpeciesIndexEntries(
    ProjectWorkspace workspace,
  ) async {
    return (await _speciesSnapshot(workspace)).index.entries;
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

    final snapshot = await _speciesSnapshot(
      workspace,
      relativeDirectory: trimmedDirectory,
    );
    final entries = <PokemonDatabaseIndexEntry>[];
    for (final speciesIndexEntry in snapshot.index.entries) {
      final relativePath = speciesIndexEntry.relativePath;
      final species = snapshot.speciesById[speciesIndexEntry.id]!;

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
      final mediaPreview = await _resolveOptionalMediaPreview(
        workspace,
        species,
      );

      entries.add(
        PokemonDatabaseIndexEntry.fromSpeciesEntry(
          speciesIndexEntry: speciesIndexEntry,
          species: species,
          portraitRelativePath: mediaPreview.portraitRelativePath,
          thumbnailRelativePath: mediaPreview.thumbnailRelativePath,
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

  Future<({String? portraitRelativePath, String? thumbnailRelativePath})>
      _resolveOptionalMediaPreview(
    ProjectWorkspace workspace,
    PokemonSpeciesFile species,
  ) async {
    final mediaId = species.refs.media.trim();
    if (mediaId.isEmpty) {
      return (portraitRelativePath: null, thumbnailRelativePath: null);
    }

    try {
      final media = await readMediaById(workspace, mediaId);
      final defaultVariant = media.variants[media.defaultFormId];
      final portraitRelativePath = await _resolveExistingMediaPath(
        workspace,
        defaultVariant?.portrait,
      );
      String? thumbnailRelativePath;
      for (final candidate in <String?>[
        defaultVariant?.frontStatic,
        defaultVariant?.icon,
        defaultVariant?.party,
      ]) {
        thumbnailRelativePath = await _resolveExistingMediaPath(
          workspace,
          candidate,
        );
        if (thumbnailRelativePath != null) {
          break;
        }
      }
      return (
        portraitRelativePath: portraitRelativePath,
        thumbnailRelativePath: thumbnailRelativePath ?? portraitRelativePath,
      );
    } on EditorApplicationException {
      // Important : le portrait de liste est décoratif.
      // Une erreur média locale ne doit pas rendre la liste Pokédex inutilisable
      // si l'espèce elle-même reste lisible et indexable.
      return (portraitRelativePath: null, thumbnailRelativePath: null);
    } catch (_) {
      // Même philosophie ici : on ne masque pas un problème plus loin dans la
      // stack, mais on n'échoue pas non plus la liste pour un portrait.
      return (portraitRelativePath: null, thumbnailRelativePath: null);
    }
  }

  Future<String?> _resolveExistingMediaPath(
    ProjectWorkspace workspace,
    String? rawRelativePath,
  ) async {
    final relativePath = rawRelativePath?.trim();
    if (relativePath == null || relativePath.isEmpty) {
      return null;
    }
    final exists = await workspace.fileExists(
      workspace.resolveProjectRelativePath(relativePath),
    );
    return exists ? relativePath : null;
  }

  Future<PokemonSpeciesFile> readSpeciesByRelativePath(
    ProjectWorkspace workspace,
    String relativePath,
  ) async {
    final normalizedPath = p.normalize(relativePath.trim());
    final snapshot = await _speciesSnapshot(workspace);
    return snapshot.speciesByRelativePath[normalizedPath] ??
        _readSpeciesAtRelativePath(workspace, normalizedPath);
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
    final evolutionsDirectory = await _evolutionsDirectoryRelativePath(
      workspace,
    );
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
        'Pokemon species id cannot be empty',
      );
    }

    final speciesDirectory = await _speciesDirectory(workspace);
    if (!await speciesDirectory.exists()) {
      return null;
    }
    return (await _speciesSnapshot(
      workspace,
    ))
        .index
        .byId(trimmedId)
        ?.relativePath;
  }

  Future<String?> resolveSpeciesWriteRelativePathById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    try {
      return await resolveSpeciesRelativePathById(workspace, speciesId);
    } on EditorConflictException catch (error) {
      throw EditorConflictException(
        'Multiple Pokemon species files match the id "${speciesId.trim()}": '
        '${error.message}',
      );
    } on EditorPersistenceException {
      return _scanSpeciesRelativePathById(workspace, speciesId.trim());
    }
  }

  Future<String?> _scanSpeciesRelativePathById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    final speciesDirectory = await _speciesDirectory(workspace);
    final matches = <String>[];
    await for (final entity in speciesDirectory.list(recursive: false)) {
      if (entity is! File) continue;
      if (p.extension(entity.path).toLowerCase() != '.json') continue;
      if (await _readDeclaredSpeciesId(entity) != speciesId) continue;
      matches.add(
        p.normalize(p.relative(entity.path, from: workspace.projectRoot)),
      );
    }
    matches.sort();
    if (matches.length > 1) {
      throw EditorConflictException(
        'Multiple Pokemon species files match the id "$speciesId": '
        '${matches.join(', ')}',
      );
    }
    return matches.isEmpty ? null : matches.single;
  }

  Future<_PokemonSpeciesSnapshot> _speciesSnapshot(
    ProjectWorkspace workspace, {
    String? relativeDirectory,
  }) async {
    final directory = p.normalize(
      relativeDirectory ?? await _speciesDirectoryRelativePath(workspace),
    );
    final cache = _snapshotCacheFor(workspace);
    final existing = cache[directory];
    if (existing != null) {
      return existing;
    }
    final pending = _buildSpeciesSnapshot(workspace, directory);
    cache[directory] = pending;
    try {
      return await pending;
    } catch (_) {
      if (identical(cache[directory], pending)) {
        cache.remove(directory);
      }
      rethrow;
    }
  }

  Map<String, Future<_PokemonSpeciesSnapshot>> _snapshotCacheFor(
    ProjectWorkspace workspace,
  ) {
    if (workspace is ProjectWorkspaceCache) {
      final cacheWorkspace = workspace as ProjectWorkspaceCache;
      final existing = cacheWorkspace
          .readCachedValue<Map<String, Future<_PokemonSpeciesSnapshot>>>(
              _speciesSnapshotCacheKey);
      if (existing != null) {
        return existing;
      }
      final created = <String, Future<_PokemonSpeciesSnapshot>>{};
      cacheWorkspace.writeCachedValue(_speciesSnapshotCacheKey, created);
      return created;
    }
    return _speciesSnapshots[workspace] ??=
        <String, Future<_PokemonSpeciesSnapshot>>{};
  }

  Future<_PokemonSpeciesSnapshot> _buildSpeciesSnapshot(
    ProjectWorkspace workspace,
    String relativeDirectory,
  ) async {
    snapshotMetrics.onSnapshotBuildStarted(
      workspace.projectRoot,
      relativeDirectory,
    );
    snapshotMetrics.onSpeciesDirectoryListed(
      workspace.projectRoot,
      relativeDirectory,
    );
    final relativePaths = await _listJsonRelativePaths(
      workspace,
      relativeDirectory,
      label: 'Pokemon species directory',
    );
    final entries = <PokemonSpeciesIndexEntry>[];
    final speciesById = <String, PokemonSpeciesFile>{};
    final speciesByRelativePath = <String, PokemonSpeciesFile>{};
    final entryById = <String, PokemonSpeciesIndexEntry>{};
    for (final relativePath in relativePaths) {
      snapshotMetrics.onSpeciesJsonRead(workspace.projectRoot, relativePath);
      final species = await _readSpeciesAtRelativePath(workspace, relativePath);
      final entry = PokemonSpeciesIndexEntry.fromSpeciesFile(
        species,
        relativePath: relativePath,
      );
      final id = entry.id.trim();
      if (id.isEmpty) {
        throw EditorPersistenceException(
          'Pokemon species index file must define a non-empty id: '
          '$relativePath',
        );
      }
      final previous = entryById[id];
      if (previous != null) {
        final paths = <String>[previous.relativePath, relativePath]..sort();
        throw EditorConflictException(
          'Multiple Pokemon species files share the same id "$id": '
          '${paths.join(', ')}',
        );
      }
      entries.add(entry);
      entryById[id] = entry;
      speciesById[id] = species;
      speciesByRelativePath[p.normalize(relativePath)] = species;
    }
    try {
      return _PokemonSpeciesSnapshot(
        index: PokemonSpeciesIndex(entries),
        relativePaths: relativePaths,
        speciesById: speciesById,
        speciesByRelativePath: speciesByRelativePath,
      );
    } on StateError catch (error) {
      throw EditorPersistenceException(
        'Invalid Pokemon species index in $relativeDirectory: $error',
      );
    }
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

  Future<Directory> _speciesDirectory(ProjectWorkspace workspace) async {
    final speciesDirectory = await _speciesDirectoryRelativePath(workspace);
    return Directory(workspace.resolveProjectRelativePath(speciesDirectory));
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

  Future<String> _mediaDirectoryRelativePath(ProjectWorkspace workspace) async {
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
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) return null;
      final id = decoded['id'];
      if (id is! String || id.trim().isEmpty) return null;
      return id.trim();
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

class _PokemonSpeciesSnapshot {
  _PokemonSpeciesSnapshot({
    required this.index,
    required List<String> relativePaths,
    required Map<String, PokemonSpeciesFile> speciesById,
    required Map<String, PokemonSpeciesFile> speciesByRelativePath,
  })  : relativePaths = List<String>.unmodifiable(relativePaths),
        speciesById = Map<String, PokemonSpeciesFile>.unmodifiable(speciesById),
        speciesByRelativePath = Map<String, PokemonSpeciesFile>.unmodifiable(
          speciesByRelativePath,
        );

  final PokemonSpeciesIndex index;
  final List<String> relativePaths;
  final Map<String, PokemonSpeciesFile> speciesById;
  final Map<String, PokemonSpeciesFile> speciesByRelativePath;
}
