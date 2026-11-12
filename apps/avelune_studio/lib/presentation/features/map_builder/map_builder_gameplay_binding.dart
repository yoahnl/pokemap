import 'package:map_core/map_core.dart';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_connection_actions.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/application/warp_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_connection_port.dart';
import 'package:avelune_studio/features/resources/domain/studio_search_text.dart';

String mapDirectionLabel(MapConnectionDirection direction) =>
    switch (direction) {
      MapConnectionDirection.north => 'Nord',
      MapConnectionDirection.east => 'Est',
      MapConnectionDirection.south => 'Sud',
      MapConnectionDirection.west => 'Ouest',
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
  }) : links = MapWorkspaceConnectionActions(
         controller: maps,
         port: port,
         isActive: isActive,
         changed: changed,
       );

  final MapWorkspaceController maps;
  final MapWorkspaceEditingState? Function() view;
  final void Function() changed;
  final MapWorkspaceConnectionActions links;
  ({String mapId, MapConnectionDirection? direction})? _connection;
  ({String mapId, Set<String> known})? _warpDraft;
  String query = '';
  String? warpError;

  MapData? get map => maps.active?.current;

  String mapName(String id) =>
      maps.project?.maps.where((entry) => entry.id == id).firstOrNull?.name ??
      'Carte introuvable';

  bool get draftingConnection =>
      _connection != null &&
      _connection!.mapId == map?.id &&
      _connection!.direction == null;

  bool get draftingWarp => _warpDraft != null && _warpDraft!.mapId == map?.id;

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
        '${mapDirectionLabel(connection.direction)}',
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
      ? 'Point d’arrivée'
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
    _connection = (mapId: map.id, direction: direction);
    links.error = null;
    changed();
  }

  void selectWarp(String id) {
    final document = maps.active;
    if (document == null) return;
    _connection = null;
    _warpDraft = null;
    warpError = null;
    release();
    view()?.select(document, MapSelectionFamily.warp, id);
    changed();
  }

  void draftWarp() {
    final map = this.map;
    final document = maps.active;
    if (map == null || document == null) return;
    view()?.clearSelection(document);
    _connection = null;
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
    if (state == null || state.tool != StudioMapTool.warp) return;
    state.tool = StudioMapTool.select;
    changed();
  }

  void leave() {
    _warpDraft = null;
    _connection = null;
    release();
  }

  void reconcile() {
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
