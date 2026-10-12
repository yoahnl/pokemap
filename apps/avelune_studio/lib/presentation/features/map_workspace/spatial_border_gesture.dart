part of 'spatial_map_editor.dart';

extension _SpatialBorderEditing on _SpatialMapEditorState {
  ({double yaw, double pitch, double zoom, Offset pan, SpatialEditorView view}) get borderCameraState =>
      (yaw: camera.yaw, pitch: camera.pitch, zoom: camera.zoom, pan: camera.pan, view: camera.view);
  bool get borderEraseContextValid => borderEraseDraft != null && !locked &&
      borderEraseDraft!.validFor(widget.document.current, widget.project) &&
      widget.view.tool == StudioMapTool.border &&
      widget.view.borderEditingMode == BorderStrokeEditingMode.erase &&
      widget.view.borderFeature == (layerId: borderEraseDraft!.layerId, featureId: borderEraseDraft!.featureId) &&
      identical(borderSession, widget.controller.session) &&
      borderFreeView == widget.view.spatialFreeView && borderEraseCamera == borderCameraState;

  bool startBorderErase(GridPos cell) {
    final target = widget.view.borderFeature;
    if (locked || target == null) {
      widget.document.error = 'Sélectionnez le tracé à gommer dans le panneau Bordures.';
      widget.onChanged();
      return false;
    }
    focus.requestFocus();
    discardGesture();
    borderEraseDraft = MapBorderEraseDraft(sourceMap: widget.document.current,
        sourceProject: widget.project, layerId: target.layerId,
        featureId: target.featureId, points: const []);
    borderSession = widget.controller.session;
    borderFreeView = widget.view.spatialFreeView;
    borderEraseCamera = borderCameraState;
    widget.view.borderPreview = null;
    sampleBorderErase(cell);
    widget.onChanged();
    return borderEraseDraft != null;
  }

  void sampleBorderErase(GridPos cell) {
    if (!borderEraseContextValid) {
      discardBorder();
      return;
    }
    try {
      borderEraseDraft = borderEraseDraft!.sample(borderEraseDraft!.pointFromWorldCell(cell));
      borderErasePreview = MapBorderEditingCommands(widget.document, widget.project)
          .previewErase(borderEraseDraft!);
      widget.document.error = null;
    } on Object catch (failure) {
      widget.document.error = failure.toString();
      discardBorder();
    }
  }

  void finishBorderErase() {
    try {
      if (borderEraseContextValid) {
        MapBorderEditingCommands(widget.document, widget.project)
            .finishErase(borderEraseDraft!);
        widget.view.repairBorderSelection(widget.document.current);
      }
    } on Object catch (failure) {
      widget.document.error = failure.toString();
    }
    discardBorder();
    widget.onChanged();
  }

  bool get borderContextValid {
    final draft = widget.view.borderDraft;
    return draft != null &&
        !locked &&
        widget.view.tool == StudioMapTool.border &&
        identical(draft.sourceMap, widget.document.current) &&
        identical(draft.sourceProject, widget.project) &&
        identical(borderSession, widget.controller.session) &&
        borderFreeView == widget.view.spatialFreeView;
  }

  void discardBorder() {
    widget.view.clearBorderDraftFailure(widget.document);
    borderEraseDraft = null;
    borderErasePreview = null;
    borderEraseCamera = null;
    widget.view.borderDraft = null;
    widget.view.borderPreview = null;
    borderFreeView = null;
    borderSession = null;
    borderPreviewDraft = null;
    borderPreviewMap = null;
    borderPreviewError = null;
  }

  void addBorderAngle(GridPos cell) {
    if (locked) return;
    focus.requestFocus();
    try {
      final current = widget.view.borderDraft;
      if (current != null && !borderContextValid) {
        discardBorder();
        throw const ValidationException(
          'La carte ou l’outil a changé. Recommencez le tracé.',
        );
      }
      final record = MapBorderEditingCommands.publishedLines(widget.project)
          .where(
            (record) =>
                record.id == widget.view.borderBlueprintId &&
                widget.project.resourceLibraryCatalog.availableForMap(
                  'borderBlueprint',
                  record.id,
                  widget.document.current.id,
                ),
          )
          .firstOrNull;
      if (record == null) {
        throw const ValidationException(
          'Choisissez une bordure publiée disponible avant de tracer.',
        );
      }
      widget.view.borderPreview = null;
      widget.view.borderDraft = current == null
          ? MapBorderDrawingDraft.start(
              mapId: widget.document.current.id,
              mapSize: widget.document.current.size,
              blueprintId: record.id,
              alignment: borderTemplateStrokeAlignment(
                record.latestPublished!.definition.template,
              ),
              origin: cell,
              sourceMap: widget.document.current,
              sourceProject: widget.project,
            )
          : current.addAngle(cell);
      borderFreeView = widget.view.spatialFreeView;
      borderSession = widget.controller.session;
      widget.view.clearBorderDraftFailure(widget.document);
      widget.document.error = null;
    } on Object catch (failure) {
      widget.document.error = failure.toString();
    }
    widget.onChanged();
  }

  void finishBorder() {
    if (widget.view.borderEditingMode == BorderStrokeEditingMode.erase) return;
    final draft = widget.view.borderDraft;
    if (draft == null || !borderContextValid || !draft.canFinish) return;
    try {
      MapBorderEditingCommands(widget.document, widget.project).finish(draft);
      discardBorder();
    } on Object catch (failure) {
      widget.view.failBorderDraft(draft, widget.document, failure);
    }
    widget.onChanged();
  }

  MapData? get spatialBorderPreview {
    if (locked || widget.view.tool != StudioMapTool.border) return null;
    if (borderEraseContextValid) return borderErasePreview;
    final regeneration = widget.view.borderPreview;
    if (regeneration != null &&
        regeneration.validFor(widget.document.current, widget.project)) {
      return regeneration.result;
    }
    final draft = widget.view.borderDraft;
    if (draft == null || !borderContextValid) return null;
    if (identical(borderPreviewDraft, draft)) return borderPreviewMap;
    borderPreviewDraft = draft;
    borderPreviewMap = null;
    borderPreviewError = null;
    try {
      final preview = draft.hover == null || draft.hover == draft.anchors.last
          ? draft
          : draft.addAngle(draft.hover!);
      if (preview.canFinish) {
        borderPreviewMap = MapBorderEditingCommands(
          widget.document,
          widget.project,
        ).preview(preview);
      }
    } on Object catch (failure) {
      borderPreviewError = failure.toString();
    }
    return borderPreviewMap;
  }

  List<SpatialCellOverlay> borderOverlays(ColorScheme colors) {
    if (!locked && widget.view.tool == StudioMapTool.border &&
        widget.view.borderEditingMode == BorderStrokeEditingMode.erase) {
      final target = widget.view.borderFeature;
      final layer = widget.document.current.layers.whereType<BorderLayer>()
          .where((layer) => layer.id == target?.layerId && layer.isVisible).firstOrNull;
      final geometry = layer?.content.featureById(target?.featureId ?? '')?.geometry;
      if (geometry is! BorderStrokeGeometry) return const [];
      final offset = layer!.content.featureById(target!.featureId)!.spatialOffsetWorld;
      final erased = borderEraseDraft?.points.toSet() ?? const <GridPos>{};
      return [for (final cell in geometry.strokes.expand((stroke) => stroke.points).toSet())
        SpatialCellOverlay(id: 'border-erase:${cell.x}:${cell.y}', cell: (
          (cell.x + (geometry.alignment == BorderStrokeAlignment.cellCenters ? .5 : 0) + (offset?.x ?? 0)).floor(),
          (cell.y + (geometry.alignment == BorderStrokeAlignment.cellCenters ? .5 : 0) + (offset?.z ?? 0)).floor()),
          kind: SpatialCellOverlayKind.preview,
          color: erased.contains(cell) ? colors.error : colors.primary.withValues(alpha: .35))];
    }
    final draft = widget.view.borderDraft;
    if (draft == null || !borderContextValid) return const [];
    return [
      for (final cell in draft.previewCells)
        SpatialCellOverlay(
          id: 'border-stroke:${cell.x}:${cell.y}',
          cell: (cell.x, cell.y),
          kind: SpatialCellOverlayKind.preview,
          color: borderPreviewError == null ? colors.primary : colors.error,
        ),
    ];
  }
}
