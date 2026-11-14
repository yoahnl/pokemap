part of 'local_map_workspace_adapter.dart';

mixin _MapWorkspaceCatalogPorts
    implements
        MapWorkspacePort,
        MapWorkspacePreviewSelectionPort,
        MapWorkspaceExternalMutationPort,
        MapWorkspaceWorkshopPort,
        MapWorkspaceResourceKindPort,
        MapWorkspaceResourcePrefetchPort,
        MapWorkspaceBorderProfilePort,
        MapWorkspaceResourceClosurePort,
        MapWorkspaceModelLightPort {
  LocalMapWorkspaceAdapter get _adapter;

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
