part of 'local_map_workspace_adapter.dart';

mixin _MapWorkspaceCatalogPorts
    implements
        MapWorkspacePort,
        MapWorkspacePreviewSelectionPort,
        ProjectResourceLibraryDimensionsPort,
        ProjectResourceLibraryMapUsagesPort,
        ProjectResourcePreviewPort,
        MapWorkspaceExternalMutationPort,
        MapWorkspaceWorkshopPort,
        MapWorkspaceResourceKindPort,
        MapWorkspaceResourcePrefetchPort,
        MapWorkspaceBorderProfilePort,
        MapWorkspaceResourceClosurePort,
        MapWorkspaceModelLightPort {
  LocalMapWorkspaceAdapter get _adapter;

  @override
  Future<ProjectResourceLibrary> readResourceLibrary(ProjectSession session) =>
      _readLibrary(session, includeCompositeDimensions: true);

  @override
  Future<ProjectResourceLibrary> readResourceLibraryIndex(
    ProjectSession session,
  ) => _readLibrary(session, includeCompositeDimensions: false);

  Future<ProjectResourceLibrary> _readLibrary(
    ProjectSession session, {
    required bool includeCompositeDimensions,
  }) {
    if (session.storage == ProjectSessionStorage.manifest) {
      return Future.sync(
        () => ProjectResourceLibrary.fromManifest(
          _adapter._project(session).manifest,
        ),
      );
    }
    final reader = _adapter._reader;
    return reader is LocalProjectFileReader
        ? _readProjectResourceLibraryInBackground(
            reader,
            session,
            includeCompositeDimensions: includeCompositeDimensions,
          )
        : _readProjectResourceLibrary(
            reader,
            session,
            includeCompositeDimensions: includeCompositeDimensions,
          );
  }

  @override
  Future<Map<String, Set<ProjectDimension>>?> readResourceLibraryDimensions(
    ProjectSession session, {
    required String revision,
  }) => _readProjectResourceLibraryDimensions(
    _adapter._reader,
    session,
    revision,
  );

  @override
  Future<Map<String, Set<String>>?> readResourceLibraryMapUsages(
    ProjectSession session, {
    required String revision,
    required Iterable<String> identities,
  }) => _readProjectResourceLibraryMapUsages(
    _adapter._reader,
    session,
    revision,
    identities,
  );

  Future<ProjectLibraryItem> readResourceLibraryItem(
    ProjectSession session,
    String kind,
    String id, {
    required String expectedRevision,
  }) async => (await readResourceLibraryItems(session, [
    (kind: kind, id: id),
  ], expectedRevision: expectedRevision)).single;

  Future<List<ProjectLibraryItem>> readResourceLibraryItems(
    ProjectSession session,
    Iterable<({String kind, String id})> resources, {
    required String expectedRevision,
  }) => _adapter._readScopedCatalog(session, (catalog, revision) async {
    if (revision != expectedRevision) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'Le catalogue a changé. Actualisez la bibliothèque et réessayez.',
      );
    }
    final items = <ProjectLibraryItem>[];
    for (final (:kind, :id) in resources) {
      final index = await catalog.snapshot.indexEntry(
        CatalogDefinitionKey(_catalogFamily(kind), id),
      );
      if (index == null) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.unavailable,
          'Cette ressource est introuvable dans le catalogue.',
        );
      }
      final classification = await catalog.snapshot.indexEntry(
        CatalogDefinitionKey(
          CatalogDefinitionKind.resourceLibraryEntry,
          '$kind:$id',
        ),
      );
      items.add(
        _projectLibraryItem(
          kind,
          index,
          classification?.summary,
          compatibleDimensions: await _readLibraryDimensions(catalog, index),
        ),
      );
    }
    return List.unmodifiable(items);
  }, metadataFields: const {});

  @override
  Future<ProjectManifest> readResourcePreview(
    ProjectSession session,
    String kind,
    String id,
  ) async => (await readResourcePreviewWithRevision(session, kind, id)).project;

  Future<({ProjectManifest project, String revision})>
  readResourcePreviewWithRevision(
    ProjectSession session,
    String kind,
    String id,
  ) => _adapter._readScopedCatalog(
    session,
    (catalog, revision) async => (
      project: await ProjectCatalogSelection(catalog)
          .resolve([CatalogDefinitionKey(_catalogFamily(kind), id)]),
      revision: revision,
    ),
    metadataFields: const {},
  );

  @override
  Future<MapWorkspaceCatalog> loadResourceKind(
    ProjectSession session,
    String canonicalKind, {
    bool placeableOnly = false,
  }) => _adapter._loadResourceKind(session, canonicalKind, placeableOnly);

  @override
  Future<void> prefetchResourceKind(
    ProjectSession session,
    String canonicalKind, {
    bool placeableOnly = false,
  }) => _adapter._prefetchResourceKind(session, canonicalKind, placeableOnly);

  @override
  Future<MapWorkspaceCatalog> loadBorderProfiles(ProjectSession session) =>
      _adapter._loadOnDemandSelection(session, null);

  @override
  Future<MapWorkspaceCatalog> loadBorderBlueprint(
    ProjectSession session,
    String blueprintId,
  ) => _adapter._loadOnDemandSelection(
    session,
    CatalogDefinitionKey(CatalogDefinitionKind.borderRecord, blueprintId),
  );

  @override
  Future<MapWorkspaceCatalog> loadResourceClosure(
    ProjectSession session,
    String canonicalKind,
    String id,
  ) => _adapter._loadOnDemandSelection(
    session,
    CatalogDefinitionKey(_catalogFamily(canonicalKind), id),
  );

  @override
  Future<MapWorkspaceCatalog> loadWorkshop(
    ProjectSession session,
    MapWorkspaceWorkshop workshop,
  ) => _adapter._loadWorkshop(session, workshop);

  @override
  Future<ProjectManifest> materializeProject(ProjectSession session) =>
      _adapter._materializeScopedProject(session);

  @override
  Future<String> saveMap(
    ProjectSession session,
    MapWorkspaceDocument base,
    MapData current,
  ) => _adapter.withResourceMutation(
    () => _adapter._saveMap(session, base, current),
  );

  @override
  Future<void> acceptModelLight(
    ProjectSession session,
    ProjectModel3dEntry model,
    String beforeRevision,
    String afterRevision,
  ) =>
      _adapter._acceptModelLight(session, model, beforeRevision, afterRevision);

  @override
  Future<String?> readExternalMapRevision(
    ProjectSession session,
    String mapId,
  ) => _adapter._readExternalMapRevision(session, mapId);

  @override
  Future<MapWorkspaceCatalog> refreshExternalBaseline(
    ProjectSession session, {
    required Set<({String kind, String id})> resources,
  }) => _adapter._refreshExternalBaseline(session, resources: resources);

  @override
  Future<MapWorkspaceCatalog> loadCatalog(ProjectSession session) =>
      _adapter._loadCatalog(session);

  @override
  Future<MapWorkspaceSelection> loadMapPreviewSelection(
    ProjectSession session,
    ProjectMapEntry entry,
  ) => _adapter._loadMapPreviewSelection(session, entry);

  @override
  Future<MapWorkspaceSelection> loadMapSelection(
    ProjectSession session,
    ProjectMapEntry entry,
  ) => _adapter._loadMapSelection(session, entry);

  @override
  Future<ProjectManifest> loadProject(ProjectSession session) =>
      _adapter._loadProject(session);

  @override
  Future<MapWorkspaceDocument> loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  ) => _adapter._loadMap(session, entry);
}
