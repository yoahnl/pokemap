import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

export 'pokemon_file_write_repository.dart';

import '../../application/errors/application_errors.dart';
import '../../application/authoring_api/authoring_query_adapter.dart';
import '../../application/models/narrative_event_authoring_session.dart';
import '../../application/models/narrative_event_registry_persistence_models.dart';
import '../../application/models/pokemon_database_index.dart';
import '../../application/ports/narrative_event_registry_persistence_gateway.dart';
import '../../application/ports/pokemon_read_repository.dart';
import '../../application/ports/project_workspace.dart';
import '../../application/services/map_lifecycle_transaction_service.dart';
import '../../application/services/editor_performance_telemetry.dart';
import '../../application/services/pokemon_project_data_reader.dart';
import '../../domain/models/map_document_persistence.dart';
import '../../domain/repositories/repositories.dart';
import 'atomic_map_document_persistence.dart';
import 'atomic_project_manifest_persistence.dart';
import 'editor_persistence_codec_executor.dart';
import 'narrative_event_registry_persistence.dart';
import 'project_manifest_write_lock.dart';

typedef _ProjectFileState = ({bool exists, List<int>? bytes});

class FileProjectRepository
    implements ProjectRepository, NarrativeEventRegistryPersistenceGateway {
  FileProjectRepository({
    NarrativeEventRegistryPersistence? eventRegistryPersistence,
    AtomicProjectManifestPersistence? narrativeAuthoringPersistence,
    MapLifecycleTransactionCoordinator? mapLifecycleTransactions,
    AuthoringQueryAdapter? authoringQueries,
    EditorPersistenceCodecExecutor? codecExecutor,
  }) : _eventRegistryPersistence =
           eventRegistryPersistence ?? NarrativeEventRegistryPersistence(),
       _mapLifecycleTransactions = mapLifecycleTransactions,
       _authoringQueries = authoringQueries,
       _codecExecutor = codecExecutor ?? EditorPersistenceCodecExecutor() {
    _narrativeAuthoringPersistence =
        narrativeAuthoringPersistence ??
        AtomicProjectManifestPersistence(
          eventRegistryPersistence: _eventRegistryPersistence,
        );
  }

  final NarrativeEventRegistryPersistence _eventRegistryPersistence;
  final MapLifecycleTransactionCoordinator? _mapLifecycleTransactions;
  final AuthoringQueryAdapter? _authoringQueries;
  final EditorPersistenceCodecExecutor _codecExecutor;
  late final AtomicProjectManifestPersistence _narrativeAuthoringPersistence;

  AtomicProjectManifestPersistence get narrativeAuthoringPersistence =>
      _narrativeAuthoringPersistence;

  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) {
    return _eventRegistryPersistence.inspectProject(projectPath);
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) {
    return _eventRegistryPersistence.write(request);
  }

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) {
    return _eventRegistryPersistence.recoverProject(projectPath);
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) {
    return _eventRegistryPersistence.undo(undoPath);
  }

  Future<NarrativeEventRegistryPersistenceResult>
  persistNarrativeEventAuthoringResult({
    required NarrativeEventAuthoringSession session,
    required String operationId,
    required NarrativeEventAuthoringResult result,
  }) {
    return persist(
      NarrativeEventRegistryWriteRequest.fromAuthoringSession(
        session: session,
        operationId: operationId,
        result: result,
      ),
    );
  }

  Future<List<NarrativeEventRegistryPersistenceResult>>
  recoverNarrativeEventRegistryWrites(String path) {
    return recover(path);
  }

  Future<NarrativeEventRegistryPersistenceResult>
  undoNarrativeEventRegistryWrite(String undoPath) {
    return undo(undoPath);
  }

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    debugPrint('FileProjectRepository: Validating and saving project to $path');
    ProjectValidator.validate(project);
    final lifecycle = _mapLifecycleTransactions;
    if (lifecycle == null) {
      await _saveProjectWithLock(project, path);
      await _invalidateAuthoringSnapshot(path);
      return;
    }
    final expectedProjectState = await _captureProjectFileState(path);
    await lifecycle.runAfterRecovery(
      path,
      (canonicalProjectPath) => _saveProjectWithLock(
        project,
        canonicalProjectPath,
        expectedProjectState: expectedProjectState,
      ),
    );
    await _invalidateAuthoringSnapshot(path);
  }

  Future<void> _saveProjectWithLock(
    ProjectManifest project,
    String path, {
    _ProjectFileState? expectedProjectState,
  }) {
    return withProjectManifestWriteLock(path, () async {
      await _ensureRecoveryGateClear(path);
      _ProjectFileState? verifiedProjectState;
      if (expectedProjectState != null) {
        verifiedProjectState = await _requireProjectFileState(
          path,
          expectedProjectState,
        );
      }
      return _saveProjectLocked(
        project,
        path,
        verifiedProjectState: verifiedProjectState,
      );
    });
  }

  Future<_ProjectFileState> _captureProjectFileState(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      return (exists: false, bytes: null);
    }
    return (exists: true, bytes: await file.readAsBytes());
  }

  Future<_ProjectFileState> _requireProjectFileState(
    String path,
    _ProjectFileState expected,
  ) async {
    final current = await _captureProjectFileState(path);
    final bytesMatch =
        !expected.exists ||
        (current.exists &&
            await _codecExecutor.projectBytesMatch(
              expected.bytes!,
              current.bytes!,
            ));
    if (current.exists != expected.exists || !bytesMatch) {
      throw const EditorConflictException(
        'The project changed while the generic save waited for map lifecycle '
        'recovery.',
      );
    }
    return current;
  }

  Future<void> _saveProjectLocked(
    ProjectManifest project,
    String path, {
    _ProjectFileState? verifiedProjectState,
  }) async {
    final file = File(path);
    if (!await file.parent.exists()) await file.parent.create(recursive: true);
    final projectExists = verifiedProjectState?.exists ?? await file.exists();
    if (!projectExists) {
      await file.writeAsBytes(
        await _codecExecutor.encodeNewProject(project),
        flush: true,
      );
      return;
    }
    final beforeBytes = verifiedProjectState?.bytes ?? await file.readAsBytes();
    late final EditorPreparedProjectUpdate preparedUpdate;
    try {
      preparedUpdate = await _codecExecutor.prepareExistingProjectUpdate(
        currentBytes: beforeBytes,
        project: project,
      );
    } on EditorPersistenceCodecException catch (error) {
      switch (error.kind) {
        case EditorPersistenceCodecFailureKind.currentProjectInvalid:
          throw EditorPersistenceException(
            'Current project cannot be preserved safely: ${error.message}',
          );
        case EditorPersistenceCodecFailureKind.eventRegistryReadOnly:
          throw EditorPersistenceException(
            'Current Event registry is read-only: ${error.message}',
          );
        case EditorPersistenceCodecFailureKind.eventRegistryConflict:
          throw const EditorConflictException(
            'The Event registry changed outside the generic project save.',
          );
        case EditorPersistenceCodecFailureKind.updatedProjectInvalid:
          throw EditorPersistenceException(
            'Updated project cannot be encoded safely: ${error.message}',
          );
      }
    } on Object catch (error) {
      throw EditorPersistenceException(
        'Updated project cannot be encoded safely: $error',
      );
    }
    final liveBytes = await file.readAsBytes();
    if (!await _codecExecutor.projectBytesMatch(beforeBytes, liveBytes)) {
      throw const EditorConflictException(
        'The project changed during the generic save.',
      );
    }
    await file.writeAsBytes(preparedUpdate.bytes, flush: true);
  }

  @override
  Future<ProjectManifest> loadProject(String path) async {
    debugPrint('FileProjectRepository: Loading project from $path');
    final lifecycle = _mapLifecycleTransactions;
    if (lifecycle == null) return _loadProjectWithLock(path);
    return lifecycle.runAfterRecovery(path, _loadProjectWithLock);
  }

  Future<ProjectManifest> _loadProjectWithLock(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw const ProjectLoadException('Project file not found');
    }
    return withProjectManifestWriteLock(path, () async {
      await _ensureRecoveryGateClear(path);
      try {
        final authoringQueries = _authoringQueries;
        if (authoringQueries != null) {
          return (await authoringQueries.open(p.dirname(path))).manifest;
        }
        return await _codecExecutor.decodeValidatedProject(
          await file.readAsBytes(),
        );
      } catch (e) {
        throw ProjectLoadException('Failed to load project: $e');
      }
    });
  }

  Future<void> _invalidateAuthoringSnapshot(String manifestPath) async {
    final authoringQueries = _authoringQueries;
    if (authoringQueries == null) return;
    await authoringQueries.invalidate(p.dirname(manifestPath));
  }

  Future<void> _ensureRecoveryGateClear(String path) async {
    final inspection = await _eventRegistryPersistence
        .inspectProjectAlreadyLocked(path);
    if (inspection.status ==
        NarrativeEventRegistryRecoveryGateStatus.recoveryRequired) {
      final issue = inspection.issues.first;
      throw ProjectRecoveryRequiredException(
        _recoveryGateMessage(
          'Une écriture d’événements interrompue doit être récupérée avant '
          'd’ouvrir ou d’enregistrer ce projet.',
          issue,
        ),
        code: issue.code,
        path: issue.path,
      );
    }
    if (inspection.status ==
        NarrativeEventRegistryRecoveryGateStatus.recoveryBlocked) {
      final issue = inspection.issues.first;
      throw ProjectRecoveryBlockedException(
        _recoveryGateMessage(
          'Une écriture d’événements interrompue est bloquée et doit être '
          'inspectée avant d’ouvrir ou d’enregistrer ce projet.',
          issue,
        ),
        code: issue.code,
        path: issue.path,
      );
    }
  }
}

String _recoveryGateMessage(
  String summary,
  NarrativeEventRegistryRecoveryIssue issue,
) {
  final path = issue.path == null ? '' : ' Fichier: ${issue.path}.';
  return '$summary Cause: ${issue.code}. ${issue.message}$path';
}

class FileMapRepository
    implements
        RevisionedMapRepository,
        RefreshableMapReadRepository,
        DurableMapDocumentRepository {
  FileMapRepository({
    AtomicMapDocumentPersistence? mapPersistence,
    AuthoringQueryAdapter? authoringQueries,
  }) : _mapPersistence = mapPersistence ?? const AtomicMapDocumentPersistence(),
       _authoringQueries = authoringQueries;

  final AtomicMapDocumentPersistence _mapPersistence;
  final AuthoringQueryAdapter? _authoringQueries;

  @override
  Future<void> saveMap(
    MapData map,
    String path, {
    ProjectManifest? projectDialogueContext,
  }) async {
    debugPrint('FileMapRepository: Validating and saving map to $path');
    _requireSupportedVisualStackForWrite(map);
    EditorPerformanceTelemetry.validateFullMap(
      map,
      projectDialogueContext: projectDialogueContext,
    );
    await _mapPersistence.replaceLatest(path, encodeMapDocumentBytes(map));
    await _invalidateAuthoringSnapshotForResource(path);
  }

  @override
  Future<RevisionedMapDocument> saveMapDocument(
    MapData map,
    String path, {
    required MapDocumentWritePrecondition precondition,
    ProjectManifest? projectDialogueContext,
  }) async {
    debugPrint('FileMapRepository: CAS saving map to $path');
    _requireSupportedVisualStackForWrite(map);
    EditorPerformanceTelemetry.validateFullMap(
      map,
      projectDialogueContext: projectDialogueContext,
    );
    final revision = await _mapPersistence.write(
      path,
      encodeMapDocumentBytes(map),
      precondition: precondition,
    );
    await _invalidateAuthoringSnapshotForResource(path);
    // A map lifecycle transaction writes the target document before updating
    // project.json. Reading through the project snapshot here would reject a
    // freshly created/renamed map because it is not declared *yet*. Verify the
    // exact durable bytes directly at this persistence boundary instead.
    final durable = await _loadMapDocumentFromPersistence(path);
    if (durable.revision != revision || durable.map != map) {
      throw const EditorPersistenceException(
        'The durable map does not match the requested document.',
      );
    }
    return durable;
  }

  @override
  Future<MapData> loadMap(String path) async {
    return (await loadMapDocument(path)).map;
  }

  @override
  Future<RevisionedMapDocument> loadMapDocument(String path) async {
    debugPrint('FileMapRepository: Loading map from $path');
    final authoringQueries = _authoringQueries;
    if (authoringQueries != null) {
      try {
        final projectRoot = await _findProjectRootForResource(path);
        final session = await authoringQueries.open(projectRoot);
        final storageKey = p
            .relative(path, from: projectRoot)
            .replaceAll(Platform.pathSeparator, '/');
        final map = session.mapByStorageKey(storageKey);
        if (map == null) {
          throw const MapLoadException(
            'Map file is not declared by the Authoring snapshot',
          );
        }
        final revision = session.resourceRevision('map:${map.id}');
        if (revision == null) {
          throw const MapLoadException(
            'Map revision is missing from the Authoring snapshot',
          );
        }
        return RevisionedMapDocument(map: map, revision: revision);
      } on MapLoadException {
        rethrow;
      } on Object catch (error) {
        throw MapLoadException('Failed to load map: $error');
      }
    }
    return _loadMapDocumentFromPersistence(path);
  }

  Future<RevisionedMapDocument> _loadMapDocumentFromPersistence(
    String path,
  ) async {
    late final AtomicMapDocumentBytes snapshot;
    try {
      snapshot = await _mapPersistence.read(path);
    } on EditorNotFoundException catch (error) {
      throw MapLoadException(error.message);
    }
    try {
      return RevisionedMapDocument(
        map: decodeValidatedNarrativeEventAuthoringMap(
          snapshot.bytes,
          path,
          validateMap: EditorPerformanceTelemetry.validateFullMap,
        ),
        revision: snapshot.revision,
      );
    } catch (e) {
      throw MapLoadException('Failed to load map: $e');
    }
  }

  @override
  Future<RevisionedMapDocument> loadDurableMapDocument(String path) {
    return _loadMapDocumentFromPersistence(path);
  }

  @override
  Future<void> refreshMapReadSnapshot(String path) async {
    await _invalidateAuthoringSnapshotForResource(path);
  }

  @override
  Future<void> deleteMap(String path) async {
    debugPrint('FileMapRepository: Deleting map at $path');
    await _mapPersistence.deleteLatest(path);
    await _invalidateAuthoringSnapshotForResource(path);
  }

  @override
  Future<void> deleteMapDocument(
    String path, {
    required String expectedRevision,
  }) {
    debugPrint('FileMapRepository: CAS deleting map at $path');
    return _deleteMapDocumentAndInvalidate(
      path,
      expectedRevision: expectedRevision,
    );
  }

  Future<void> _deleteMapDocumentAndInvalidate(
    String path, {
    required String expectedRevision,
  }) async {
    await _mapPersistence.delete(path, expectedRevision: expectedRevision);
    await _invalidateAuthoringSnapshotForResource(path);
  }

  @override
  Future<MapDocumentRecoveryResult> recoverMapDocument(String path) {
    return _mapPersistence.recover(path);
  }

  @override
  Future<void> renameMap(String oldPath, String newPath) async {
    debugPrint('FileMapRepository: Renaming map from $oldPath to $newPath');
    final file = File(oldPath);
    if (await file.exists()) {
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }
      await file.rename(newPath);
      await _invalidateAuthoringSnapshotForResource(oldPath);
    }
  }

  Future<void> _invalidateAuthoringSnapshotForResource(String path) async {
    final authoringQueries = _authoringQueries;
    if (authoringQueries == null) return;
    final projectRoot = await _findProjectRootForResource(path);
    await authoringQueries.invalidate(projectRoot);
  }
}

Future<String> _findProjectRootForResource(String resourcePath) async {
  var directory = File(resourcePath).absolute.parent;
  while (true) {
    if (await File(p.join(directory.path, 'project.json')).exists()) {
      return directory.path;
    }
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw const MapLoadException(
        'Map resource is not inside a PokeMap project',
      );
    }
    directory = parent;
  }
}

void _requireSupportedVisualStackForWrite(MapData map) {
  final composition = buildMapVisualCompositionPlan(map);
  if (composition.canCompose) {
    return;
  }
  final semanticsVersion = map.visualStack?.semanticsVersion;
  throw ValidationException(
    'visualStack semanticsVersion $semanticsVersion is not supported for '
    'writes',
  );
}

class FileTilesetRepository implements TilesetRepository {
  @override
  Future<void> saveTileset(TilesetConfig tileset, String path) async {
    final file = File(path);
    if (!await file.parent.exists()) await file.parent.create(recursive: true);
    final json = tileset.toJson();
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
  }

  @override
  Future<TilesetConfig> loadTileset(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw const AssetNotFoundException('Tileset file not found');
    }
    final content = await file.readAsString();
    try {
      final json = jsonDecode(content) as Map<String, dynamic>;
      return TilesetConfig.fromJson(json);
    } catch (e) {
      throw const ValidationException('Failed to load tileset');
    }
  }
}

/// Implémentation filesystem/workspace de la lecture locale Pokémon.
///
/// Cette classe sert de frontière infrastructurelle pour les use cases :
/// la mécanique JSON concrète reste déléguée au lecteur local existant.
class FilePokemonReadRepository
    implements PokemonReadRepository, PokemonSpeciesSnapshotController {
  FilePokemonReadRepository({PokemonProjectDataReader? reader})
    : reader = reader ?? PokemonProjectDataReader();

  final PokemonProjectDataReader reader;

  @override
  Future<PokemonDataManifest> readManifest(ProjectWorkspace workspace) {
    return reader.readManifest(workspace);
  }

  @override
  Future<PokemonCatalogFile> readCatalogByKey(
    ProjectWorkspace workspace,
    String catalogKey,
  ) {
    return reader.readCatalogByKey(workspace, catalogKey);
  }

  @override
  Future<List<PokemonSpeciesIndexEntry>> listSpeciesIndexEntries(
    ProjectWorkspace workspace,
  ) {
    return reader.listSpeciesIndexEntries(workspace);
  }

  @override
  Future<List<PokemonDatabaseIndexEntry>> listDatabaseIndexEntries(
    ProjectWorkspace workspace, {
    required String speciesDirectoryRelativePath,
  }) {
    return reader.listDatabaseIndexEntries(
      workspace,
      speciesDirectoryRelativePath: speciesDirectoryRelativePath,
    );
  }

  @override
  Future<List<String>> listSpeciesFiles(ProjectWorkspace workspace) {
    return reader.listSpeciesFiles(workspace);
  }

  @override
  Future<PokemonSpeciesFile> readSpeciesByRelativePath(
    ProjectWorkspace workspace,
    String relativePath,
  ) {
    return reader.readSpeciesByRelativePath(workspace, relativePath);
  }

  @override
  Future<PokemonSpeciesFile> readSpeciesById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    return reader.readSpeciesById(workspace, speciesId);
  }

  @override
  Future<String?> resolveSpeciesRelativePathById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    return reader.resolveSpeciesRelativePathById(workspace, speciesId);
  }

  @override
  void invalidateSpeciesSnapshot(ProjectWorkspace workspace) {
    reader.invalidateSpeciesSnapshot(workspace);
  }

  @override
  Future<PokemonLearnsetFile> readLearnsetById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    return reader.readLearnsetById(workspace, speciesId);
  }

  @override
  Future<List<String>> listLearnsetIds(ProjectWorkspace workspace) {
    return reader.listLearnsetIds(workspace);
  }

  @override
  Future<PokemonEvolutionFile> readEvolutionById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    return reader.readEvolutionById(workspace, speciesId);
  }

  @override
  Future<List<String>> listEvolutionIds(ProjectWorkspace workspace) {
    return reader.listEvolutionIds(workspace);
  }

  @override
  Future<PokemonMediaFile> readMediaById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    return reader.readMediaById(workspace, speciesId);
  }

  @override
  Future<List<String>> listMediaIds(ProjectWorkspace workspace) {
    return reader.listMediaIds(workspace);
  }
}

/// Implémentation filesystem/workspace de l'écriture locale Pokémon.
///
/// Cette classe écrit uniquement les JSON déjà stabilisés à ce stade :
/// - catalogues globaux
/// - espèces
/// - learnsets
/// - évolutions
///
/// Elle ne touche jamais à `project.json` et n'écrit jamais hors du workspace.
