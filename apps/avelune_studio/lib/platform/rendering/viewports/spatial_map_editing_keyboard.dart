part of 'spatial_map_editing_viewport.dart';

extension _SpatialKeyboardEditing on _SpatialMapEditingViewportState {
  bool get textEditing =>
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<EditableText>() !=
      null;

  KeyEventResult handleKey(KeyEvent event, LogicalKeyboardKey key) {
    final delta = switch (key) {
      LogicalKeyboardKey.arrowLeft => (-1, 0),
      LogicalKeyboardKey.arrowRight => (1, 0),
      LogicalKeyboardKey.arrowUp => (0, -1),
      LogicalKeyboardKey.arrowDown => (0, 1),
      _ => null,
    };
    if (event is KeyUpEvent && cameraKeys.remove(key)) {
      return KeyEventResult.handled;
    }
    if (event is KeyRepeatEvent && cameraKeys.contains(key) && !precision) {
      return KeyEventResult.handled;
    }
    if (event is KeyRepeatEvent &&
        !cameraKeys.contains(key) &&
        !nudgeKeys.contains(key)) {
      return KeyEventResult.ignored;
    }
    if (event is KeyDownEvent && widget.view.tool == StudioMapTool.border) {
      if (key == LogicalKeyboardKey.escape) {
        discardBorder();
        widget.onChanged();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter) {
        finishBorder();
        return KeyEventResult.handled;
      }
    }
    if (event is KeyDownEvent &&
        (key == LogicalKeyboardKey.delete ||
            key == LogicalKeyboardKey.backspace) &&
        !precision &&
        !HardwareKeyboard.instance.isControlPressed &&
        !HardwareKeyboard.instance.isMetaPressed &&
        !HardwareKeyboard.instance.isAltPressed) {
      final id = widget.view.selectedFor(
        editingDocument.current.id,
        MapSelectionFamily.decor,
      );
      final commands = SpatialModelEditingCommands(
        editingDocument,
        widget.project,
      );
      if (id != null &&
          commands.selected(id) != null &&
          !editingDocument.isElementUnavailable('model', id)) {
        if (!locked) {
          discardGesture();
          try {
            if (commands.delete(id)) {
              widget.view.clearSelection(editingDocument);
            }
          } on Object catch (failure) {
            editingDocument.error = failure.toString();
          }
          widget.onChanged();
        }
        return KeyEventResult.handled;
      }
    }
    if (event is! KeyUpEvent &&
        delta != null &&
        !locked &&
        HardwareKeyboard.instance.isShiftPressed &&
        !HardwareKeyboard.instance.isControlPressed &&
        !HardwareKeyboard.instance.isMetaPressed &&
        !HardwareKeyboard.instance.isAltPressed) {
      if (nudgeKeys.isNotEmpty) finish();
      cameraKeys.add(key);
      widget.view.spatialFreeView = true;
      syncCameraView(preserveGesture: true);
      camera.orbit(delta.$1 * 12, delta.$2 * 12);
      widget.onChanged();
      return KeyEventResult.handled;
    }
    if (event is KeyDownEvent &&
        key == LogicalKeyboardKey.escape &&
        (contentSource != null ||
            reliefStroke != null ||
            terrainStroke != null ||
            environmentGesture != null ||
            widget.view.rampPreview != null ||
            widget.view.terrainSurfacePreview != null ||
            (selectingTerrainSurface && widget.view.spatialSurfaceId != null) ||
            widget.view.hasSelectionIn(editingDocument.current.id) ||
            widget.view.pendingMove != null ||
            widget.view.tool == StudioMapTool.place)) {
      discardGesture();
      widget.view.rampPreview = null;
      widget.view.terrainSurfacePreview = null;
      widget.view.spatialSurfaceId = null;
      hover = null;
      if (widget.view.tool == StudioMapTool.place) {
        widget.view.tool = StudioMapTool.select;
      }
      widget.view.clearSelection(editingDocument);
      widget.onChanged();
      return KeyEventResult.handled;
    }
    if (event is KeyUpEvent && nudgeKeys.remove(key)) {
      if (nudgeKeys.isEmpty) finish();
      return KeyEventResult.handled;
    }
    if (event is KeyUpEvent ||
        locked ||
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isAltPressed ||
        widget.view.tool != StudioMapTool.select ||
        (contentSource != null && nudgeKeys.isEmpty)) {
      return KeyEventResult.ignored;
    }
    if (delta == null) return KeyEventResult.ignored;
    if (nudgeKeys.isEmpty) {
      final map = editingDocument.current;
      final modelId = widget.view.selectedFor(map.id, MapSelectionFamily.decor);
      final model = modelId == null
          ? null
          : SpatialModelEditingCommands(
              editingDocument,
              widget.project,
            ).selected(modelId);
      final npc = map.entities
          .where(
            (entity) =>
                entity.id ==
                widget.view.selectedFor(map.id, MapSelectionFamily.character),
          )
          .firstOrNull;
      final marker = map.entities
          .where(
            (entity) =>
                entity.id ==
                widget.view.selectedFor(map.id, MapSelectionFamily.marker),
          )
          .firstOrNull;
      final warp = map.warps
          .where(
            (warp) =>
                warp.id ==
                widget.view.selectedFor(map.id, MapSelectionFamily.warp),
          )
          .firstOrNull;
      final hit = marker != null
          ? SpatialSceneContentHit(
              kind: SpatialSceneContentKind.marker,
              id: marker.id,
              cell: (marker.pos.x, marker.pos.y),
            )
          : warp != null
          ? SpatialSceneContentHit(
              kind: SpatialSceneContentKind.warp,
              id: warp.id,
              cell: (warp.pos.x, warp.pos.y),
            )
          : model != null
          ? SpatialSceneContentHit(
              kind: SpatialSceneContentKind.model,
              id: model.id,
              cell: (model.position.x.floor(), model.position.z.floor()),
            )
          : npc != null
          ? SpatialSceneContentHit(
              kind: SpatialSceneContentKind.actor,
              id: 'npc:${npc.id}',
              cell: (npc.pos.x, npc.pos.y),
            )
          : null;
      if (hit == null || !start(hit.cell.$1, hit.cell.$2, hit: hit)) {
        return KeyEventResult.ignored;
      }
    }
    nudgeKeys.add(key);
    final position = modelEnd ?? modelOrigin ?? gesture!.end;
    updateDrag((position.x + delta.$1, position.y + delta.$2));
    return KeyEventResult.handled;
  }
}
