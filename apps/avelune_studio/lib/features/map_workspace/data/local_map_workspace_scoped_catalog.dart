part of 'local_map_workspace_adapter.dart';

extension _LocalScopedMapCatalog on LocalMapWorkspaceAdapter {
  Future<MapWorkspaceCatalog> _loadScopedCatalog(ProjectSession session) async {
    await _requireRoot(session);
    _resourceSelections.remove(session.sessionId);
    _workshopCharacterDefinitions.remove(session.sessionId);
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
      metadataFields: _mapCatalogMetadataFields,
    );
    return result;
  }

  Future<MapWorkspaceCatalog> _loadWorkshop(
    ProjectSession session,
    MapWorkspaceWorkshop workshop,
  ) async {
    final current = _project(session);
    final projection = await _readScopedCatalog(
      session,
      (catalog, revision) async {
        if (revision != current.revision) {
          throw const MapWorkspaceFailure(
            MapWorkspaceProblem.conflict,
            'Le catalogue a changé avant l’ouverture de cet atelier.',
          );
        }
        var manifest = catalog.projectMetadata;
        if (workshop == MapWorkspaceWorkshop.dialogue ||
            workshop == MapWorkspaceWorkshop.cinematic) {
          final roots = <CatalogDefinitionKey>[];
          String? cursor;
          do {
            final page = await catalog.snapshot.page(
              kind: CatalogDefinitionKind.character,
              limit: catalog.snapshot.limits.indexPageSize,
              cursor: cursor,
            );
            roots.addAll(page.items.map((entry) => entry.key));
            cursor = page.nextCursor;
          } while (cursor != null);
          manifest = await ProjectCatalogSelection(catalog).resolve(roots);
        }
        return MapWorkspaceCatalog(metadata: manifest, revision: revision);
      },
      metadataFields: {
        ..._mapCatalogMetadataFields,
        ...workshop.metadataFields,
      },
    );
    if (workshop == MapWorkspaceWorkshop.dialogue ||
        workshop == MapWorkspaceWorkshop.cinematic) {
      _workshopCharacterDefinitions[session.sessionId] = projection.metadata;
    }
    final latest = _project(session);
    if (latest.revision != projection.revision) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'Le catalogue a changé pendant l’ouverture de cet atelier.',
      );
    }
    _projects[session.sessionId] = _ProjectDocument(
      latest.root,
      workshop.merge(latest.manifest, projection.metadata),
      projection.revision,
      complete: false,
      metadataFields: {
        ...?latest.metadataFields,
        ..._mapCatalogMetadataFields,
        ...workshop.metadataFields,
      },
    );
    return projection;
  }

  Future<MapWorkspaceCatalog> _loadResourceKind(
    ProjectSession session,
    String canonicalKind,
  ) async {
    final kind = switch (canonicalKind) {
      'tileset' => CatalogDefinitionKind.tileset,
      'element' => CatalogDefinitionKind.element,
      'model3d' => CatalogDefinitionKind.model3d,
      'character' => CatalogDefinitionKind.character,
      'environmentPreset' => CatalogDefinitionKind.environmentPreset,
      'smartTilePreset' => CatalogDefinitionKind.smartTilePreset,
      'borderBlueprint' => CatalogDefinitionKind.borderRecord,
      _ => throw const FormatException('Famille de ressources inconnue.'),
    };
    final before = _project(session);
    final result = await _readScopedCatalog(
      session,
      (catalog, revision) async {
        if (revision != before.revision) {
          throw const MapWorkspaceFailure(
            MapWorkspaceProblem.conflict,
            'Le catalogue a changé avant le chargement de cette famille.',
          );
        }
        final roots = <CatalogDefinitionKey>[];
        String? cursor;
        do {
          final page = await catalog.snapshot.page(
            kind: kind,
            limit: catalog.snapshot.limits.indexPageSize,
            cursor: cursor,
          );
          roots.addAll(page.items.map((entry) => entry.key));
          cursor = page.nextCursor;
        } while (cursor != null);
        final manifest = await ProjectCatalogSelection(catalog).resolve(roots);
        return MapWorkspaceCatalog(metadata: manifest, revision: revision);
      },
      metadataFields: {
        ..._mapCatalogMetadataFields,
        ...MapWorkspaceWorkshop.resources.metadataFields,
        if (canonicalKind == 'character') 'characterStudioCatalog',
      },
    );
    final latest = _project(session);
    if (latest.revision != result.revision) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'Le catalogue a changé pendant le chargement de cette famille.',
      );
    }
    _resourceSelections[session.sessionId] = result.metadata;
    _projects[session.sessionId] = _ProjectDocument(
      latest.root,
      mergeResourceSelection(
        latest.manifest,
        combineResourceVisuals(
          _activeMapDefinitions[session.sessionId] ?? latest.manifest,
          _workshopCharacterDefinitions[session.sessionId] == null
              ? result.metadata
              : combineResourceVisuals(
                  result.metadata,
                  _workshopCharacterDefinitions[session.sessionId]!,
                ),
        ),
      ),
      result.revision,
      complete: false,
      metadataFields: latest.metadataFields,
    );
    return result;
  }

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
        definitions: source.definitions,
        catalogRevision: source.catalogRevision,
        snapshotRevision: source.snapshotRevision,
      );
    });
    _loadedPaths[(session.sessionId, entry.id)] = path;
    return selection;
  }

  Future<MapWorkspaceSelection> _loadScopedMapSelection(ProjectSession session, ProjectMapEntry entry) async {
    final selection = await _loadScopedPreviewSelection(session, entry);
    _activeMapDefinitions[session.sessionId] = selection.definitions;
    final latest = _project(session);
    var definitions = selection.definitions;
    final characters = _workshopCharacterDefinitions[session.sessionId];
    if (characters != null) {
      definitions = combineResourceVisuals(definitions, characters);
    }
    final resources = _resourceSelections[session.sessionId];
    if (resources != null) {
      definitions = combineResourceVisuals(definitions, resources);
    }
    _projects[session.sessionId] = _ProjectDocument(
      latest.root,
      mergeProjectMetadataSections(
        definitions,
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
      catalogMetadataFields: _mapCatalogMetadataFields,
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
    Future<T> Function(PortableProjectCatalog catalog, String revision)
    action, {
    Set<String> metadataFields = _mapCatalogMetadataFields,
  }) async {
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [session.directoryPath],
      fileReader: _reader,
    );
    final handles = WorkspaceHandleStore();
    final service = ProjectOpenService(
      policy: policy,
      fileReader: _reader,
      handles: handles,
      catalogMetadataFields: metadataFields,
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

const _mapCatalogMetadataFields = <String>{
  'maps',
  'groups',
  'settings',
  'newGame',
  'scenes',
  'eventRegistry',
  'cinematics',
  'trainers',
  'scenarios',
  'pokemon',
};
