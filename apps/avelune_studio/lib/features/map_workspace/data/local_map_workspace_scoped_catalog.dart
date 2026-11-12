part of 'local_map_workspace_adapter.dart';

extension _LocalScopedMapCatalog on LocalMapWorkspaceAdapter {
  Future<MapWorkspaceCatalog> _loadScopedCatalog(ProjectSession session) async {
    await _requireRoot(session);
    _resourceSelections.remove(session.sessionId);
    _resourceKindReads.remove(session.sessionId);
    _onDemandSelections.remove(session.sessionId);
    _workshopCharacterDefinitions.remove(session.sessionId);
    final result = await _readScopedCatalog(session, (catalog, revision) async {
      return MapWorkspaceCatalog(
        metadata: catalog.projectMetadata.copyWith(
          models3d: ProjectModel3dEntries.prepare(catalog.projectMetadata.models3d),
        ),
        revision: revision,
      );
    });
    _projects[session.sessionId] = _ProjectDocument(
      session.directoryPath,
      result.metadata,
      result.revision,
      complete: false,
      metadataFields: _mapCatalogMetadataFields,
      onMapEntryRead: onMapMetadataEntryRead,
    );
    return MapWorkspaceCatalog(metadata: _project(session).manifest, revision: result.revision);
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
      metadataFields: workshop == MapWorkspaceWorkshop.resources
          ? {'settings', ...workshop.metadataFields}
          : {..._mapCatalogMetadataFields, ...workshop.metadataFields},
    );
    if (workshop == MapWorkspaceWorkshop.dialogue ||
        workshop == MapWorkspaceWorkshop.cinematic) {
      _workshopCharacterDefinitions[session.sessionId] = projection.metadata.copyWith(
        models3d: ProjectModel3dEntries.prepare(projection.metadata.models3d),
      );
    }
    final latest = _project(session);
    if (latest.revision != projection.revision) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'Le catalogue a changé pendant l’ouverture de cet atelier.',
      );
    }
    final merged = workshop.merge(latest.manifest, projection.metadata);
    _projects[session.sessionId] = _ProjectDocument(
      latest.root,
      merged.copyWith(models3d: ProjectModel3dEntries.prepare(merged.models3d)),
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

  Future<MapWorkspaceCatalog> _loadOnDemandSelection(
    ProjectSession session,
    CatalogDefinitionKey? root,
  ) async {
    final before = _project(session);
    final result = await _readScopedCatalog(
      session,
      (catalog, revision) async {
        if (revision != before.revision) {
          throw const MapWorkspaceFailure(
            MapWorkspaceProblem.conflict,
            'Le catalogue a changé avant le chargement de ces ressources.',
          );
        }
        final ProjectManifest manifest;
        if (root != null) {
          manifest = await ProjectCatalogSelection(catalog).resolve([root]);
        } else {
          final units = <CatalogDefinitionUnit>[];
          for (final kind in const [
            CatalogDefinitionKind.borderRecord,
            CatalogDefinitionKind.resourceFamily,
          ]) {
            String? cursor;
            do {
              final page = await catalog.snapshot.page(
                kind: kind,
                limit: catalog.snapshot.limits.indexPageSize,
                cursor: cursor,
              );
              for (final entry in page.items) {
                units.add((await catalog.lookup(entry.key))!);
                if (kind != CatalogDefinitionKind.borderRecord) continue;
                final classification = await catalog.lookup(
                  CatalogDefinitionKey(
                    CatalogDefinitionKind.resourceLibraryEntry,
                    'borderBlueprint:${entry.key.id}',
                  ),
                );
                if (classification != null) units.add(classification);
              }
              cursor = page.nextCursor;
            } while (cursor != null);
          }
          manifest = catalog.projectWithDefinitions(units);
        }
        return MapWorkspaceCatalog(
          metadata: manifest.copyWith(
            models3d: ProjectModel3dEntries.prepare(manifest.models3d),
          ),
          revision: revision,
        );
      },
      metadataFields: const {'settings', 'globalProperties'},
    );
    final latest = _project(session);
    if (latest.revision != result.revision) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'Le catalogue a changé pendant le chargement de ces ressources.',
      );
    }
    final previous = _onDemandSelections[session.sessionId];
    _onDemandSelections[session.sessionId] = previous == null
        ? result.metadata
        : combineResourceVisuals(previous, result.metadata);
    final merged = mergeBorderSelection(latest.manifest, result.metadata);
    _projects[session.sessionId] = _ProjectDocument(
      latest.root,
      merged.copyWith(models3d: ProjectModel3dEntries.prepare(merged.models3d)),
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
        definitions: mergeProjectMetadataSections(source.definitions,
          project.manifest, project.metadataFields ?? _mapCatalogMetadataFields),
        catalogRevision: source.catalogRevision,
        snapshotRevision: source.snapshotRevision,
      );
    }, metadataFields: _mapCatalogMetadataFields.difference({'maps'}));
    _loadedPaths[(session.sessionId, entry.id)] = path;
    return selection;
  }

  Future<MapWorkspaceSelection> _loadScopedMapSelection(ProjectSession session, ProjectMapEntry entry) async {
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
      catalogMetadataFields: _mapCatalogMetadataFields.difference({'maps'}),
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
  }) => _readScopedCatalogWith(
    _reader,
    session,
    action,
    metadataFields: metadataFields,
  );
}

Future<T> _readScopedCatalogWith<T>(
  ProjectFileReader reader,
  ProjectSession session,
  Future<T> Function(PortableProjectCatalog catalog, String revision)
  action, {
  Set<String> metadataFields = _mapCatalogMetadataFields,
}) async {
  final policy = await WorkspacePolicy.create(
    allowedRootPaths: [session.directoryPath],
    fileReader: reader,
  );
  final handles = WorkspaceHandleStore();
  final service = ProjectOpenService(
    policy: policy,
    fileReader: reader,
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
      final descriptor = await reader.readBytes(
        projectRoot: session.directoryPath,
        relativePath: 'project.json',
      );
      final head = session.storage == ProjectSessionStorage.workingCatalog
          ? await reader.readBytes(
              projectRoot: session.directoryPath,
              relativePath: CatalogStorageStore.headStorageKey,
            )
          : null;
      final revision = studioProjectDocumentRevision(
        descriptorBytes: descriptor,
        headBytes: head,
      );
      final result = await action(catalog, revision);
      final observedDescriptor = await reader.readBytes(
        projectRoot: session.directoryPath,
        relativePath: 'project.json',
      );
      final observedHead = head == null
          ? null
          : await reader.readBytes(
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
