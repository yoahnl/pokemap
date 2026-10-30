import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:map_authoring/map_authoring.dart'
    show AssetRecord, assetBlobStorageKey, probeProjectAudioSourceBytes;
import 'package:map_authoring/map_authoring_documents.dart';
import 'package:map_authoring/map_authoring_local.dart';

import '../domain/map_atmosphere_port.dart';
import '../domain/map_exterior_decoration_port.dart';
import '../../project_visuals/domain/project_visuals_port.dart';
import '../domain/map_editor_port.dart';
import '../domain/spatial_field_obstacle_port.dart';
import '../domain/field_traversal_zone_port.dart';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_catalog_port.dart';
import 'package:avelune_studio/features/map_workspace/data/map_document_retention.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';

import '../../project_session/data/studio_project_document_revision.dart';
import '../../project_session/data/local_workshop_reader.dart';
import '../../project_surf/domain/project_surf_port.dart';
import '../../project_cs/domain/project_cs_port.dart';
import '../../project_audio/domain/project_audio_port.dart';

part 'local_map_atmosphere_adapter.dart';
part 'local_map_exterior_decoration_adapter.dart';
part 'local_project_visuals_adapter.dart';
part 'local_project_surf_adapter.dart';
part 'local_project_cs_adapter.dart';
part 'local_project_audio_adapter.dart';
part 'local_project_settings_mutation.dart';
part 'local_map_editor_adapter.dart';
part 'local_spatial_field_obstacle_adapter.dart';
part 'local_field_traversal_zone_adapter.dart';
part 'local_map_workspace_catalog.dart';
part 'local_map_workspace_working_catalog.dart';
part 'local_map_workspace_scoped_catalog.dart';

final class LocalMapWorkspaceAdapter
    implements
        MapWorkspacePort,
        MapWorkspacePreviewSelectionPort,
        MapWorkspaceExternalMutationPort,
        MapWorkspaceWorkshopPort,
        MapWorkspaceResourceKindPort,
        MapWorkspaceModelLightPort,
        MapAtmospherePort,
        MapExteriorDecorationPort,
        ProjectVisualsPort,
        ProjectSurfPort,
        ProjectCsPort,
        ProjectAudioPort,
        MapEditorPort,
        MapElementOrderPort,
        SpatialFieldObstaclePort,
        FieldTraversalZonePort {
  @override
  Future<FieldTraversalZoneReceipt> publishFieldTraversalZone(ProjectSession session, MapWorkspaceDocument base, String actionId, Map<String, Object?> parameters) => withResourceMutation(() => _publishFieldTraversalZone(session, base, actionId, parameters));
  @override
  Future<FieldTraversalZoneReceipt> restoreFieldTraversalZone(ProjectSession session, MapWorkspaceDocument base, FieldTraversalZoneReceipt receipt, {required bool redo}) => withResourceMutation(() => _publishFieldTraversalZone(session, base, receipt.actionId, receipt.parameters, undo: receipt, redo: redo));
  @override
  Future<SpatialFieldObstacleReceipt> configureSpatialFieldObstacle(ProjectSession session, MapWorkspaceDocument base, String instanceId, MapEntityFieldObstacleData? fieldObstacle) => withResourceMutation(() => _configureSpatialFieldObstacle(session, base, instanceId, fieldObstacle));
  @override
  Future<SpatialFieldObstacleReceipt> undoSpatialFieldObstacle(ProjectSession session, MapWorkspaceDocument base, SpatialFieldObstacleReceipt receipt, {required bool redo}) => withResourceMutation(() => _mutateSpatialFieldObstacle(session, base, undo: receipt, redo: redo));
  LocalMapWorkspaceAdapter({
    ProjectFileReader? reader,
    AtomicMapDocumentPersistence? persistence,
    this.onMapMetadataEntryRead,
    this.onMapMetadataNodeCopied,
  }) : _reader = reader ?? const LocalProjectFileReader(),
       _persistence = persistence ?? const AtomicMapDocumentPersistence();

  @override
  Future<ProjectAudioState> loadAudio(ProjectSession session) => _loadAudio(session);
  @override
  Future<ProjectAudioState> saveAudioCue(ProjectSession session, ProjectSoundCue cue, ProjectSoundBinding? binding, String expectedRevision) => withResourceMutation(() => _saveAudioCue(session, cue, binding, expectedRevision));
  @override
  Future<ProjectAudioPage> queryAudio(ProjectSession session, {String query = '', String? cursor}) => _queryAudio(session, query: query, cursor: cursor);
  @override
  Future<ProjectAudioImport> importAudio(ProjectSession session, String sourcePath, String label, String expectedRevision) => withResourceMutation(() => _importAudio(session, sourcePath, label, expectedRevision));
  @override
  Future<ProjectAudioFile> resolveAudio(ProjectSession session, String mediaId) => _resolveAudio(session, mediaId);
  @override
  Future<ProjectAudioPage> queryLegacyAudio(ProjectSession session, {String query = '', String? cursor}) => _queryLegacyAudio(session, query: query, cursor: cursor);
  @override
  Future<ProjectAudioImport> adoptAudioAsset(ProjectSession session, String assetId, String mediaId, String label, String expectedRevision) => withResourceMutation(() => _adoptAudioAsset(session, assetId, mediaId, label, expectedRevision));
  var _settingsOperations = 0;
  @override
  Future<ProjectCsState> loadFieldAbilities(ProjectSession session) => _loadFieldAbilities(session);
  @override
  Future<ProjectCsState> saveFieldAbility(ProjectSession session, FieldAbility ability, bool enabled, String expectedRevision) => saveFieldAbilityId(session, ability.moveId, enabled, expectedRevision);
  @override
  Future<ProjectCsState> saveFieldAbilityId(ProjectSession session, String abilityId, bool enabled, String expectedRevision) => withResourceMutation(() => _saveFieldAbilityId(session, abilityId, enabled, expectedRevision));
  var _surfOperations = 0;
  @override
  Future<ProjectSurfState> loadSurf(ProjectSession session) => _loadSurf(session);
  @override
  Future<ProjectSurfState> saveSurf(ProjectSession session, ProjectSurfSettings? configuration, String expectedRevision) => withResourceMutation(() => _saveSurf(session, configuration, expectedRevision));
  @override
  Future<ProjectSurfReferences> loadSurfReferences(ProjectSession session) => _loadSurfReferences(session);
  @override
  Future<NarrativeFactDefinition> loadSurfFact(ProjectSession session, String id) => _loadSurfFact(session, id);

  final _visualServices = <String, Future<LocalVisualSettingsAuthoring>>{};
  var _visualOperations = 0;
  @override
  Future<ProjectVisualsState> loadVisuals(ProjectSession session, {ProjectMapEntry? map}) => _loadVisuals(session, map);
  @override
  Future<ProjectVisualsState> saveVisuals(ProjectSession session, SpatialVisualPatch profile, String expectedRevision, {ProjectMapEntry? map}) => _saveVisuals(session, profile, expectedRevision, map);
  @override
  Future<ProjectVisualsState> undoVisuals(ProjectSession session, String receiptId, String expectedRevision, {ProjectMapEntry? map}) => _undoVisuals(session, receiptId, expectedRevision, map);

  @override
  Future<MapWorkspaceCatalog> loadResourceKind(
    ProjectSession session,
    String canonicalKind,
  ) => _loadResourceKind(session, canonicalKind);

  @override
  Future<void> acceptModelLight(ProjectSession session, ProjectModel3dEntry model,
      String beforeRevision, String afterRevision) async {
    final current = _projects[session.sessionId];
    if (current == null) return;
    if ((current.revision != beforeRevision && current.revision != afterRevision) ||
        await resourceRevision(session) != afterRevision) {
      throw const MapWorkspaceFailure(MapWorkspaceProblem.conflict,
          'La lumière est enregistrée, mais le catalogue ouvert a changé.');
    }
    ProjectManifest update(ProjectManifest value) {
      final entries = value.models3d;
      if (entries is! ProjectModel3dEntries) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.invalidDocument,
          'Rechargez le catalogue des modèles avant de régler sa lumière.',
        );
      }
      final item = entries.lookup(model.id);
      if (item == null) return value;
      return value.copyWith(models3d: entries.replaceSelected([
        item.copyWith(light: model.light, clearLight: model.light == null),
      ]));
    }
    final manifest = update(current.manifest);
    final projections = [
      for (final cache in [_resourceSelections, _activeMapDefinitions, _workshopCharacterDefinitions])
        if (cache[session.sessionId] case final value?)
          (cache: cache, manifest: update(value)),
    ];
    _projects[session.sessionId] = _ProjectDocument(current.root,
        manifest, afterRevision,
        complete: current.complete, metadataFields: current.metadataFields);
    for (final projection in projections) {
      projection.cache[session.sessionId] = projection.manifest;
    }
  }

  final void Function()? onMapMetadataEntryRead;
  final void Function()? onMapMetadataNodeCopied;
  final ProjectFileReader _reader;
  final AtomicMapDocumentPersistence _persistence;
  final _projects = <String, _ProjectDocument>{};
  final _resourceSelections = <String, ProjectManifest>{};
  final _activeMapDefinitions = <String, ProjectManifest>{};
  final _workshopCharacterDefinitions = <String, ProjectManifest>{};
  final _loadedPaths = <(String, String), String>{};
  Future<void> _writes = Future.value();
  @override Future<MapExteriorDecorationWrite> saveExteriorDecorationBorder(ProjectSession session,String mapId,ExteriorDecorationBorder border,String expectedRevision)=>_saveExteriorDecorationBorder(session,mapId,border,expectedRevision);
  @override Future<MapExteriorDecorationWrite> removeExteriorDecorationBorder(ProjectSession session,String mapId,String borderId,String expectedRevision)=>_removeExteriorDecorationBorder(session,mapId,borderId,expectedRevision);
  @override Future<MapExteriorDecorationWrite> saveExteriorDecorationSectors(ProjectSession session,String mapId,List<ExteriorDecorationSector> sectors,List<String> removeSectorIds,String expectedRevision)=>_saveExteriorDecorationSectors(session,mapId,sectors,removeSectorIds,expectedRevision);
  final _exteriorServices = <String, Future<LocalMapExteriorDecorationAuthoring>>{};
  var _exteriorOperations = 0;
  @override Future<MapExteriorDecorationState> loadExteriorDecoration(ProjectSession session,String mapId) => _loadExteriorDecoration(session,mapId);
  @override Future<MapExteriorDecorationWrite> configureExteriorDecoration(ProjectSession session,String mapId,MapExteriorDecoration? definition,String expectedRevision) => _configureExteriorDecoration(session,mapId,definition,expectedRevision);
  @override Future<MapExteriorDecorationWrite> saveExteriorDecorationSector(ProjectSession session,String mapId,ExteriorDecorationSector sector,String expectedRevision) => _saveExteriorDecorationSector(session,mapId,sector,expectedRevision);
  @override Future<MapExteriorDecorationWrite> removeExteriorDecorationSector(ProjectSession session,String mapId,String sectorId,String expectedRevision) => _removeExteriorDecorationSector(session,mapId,sectorId,expectedRevision);
  final _atmosphereServices = <String, Future<LocalMapAtmosphereAuthoring>>{};
  final _editorServices = <String, Future<LocalMapEditorAuthoring>>{};
  final _elementOrderServices = <String, Future<LocalMapElementOrderAuthoring>>{};
  var _editorOperations = 0;
  var _atmosphereOperations = 0;

  @override
  Future<MapEditorWorkspaceState> loadEditorState(
    ProjectSession session,
    String mapId,
  ) => _loadEditorState(session, mapId);

  @override
  Future<MapEditorWorkspaceState> saveEditorState(
    ProjectSession session,
    String mapId,
    MapEditorState state,
    String expectedRevision,
  ) => _saveEditorState(session, mapId, state, expectedRevision);

  @override
  Future<MapElementOrderWorkspaceReceipt> reorderMapElements(ProjectSession session, MapWorkspaceDocument base, String kind, List<String> frontFirstIds, String? layerId) => _reorderMapElements(session, base, kind, frontFirstIds, layerId);

  @override
  Future<MapElementOrderWorkspaceReceipt> undoMapElementOrder(ProjectSession session, MapWorkspaceDocument base, MapElementOrderWorkspaceReceipt receipt) => _undoMapElementOrder(session, base, receipt);

  @override
  Future<MapAtmosphereState> loadAtmosphere(
    ProjectSession session,
    String mapId,
  ) async {
    final service = await _atmosphereAuthoring(session);
    final state = await service.inspect(
      projectRoot: session.directoryPath,
      mapId: mapId,
      mapRelativePath: p.relative(
        _loadedPaths[(session.sessionId, mapId)] ??
            (throw const MapWorkspaceFailure(
              MapWorkspaceProblem.unavailable,
              'Ouvrez la carte avant de régler son ambiance.',
            )),
        from: session.directoryPath,
      ),
    );
    return MapAtmosphereState(
      settings: state.settings,
      revision: state.revision,
    );
  }

  @override
  Future<MapAtmosphereState> saveAtmosphere(
    ProjectSession session,
    String mapId,
    SpatialAtmosphereSettings settings,
    String expectedRevision,
  ) async {
    if (session.storage == ProjectSessionStorage.portableCatalog) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.unavailable,
        'Ce projet est en lecture seule. Créez une copie de travail pour régler son ambiance.',
      );
    }
    final service = await _atmosphereAuthoring(session);
    final result = await service.set(
      projectRoot: session.directoryPath,
      mapId: mapId,
      mapRelativePath: p.relative(
        _loadedPaths[(session.sessionId, mapId)] ??
            (throw const MapWorkspaceFailure(
              MapWorkspaceProblem.unavailable,
              'Ouvrez la carte avant de régler son ambiance.',
            )),
        from: session.directoryPath,
      ),
      settings: settings,
      expectedRevision: expectedRevision,
      operationId:
          'studio_atmosphere_${DateTime.now().microsecondsSinceEpoch}_${_atmosphereOperations++}',
    );
    return MapAtmosphereState(
      settings: result.afterSettings,
      revision: result.afterRevision,
    );
  }

  Future<T> withResourceMutation<T>(Future<T> Function() operation) {
    final result = _writes.then((_) => operation());
    _writes = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<({ProjectManifest manifest, String revision})> resourceBaseline(
    ProjectSession session, {
    bool refreshCatalog = false,
  }) async {
    var project = _project(session);
    await _requireRoot(session);
    if (refreshCatalog) {
      project = await _refreshCatalog(session, project);
    }
    await _requireProjectRevision(session, project);
    return (manifest: project.manifest, revision: project.revision);
  }

  Future<String> resourceRevision(ProjectSession session) async {
    final descriptor = await _reader.readBytes(
      projectRoot: session.directoryPath,
      relativePath: 'project.json',
    );
    final head = session.storage == ProjectSessionStorage.workingCatalog
        ? await _reader.readBytes(
            projectRoot: session.directoryPath,
            relativePath: CatalogStorageStore.headStorageKey,
          )
        : null;
    return studioProjectDocumentRevision(
      descriptorBytes: descriptor,
      headBytes: head,
    );
  }

  @override
  Future<String?> readExternalMapRevision(
    ProjectSession session,
    String mapId,
  ) async {
    final entries = _project(session).manifest.maps as ProjectMapEntries;
    final entry = entries.lookup(mapId);
    if (entry == null) return null;
    await _mapPath(session, entry);
    final bytes = await _reader.readBytes(
      projectRoot: session.directoryPath,
      relativePath: entry.relativePath,
    );
    return narrativeEventBytesFingerprint(bytes);
  }

  @override
  Future<MapWorkspaceCatalog> refreshExternalBaseline(
    ProjectSession session, {
    required Set<({String kind, String id})> resources,
  }) => withResourceMutation(() async {
    final current = _project(session);
    await _requireRoot(session);
    if (resources.any(
      (resource) => const {
        'model3d',
        'tileset',
        'element',
        'character',
        'environmentPreset',
        'smartTilePreset',
        'smartTileMaterial',
        'smartTilePattern',
        'smartTileAtlas',
        'smartTileAnimation',
        'borderBlueprint',
        'borderRecord',
      }.contains(resource.kind),
    )) {
      _resourceSelections.remove(session.sessionId);
    }
    if (resources.any((resource) => resource.kind == 'character')) {
      _workshopCharacterDefinitions.remove(session.sessionId);
    }
    final projectChanged = resources.any(
      (resource) => resource.kind == 'project',
    );
    final settingsChanged = resources.any(
      (resource) => resource.kind == 'projectSettings',
    );
    final mapIds = {
      for (final resource in resources)
        if (resource.kind == 'map' || resource.kind == 'mapMetadata')
          resource.id,
    };
    final metadataChanged =
        projectChanged || settingsChanged || mapIds.isNotEmpty;
    if (metadataChanged && session.storage == ProjectSessionStorage.manifest) {
      final bytes = await _reader.readBytes(
        projectRoot: session.directoryPath,
        relativePath: 'project.json',
      );
      final manifest = ProjectManifest.fromJson(
        Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map),
      );
      final revision = narrativeEventBytesFingerprint(bytes);
      final next = _ProjectDocument(current.root, manifest, revision);
      await _requireProjectRevision(session, next);
      _projects[session.sessionId] = next;
      return MapWorkspaceCatalog(metadata: next.manifest, revision: revision);
    }
    if (metadataChanged && session.storage != ProjectSessionStorage.manifest) {
      final fields = projectChanged
          ? (current.metadataFields ?? _mapCatalogMetadataFields).difference({
              'maps',
            })
          : settingsChanged
          ? const {'settings'}
          : const <String>{};
      final result = await _readScopedCatalog(session, (
        catalog,
        revision,
      ) async {
        final selected = mapIds.isEmpty
            ? (
                entries: const <ProjectMapEntry>[],
                positions: const <String, int>{},
              )
            : await CatalogTargetedMapSelection.readMapMetadata(
                catalog: catalog,
                mapIds: mapIds,
              );
        final maps = selected.entries;
        final presentIds = {for (final map in maps) map.id};
        final entries = current.manifest.maps as ProjectMapEntries;
        final metadata = mergeProjectMetadataSections(
          current.manifest,
          catalog.projectMetadata,
          fields,
        );
        return MapWorkspaceCatalog(
          metadata: metadata.copyWith(
            maps: entries.applySelected(
              upserts: maps,
              removedIds: mapIds.difference(presentIds),
              positions: selected.positions,
              onNodeCopied: onMapMetadataNodeCopied,
            ),
          ),
          revision: revision,
        );
      }, metadataFields: fields);
      _projects[session.sessionId] = _ProjectDocument(
        current.root,
        result.metadata,
        result.revision,
        complete: false,
        metadataFields: current.metadataFields ?? _mapCatalogMetadataFields,
      );
      return result;
    }
    final revision = await resourceRevision(session);
    final next = _ProjectDocument(
      current.root,
      current.manifest,
      revision,
      complete:
          session.storage == ProjectSessionStorage.manifest && current.complete,
      metadataFields: current.metadataFields ?? _mapCatalogMetadataFields,
    );
    await _requireProjectRevision(session, next);
    _projects[session.sessionId] = next;
    return MapWorkspaceCatalog(metadata: next.manifest, revision: revision);
  });

  @override
  Future<MapWorkspaceCatalog> loadCatalog(ProjectSession session) async {
    if (session.storage != ProjectSessionStorage.manifest) {
      return _loadScopedCatalog(session);
    }
    await loadProject(session);
    final project = _project(session);
    return MapWorkspaceCatalog(
      metadata: project.manifest,
      revision: project.revision,
    );
  }

  @override
  Future<MapWorkspaceSelection> loadMapPreviewSelection(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    final project = _project(session);
    if (!project.complete) return _loadScopedPreviewSelection(session, entry);
    final document = await loadMap(session, entry);
    return MapWorkspaceSelection(
      document: document,
      definitions: project.manifest,
      catalogRevision: project.revision,
      snapshotRevision: project.revision,
    );
  }

  @override
  Future<MapWorkspaceSelection> loadMapSelection(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    final project = _project(session);
    if (!project.complete) return _loadScopedMapSelection(session, entry);
    final document = await loadMap(session, entry);
    return MapWorkspaceSelection(
      document: document,
      definitions: project.manifest,
      catalogRevision: project.revision,
      snapshotRevision: project.revision,
    );
  }

  @override
  Future<MapWorkspaceCatalog> loadWorkshop(
    ProjectSession session,
    MapWorkspaceWorkshop workshop,
  ) => _loadWorkshop(session, workshop);

  @override
  Future<ProjectManifest> materializeProject(ProjectSession session) =>
      _materializeScopedProject(session);

  @override
  Future<ProjectManifest> loadProject(ProjectSession session) async {
    try {
      _projects.clear();
      _loadedPaths.clear();
      await _requireRoot(session);
      if (session.storage != ProjectSessionStorage.manifest) {
        final loaded = await _readCatalogProject(session);
        _projects[session.sessionId] = loaded;
        return loaded.manifest;
      }
      final bytes = await _reader.readBytes(
        projectRoot: session.directoryPath,
        relativePath: 'project.json',
      );
      final value = decodeNarrativeEventJsonStrict(utf8.decode(bytes));
      if (value is! Map<String, dynamic>) throw const FormatException();
      final decoded = ProjectManifest.fromJson(value);
      final project = decoded.copyWith(
        models3d: ProjectModel3dEntries.prepare(decoded.models3d),
      );
      final ids = <String>{};
      final paths = <String>{};
      for (final entry in project.maps) {
        if (!ids.add(entry.id) || !paths.add(entry.relativePath)) {
          throw const FormatException();
        }
      }
      _projects[session.sessionId] = _ProjectDocument(
        session.directoryPath,
        project,
        narrativeEventBytesFingerprint(bytes),
      );
      return project;
    } on MapWorkspaceFailure {
      rethrow;
    } on Object {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.invalidDocument,
        'Le catalogue du projet ne peut pas être chargé.',
      );
    }
  }

  @override
  Future<MapWorkspaceDocument> loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    try {
      final project = _project(session);
      if (!project.complete) {
        return (await loadMapSelection(session, entry)).document;
      }
      if (!project.manifest.maps.contains(entry)) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.unsafePath,
          'Cette carte ne figure pas dans le projet ouvert.',
        );
      }
      final path = await _mapPath(session, entry);
      await _requireProjectRevision(session, project);
      final bytes = await _reader.readBytes(
        projectRoot: session.directoryPath,
        relativePath: entry.relativePath,
      );
      final map = decodeValidatedMapDocument(
        bytes,
        entry.relativePath,
        validateMap: (map) => MapValidator.validate(
          map,
          projectDialogueContext: project.manifest,
        ),
      );
      if (map.id != entry.id ||
          !buildMapVisualCompositionPlan(map).canCompose) {
        throw const FormatException();
      }
      requireMapDocumentRetention(bytes, map);
      _loadedPaths[(session.sessionId, entry.id)] = path;
      return MapWorkspaceDocument(
        map: map,
        revision: narrativeEventBytesFingerprint(bytes),
        mapId: entry.id,
      );
    } on MapWorkspaceFailure {
      rethrow;
    } on Object {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.invalidDocument,
        'Cette carte est absente, invalide ou utilise un format non pris en charge.',
      );
    }
  }

  @override
  Future<String> saveMap(
    ProjectSession session,
    MapWorkspaceDocument base,
    MapData current,
  ) => withResourceMutation(() => _saveMap(session, base, current));

  Future<String> _saveMap(
    ProjectSession session,
    MapWorkspaceDocument base,
    MapData current,
  ) async {
    try {
      if (session.storage == ProjectSessionStorage.portableCatalog) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.unavailable,
          'Ce projet publié est en lecture seule.',
        );
      }
      if (base.map.spatialScene != null && current.spatialScene != null && jsonEncode(base.map.spatialScene!.platforms.map((value) => value.toJson()).toList()) != jsonEncode(current.spatialScene!.platforms.map((value) => value.toJson()).toList())) {
        return await _saveSpatialPlatformChange(session, base, current);
      }
      final project = _project(session);
      final entry = project.manifest.maps.singleWhere(
        (e) => e.id == base.mapId,
      );
      final path = await _mapPath(session, entry);
      if (_loadedPaths[(session.sessionId, entry.id)] != path ||
          base.map.id != entry.id ||
          current.id != entry.id) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.unsafePath,
          'La destination de la carte a changé. Votre travail reste ouvert.',
        );
      }
      await _requireProjectRevision(session, project);
      if (!buildMapVisualCompositionPlan(current).canCompose) {
        throw const FormatException();
      }
      if (project.complete) {
        MapValidator.validate(
          current,
          projectDialogueContext: project.manifest,
        );
      }
      final bytes = encodeMapDocumentBytes(current);
      if (session.storage == ProjectSessionStorage.workingCatalog) {
        return await _saveWorkingMap(session, project, base, current);
      }
      return await _persistence.write(
        path,
        bytes,
        precondition: MapDocumentWritePrecondition.revision(base.revision),
      );
    } on MapWorkspaceFailure {
      rethrow;
    } on EditorConflictException {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'La carte ou le projet a changé sur le disque. Rien n’a été écrasé ; votre travail reste ouvert.',
      );
    } on Object {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.writeFailed,
        'La carte n’a pas pu être enregistrée. Votre travail reste ouvert.',
      );
    }
  }

  Future<void> _requireProjectRevision(
    ProjectSession session,
    _ProjectDocument project,
  ) async {
    final bytes = await _reader.readBytes(
      projectRoot: session.directoryPath,
      relativePath: 'project.json',
    );
    final head = session.storage == ProjectSessionStorage.workingCatalog
        ? await _reader.readBytes(
            projectRoot: session.directoryPath,
            relativePath: 'catalog/HEAD.json',
          )
        : null;
    if (studioProjectDocumentRevision(
          descriptorBytes: bytes,
          headBytes: head,
        ) !=
        project.revision) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'Le projet a changé sur le disque. Votre travail reste ouvert ; rouvrez le projet pour utiliser sa nouvelle version.',
      );
    }
  }

  _ProjectDocument _project(ProjectSession session) {
    final project = _projects[session.sessionId];
    if (project == null || project.root != session.directoryPath) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.unavailable,
        'Le projet doit être ouvert avant de charger une carte.',
      );
    }
    return project;
  }

  Future<void> _requireRoot(ProjectSession session) async {
    final root = session.directoryPath;
    if (root != root.trim() || !p.isAbsolute(root)) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.unsafePath,
        'Le chemin du projet ne peut pas être préservé.',
      );
    }
    final resolved = await Directory(root).resolveSymbolicLinks();
    if (resolved != root || resolved != resolved.trim()) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.unsafePath,
        'Le dossier du projet a changé depuis son ouverture.',
      );
    }
  }

  Future<String> _mapPath(ProjectSession session, ProjectMapEntry entry) async {
    await _requireRoot(session);
    final relative = entry.relativePath;
    if (relative != relative.trim() ||
        p.isAbsolute(relative) ||
        relative.contains('\\') ||
        relative
            .split('/')
            .any((part) => part.isEmpty || part == '..' || part == '.') ||
        relative.contains('\u0000')) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.unsafePath,
        'Le chemin de cette carte n’est pas sûr.',
      );
    }
    final file = File(p.join(session.directoryPath, relative));
    if (await FileSystemEntity.type(file.path, followLinks: false) !=
        FileSystemEntityType.file) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.unsafePath,
        'La carte doit être un fichier ordinaire du projet.',
      );
    }
    final canonical = await file.resolveSymbolicLinks();
    if (!p.isWithin(session.directoryPath, canonical)) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.unsafePath,
        'La carte pointe en dehors du projet ouvert.',
      );
    }
    return canonical;
  }
}
