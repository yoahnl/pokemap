part of 'map_character_gesture.dart';

MapCharacterGesture? _startMapCharacterGesture({
  required EditableMapDocument document,
  required ProjectManifest project,
  required MapWorkspaceEditingState view,
  required GridPos origin,
}) {
  view.reconcileLocks(document);
  final commands = CharacterEditingCommands(document, project);
  final size = document.current.size;
  if (origin.x < 0 ||
      origin.y < 0 ||
      origin.x >= size.width ||
      origin.y >= size.height) {
    return null;
  }
  MapCharacterGesture holding(MapEntity? entity, {MapWarp? warp}) {
    document.stackPosition = origin;
    return MapCharacterGesture._(
      document,
      project,
      view,
      origin,
      entity,
      false,
      warp: warp,
    );
  }

  final armed = view.pendingMove;
  if (armed != null &&
      armed.mapId == document.current.id &&
      armed.family != MapSelectionFamily.decor) {
    return MapCharacterGesture._(
      document,
      project,
      view,
      origin,
      armed.family == MapSelectionFamily.character ||
              armed.family == MapSelectionFamily.marker
          ? document.current.entities
                .where((entry) => entry.id == armed.id)
                .firstOrNull
          : null,
      false,
      warp: armed.family == MapSelectionFamily.warp
          ? document.current.warps
                .where((entry) => entry.id == armed.id)
                .firstOrNull
          : null,
      armed: armed,
    );
  }
  if (view.tool == StudioMapTool.zone ||
      view.tool == StudioMapTool.gameplayZone) {
    return MapCharacterGesture._(document, project, view, origin, null, true);
  }
  if (view.tool == StudioMapTool.fieldObstacle) {
    final brush = view.brush;
    if (brush == null) {
      document.error =
          'Choisissez le visuel de cet obstacle dans la barre d’outils.';
      return holding(null);
    }
    final entity = MapEntityEditingCommands(document, project)
        .placeFieldObstacle(
          position: origin,
          elementId: brush.id,
          kind: view.fieldObstacleKind,
          resetPolicy: view.fieldObstacleResetPolicy,
        );
    view.select(document, MapSelectionFamily.marker, entity.id);
    return holding(null);
  }
  final placed = switch (view.tool) {
    StudioMapTool.spawn => MapEntityKind.spawn,
    StudioMapTool.sign => MapEntityKind.sign,
    _ => null,
  };
  if (placed != null) {
    final entity = MapEntityEditingCommands(
      document,
      project,
    ).place(placed, origin);
    view.select(document, MapSelectionFamily.marker, entity.id);
    return holding(null);
  }
  if (view.tool == StudioMapTool.warp &&
      (view.warpPlacementMode == MapWarpTriggerMode.sceneOnly ||
          view.warpDestination != null)) {
    final warpCommands = WarpEditingCommands(document, project);
    final placedWarp = view.warpPlacementMode == MapWarpTriggerMode.sceneOnly
        ? warpCommands.placeArrival(origin)
        : warpCommands.place(view.warpDestination!, origin);
    view.select(document, MapSelectionFamily.warp, placedWarp.id);
    return holding(null);
  }
  if (view.tool == StudioMapTool.character && view.character != null) {
    final entity = commands.place(view.character!, origin);
    view.select(document, MapSelectionFamily.character, entity.id);
    return holding(null);
  }
  if (view.tool != StudioMapTool.select) return null;
  final hits = commands
      .at(origin)
      .where(
        (entry) => !view.isUnavailable(
          document,
          MapSelectionFamily.character,
          entry.id,
        ),
      )
      .toList();
  if (hits.isEmpty) {
    final placements = MapEntityEditingCommands(document, project)
        .at(origin)
        .where(
          (entry) => !view.isUnavailable(
            document,
            MapSelectionFamily.marker,
            entry.id,
          ),
        )
        .toList();
    final marker =
        placements
            .where(
              (entry) =>
                  entry.id ==
                  view.selectedFor(
                    document.current.id,
                    MapSelectionFamily.marker,
                  ),
            )
            .firstOrNull ??
        placements.firstOrNull;
    if (marker != null) {
      view.select(document, MapSelectionFamily.marker, marker.id);
      return holding(marker);
    }
    final warps = WarpEditingCommands(document, project)
        .at(origin)
        .where(
          (entry) =>
              !view.isUnavailable(document, MapSelectionFamily.warp, entry.id),
        )
        .toList();
    final chosen =
        warps
            .where(
              (entry) =>
                  entry.id ==
                  view.selectedFor(
                    document.current.id,
                    MapSelectionFamily.warp,
                  ),
            )
            .firstOrNull ??
        warps.firstOrNull;
    if (chosen != null) {
      view.select(document, MapSelectionFamily.warp, chosen.id);
      return holding(null, warp: chosen);
    }
  }
  final selected = hits
      .where(
        (entry) =>
            entry.id ==
            view.selectedFor(document.current.id, MapSelectionFamily.character),
      )
      .firstOrNull;
  final selectedDecorHere =
      document.selected != null &&
      MapEditingCommands(
        document,
        project,
      ).stack(origin).any((entry) => entry.id == document.selectedId);
  if (hits.isEmpty || (selected == null && selectedDecorHere)) {
    return null;
  }
  final entity = selected ?? hits.first;
  view.select(document, MapSelectionFamily.character, entity.id);
  return holding(entity);
}
