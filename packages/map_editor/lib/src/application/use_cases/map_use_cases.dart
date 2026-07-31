import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../domain/repositories/repositories.dart';
import '../../domain/models/map_document_persistence.dart';
import '../errors/application_errors.dart';
import '../authoring_api/authoring_mutation_adapter.dart';
import '../ports/project_workspace.dart';
import '../services/map_dependency_preflight_service.dart';
import '../services/map_lifecycle_transaction_service.dart';
import '../services/project_map_id_policy.dart';
import '../services/project_map_manifest_integrity_policy.dart';
import 'project_use_case_support.dart';

const ProjectMapIdPolicy _mapIdPolicy = ProjectMapIdPolicy();
const ProjectMapManifestIntegrityPolicy _mapManifestIntegrityPolicy =
    ProjectMapManifestIntegrityPolicy();

class SaveMapUseCase {
  final MapRepository _repo;
  final AuthoringMutationAdapter? _authoringMutations;

  SaveMapUseCase(
    this._repo, {
    AuthoringMutationAdapter? authoringMutations,
  }) : _authoringMutations = authoringMutations;

  Future<void> execute(
    MapData map,
    String path, {
    ProjectManifest? projectDialogueContext,
  }) async {
    _mapIdPolicy.requireValid(map.id);
    await _repo.saveMap(
      map,
      path,
      projectDialogueContext: projectDialogueContext,
    );
  }

  Future<String?> executeRevisioned(
    MapData map,
    String path, {
    required String? expectedRevision,
    ProjectManifest? projectDialogueContext,
  }) async {
    _mapIdPolicy.requireValid(map.id);
    final authoringMutations = _authoringMutations;
    if (authoringMutations != null) {
      if (expectedRevision == null) {
        throw const EditorConflictException(
          'Cette carte ne possède pas de révision disque attestée. '
          'Rechargez-la avant de l’enregistrer.',
        );
      }
      final result = await authoringMutations.saveMap(
        map,
        path,
        expectedMapRevision: expectedRevision,
      );
      return result.resourceRevision;
    }
    if (_repo case RevisionedMapRepository revisioned) {
      if (expectedRevision == null) {
        throw const EditorConflictException(
          'Cette carte ne possède pas de révision disque attestée. '
          'Rechargez-la avant de l’enregistrer.',
        );
      }
      final saved = await revisioned.saveMapDocument(
        map,
        path,
        precondition: MapDocumentWritePrecondition.revision(expectedRevision),
        projectDialogueContext: projectDialogueContext,
      );
      return saved.revision;
    }
    await _repo.saveMap(
      map,
      path,
      projectDialogueContext: projectDialogueContext,
    );
    return null;
  }
}

class CreateMapUseCase {
  final MapRepository _mapRepo;
  final ProjectRepository _projectRepo;
  final MapLifecycleTransactionCoordinator? _lifecycleTransactions;

  CreateMapUseCase(
    this._mapRepo,
    this._projectRepo, {
    MapLifecycleTransactionCoordinator? lifecycleTransactions,
  }) : _lifecycleTransactions = lifecycleTransactions;

  Future<MapData> execute(
      ProjectWorkspace fs, ProjectManifest project, String mapId, int w, int h,
      {String? groupId, MapRole role = MapRole.exterior}) async {
    final canonicalMapId = _mapIdPolicy.requireValid(mapId);
    _mapIdPolicy.requireAvailable(
      canonicalMapId,
      project.maps.map((entry) => entry.id),
    );
    _requireAvailableMapRelativePath(
      project,
      _canonicalMapRelativePath(canonicalMapId),
    );
    _mapManifestIntegrityPolicy.requireValid(fs, project);
    final defaultTilesetId = pickDefaultTilesetId(project, groupId);

    final map = MapData(
      id: canonicalMapId,
      name: canonicalMapId,
      size: GridSize(width: w, height: h),
      version: ProjectVersion.v4,
      visualStack: MapVisualStackConfig.canonicalV1,
      tilesetId: defaultTilesetId ?? '',
      layers: [
        MapLayer.tile(
          id: 'l_base',
          name: 'Base',
          tilesetId: defaultTilesetId,
          tiles: List.filled(w * h, 0),
        ),
        MapLayer.collision(
          id: 'l_collisions',
          name: 'Collisions',
          collisions: List.filled(w * h, false),
        ),
      ],
    );

    final mapPath = fs.getMapRelativePath(canonicalMapId);
    final absPath = fs.resolveMapPath(mapPath);
    if (await fs.fileExists(absPath)) {
      throw EditorConflictException(
        'A map file already exists at "$mapPath"',
      );
    }
    await fs.ensureDirectoryExists(absPath);

    final updatedProject = project.copyWith(maps: [
      ...project.maps,
      ProjectMapEntry(
        id: canonicalMapId,
        name: canonicalMapId,
        relativePath: mapPath,
        groupId: groupId,
        role: role,
      )
    ]);

    final lifecycleTransactions = _lifecycleTransactions;
    if (lifecycleTransactions != null) {
      await lifecycleTransactions.execute(
        MapLifecycleTransactionRequest.create(
          projectPath: fs.projectManifestPath,
          beforeProject: project,
          afterProject: updatedProject,
          targetPath: absPath,
          targetMap: map,
        ),
      );
      return map;
    }

    // Compatibility path for historical non-revisioned fakes. The product
    // composition root always injects DS-05; this fallback must never be
    // described as a recoverable multi-file transaction.
    final savedRevision = await _saveNewMapDocument(
      _mapRepo,
      map,
      absPath,
    );
    try {
      await _projectRepo.saveProject(updatedProject, fs.projectManifestPath);
    } catch (_) {
      try {
        await _deleteMapDocument(
          _mapRepo,
          absPath,
          revision: savedRevision,
        );
      } on Object {
        // Best-effort cleanup exists only for the compatibility path above.
      }
      rethrow;
    }

    return map;
  }
}

class LoadMapUseCase {
  final MapRepository _repo;

  LoadMapUseCase(this._repo);

  Future<MapData> execute(ProjectWorkspace fs, String relativePath) async {
    final document = await executeDocument(fs, relativePath);
    return document.map;
  }

  Future<LoadedMapDocumentResult> executeDocument(
    ProjectWorkspace fs,
    String relativePath, {
    bool refreshSnapshot = false,
  }) async {
    final path = fs.resolveMapPath(relativePath);
    return executeAbsolutePath(path, refreshSnapshot: refreshSnapshot);
  }

  Future<LoadedMapDocumentResult> executeAbsolutePath(
    String path, {
    bool refreshSnapshot = false,
  }) async {
    if (refreshSnapshot && _repo is RefreshableMapReadRepository) {
      await (_repo as RefreshableMapReadRepository)
          .refreshMapReadSnapshot(path);
    }
    final loaded = await _loadMapDocument(_repo, path);
    return (
      map: _migrateLegacyLayerTilesets(loaded.map),
      revision: loaded.revision,
    );
  }

  MapData _migrateLegacyLayerTilesets(MapData map) {
    final legacyTilesetId = map.tilesetId.trim();
    if (legacyTilesetId.isEmpty) return map;

    var changed = false;
    final updatedLayers = map.layers.map((layer) {
      if (layer is! TileLayer) return layer;
      final layerTilesetId = layer.tilesetId?.trim();
      if (layerTilesetId == null || layerTilesetId.isEmpty) {
        changed = true;
        return layer.copyWith(tilesetId: legacyTilesetId);
      }
      return layer;
    }).toList(growable: false);

    if (!changed) return map;
    return map.copyWith(layers: updatedLayers);
  }
}

typedef LoadedMapDocumentResult = ({MapData map, String? revision});

/// Safe application-layer result for map resize.
///
/// A null [map] means the pure impact plan or the Border preflight blocked the
/// operation before mutation. Callers can always present [plan] instead of
/// reverse-engineering a validation exception after data was truncated.
final class ResizeMapUseCaseResult {
  const ResizeMapUseCaseResult({
    required this.plan,
    required this.map,
    required this.diagnosticReport,
  });

  final MapResizePlan plan;
  final MapData? map;
  final BorderDiagnosticsReport diagnosticReport;

  bool get canApply =>
      plan.canApply && map != null && !diagnosticReport.hasErrors;
}

class ResizeMapUseCase {
  MapResizePlan plan(
    MapData map,
    int width,
    int height, {
    GridSize? tileSizePx,
    ProjectManifest? project,
  }) =>
      planMapResize(
        map,
        width: width,
        height: height,
        tileSizePx: tileSizePx,
        project: project,
      );

  ResizeMapUseCaseResult execute(
    MapData map,
    int width,
    int height, {
    required GridSize tileSizePx,
    ProjectManifest? project,
  }) {
    final impactPlan = plan(
      map,
      width,
      height,
      tileSizePx: tileSizePx,
      project: project,
    );
    if (!impactPlan.canApply) {
      return ResizeMapUseCaseResult(
        plan: impactPlan,
        map: null,
        diagnosticReport: impactPlan.borderDiagnostics,
      );
    }

    final result = resizeMapDataWithBorderDiagnostics(
      map,
      width: width,
      height: height,
      tileSizePx: tileSizePx,
    );
    final resized = result.map;
    if (resized != null) {
      MapValidator.validate(resized);
    }
    return ResizeMapUseCaseResult(
      plan: impactPlan,
      map: resized,
      diagnosticReport: result.diagnosticReport,
    );
  }
}

class UpdateMapMetadataUseCase {
  MapData execute(
    MapData map,
    MapMetadata metadata, {
    ProjectManifest? projectDialogueContext,
  }) {
    return updateMapMetadataOnMap(
      map,
      metadata,
      projectDialogueContext: projectDialogueContext,
    );
  }
}

class RenameMapUseCase {
  final MapRepository _mapRepo;
  final ProjectRepository _projectRepo;
  final MapDependencyPreflightService _dependencyPreflight;
  final MapLifecycleTransactionCoordinator? _lifecycleTransactions;

  RenameMapUseCase(
    this._mapRepo,
    this._projectRepo,
    this._dependencyPreflight, {
    MapLifecycleTransactionCoordinator? lifecycleTransactions,
  }) : _lifecycleTransactions = lifecycleTransactions;

  Future<ProjectManifest> execute(ProjectWorkspace fs, ProjectManifest project,
      String oldId, String newId) async {
    final result = await executeRevisioned(
      fs,
      project,
      oldId,
      newId,
    );
    return result.project;
  }

  Future<RenameMapResult> executeRevisioned(
    ProjectWorkspace fs,
    ProjectManifest project,
    String oldId,
    String newId,
  ) async {
    final canonicalNewId = _mapIdPolicy.requireValid(newId);
    final sourceEntry = _findMapEntry(project, oldId);
    if (oldId == canonicalNewId) {
      return (project: project, map: null, revision: null);
    }
    _mapIdPolicy.requireAvailable(
      canonicalNewId,
      project.maps.map((entry) => entry.id),
      excludingId: oldId,
    );
    final canonicalNewRelativePath = _canonicalMapRelativePath(canonicalNewId);
    _requireAvailableMapRelativePath(
      project,
      canonicalNewRelativePath,
      excludingId: oldId,
    );
    if (p.posix.normalize(sourceEntry.relativePath).toLowerCase() ==
        p.posix.normalize(canonicalNewRelativePath).toLowerCase()) {
      throw const EditorInvalidOperationException(
        'Case-equivalent legacy map renames require an explicit migration',
      );
    }
    _mapManifestIntegrityPolicy.requireValid(
      fs,
      project,
      allowedLegacyId: oldId,
    );
    await _dependencyPreflight.requireAllowed(
      workspace: fs,
      project: project,
      mapId: oldId,
      operation: MapDependencyPreflightOperation.rename,
    );

    // The manifest path is authoritative for legacy projects: a map file is
    // not required to have the same basename as its logical ID.
    final oldPath = fs.resolveMapPath(sourceEntry.relativePath);
    final newRelativePath = fs.getMapRelativePath(canonicalNewId);
    final newPath = fs.resolveMapPath(newRelativePath);
    if (oldPath.toLowerCase() == newPath.toLowerCase()) {
      throw const EditorInvalidOperationException(
        'Case-equivalent legacy map renames require an explicit migration',
      );
    }
    if (await fs.fileExists(newPath)) {
      throw EditorConflictException(
        'A map file already exists at "$newRelativePath"',
      );
    }

    final sourceDocument = await _loadMapDocument(_mapRepo, oldPath);
    final mapData = sourceDocument.map;
    _requireLoadedMapIdentity(mapData, sourceEntry);
    requireWritableMapVisualStackForLifecycle(mapData);
    final updatedMap = mapData.copyWith(
      id: canonicalNewId,
      name: canonicalNewId,
    );

    final updatedMaps = project.maps.map((entry) {
      if (entry.id == oldId) {
        return entry.copyWith(
          id: canonicalNewId,
          name: canonicalNewId,
          relativePath: newRelativePath,
        );
      }
      return entry;
    }).toList();

    final updatedProject = project.copyWith(maps: updatedMaps);
    final lifecycleTransactions = _lifecycleTransactions;
    if (lifecycleTransactions != null) {
      final sourceRevision = sourceDocument.revision;
      if (sourceRevision == null) {
        throw const EditorConflictException(
          'A transaction lifecycle requires the exact source revision.',
        );
      }
      final result = await lifecycleTransactions.execute(
        MapLifecycleTransactionRequest.rename(
          projectPath: fs.projectManifestPath,
          beforeProject: project,
          afterProject: updatedProject,
          sourcePath: oldPath,
          sourceRevision: sourceRevision,
          targetPath: newPath,
          targetMap: updatedMap,
        ),
      );
      return (
        project: result.project,
        map: result.targetMap,
        revision: result.targetRevision,
      );
    }

    // Compatibility-only path for direct legacy fakes. Production uses the
    // durable DS-05 coordinator injected by the composition root.
    final savedRevision = await _saveNewMapDocument(
      _mapRepo,
      updatedMap,
      newPath,
    );
    try {
      await _projectRepo.saveProject(updatedProject, fs.projectManifestPath);
    } catch (_) {
      try {
        await _deleteMapDocument(
          _mapRepo,
          newPath,
          revision: savedRevision,
        );
      } on Object {
        // Best-effort cleanup exists only for this legacy fallback.
      }
      rethrow;
    }
    // Once the manifest points at the new file, failing to clean the old file
    // may leave an orphan but must never delete the committed rename target.
    await _deleteMapDocument(
      _mapRepo,
      oldPath,
      revision: sourceDocument.revision,
    );
    return (
      project: updatedProject,
      map: updatedMap,
      revision: savedRevision,
    );
  }
}

typedef RenameMapResult = ({
  ProjectManifest project,
  MapData? map,
  String? revision,
});

class DeleteMapUseCase {
  final MapRepository _mapRepo;
  final ProjectRepository _projectRepo;
  final MapDependencyPreflightService _dependencyPreflight;
  final MapLifecycleTransactionCoordinator? _lifecycleTransactions;

  DeleteMapUseCase(
    this._mapRepo,
    this._projectRepo,
    this._dependencyPreflight, {
    MapLifecycleTransactionCoordinator? lifecycleTransactions,
  }) : _lifecycleTransactions = lifecycleTransactions;

  Future<ProjectManifest> execute(
      ProjectWorkspace fs, ProjectManifest project, String mapId) async {
    _mapIdPolicy.requireValid(mapId);
    final sourceEntry = _findMapEntry(project, mapId);
    _mapManifestIntegrityPolicy.requireValid(fs, project);
    await _dependencyPreflight.requireAllowed(
      workspace: fs,
      project: project,
      mapId: mapId,
      operation: MapDependencyPreflightOperation.delete,
    );
    final mapPath = fs.resolveMapPath(sourceEntry.relativePath);
    final sourceDocument = await _loadMapDocument(_mapRepo, mapPath);
    final mapData = sourceDocument.map;
    _requireLoadedMapIdentity(mapData, sourceEntry);
    requireWritableMapVisualStackForLifecycle(mapData);

    final updatedMaps =
        project.maps.where((entry) => entry.id != mapId).toList();
    final updatedProject = project.copyWith(maps: updatedMaps);
    final lifecycleTransactions = _lifecycleTransactions;
    if (lifecycleTransactions != null) {
      final sourceRevision = sourceDocument.revision;
      if (sourceRevision == null) {
        throw const EditorConflictException(
          'A transaction lifecycle requires the exact source revision.',
        );
      }
      final result = await lifecycleTransactions.execute(
        MapLifecycleTransactionRequest.delete(
          projectPath: fs.projectManifestPath,
          beforeProject: project,
          afterProject: updatedProject,
          sourcePath: mapPath,
          sourceRevision: sourceRevision,
        ),
      );
      return result.project;
    }

    // Compatibility-only fallback for non-revisioned test repositories.
    await _projectRepo.saveProject(updatedProject, fs.projectManifestPath);
    await _deleteMapDocument(
      _mapRepo,
      mapPath,
      revision: sourceDocument.revision,
    );

    return updatedProject;
  }
}

class DuplicateMapUseCase {
  final MapRepository _mapRepo;
  final ProjectRepository _projectRepo;
  final MapLifecycleTransactionCoordinator? _lifecycleTransactions;

  DuplicateMapUseCase(
    this._mapRepo,
    this._projectRepo, {
    MapLifecycleTransactionCoordinator? lifecycleTransactions,
  }) : _lifecycleTransactions = lifecycleTransactions;

  Future<ProjectManifest> execute(
      ProjectWorkspace fs, ProjectManifest project, String sourceId) async {
    final canonicalSourceId = _mapIdPolicy.requireValid(sourceId);
    final sourceEntry = _findMapEntry(project, canonicalSourceId);
    final targetId = _mapIdPolicy.nextCopyId(
      canonicalSourceId,
      project.maps.map((entry) => entry.id),
    );
    _requireAvailableMapRelativePath(
      project,
      _canonicalMapRelativePath(targetId),
    );
    _mapManifestIntegrityPolicy.requireValid(fs, project);

    final sourcePath = fs.resolveMapPath(sourceEntry.relativePath);
    final targetRelativePath = fs.getMapRelativePath(targetId);
    final targetPath = fs.resolveMapPath(targetRelativePath);
    if (await fs.fileExists(targetPath)) {
      throw EditorConflictException(
        'A map file already exists at "$targetRelativePath"',
      );
    }

    final sourceDocument = await _loadMapDocument(_mapRepo, sourcePath);
    final mapData = sourceDocument.map;
    _requireLoadedMapIdentity(mapData, sourceEntry);
    requireWritableMapVisualStackForLifecycle(mapData);
    final duplicatedMap = mapData.copyWith(id: targetId, name: targetId);
    final updatedProject = project.copyWith(maps: [
      ...project.maps,
      ProjectMapEntry(
        id: targetId,
        name: targetId,
        relativePath: targetRelativePath,
        groupId: sourceEntry.groupId,
        role: sourceEntry.role,
      )
    ]);
    final lifecycleTransactions = _lifecycleTransactions;
    if (lifecycleTransactions != null) {
      final sourceRevision = sourceDocument.revision;
      if (sourceRevision == null) {
        throw const EditorConflictException(
          'A transaction lifecycle requires the exact source revision.',
        );
      }
      final result = await lifecycleTransactions.execute(
        MapLifecycleTransactionRequest.duplicate(
          projectPath: fs.projectManifestPath,
          beforeProject: project,
          afterProject: updatedProject,
          sourcePath: sourcePath,
          sourceRevision: sourceRevision,
          targetPath: targetPath,
          targetMap: duplicatedMap,
        ),
      );
      return result.project;
    }

    // Compatibility-only path for historical non-revisioned fakes.
    final savedRevision = await _saveNewMapDocument(
      _mapRepo,
      duplicatedMap,
      targetPath,
    );
    try {
      await _projectRepo.saveProject(updatedProject, fs.projectManifestPath);
    } catch (_) {
      try {
        await _deleteMapDocument(
          _mapRepo,
          targetPath,
          revision: savedRevision,
        );
      } on Object {
        // Best-effort cleanup exists only for this legacy fallback.
      }
      rethrow;
    }

    return updatedProject;
  }
}

ProjectMapEntry _findMapEntry(ProjectManifest project, String mapId) {
  for (final entry in project.maps) {
    if (entry.id == mapId) {
      return entry;
    }
  }
  throw EditorNotFoundException('Map "$mapId" does not exist');
}

void _requireLoadedMapIdentity(
  MapData map,
  ProjectMapEntry manifestEntry,
) {
  if (map.id != manifestEntry.id) {
    throw EditorValidationException(
      'Loaded map ID "${map.id}" does not match manifest entry '
      '"${manifestEntry.id}"',
    );
  }
}

String _canonicalMapRelativePath(String mapId) {
  return p.posix.join('maps', '$mapId.json');
}

void _requireAvailableMapRelativePath(
  ProjectManifest project,
  String targetRelativePath, {
  String? excludingId,
}) {
  final normalizedTarget = p.posix.normalize(targetRelativePath).toLowerCase();
  for (final entry in project.maps) {
    if (entry.id == excludingId) continue;
    if (p.posix.normalize(entry.relativePath).toLowerCase() ==
        normalizedTarget) {
      throw EditorConflictException(
        'A map manifest entry already owns "$targetRelativePath"',
      );
    }
  }
}

typedef _LoadedMapDocument = ({MapData map, String? revision});

Future<_LoadedMapDocument> _loadMapDocument(
  MapRepository repository,
  String path,
) async {
  if (repository case RevisionedMapRepository revisioned) {
    final document = await revisioned.loadMapDocument(path);
    return (map: document.map, revision: document.revision);
  }
  return (map: await repository.loadMap(path), revision: null);
}

Future<String?> _saveNewMapDocument(
  MapRepository repository,
  MapData map,
  String path,
) async {
  if (repository case RevisionedMapRepository revisioned) {
    final document = await revisioned.saveMapDocument(
      map,
      path,
      precondition: const MapDocumentWritePrecondition.absent(),
    );
    return document.revision;
  }
  await repository.saveMap(map, path);
  return null;
}

Future<void> _deleteMapDocument(
  MapRepository repository,
  String path, {
  required String? revision,
}) {
  if (repository case RevisionedMapRepository revisioned) {
    if (revision == null) {
      throw const EditorConflictException(
        'A revisioned map cannot be deleted without its loaded revision.',
      );
    }
    return revisioned.deleteMapDocument(
      path,
      expectedRevision: revision,
    );
  }
  return repository.deleteMap(path);
}
