part of 'map_builder_gameplay_binding.dart';

extension MapGameplayPassageEditing on MapBuilderGameplayBinding {
  bool get draftingConnection =>
      _connection != null &&
      _connection!.mapId == map?.id &&
      _connection!.direction == null;

  bool get draftingWarp => _warpDraft != null && _warpDraft!.mapId == map?.id;

  bool get draftingSpawn =>
      _spawnDraft != null && _spawnDraft!.mapId == map?.id;

  MapEntity? get selectedSpawn {
    final map = this.map;
    if (map == null) return null;
    final id = view()?.selectedFor(map.id, MapSelectionFamily.marker);
    return map.entities
        .where(
          (entity) => entity.id == id && entity.kind == MapEntityKind.spawn,
        )
        .firstOrNull;
  }

  MapEntityEditingCommands? get entities {
    final document = maps.active;
    final project = maps.project;
    return document == null || project == null
        ? null
        : _GuardedEntityCommands(
            document,
            storyProject?.call(project) ?? project,
            entityDeletionProblem,
          );
  }

  List<MapEntity> get spawns => [
    for (final entity in map?.entities ?? const <MapEntity>[])
      if (entity.kind == MapEntityKind.spawn &&
          studioSearchMatches(entity.name, query))
        entity,
  ];

  bool get startsNowhere {
    final map = this.map;
    if (map == null) return false;
    final preferred = map.mapMetadata.defaultSpawnId?.trim() ?? '';
    return !map.entities.any(
      (entity) =>
          entity.kind == MapEntityKind.spawn &&
          (preferred.isEmpty
              ? entity.spawn?.role == EntitySpawnRole.playerStart
              : entity.id == preferred),
    );
  }

  MapConnection? get selectedConnection {
    final focus = _connection;
    final map = this.map;
    if (focus == null || map == null || focus.mapId != map.id) return null;
    return map.connections
        .where((entry) => entry.direction == focus.direction)
        .firstOrNull;
  }

  MapWarp? get selectedWarp {
    final map = this.map;
    if (map == null) return null;
    final id = view()?.selectedFor(map.id, MapSelectionFamily.warp);
    return map.warps.where((warp) => warp.id == id).firstOrNull;
  }

  WarpEditingCommands? get warps {
    final document = maps.active;
    final project = maps.project;
    return document == null || project == null
        ? null
        : WarpEditingCommands(document, project);
  }

  bool get placingWarp => view()?.tool == StudioMapTool.warp;

  List<MapConnection> get connections => [
    for (final connection in map?.connections ?? const <MapConnection>[])
      if (studioSearchMatches(
        '${mapName(connection.targetMapId)} '
        '${labels().direction(connection.direction)}',
        query,
      ))
        connection,
  ];

  List<MapWarp> get passages => [
    for (final warp in map?.warps ?? const <MapWarp>[])
      if (studioSearchMatches(warpLabel(warp), query)) warp,
  ];

  String warpLabel(MapWarp warp) =>
      warp.triggerMode == MapWarpTriggerMode.sceneOnly
      ? labels().arrivalPoint
      : mapName(warp.targetMapId);

  void selectConnection(MapConnectionDirection direction) =>
      _focusConnection(direction);

  void draftConnection() => _focusConnection(null);

  void _focusConnection(MapConnectionDirection? direction) {
    final map = this.map;
    final document = maps.active;
    if (map == null || document == null) return;
    view()?.clearSelection(document);
    release();
    _warpDraft = null;
    _spawnDraft = null;
    _connection = (mapId: map.id, direction: direction);
    links.error = null;
    changed();
  }

  void selectWarp(String id) {
    final document = maps.active;
    if (document == null) return;
    _connection = null;
    _warpDraft = null;
    _spawnDraft = null;
    warpError = null;
    release();
    view()?.select(document, MapSelectionFamily.warp, id);
    changed();
  }

  void selectSpawn(String id) {
    final document = maps.active;
    if (document == null) return;
    _connection = null;
    _warpDraft = null;
    _spawnDraft = null;
    entityError = null;
    release();
    view()?.select(document, MapSelectionFamily.marker, id);
    changed();
  }

  void armSpawn() {
    final state = view();
    final map = this.map;
    final document = maps.active;
    if (state == null || map == null || document == null) return;
    state.clearSelection(document);
    _connection = null;
    _warpDraft = null;
    entityError = null;
    _spawnDraft = (
      mapId: map.id,
      known: {for (final entity in map.entities) entity.id},
    );
    state.tool = StudioMapTool.spawn;
    changed();
  }

  void draftWarp() {
    final map = this.map;
    final document = maps.active;
    if (map == null || document == null) return;
    view()?.clearSelection(document);
    _connection = null;
    _spawnDraft = null;
    _warpDraft = (
      mapId: map.id,
      known: {for (final warp in map.warps) warp.id},
    );
    changed();
  }

  void armWarp(ProjectMapEntry destination) => _arm(
    (state) => state
      ..warpDestination = destination
      ..warpPlacementMode = MapWarpTriggerMode.onEnter,
  );

  void armArrival() =>
      _arm((state) => state.warpPlacementMode = MapWarpTriggerMode.sceneOnly);

  void _arm(void Function(MapWorkspaceEditingState state) configure) {
    final state = view();
    final map = this.map;
    if (state == null || map == null) return;
    _connection = null;
    _spawnDraft = null;
    _warpDraft = (
      mapId: map.id,
      known: {for (final warp in map.warps) warp.id},
    );
    configure(state);
    state.prepareWarpPlacement();
    changed();
  }

  Future<void> link(
    MapConnectionDirection direction,
    String targetMapId,
    int offset,
  ) async {
    await links.link(direction, targetMapId, offset);
    if (links.error == null && map != null) {
      _connection = (mapId: map!.id, direction: direction);
      changed();
    }
  }

  Future<void> unlink(MapConnectionDirection direction) async {
    await links.unlink(direction);
    if (links.error == null) {
      _connection = null;
      changed();
    }
  }

  void editEntities(void Function(MapEntityEditingCommands commands) edit) {
    final commands = entities;
    if (commands == null) return;
    try {
      edit(commands);
      entityError = null;
    } on StateError catch (failure) {
      entityError = failure.message;
    } on MapException catch (failure) {
      entityError = failure.message;
    } on FormatException catch (failure) {
      entityError = failure.message;
    }
    maps.notify();
  }

  void rejectWarp(String message) {
    warpError = message;
    maps.notify();
  }

  void editWarp(void Function(WarpEditingCommands commands) edit) {
    final commands = warps;
    if (commands == null) return;
    try {
      edit(commands);
      warpError = null;
    } on Object catch (failure) {
      warpError = failure.toString();
    }
    maps.notify();
  }
}
