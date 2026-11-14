part of 'spatial_map_editing_viewport.dart';

extension _SpatialGestureFlow on _SpatialMapEditingViewportState {
  bool get locked =>
      editingExterior && !widget.exteriorContextReady ||
      exterior?.saving == true ||
      editingDocument.saving ||
      widget.controller.catalogLocks(editingDocument.base.mapId);
  bool get selectingTerrainSurface =>
      widget.view.tool == StudioMapTool.terrain &&
      widget.view.spatialTerrainMode == SpatialTerrainMode.relief &&
      widget.view.spatialContinuousTerrain &&
      widget.view.spatialSurfaceSelect;

  void selectTerrainSurfaceAt(double x, double z) {
    SpatialTerrainSurface? selected;
    for (final surface
        in editingDocument.current.spatialScene!.terrainSurfaces.surfaces) {
      if (surface.contains(x, z) &&
          (selected == null ||
              surface.heightAt(x, z) >= selected.heightAt(x, z))) {
        selected = surface;
      }
    }
    widget.view.spatialSurfaceId = selected?.id;
    widget.view.terrainSurfacePreview = null;
    widget.onChanged();
  }

  bool get contentGestureValid =>
      !locked &&
      (modelGesture == null ||
          !editingDocument.isElementUnavailable('model', modelGesture!)) &&
      gesture?.isLocked != true &&
      widget.view.tool == StudioMapTool.select &&
      gestureFreeView == widget.view.spatialFreeView &&
      identical(contentSource, editingDocument.current) &&
      identical(contentProject, widget.project);

  bool get terrainGestureValid =>
      !locked &&
      terrainTool == widget.view.tool &&
      gestureFreeView == widget.view.spatialFreeView &&
      identical(terrainSource, editingDocument.current) &&
      identical(terrainProject, widget.project) &&
      (!widget.view.spatialSurfaceSelect ||
          reliefStroke?.surfaceBrush == null) &&
      (terrainSurfaceOptions == null ||
          terrainSurfaceOptions == widget.view.terrainSurfaceOptions) &&
      (terrainStroke == null || terrainStroke!.matches(widget.view)) &&
      (reliefStroke == null ||
          reliefStroke!.mode == widget.view.spatialTerrainMode &&
              reliefStroke!.level == widget.view.spatialTerrainLevel);

  SpatialSceneContentPreview? get contentPreview {
    if (!contentGestureValid) return null;
    final scene = editingDocument.current.spatialScene!;
    if (modelGesture != null && modelEnd != null) {
      final x = modelPosition!.x + modelEnd!.x - modelOrigin!.x;
      final z = modelPosition!.z + modelEnd!.y - modelOrigin!.y;
      return SpatialSceneContentPreview(
        kind: SpatialSceneContentKind.model,
        id: modelGesture!,
        position: Model3dVector3(
          x: x,
          y:
              scene.worldHeightAt(x, z) +
              modelPosition!.y -
              scene.worldHeightAt(modelPosition!.x, modelPosition!.z),
          z: z,
        ),
      );
    }
    final entity = gesture?.entity;
    final destination = gesture?.destination;
    if (entity == null ||
        entity.kind != MapEntityKind.npc ||
        destination == null) {
      return null;
    }
    final x = destination.x + .5, z = destination.y + .5;
    return SpatialSceneContentPreview(
      kind: SpatialSceneContentKind.actor,
      id: 'npc:${entity.id}',
      position: Model3dVector3(x: x, y: scene.worldHeightAt(x, z), z: z),
    );
  }

  void discardGesture() {
    contentSource = null;
    contentProject = null;
    nudgeKeys.clear();
    gestureFreeView = null;
    terrainStroke = null;
    environmentGesture = null;
    reliefStroke = null;
    terrainSource = null;
    terrainProject = null;
    terrainTool = null;
    terrainSurfaceOptions = null;
    gesture = null;
    modelGesture = null;
    modelEnd = null;
    modelOrigin = null;
    modelPosition = null;
    widget.view.pendingMove = null;
  }

  void cancel() {
    if (_exteriorGestureActive) exterior?.cancelGesture();
    _exteriorGestureActive = false;
    _exteriorLastCell = null;
    discardGesture();
    if (widget.view.tool == StudioMapTool.border) discardBorder();
    widget.onChanged();
  }

  void finish() {
    finishSegment();
    if (_exteriorGestureActive) exterior?.endGesture();
    _exteriorGestureActive = false;
    _exteriorLastCell = null;
  }

  void finishSegment() {
    if (borderEraseDraft != null || exteriorBorderEraseActive) {
      finishBorderErase();
      return;
    }
    if (locked ||
        (contentSource != null && !contentGestureValid) ||
        (terrainSource != null && !terrainGestureValid) ||
        (environmentGesture != null && !environmentGestureValid) ||
        (gestureFreeView != null &&
            gestureFreeView != widget.view.spatialFreeView)) {
      cancel();
      return;
    }
    if (environmentGesture != null) {
      finishEnvironment();
      return;
    }
    gestureFreeView = null;
    contentSource = null;
    contentProject = null;
    nudgeKeys.clear();
    final stroke = terrainStroke;
    final relief = reliefStroke;
    final source = terrainSource;
    final tool = terrainTool;
    terrainStroke = null;
    reliefStroke = null;
    terrainSource = null;
    terrainProject = null;
    terrainTool = null;
    terrainSurfaceOptions = null;
    if (stroke != null || relief != null) {
      if (!locked &&
          identical(editingDocument.current, source) &&
          widget.view.tool == tool &&
          (relief == null ||
              relief.mode == widget.view.spatialTerrainMode &&
                  relief.level == widget.view.spatialTerrainLevel)) {
        try {
          editingDocument.commit(relief?.commit() ?? stroke!.commit());
          if (relief?.surfaceId != null) {
            widget.view.spatialSurfaceId = relief!.surfaceId;
          }
        } on Object catch (failure) {
          editingDocument.error = failure.toString();
        }
      }
      widget.onChanged();
      return;
    }
    if (modelGesture != null && modelEnd != null) {
      try {
        SpatialModelEditingCommands(editingDocument, widget.project).update(
          modelGesture!,
          x: modelPosition!.x + modelEnd!.x - modelOrigin!.x,
          z: modelPosition!.z + modelEnd!.y - modelOrigin!.y,
        );
      } on Object catch (failure) {
        editingDocument.error = failure.toString();
      }
      widget.view.pendingMove = null;
    }
    modelGesture = null;
    modelEnd = null;
    modelOrigin = null;
    modelPosition = null;
    if (widget.view.tool == StudioMapTool.gameplayZone) {
      try {
        gesture?.commit();
      } on Object catch (failure) {
        editingDocument.error = failure.toString();
      }
    } else {
      final area = gesture?.commit();
      if (area != null) widget.onZoneDrawn?.call(area);
    }
    gesture = null;
    widget.onChanged();
  }

  void tap(int x, int z) {
    start(x, z);
    finish();
  }

  void updateDrag((int, int) cell) {
    if (borderEraseDraft != null || exteriorBorderEraseActive) {
      sampleBorderErase(GridPos(x: cell.$1, y: cell.$2));
      widget.onChanged();
      return;
    }
    if (environmentGesture != null) {
      if (!environmentGestureValid) {
        cancel();
        return;
      }
      environmentGesture!.paint(GridPos(x: cell.$1, y: cell.$2));
      widget.onChanged();
      return;
    }
    if (contentSource != null && !contentGestureValid) {
      cancel();
      return;
    }
    if (terrainSource != null && !terrainGestureValid) {
      cancel();
      return;
    }
    if (terrainStroke != null && !locked) {
      try {
        terrainStroke!.paint(GridPos(x: cell.$1, y: cell.$2));
      } on Object catch (error) {
        editingDocument.error = error.toString();
        cancel();
        return;
      }
      widget.onChanged();
    }
    if (reliefStroke != null && !locked) {
      reliefStroke!.paint(GridPos(x: cell.$1, y: cell.$2));
      editingDocument.error = reliefStroke!.error;
      widget.onChanged();
    }
    gesture?.end = GridPos(x: cell.$1, y: cell.$2);
    final moving = gesture;
    final sourcePosition = moving?.entity?.pos ?? moving?.warp?.pos;
    final destination = moving?.destination;
    if (moving != null && sourcePosition != null && destination != null) {
      moving.end = GridPos(
        x: moving.origin.x + destination.x - sourcePosition.x,
        y: moving.origin.y + destination.y - sourcePosition.y,
      );
    }
    if (modelGesture != null) {
      final scene = editingDocument.current.spatialScene!;
      final x = modelPosition!.x.floor(), z = modelPosition!.z.floor();
      modelEnd = GridPos(
        x:
            modelOrigin!.x +
            (x + cell.$1 - modelOrigin!.x).clamp(0, scene.width - 1) -
            x,
        y:
            modelOrigin!.y +
            (z + cell.$2 - modelOrigin!.y).clamp(0, scene.depth - 1) -
            z,
      );
    }
    if (contentSource != null) widget.onChanged();
  }
}
