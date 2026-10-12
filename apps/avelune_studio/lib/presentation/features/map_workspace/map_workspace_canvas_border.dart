part of 'map_workspace_canvas.dart';

extension _MapWorkspaceCanvasBorder on _MapWorkspaceCanvasState {
  List<GridPos> get _selectedBorderCells {
    if (widget.view.tool != StudioMapTool.border ||
        widget.view.borderEditingMode != BorderStrokeEditingMode.erase) {
      return const [];
    }
    final target = widget.view.borderFeature;
    final layer = widget.document.current.layers.whereType<BorderLayer>()
        .where((layer) => layer.id == target?.layerId && layer.isVisible).firstOrNull;
    final geometry = layer?.content.featureById(target?.featureId ?? '')?.geometry;
    return geometry is BorderStrokeGeometry
        ? geometry.strokes.expand((stroke) => stroke.points).toSet().toList() : const [];
  }
  void _startBorderErase(Offset position) {
    final target = widget.view.borderFeature;
    if (target == null) {
      widget.document.error = 'Sélectionnez le tracé à gommer dans le panneau Bordures.';
      _cancel();
      widget.onChanged();
      return;
    }
    _borderErase = MapBorderEraseDraft(sourceMap: widget.document.current,
        sourceProject: widget.project, layerId: target.layerId,
        featureId: target.featureId, points: const []);
    _borderEraseTransform = widget.view.transform.value.clone();
    _sampleBorderErase(position);
  }

  void _sampleBorderErase(Offset position) {
    if (!_ownsBorderEraseGesture) {
      _cancel();
      return;
    }
    try {
      final draft = _borderErase!;
      _borderErase = draft.sample(_borderPoint(position, draft.geometry.alignment));
      _borderErasePreview = MapBorderEditingCommands(widget.document, widget.project)
          .previewErase(_borderErase!);
      widget.document.error = null;
    } on Object catch (failure) {
      widget.document.error = failure.toString();
      _cancel();
      widget.onChanged();
    }
  }

  GridPos _borderPoint(Offset position, BorderStrokeAlignment alignment) =>
      alignment == BorderStrokeAlignment.gridEdges
      ? GridPos(
          x: (position.dx / _width).round(),
          y: (position.dy / _height).round(),
        )
      : _cell(position);

  void _previewBorderAt(Offset localPosition) {
    if (widget.view.borderEditingMode == BorderStrokeEditingMode.erase) return;
    final draft = widget.view.borderDraft;
    var alignment = draft?.alignment;
    if (alignment == null) {
      final models = MapBorderEditingCommands.publishedLines(widget.project);
      final blueprint = models
          .where((entry) => entry.id == widget.view.borderBlueprintId)
          .firstOrNull;
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
    final blueprint = models
        .where((entry) => entry.id == widget.view.borderBlueprintId)
        .firstOrNull;
    if (blueprint == null) {
      widget.document.error =
          'Choisissez une bordure publiée disponible avant de tracer.';
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
    if (widget.view.borderEditingMode == BorderStrokeEditingMode.erase) return;
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
