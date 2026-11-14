part of 'spatial_map_editing_viewport.dart';

extension _SpatialReliefEditing on _SpatialMapEditingViewportState {
  bool startRelief(GridPos cell) {
    final tool = widget.view.tool;
    widget.view.slope.outcome = null;
    if (tool == StudioMapTool.stair) {
      MapSlopeCommands(
        editingDocument,
        widget.project,
      ).placeStair(cell, widget.view.slope);
      widget.onChanged();
      return false;
    }
    final state = widget.view.relief;
    final keys = HardwareKeyboard.instance;
    state.outcome = null;
    if (tool == StudioMapTool.relief && keys.isAltPressed) {
      state.pick(editingDocument.current, cell);
      widget.onChanged();
      return false;
    }
    reliefPaint = MapReliefStroke(
      source: editingDocument.current,
      origin: cell,
      level: state.level,
      rectangle: tool == StudioMapTool.slope || keys.isShiftPressed,
    );
    terrainSource = editingDocument.current;
    terrainProject = widget.project;
    terrainTool = widget.view.tool;
    widget.onChanged();
    return true;
  }

  void finishRelief(MapReliefStroke stroke) {
    if (widget.view.tool == StudioMapTool.slope) {
      MapSlopeCommands(
        editingDocument,
        widget.project,
      ).paintSlope(stroke.source, stroke.origin, stroke.end, widget.view.slope);
    } else {
      MapReliefCommands(
        editingDocument,
        widget.project,
      ).apply(stroke, widget.view.relief);
    }
    widget.onChanged();
  }

  KeyEventResult reliefKey(KeyEvent event, LogicalKeyboardKey key) {
    if (widget.view.tool != StudioMapTool.relief ||
        event is KeyUpEvent ||
        locked) {
      return KeyEventResult.ignored;
    }
    final delta = switch (key) {
      LogicalKeyboardKey.equal ||
      LogicalKeyboardKey.add ||
      LogicalKeyboardKey.numpadAdd => 1,
      LogicalKeyboardKey.minus || LogicalKeyboardKey.numpadSubtract => -1,
      _ => null,
    };
    if (delta == null) return KeyEventResult.ignored;
    widget.view.relief.step(editingDocument.current, delta);
    widget.onChanged();
    return KeyEventResult.handled;
  }

  List<SpatialCellOverlay> reliefOverlays(ColorScheme colors) {
    final tool = widget.view.tool;
    if (tool == StudioMapTool.slope || tool == StudioMapTool.stair) {
      return slopeOverlays(colors);
    }
    if (tool != StudioMapTool.relief) return const [];
    final stroke = reliefPaint;
    final scene = editingDocument.current.spatialScene!;
    final height =
        stroke?.targetHeight ?? widget.view.relief.level * scene.levelHeight;
    final cells =
        stroke?.contour.map((cell) => (cell.x, cell.y)) ??
        [if (hover != null) hover!.cell];
    return [
      for (final cell in cells)
        SpatialCellOverlay(
          id: 'relief:${cell.$1}:${cell.$2}',
          cell: cell,
          kind: SpatialCellOverlayKind.preview,
          color: colors.primary,
          targetHeight: height,
        ),
    ];
  }
}

extension _SpatialSlopeEditing on _SpatialMapEditingViewportState {
  List<SpatialCellOverlay> slopeOverlays(ColorScheme colors) {
    final map = editingDocument.current;
    final stroke = reliefPaint;
    final hovered = hover?.cell;
    final plan = stroke != null
        ? mapSlopePreview(map, stroke.origin, stroke.end)
        : widget.view.tool == StudioMapTool.stair && hovered != null
        ? mapStairPreview(
            widget.project,
            map,
            GridPos(x: hovered.$1, y: hovered.$2),
            widget.view.slope.stairModelId,
          )
        : null;
    final cells =
        plan?.cells.map((cell) => (cell.x, cell.y)) ??
        stroke?.cells.map((cell) => (cell.x, cell.y)) ??
        [?hovered];
    return [
      for (final cell in cells)
        SpatialCellOverlay(
          id: 'slope:${cell.$1}:${cell.$2}',
          cell: cell,
          kind: SpatialCellOverlayKind.preview,
          color: plan == null && stroke != null ? colors.error : colors.primary,
        ),
    ];
  }
}
