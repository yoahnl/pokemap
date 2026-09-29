part of 'map_workspace_canvas.dart';

extension _MapWorkspaceCanvasBorder on _MapWorkspaceCanvasState {
  GridPos _borderPoint(Offset position, BorderStrokeAlignment alignment) =>
      alignment == BorderStrokeAlignment.gridEdges
      ? GridPos(
          x: (position.dx / _width).round(),
          y: (position.dy / _height).round(),
        )
      : _cell(position);

  void _previewBorderAt(Offset localPosition) {
    final draft = widget.view.borderDraft;
    var alignment = draft?.alignment;
    if (alignment == null) {
      final models = MapBorderEditingCommands.publishedLines(widget.project);
      final blueprint =
          models
              .where((entry) => entry.id == widget.view.borderBlueprintId)
              .firstOrNull ??
          models.firstOrNull;
      alignment = blueprint == null
          ? BorderStrokeAlignment.cellCenters
          : borderTemplateStrokeAlignment(
              blueprint.latestPublished!.definition.template,
            );
    }
    final position = _borderPoint(localPosition, alignment);
    if (draft != null && draft.hover != position) {
      _mutateGesture(() => widget.view.borderDraft = draft.pointAt(position));
    } else if (draft == null && _hoverCell != position) {
      _mutateGesture(() => _hoverCell = position);
    }
  }

  void _addBorderAngle(Offset localPosition) {
    final models = MapBorderEditingCommands.publishedLines(widget.project);
    final blueprint =
        models
            .where((entry) => entry.id == widget.view.borderBlueprintId)
            .firstOrNull ??
        models.firstOrNull;
    if (blueprint == null) {
      widget.document.error = 'Aucune bordure publiée à tracer.';
      widget.onChanged();
      return;
    }
    try {
      final draft = widget.view.borderDraft;
      final alignment =
          draft?.alignment ??
          borderTemplateStrokeAlignment(
            blueprint.latestPublished!.definition.template,
          );
      final cell = _borderPoint(localPosition, alignment);
      widget.view.borderDraft = draft == null
          ? MapBorderDrawingDraft.start(
              mapId: widget.document.current.id,
              mapSize: widget.document.current.size,
              blueprintId: blueprint.id,
              alignment: alignment,
              origin: cell,
            )
          : draft.addAngle(cell);
      widget.document.error = null;
    } catch (error) {
      widget.document.error = error.toString();
    }
    _refreshGesture();
    widget.onChanged();
  }

  void _finishBorder() {
    final draft = widget.view.borderDraft;
    if (draft == null || !draft.canFinish) return;
    try {
      MapBorderEditingCommands(widget.document, widget.project).finish(draft);
      widget.view.borderDraft = null;
    } catch (error) {
      widget.document.error = error.toString();
    }
    _refreshGesture();
    widget.onChanged();
  }
}
