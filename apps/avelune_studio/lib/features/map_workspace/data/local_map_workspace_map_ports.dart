part of 'local_map_workspace_adapter.dart';

mixin _MapWorkspaceMapFeaturePorts
    implements
        FieldTraversalZonePort,
        SpatialFieldObstaclePort,
        SpatialModelVisibilityPort,
        MapElementOrderPort,
        MapEditorPort,
        MapExteriorDecorationPort,
        MapAtmospherePort {
  LocalMapWorkspaceAdapter get _adapter;

  @override
  Future<FieldTraversalZoneReceipt> publishFieldTraversalZone(
    ProjectSession session,
    MapWorkspaceDocument base,
    String actionId,
    Map<String, Object?> parameters,
  ) => _adapter.withResourceMutation(
    () => _adapter._publishFieldTraversalZone(
      session,
      base,
      actionId,
      parameters,
    ),
  );
  @override
  Future<FieldTraversalZoneReceipt> restoreFieldTraversalZone(
    ProjectSession session,
    MapWorkspaceDocument base,
    FieldTraversalZoneReceipt receipt, {
    required bool redo,
  }) => _adapter.withResourceMutation(
    () => _adapter._publishFieldTraversalZone(
      session,
      base,
      receipt.actionId,
      receipt.parameters,
      undo: receipt,
      redo: redo,
    ),
  );
  @override
  Future<SpatialFieldObstacleReceipt> configureSpatialFieldObstacle(
    ProjectSession session,
    MapWorkspaceDocument base,
    String instanceId,
    MapEntityFieldObstacleData? fieldObstacle,
  ) => _adapter.withResourceMutation(
    () => _adapter._configureSpatialFieldObstacle(
      session,
      base,
      instanceId,
      fieldObstacle,
    ),
  );
  @override
  Future<SpatialFieldObstacleReceipt> undoSpatialFieldObstacle(
    ProjectSession session,
    MapWorkspaceDocument base,
    SpatialFieldObstacleReceipt receipt, {
    required bool redo,
  }) => _adapter.withResourceMutation(
    () => _adapter._mutateSpatialFieldObstacle(
      session,
      base,
      undo: receipt,
      redo: redo,
    ),
  );
  @override
  Future<SpatialModelVisibilityReceipt> configureSpatialModelVisibility(
    ProjectSession session,
    MapWorkspaceDocument base,
    String instanceId,
    NarrativeEventConditionExpression? condition,
  ) => _adapter.withResourceMutation(
    () => _adapter._configureSpatialModelVisibility(
      session,
      base,
      instanceId,
      condition,
    ),
  );
  @override
  Future<SpatialModelVisibilityReceipt> undoSpatialModelVisibility(
    ProjectSession session,
    MapWorkspaceDocument base,
    SpatialModelVisibilityReceipt receipt, {
    required bool redo,
  }) => _adapter.withResourceMutation(
    () => _adapter._mutateSpatialModelVisibility(
      session,
      base,
      undo: receipt,
      redo: redo,
    ),
  );

  @override
  Future<MapExteriorDecorationWrite> saveExteriorDecorationBorder(
    ProjectSession session,
    String mapId,
    ExteriorDecorationBorder border,
    String expectedRevision,
  ) => _adapter._saveExteriorDecorationBorder(
    session,
    mapId,
    border,
    expectedRevision,
  );
  @override
  Future<MapExteriorDecorationWrite> removeExteriorDecorationBorder(
    ProjectSession session,
    String mapId,
    String borderId,
    String expectedRevision,
  ) => _adapter._removeExteriorDecorationBorder(
    session,
    mapId,
    borderId,
    expectedRevision,
  );
  @override
  Future<MapExteriorDecorationWrite> saveExteriorDecorationSectors(
    ProjectSession session,
    String mapId,
    List<ExteriorDecorationSector> sectors,
    List<String> removeSectorIds,
    String expectedRevision,
  ) => _adapter._saveExteriorDecorationSectors(
    session,
    mapId,
    sectors,
    removeSectorIds,
    expectedRevision,
  );

  @override
  Future<MapExteriorDecorationState> loadExteriorDecoration(
    ProjectSession session,
    String mapId,
  ) => _adapter._loadExteriorDecoration(session, mapId);
  @override
  Future<MapExteriorDecorationWrite> configureExteriorDecoration(
    ProjectSession session,
    String mapId,
    MapExteriorDecoration? definition,
    String expectedRevision,
  ) => _adapter._configureExteriorDecoration(
    session,
    mapId,
    definition,
    expectedRevision,
  );
  @override
  Future<MapExteriorDecorationWrite> saveExteriorDecorationSector(
    ProjectSession session,
    String mapId,
    ExteriorDecorationSector sector,
    String expectedRevision,
  ) => _adapter._saveExteriorDecorationSector(
    session,
    mapId,
    sector,
    expectedRevision,
  );
  @override
  Future<MapExteriorDecorationWrite> removeExteriorDecorationSector(
    ProjectSession session,
    String mapId,
    String sectorId,
    String expectedRevision,
  ) => _adapter._removeExteriorDecorationSector(
    session,
    mapId,
    sectorId,
    expectedRevision,
  );

  @override
  Future<MapEditorWorkspaceState> loadEditorState(
    ProjectSession session,
    String mapId,
  ) => _adapter._loadEditorState(session, mapId);

  @override
  Future<MapEditorWorkspaceState> saveEditorState(
    ProjectSession session,
    String mapId,
    MapEditorState state,
    String expectedRevision,
  ) => _adapter._saveEditorState(session, mapId, state, expectedRevision);

  @override
  Future<MapElementOrderWorkspaceReceipt> reorderMapElements(
    ProjectSession session,
    MapWorkspaceDocument base,
    String kind,
    List<String> frontFirstIds,
    String? layerId,
  ) =>
      _adapter._reorderMapElements(session, base, kind, frontFirstIds, layerId);

  @override
  Future<MapElementOrderWorkspaceReceipt> undoMapElementOrder(
    ProjectSession session,
    MapWorkspaceDocument base,
    MapElementOrderWorkspaceReceipt receipt,
  ) => _adapter._undoMapElementOrder(session, base, receipt);

  @override
  Future<MapAtmosphereState> loadAtmosphere(
    ProjectSession session,
    String mapId,
  ) => _adapter._loadAtmosphere(session, mapId);

  @override
  Future<MapAtmosphereState> saveAtmosphere(
    ProjectSession session,
    String mapId,
    SpatialAtmosphereSettings settings,
    String expectedRevision,
  ) => _adapter._saveAtmosphere(session, mapId, settings, expectedRevision);
}
