import 'dart:async';

import 'package:map_core/map_core.dart';

import 'package:avelune_studio/features/map_workspace/application/gameplay_zone_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_field_obstacle_eligibility.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_model_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_connection_actions.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/application/warp_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_connection_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/resources/domain/studio_search_text.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_labels.dart';

const mapBuilderGameplayRubrics = {
  'connections',
  'movement',
  'encounters',
  'spawns',
  'fieldObjects',
};

const mapBuilderMovementZoneKinds = {
  GameplayZoneKind.movement,
  GameplayZoneKind.movementEffect,
};

MapConnectionPort? configuredConnectionPort(MapConnectionPort Function() read) {
  try {
    return read();
  } on Object {
    return null;
  }
}

class MapBuilderGameplayBinding {
  MapBuilderGameplayBinding({
    required this.maps,
    required this.view,
    required MapConnectionPort? port,
    required bool Function() isActive,
    required this.changed,
    required this.labels,
    this.entityDeletionProblem,
    this.storyProject,
  }) : links = MapWorkspaceConnectionActions(
         controller: maps,
         port: port,
         isActive: isActive,
         changed: changed,
       );

  final MapWorkspaceController maps;
  final MapWorkspaceEditingState? Function() view;
  final void Function() changed;
  final AppLocalizations Function() labels;
  final String? Function(String entityId)? entityDeletionProblem;
  final ProjectManifest Function(ProjectManifest project)? storyProject;
  final MapWorkspaceConnectionActions links;
  ({String mapId, MapConnectionDirection? direction})? _connection;
  ({String mapId, Set<String> known})? _warpDraft;
  ({String mapId, Set<String> known})? _spawnDraft;
  ({String mapId, Set<String> known})? _zoneDraft;
  ({String mapId, Set<String> known, FieldObstacleKind kind})? _obstacleDraft;
  bool shown = false;
  String rubric = 'connections';
  String query = '';
  String? warpError;
  String? entityError;
  String? zoneError;
  String? encounterTablesError;

  MapData? get map => maps.active?.current;

  String mapName(String id) =>
      maps.project?.maps.where((entry) => entry.id == id).firstOrNull?.name ??
      labels().mapMissing;

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
        .where((entity) => entity.id == id && entity.kind == MapEntityKind.spawn)
        .firstOrNull;
  }

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

  bool get spatial => map?.spatialScene != null;

  List<MapEntity> get obstacles => [
    for (final entity in map?.entities ?? const <MapEntity>[])
      if (entity.fieldObstacle != null &&
          studioSearchMatches(entity.name, query))
        entity,
  ];

  FieldObstacleKind? get draftingObstacle {
    final draft = _obstacleDraft;
    return draft != null && draft.mapId == map?.id ? draft.kind : null;
  }

  List<ProjectElementEntry> get obstacleVisuals =>
      maps.project?.elements ?? const [];

  ProjectElementEntry? get obstacleVisual => view()?.brush;

  MapEntity? get selectedObstacle {
    final map = this.map;
    if (map == null) return null;
    final id = view()?.selectedFor(map.id, MapSelectionFamily.marker);
    return map.entities
        .where((entity) => entity.id == id && entity.fieldObstacle != null)
        .firstOrNull;
  }

  SpatialModelInstance? get selectedInstance {
    final map = this.map;
    final scene = map?.spatialScene;
    if (map == null || scene == null) return null;
    final id = view()?.selectedFor(map.id, MapSelectionFamily.decor);
    return scene.instances.where((instance) => instance.id == id).firstOrNull;
  }

  MapEntity? boundEntity(SpatialModelInstance instance) => map?.entities
      .where((entity) => entity.id == instance.entityId)
      .firstOrNull;

  String? obstacleRefusal(SpatialModelInstance instance) =>
      spatialFieldObstacleRefusal(
        instance,
        maps.project?.models3d
            .where((model) => model.id == instance.modelId)
            .firstOrNull,
        boundEntity(instance),
      );

  int get blockedCells => [
    for (final layer
        in map?.layers.whereType<CollisionLayer>() ??
            const <CollisionLayer>[])
      for (final blocked in layer.collisions)
        if (blocked) 1,
  ].length;

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

  bool get placing => switch (view()?.tool) {
    StudioMapTool.warp ||
    StudioMapTool.spawn ||
    StudioMapTool.collisionPaint ||
    StudioMapTool.collisionErase ||
    StudioMapTool.encounterPaint ||
    StudioMapTool.encounterErase ||
    StudioMapTool.fieldObstacle ||
    StudioMapTool.gameplayZone => true,
    _ => false,
  };

  StudioMapTool? get tool => view()?.tool;

  void openRubric(String id) {
    if (id == rubric) return;
    final document = maps.active;
    if (document != null) view()?.clearSelection(document);
    leave();
    rubric = id;
    query = '';
    reconcile();
    changed();
    if (id == 'encounters') unawaited(_loadEncounterTables());
  }

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

  void search(String value) {
    query = value;
    changed();
  }

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

  void draftObstacle(FieldObstacleKind kind) {
    final state = view();
    final map = this.map;
    final document = maps.active;
    if (state == null || map == null || document == null) return;
    state.clearSelection(document);
    _clearDrafts();
    entityError = null;
    _obstacleDraft = (
      mapId: map.id,
      known: {for (final entity in map.entities) entity.id},
      kind: kind,
    );
    state
      ..selectFieldObstacleKind(kind)
      ..brush = null
      ..tool = StudioMapTool.select;
    changed();
  }

  void chooseObstacleVisual(ProjectElementEntry element) {
    final state = view();
    final kind = draftingObstacle;
    if (state == null || kind == null) return;
    state.brush = element;
    state.prepareFieldObstaclePlacement(kind);
    changed();
  }

  void selectObstacle(MapEntity entity) {
    final document = maps.active;
    if (document == null) return;
    _clearDrafts();
    entityError = null;
    release();
    final instance = map?.spatialScene?.instances
        .where((instance) => instance.entityId == entity.id)
        .firstOrNull;
    if (instance != null) {
      view()?.select(document, MapSelectionFamily.decor, instance.id);
    } else {
      view()?.select(document, MapSelectionFamily.marker, entity.id);
    }
    changed();
  }

  Future<void> configureInstanceObstacle(
    String instanceId,
    MapEntityFieldObstacleData? value,
  ) async {
    final document = maps.active;
    final project = maps.project;
    if (document == null || project == null) return;
    final configured = await SpatialModelEditingCommands(
      document,
      project,
    ).configureFieldObstacle(instanceId, value);
    entityError = configured ? null : document.error;
    maps.notify();
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

  void _clearDrafts() {
    _obstacleDraft = null;
    _connection = null;
    _warpDraft = null;
    _spawnDraft = null;
    _zoneDraft = null;
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

  void release() {
    final state = view();
    if (state == null || !placing) return;
    state.tool = StudioMapTool.select;
    changed();
  }

  void leave() {
    _obstacleDraft = null;
    _warpDraft = null;
    _spawnDraft = null;
    _zoneDraft = null;
    view()
      ?..revealCollisions = false
      ..revealedZones = const {};
    _connection = null;
    release();
  }

  void reconcile() {
    view()
      ?..revealCollisions = shown && rubric == 'movement'
      ..revealedZones = !shown
          ? const {}
          : switch (rubric) {
              'movement' => mapBuilderMovementZoneKinds,
              'encounters' => const {GameplayZoneKind.encounter},
              _ => const {},
            };
    final zoneDraft = _zoneDraft;
    final drawn = this.map;
    if (zoneDraft != null &&
        drawn != null &&
        zoneDraft.mapId == drawn.id &&
        (selectedZone != null ||
            drawn.gameplayZones.any(
              (zone) => !zoneDraft.known.contains(zone.id),
            ))) {
      _zoneDraft = null;
      view()?.tool = StudioMapTool.select;
    }
    final obstacleDraft = _obstacleDraft;
    final dropped = this.map;
    if (obstacleDraft != null &&
        dropped != null &&
        obstacleDraft.mapId == dropped.id &&
        dropped.entities.any(
          (entity) => !obstacleDraft.known.contains(entity.id),
        )) {
      _obstacleDraft = null;
      view()?.tool = StudioMapTool.select;
    }
    final spawnDraft = _spawnDraft;
    final placed = this.map;
    if (spawnDraft != null &&
        placed != null &&
        spawnDraft.mapId == placed.id &&
        placed.entities.any(
          (entity) => !spawnDraft.known.contains(entity.id),
        )) {
      _spawnDraft = null;
      view()?.tool = StudioMapTool.select;
    }
    final draft = _warpDraft;
    final map = this.map;
    if (draft == null || map == null || draft.mapId != map.id) return;
    if (map.warps.any((warp) => !draft.known.contains(warp.id))) {
      _warpDraft = null;
      view()?.tool = StudioMapTool.select;
    }
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

class _GuardedEntityCommands extends MapEntityEditingCommands {
  _GuardedEntityCommands(super.document, super.project, this._problem);

  final String? Function(String entityId)? _problem;

  @override
  String? deletionProblem(String id) =>
      _problem?.call(id) ?? super.deletionProblem(id);
}
