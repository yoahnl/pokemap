part of 'local_map_workspace_adapter.dart';

extension _LocalScopedMapSelection on LocalMapWorkspaceAdapter {
  Future<MapWorkspaceSelection> _loadScopedPreviewSelection(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    final project = _project(session);
    if (!project.manifest.maps.contains(entry)) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.unsafePath,
        'Cette carte ne figure pas dans le catalogue ouvert.',
      );
    }
    final path = await _mapPath(session, entry);
    final selection = await _readScopedCatalog(session, (
      catalog,
      revision,
    ) async {
      if (revision != project.revision) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.conflict,
          'Le catalogue a changé depuis l’ouverture de cette carte.',
        );
      }
      final source = await _readCanonicalMapSelection(session, entry.id);
      final map = source.map;
      if (map.id != entry.id ||
          !buildMapVisualCompositionPlan(map).canCompose) {
        throw const FormatException();
      }
      requireMapDocumentRetention(source.mapBytes, map);
      return MapWorkspaceSelection(
        document: MapWorkspaceDocument(
          map: map,
          revision: narrativeEventBytesFingerprint(source.mapBytes),
          mapId: entry.id,
        ),
        definitions: mergeProjectMetadataSections(
          source.definitions,
          project.manifest,
          project.metadataFields ?? _mapCatalogMetadataFields,
        ),
        catalogRevision: source.catalogRevision,
        snapshotRevision: source.snapshotRevision,
      );
    }, metadataFields: _mapCatalogMetadataFields.difference({'maps'}));
    _loadedPaths[(session.sessionId, entry.id)] = path;
    return selection;
  }

  Future<MapWorkspaceSelection> _loadScopedMapSelection(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    final selection = await _loadScopedPreviewSelection(session, entry);
    final activeDefinitions = selection.definitions.copyWith(
      models3d: ProjectModel3dEntries.prepare(selection.definitions.models3d),
    );
    _activeMapDefinitions[session.sessionId] = activeDefinitions;
    final latest = _project(session);
    var definitions = activeDefinitions;
    final characters = _workshopCharacterDefinitions[session.sessionId];
    if (characters != null) {
      definitions = combineResourceVisuals(definitions, characters);
    }
    final resources = _resourceSelections[session.sessionId];
    if (resources != null) {
      definitions = combineResourceVisuals(definitions, resources);
    }
    final borders = _onDemandSelections[session.sessionId];
    if (borders != null) {
      definitions = combineResourceVisuals(definitions, borders);
    }
    _projects[session.sessionId] = _ProjectDocument(
      latest.root,
      mergeProjectMetadataSections(
        definitions.copyWith(
          models3d: ProjectModel3dEntries.prepare(definitions.models3d),
        ),
        latest.manifest,
        latest.metadataFields ?? _mapCatalogMetadataFields,
      ),
      latest.revision,
      complete: false,
      metadataFields: latest.metadataFields,
    );
    return selection;
  }

  Future<ProjectManifest> _materializeScopedProject(
    ProjectSession session,
  ) async {
    final current = _project(session);
    await _requireProjectRevision(session, current);
    final complete = await _readCatalogProject(session);
    if (complete.revision != current.revision) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'Le projet a changé avant le chargement des ateliers.',
      );
    }
    _projects[session.sessionId] = complete;
    return complete.manifest;
  }
}
