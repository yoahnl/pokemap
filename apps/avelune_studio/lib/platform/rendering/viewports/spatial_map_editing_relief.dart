part of 'spatial_map_editing_viewport.dart';

extension _SpatialReliefEditing on _SpatialMapEditingViewportState {
  bool startRelief(GridPos cell) {
    final state = widget.view.relief;
    final keys = HardwareKeyboard.instance;
    state.outcome = null;
    if (keys.isAltPressed) {
      state.pick(editingDocument.current, cell);
      widget.onChanged();
      return false;
    }
    reliefPaint = MapReliefStroke(
      source: editingDocument.current,
      origin: cell,
      level: state.level,
      rectangle: keys.isShiftPressed,
    );
    terrainSource = editingDocument.current;
    terrainProject = widget.project;
    terrainTool = widget.view.tool;
    widget.onChanged();
    return true;
  }

  void finishRelief(MapReliefStroke stroke) {
    MapReliefCommands(
      editingDocument,
      widget.project,
    ).apply(stroke, widget.view.relief);
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
    if (widget.view.tool != StudioMapTool.relief) return const [];
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
