part of 'spatial_map_editing_viewport.dart';

final _exteriorBorderOwners = Expando<ExteriorDecorationRect>();
final _exteriorBorderPreviews = Expando<ExteriorDecorationBorder>();

extension _SpatialBorderEditing on _SpatialMapEditingViewportState {
  bool get borderContextValid {
    final draft = widget.view.borderDraft;
    final exteriorOwner = _exteriorBorderOwners[this];
    final source = editingExterior
        ? widget.document.current
        : editingDocument.current;
    final bounds = exterior?.current?.outerBounds;
    return draft != null &&
        (!editingExterior ||
            exteriorOwner != null && bounds == exteriorOwner) &&
        !locked &&
        widget.view.tool == StudioMapTool.border &&
        identical(draft.sourceMap, source) &&
        identical(draft.sourceProject, widget.project) &&
        identical(borderSession, widget.controller.session) &&
        borderFreeView == widget.view.spatialFreeView;
  }

  void discardBorder() {
    widget.view.clearBorderDraftFailure(editingDocument);
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
    _exteriorEraseDrafts[this] = null;
    _exteriorErasedOwners[this] = null;
    _exteriorBorderOwners[this] = null;
    _exteriorBorderPreviews[this] = null;
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
                  editingDocument.current.id,
                ),
          )
          .firstOrNull;
      if (record == null) {
        throw const ValidationException(
          'Choisissez une bordure publiée disponible avant de tracer.',
        );
      }
      if (editingExterior && current == null) {
        _exteriorBorderOwners[this] = exterior!.current!.outerBounds;
      }
      final point = borderPointForCell(cell);
      final source = editingExterior
          ? widget.document.current
          : editingDocument.current;
      final bounds = _exteriorBorderOwners[this];
      widget.view.borderPreview = null;
      final moving = widget.view.borderMovingAngle;
      widget.view.borderMovingAngle = null;
      widget.view.borderDraft = current != null && moving != null
          ? current.moveAngle(moving, point)
          : current == null
          ? MapBorderDrawingDraft.start(
              mapId: editingDocument.current.id,
              mapSize: editingExterior
                  ? GridSize(width: bounds!.width, height: bounds.depth)
                  : editingDocument.current.size,
              blueprintId: record.id,
              alignment: borderTemplateStrokeAlignment(
                record.latestPublished!.definition.template,
              ),
              origin: point,
              sourceMap: source,
              logicalOrigin: editingExterior
                  ? GridPos(x: bounds!.x, y: bounds.z)
                  : null,
              sourceProject: widget.project,
            )
          : current.addAngle(point);
      borderFreeView = widget.view.spatialFreeView;
      borderSession = widget.controller.session;
      widget.view.clearBorderDraftFailure(editingDocument);
      editingDocument.error = null;
    } on Object catch (failure) {
      editingDocument.error = failure.toString();
    }
    widget.onChanged();
  }

  void finishBorder() {
    if (widget.view.borderEditingMode == BorderStrokeEditingMode.erase) return;
    final draft = widget.view.borderDraft;
    if (draft == null || !borderContextValid || !draft.canFinish) return;
    try {
      if (editingExterior) {
        final owner = _exteriorBorderOwners[this]!;
        exterior!.drawBorder(
          manifest: widget.project,
          blueprintId: draft.blueprintId,
          logicalPoints: [
            for (final point in draft.anchors)
              GridPos(x: point.x + owner.x, y: point.y + owner.z),
          ],
          seed: draft.seed,
          borderId: draft.featureId,
          closed: draft.closed,
        );
      } else {
        MapBorderEditingCommands(editingDocument, widget.project).finish(draft);
      }
      discardBorder();
    } on Object catch (failure) {
      widget.view.failBorderDraft(draft, editingDocument, failure);
    }
    widget.onChanged();
  }

  MapData? get spatialBorderPreview {
    if (locked || widget.view.tool != StudioMapTool.border) return null;
    if (borderEraseContextValid) return borderErasePreview;
    final regeneration = widget.view.borderPreview;
    if (regeneration != null &&
        regeneration.validFor(editingDocument.current, widget.project)) {
      return regeneration.result;
    }
    final draft = widget.view.borderDraft;
    if (draft == null || !borderContextValid) return null;
    if (identical(borderPreviewDraft, draft)) return borderPreviewMap;
    borderPreviewDraft = draft;
    borderPreviewMap = null;
    borderPreviewError = null;
    _exteriorBorderPreviews[this] = null;
    try {
      final preview = draft.hover == null || draft.hover == draft.anchors.last
          ? draft
          : draft.addAngle(draft.hover!);
      if (preview.canFinish) {
        if (editingExterior) {
          final owner = _exteriorBorderOwners[this]!;
          _exteriorBorderPreviews[this] = exterior!.previewBorder(
            manifest: widget.project,
            blueprintId: preview.blueprintId,
            logicalPoints: [
              for (final point in preview.anchors)
                GridPos(x: point.x + owner.x, y: point.y + owner.z),
            ],
            seed: preview.seed,
            borderId: preview.featureId,
            closed: preview.closed,
          );
          return null;
        }
        borderPreviewMap = MapBorderEditingCommands(
          editingDocument,
          widget.project,
        ).preview(preview);
      }
    } on Object catch (failure) {
      borderPreviewError = failure.toString();
    }
    return borderPreviewMap;
  }

  GridPos borderPointForCell(GridPos cell) {
    final owner = _exteriorBorderOwners[this];
    return editingExterior && owner != null
        ? GridPos(
            x: cell.x + exterior!.originX - owner.x,
            y: cell.y + exterior!.originZ - owner.z,
          )
        : cell;
  }

  MapExteriorDecoration withExteriorBorderPreview(
    MapExteriorDecoration decoration,
  ) {
    final preview = _exteriorBorderPreviews[this];
    final erased = _exteriorErasedOwners[this];
    final erasing = exteriorBorderEraseActive && borderEraseContextValid;
    if (!erasing &&
        (preview == null ||
            widget.view.borderDraft == null ||
            !borderContextValid)) {
      return decoration;
    }
    return MapExteriorDecoration(
      mapId: decoration.mapId,
      playableWidth: decoration.playableWidth,
      playableDepth: decoration.playableDepth,
      west: decoration.west,
      east: decoration.east,
      north: decoration.north,
      south: decoration.south,
      sectors: decoration.sectors,
      borders: [
        for (final border in decoration.borders)
          if (border.id != (preview?.id ?? erased)) border,
        ?preview,
      ],
    );
  }

  List<SpatialCellOverlay> borderOverlays(ColorScheme colors) {
    if (!locked &&
        widget.view.tool == StudioMapTool.border &&
        widget.view.borderEditingMode == BorderStrokeEditingMode.erase) {
      final target = widget.view.borderFeature;
      final layer = editingDocument.current.layers
          .whereType<BorderLayer>()
          .where((layer) => layer.id == target?.layerId && layer.isVisible)
          .firstOrNull;
      final geometry = layer?.content
          .featureById(target?.featureId ?? '')
          ?.geometry;
      if (geometry is! BorderStrokeGeometry) return const [];
      final offset = layer!.content
          .featureById(target!.featureId)!
          .spatialOffsetWorld;
      final erased = borderEraseDraft?.points.toSet() ?? const <GridPos>{};
      return [
        for (final cell
            in geometry.strokes.expand((stroke) => stroke.points).toSet())
          SpatialCellOverlay(
            id: 'border-erase:${cell.x}:${cell.y}',
            cell: (
              (cell.x +
                      (geometry.alignment == BorderStrokeAlignment.cellCenters
                          ? .5
                          : 0) +
                      (offset?.x ?? 0))
                  .floor(),
              (cell.y +
                      (geometry.alignment == BorderStrokeAlignment.cellCenters
                          ? .5
                          : 0) +
                      (offset?.z ?? 0))
                  .floor(),
            ),
            kind: SpatialCellOverlayKind.preview,
            color: erased.contains(cell)
                ? colors.error
                : colors.primary.withValues(alpha: .35),
          ),
      ];
    }
    final draft = widget.view.borderDraft;
    if (draft == null || !borderContextValid) return const [];
    return [
      for (final cell in draft.previewCells)
        SpatialCellOverlay(
          id: 'border-stroke:${cell.x}:${cell.y}',
          cell: editingExterior
              ? (
                  cell.x + _exteriorBorderOwners[this]!.x - exterior!.originX,
                  cell.y + _exteriorBorderOwners[this]!.z - exterior!.originZ,
                )
              : (cell.x, cell.y),
          kind: SpatialCellOverlayKind.preview,
          color: borderPreviewError == null ? colors.primary : colors.error,
        ),
    ];
  }
}
