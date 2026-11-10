part of 'spatial_map_editing_viewport.dart';

extension _SpatialMapEditorGuidance on _SpatialMapEditingViewportState {
  List<SpatialCellOverlay> terrainSurfaceSelectionOverlays(ColorScheme colors) {
    if (widget.view.tool != StudioMapTool.terrain ||
        widget.view.spatialTerrainMode != SpatialTerrainMode.relief ||
        !widget.view.spatialContinuousTerrain) {
      return const [];
    }
    final preview = widget.view.terrainSurfacePreview;
    final scene = preview?.validFor(editingDocument.current) == true
        ? preview!.result.spatialScene!
        : editingDocument.current.spatialScene!;
    final surface = scene.terrainSurfaces.surfaces
        .where((surface) => surface.id == widget.view.spatialSurfaceId)
        .firstOrNull;
    if (surface == null) return const [];
    final bounds = surface.bounds;
    final left = bounds.left.floor().clamp(0, scene.width - 1);
    final right = (bounds.right.ceil() - 1).clamp(left, scene.width - 1);
    final top = bounds.top.floor().clamp(0, scene.depth - 1);
    final bottom = (bounds.bottom.ceil() - 1).clamp(top, scene.depth - 1);
    final cells = <(int, int)>{
      for (var x = left; x <= right; x++) ...[(x, top), (x, bottom)],
      for (var z = top; z <= bottom; z++) ...[(left, z), (right, z)],
    };
    return [
      for (final cell in cells)
        SpatialCellOverlay(
          id: 'terrain-surface-selection:${cell.$1}:${cell.$2}',
          cell: cell,
          kind: SpatialCellOverlayKind.preview,
          color: colors.secondary,
        ),
    ];
  }

  List<SpatialCellOverlay> previewOverlays(ColorScheme colors) {
    if (!showsHover) return const [];
    final scene = editingDocument.current.spatialScene!;
    final stroke = reliefStroke;
    final targets = <(int, int)>{};
    if (widget.view.tool == StudioMapTool.environment) {
      if (hover != null && environmentGesture == null) targets.add(hover!.cell);
    } else if (stroke != null &&
        stroke.mode == SpatialTerrainMode.ramp &&
        !stroke.erase) {
      for (
        var z = math.min(stroke.origin.y, stroke.end.y);
        z <= math.max(stroke.origin.y, stroke.end.y);
        z++
      ) {
        for (
          var x = math.min(stroke.origin.x, stroke.end.x);
          x <= math.max(stroke.origin.x, stroke.end.x);
          x++
        ) {
          targets.add((x, z));
        }
      }
    } else if (stroke != null) {
      targets.addAll(stroke.cells.map((cell) => (cell.x, cell.y)));
    } else if (hover != null) {
      targets.add(hover!.cell);
    }
    final relief =
        widget.view.spatialTerrainMode == SpatialTerrainMode.relief &&
        !widget.view.spatialContinuousTerrain &&
        (widget.view.tool == StudioMapTool.terrain ||
            widget.view.tool == StudioMapTool.erase);
    final targetHeight =
        (widget.view.tool == StudioMapTool.erase
            ? 0
            : widget.view.spatialTerrainLevel) *
        scene.levelHeight;
    return [
      for (final cell in targets)
        if (!relief ||
            hover == null ||
            cell != hover!.cell ||
            hover!.position.y != targetHeight)
          SpatialCellOverlay(
            id: 'brush:${cell.$1}:${cell.$2}',
            cell: cell,
            kind: SpatialCellOverlayKind.preview,
            color: stroke?.error != null
                ? colors.error
                : relief
                ? colors.outline
                : colors.primary,
            targetHeight: relief ? targetHeight : null,
          ),
      if (relief && hover != null)
        SpatialCellOverlay(
          id: 'brush-cursor',
          cell: hover!.cell,
          kind: SpatialCellOverlayKind.preview,
          color: stroke?.error != null ? colors.error : colors.primary,
          targetHeight: hover!.position.y,
        ),
    ];
  }
}
