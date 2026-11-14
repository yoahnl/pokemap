part of 'map_builder_gameplay_binding.dart';

extension MapGameplayZoneEditing on MapBuilderGameplayBinding {
  bool get draftingZone => _zoneDraft != null && _zoneDraft!.mapId == map?.id;

  MapGameplayZone? get selectedZone {
    final map = this.map;
    if (map == null) return null;
    final id = view()?.selectedFor(map.id, MapSelectionFamily.zone);
    return map.gameplayZones.where((zone) => zone.id == id).firstOrNull;
  }

  GameplayZoneEditingCommands? get zones {
    final document = maps.active;
    final project = maps.project;
    return document == null || project == null
        ? null
        : GameplayZoneEditingCommands(document, project);
  }

  List<MapGameplayZone> get movementZones => [
    for (final zone in map?.gameplayZones ?? const <MapGameplayZone>[])
      if (mapBuilderMovementZoneKinds.contains(zone.kind) &&
          studioSearchMatches(zone.name, query))
        zone,
  ];

  List<MapGameplayZone> get encounterZones => [
    for (final zone in map?.gameplayZones ?? const <MapGameplayZone>[])
      if (zone.kind == GameplayZoneKind.encounter &&
          studioSearchMatches(zone.name, query))
        zone,
  ];

  bool get encounterTablesReady =>
      maps.hasWorkshop(MapWorkspaceWorkshop.pokemon);

  Future<void> _loadEncounterTables() async {
    if (encounterTablesReady) return;
    try {
      await maps.ensureWorkshop(MapWorkspaceWorkshop.pokemon);
      encounterTablesError = null;
    } on MapWorkspaceFailure catch (failure) {
      encounterTablesError = failure.message;
    } on Object catch (failure) {
      encounterTablesError = '$failure';
    }
    changed();
  }

  List<ProjectEncounterTable> get encounterTables =>
      zones?.encounterTables() ?? const [];

  bool get paintsEncounters => map != null && map!.spatialScene == null;

  int get blockedCells => [
    for (final layer
        in map?.layers.whereType<CollisionLayer>() ?? const <CollisionLayer>[])
      for (final blocked in layer.collisions)
        if (blocked) 1,
  ].length;

  void armCollisions({required bool erase}) {
    final state = view();
    final document = maps.active;
    if (state == null || document == null) return;
    final wanted = erase
        ? StudioMapTool.collisionErase
        : StudioMapTool.collisionPaint;
    if (state.tool == wanted) {
      release();
      return;
    }
    state.clearSelection(document);
    _clearDrafts();
    state.tool = wanted;
    changed();
  }

  void armEncounterBrush({required bool erase, bool fresh = false}) {
    final state = view();
    final document = maps.active;
    if (state == null || document == null || !paintsEncounters) return;
    final wanted = erase
        ? StudioMapTool.encounterErase
        : StudioMapTool.encounterPaint;
    if (state.tool == wanted && !fresh) {
      release();
      return;
    }
    if (fresh) state.clearSelection(document);
    _clearDrafts();
    zoneError = null;
    state.tool = wanted;
    changed();
  }

  void armZone(GameplayZoneKind kind) {
    final state = view();
    final map = this.map;
    final document = maps.active;
    if (state == null || map == null || document == null) return;
    state.clearSelection(document);
    _clearDrafts();
    zoneError = null;
    _zoneDraft = (
      mapId: map.id,
      known: {for (final zone in map.gameplayZones) zone.id},
    );
    state
      ..zoneKind = kind
      ..tool = StudioMapTool.gameplayZone;
    changed();
  }

  void selectZone(String id) {
    final document = maps.active;
    if (document == null) return;
    _clearDrafts();
    zoneError = null;
    release();
    view()?.select(document, MapSelectionFamily.zone, id);
    changed();
  }

  void editZones(void Function(GameplayZoneEditingCommands commands) edit) {
    final commands = zones;
    if (commands == null) return;
    try {
      edit(commands);
      zoneError = null;
    } on MapException catch (failure) {
      zoneError = failure.message;
    } on StateError catch (failure) {
      zoneError = failure.message;
    }
    maps.notify();
  }
}
