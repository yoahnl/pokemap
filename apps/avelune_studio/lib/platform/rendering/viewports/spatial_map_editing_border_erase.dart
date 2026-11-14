part of 'spatial_map_editing_viewport.dart';

final _exteriorEraseDrafts =
    Expando<
      ({
        ExteriorDecorationBorder before,
        List<GridPos> points,
        MapData source,
        ProjectManifest project,
      })
    >();
final _exteriorErasedOwners = Expando<String>();

extension _SpatialBorderErasing on _SpatialMapEditingViewportState {
  ({double yaw, double pitch, double zoom, Offset pan, SpatialEditorView view})
  get borderCameraState => (
    yaw: camera.yaw,
    pitch: camera.pitch,
    zoom: camera.zoom,
    pan: camera.pan,
    view: camera.view,
  );
  bool get exteriorBorderEraseActive => _exteriorEraseDrafts[this] != null;
  bool get borderEraseContextValid {
    final exteriorDraft = _exteriorEraseDrafts[this];
    if (editingExterior) {
      return exteriorDraft != null &&
          !locked &&
          identical(exteriorDraft.source, widget.document.current) &&
          identical(exteriorDraft.project, widget.project) &&
          widget.view.tool == StudioMapTool.border &&
          widget.view.borderEditingMode == BorderStrokeEditingMode.erase &&
          identical(borderSession, widget.controller.session) &&
          borderFreeView == widget.view.spatialFreeView &&
          borderEraseCamera == borderCameraState;
    }
    return borderEraseDraft != null &&
        !locked &&
        borderEraseDraft!.validFor(editingDocument.current, widget.project) &&
        widget.view.tool == StudioMapTool.border &&
        widget.view.borderEditingMode == BorderStrokeEditingMode.erase &&
        widget.view.borderFeature ==
            (
              layerId: borderEraseDraft!.layerId,
              featureId: borderEraseDraft!.featureId,
            ) &&
        identical(borderSession, widget.controller.session) &&
        borderFreeView == widget.view.spatialFreeView &&
        borderEraseCamera == borderCameraState;
  }

  bool startBorderErase(GridPos cell) {
    if (editingExterior) return startExteriorBorderErase(cell);
    final target = widget.view.borderFeature;
    if (locked || target == null) {
      editingDocument.error =
          'Sélectionnez le tracé à gommer dans le panneau Bordures.';
      widget.onChanged();
      return false;
    }
    focus.requestFocus();
    discardGesture();
    borderEraseDraft = MapBorderEraseDraft(
      sourceMap: editingDocument.current,
      sourceProject: widget.project,
      layerId: target.layerId,
      featureId: target.featureId,
      points: const [],
    );
    borderSession = widget.controller.session;
    borderFreeView = widget.view.spatialFreeView;
    borderEraseCamera = borderCameraState;
    widget.view.borderPreview = null;
    sampleBorderErase(cell);
    widget.onChanged();
    return borderEraseDraft != null;
  }

  void sampleBorderErase(GridPos cell) {
    if (editingExterior) {
      sampleExteriorBorderErase(cell);
      return;
    }
    if (!borderEraseContextValid) {
      discardBorder();
      return;
    }
    try {
      borderEraseDraft = borderEraseDraft!.sample(
        borderEraseDraft!.pointFromWorldCell(cell),
      );
      borderErasePreview = MapBorderEditingCommands(
        editingDocument,
        widget.project,
      ).previewErase(borderEraseDraft!);
      editingDocument.error = null;
    } on Object catch (failure) {
      editingDocument.error = failure.toString();
      discardBorder();
    }
  }

  void finishBorderErase() {
    if (editingExterior) {
      final draft = _exteriorEraseDrafts[this];
      try {
        if (draft != null && borderEraseContextValid) {
          exterior!.eraseBorder(
            manifest: widget.project,
            before: draft.before,
            logicalPoints: draft.points,
          );
        }
      } catch (failure) {
        editingDocument.error = '$failure';
      }
      discardBorder();
      widget.onChanged();
      return;
    }
    try {
      if (borderEraseContextValid) {
        MapBorderEditingCommands(
          editingDocument,
          widget.project,
        ).finishErase(borderEraseDraft!);
        widget.view.repairBorderSelection(editingDocument.current);
      }
    } on Object catch (failure) {
      editingDocument.error = failure.toString();
    }
    discardBorder();
    widget.onChanged();
  }

  bool startExteriorBorderErase(GridPos cell) {
    if (locked) return false;
    final borders =
        exterior!.current?.borders ?? const <ExteriorDecorationBorder>[];
    final selected =
        borders
            .where((v) => v.id == widget.view.borderFeature?.featureId)
            .firstOrNull ??
        borders.firstOrNull;
    if (selected == null) {
      editingDocument.error =
          'Choisissez un tracé du décor extérieur avant de gommer.';
      widget.onChanged();
      return false;
    }
    discardGesture();
    widget.view.borderFeature = (
      layerId: selected.layerId,
      featureId: selected.id,
    );
    borderSession = widget.controller.session;
    borderFreeView = widget.view.spatialFreeView;
    borderEraseCamera = borderCameraState;
    _exteriorEraseDrafts[this] = (
      before: selected,
      points: const [],
      source: widget.document.current,
      project: widget.project,
    );
    sampleExteriorBorderErase(cell);
    return exteriorBorderEraseActive;
  }

  void sampleExteriorBorderErase(GridPos cell) {
    final draft = _exteriorEraseDrafts[this];
    if (draft == null || !borderEraseContextValid) {
      discardBorder();
      return;
    }
    final point = GridPos(
      x: cell.x + exterior!.originX,
      y: cell.y + exterior!.originZ,
    );
    if (draft.points.lastOrNull == point) return;
    final next = (
      before: draft.before,
      points: [...draft.points, point],
      source: draft.source,
      project: draft.project,
    );
    _exteriorEraseDrafts[this] = next;
    try {
      final preview = exterior!.previewBorderErase(
        manifest: widget.project,
        before: next.before,
        logicalPoints: next.points,
      );
      _exteriorBorderPreviews[this] = preview;
      _exteriorErasedOwners[this] = preview == null ? next.before.id : null;
      editingDocument.error = null;
    } catch (failure) {
      editingDocument.error = '$failure';
    }
  }
}
