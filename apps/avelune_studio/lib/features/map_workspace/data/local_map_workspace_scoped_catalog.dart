part of 'local_map_workspace_adapter.dart';

extension _LocalScopedMapCatalog on LocalMapWorkspaceAdapter {
  Future<MapWorkspaceCatalog> _loadScopedCatalog(ProjectSession session) async {
    await _requireRoot(session);
    final result = await _readScopedCatalog(session, (catalog, revision) async {
      return MapWorkspaceCatalog(
        metadata: catalog.projectMetadata,
        revision: revision,
      );
    });
    _projects[session.sessionId] = _ProjectDocument(
      session.directoryPath,
      result.metadata,
      result.revision,
      complete: false,
    );
    return result;
  }

  Future<MapWorkspaceSelection> _loadScopedMapSelection(
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
        definitions: source.definitions,
        catalogRevision: source.catalogRevision,
        snapshotRevision: source.snapshotRevision,
      );
    });
    _loadedPaths[(session.sessionId, entry.id)] = path;
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

  Future<CatalogTargetedMapSelection> _readCanonicalMapSelection(
    ProjectSession session,
    String mapId,
  ) async {
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [session.directoryPath],
      fileReader: _reader,
    );
    final handles = WorkspaceHandleStore();
    final service = ProjectOpenService(
      policy: policy,
      fileReader: _reader,
      handles: handles,
    );
    final opened = await service.openProject(session.directoryPath);
    try {
      final reader = await service.catalogProject(opened.projectHandle);
      if (reader == null) throw const FormatException();
      return await CatalogTargetedMapSelection.read(
        reader: reader,
        mapId: mapId,
      );
    } finally {
      service.closeWorkspace(opened.workspaceHandle);
    }
  }

  Future<T> _readScopedCatalog<T>(
    ProjectSession session,
    Future<T> Function(PortableProjectCatalog catalog, String revision) action,
  ) async {
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [session.directoryPath],
      fileReader: _reader,
    );
    final handles = WorkspaceHandleStore();
    final service = ProjectOpenService(
      policy: policy,
      fileReader: _reader,
      handles: handles,
    );
    final opened = await service.openProject(session.directoryPath);
    try {
      final source = await service.catalogProject(opened.projectHandle);
      if (source == null) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.invalidDocument,
          'Ce projet ne possède pas de catalogue partitionné.',
        );
      }
      return await source.read((catalog) async {
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
        final revision = studioProjectDocumentRevision(
          descriptorBytes: descriptor,
          headBytes: head,
        );
        final result = await action(catalog, revision);
        final observedDescriptor = await _reader.readBytes(
          projectRoot: session.directoryPath,
          relativePath: 'project.json',
        );
        final observedHead = head == null
            ? null
            : await _reader.readBytes(
                projectRoot: session.directoryPath,
                relativePath: CatalogStorageStore.headStorageKey,
              );
        if (studioProjectDocumentRevision(
              descriptorBytes: observedDescriptor,
              headBytes: observedHead,
            ) !=
            revision) {
          throw const MapWorkspaceFailure(
            MapWorkspaceProblem.conflict,
            'Le catalogue a changé pendant sa lecture.',
          );
        }
        return result;
      });
    } finally {
      service.closeWorkspace(opened.workspaceHandle);
    }
  }
}
