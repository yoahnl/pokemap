part of 'map_workspace_canvas.dart';

extension _MapWorkspaceCanvasGestures on _MapWorkspaceCanvasState {
  void _down(PointerDownEvent event) {
    if (event.buttons == kSecondaryButton) {
      // Never reaches the painting, placement or erasing path.
      _cancel();
      widget.onContextMenu?.call(_cell(event.localPosition), event.position);
      return;
    }
    if (event.buttons != kPrimaryButton ||
        widget.view.tool == StudioMapTool.pan) {
      return;
    }
    _focus.requestFocus();
    final cell = _cell(event.localPosition);
    final armed = widget.view.armedDecorIn(widget.document.current);
    if (armed == null) {
      try {
        _characterGesture = MapCharacterGesture.start(
          document: widget.document,
          project: widget.project,
          view: widget.view,
          origin: cell,
        );
        if (_characterGesture != null) {
          widget.onChanged();
          return;
        }
      } catch (error) {
        widget.document.error = error.toString();
        widget.onChanged();
        return;
      }
    }
    _start = cell;
    _gestureSource = widget.document.current;
    final tool = widget.view.tool;
    if (tool == StudioMapTool.encounterPaint ||
        tool == StudioMapTool.encounterErase) {
      _encounterStroke = MapEncounterCellStroke(
        widget.document.current.size,
        tool == StudioMapTool.encounterErase,
        cell,
      );
      _refreshGesture();
    } else if (tool == StudioMapTool.place) {
      final brush = widget.view.brush;
      final placed = brush == null ? null : _commands.place(brush, cell);
      if (placed != null) {
        widget.view.select(widget.document, MapSelectionFamily.decor, placed);
      }
      _cancel();
      widget.onChanged();
    } else if (tool == StudioMapTool.select) {
      final hits = _commands.stack(cell);
      final held = widget.view.selectedFor(
        widget.document.current.id,
        MapSelectionFamily.decor,
      );
      _armed = armed != null;
      _moving =
          armed ??
          (hits.any((e) => e.id == held)
              ? hits.firstWhere((e) => e.id == held)
              : hits.firstOrNull);
      final moving = _moving;
      if (moving == null) {
        widget.view.clearSelection(widget.document);
      } else {
        widget.view.select(
          widget.document,
          MapSelectionFamily.decor,
          moving.id,
        );
      }
      widget.document.stackPosition = cell;
      widget.onChanged();
    } else {
      try {
        _stroke = MapCanvasStroke.start(
          map: widget.document.current,
          project: widget.project,
          view: widget.view,
          commands: _commands,
          origin: cell,
        );
        _refreshGesture();
      } catch (error) {
        widget.document.error = error.toString();
        _cancel();
        widget.onChanged();
      }
    }
  }
}
