part of 'spatial_map_editor.dart';

class _SpatialEnvironmentGesture {
  _SpatialEnvironmentGesture({
    required this.source,
    required this.project,
    required this.session,
    required this.freeView,
    required this.origin,
  }) : tool = session.tool,
       end = origin,
       stroke = MapEncounterCellStroke(
         source.size,
         session.tool == EnvironmentPaintTool.erase,
         origin,
       );
  final MapData source;
  final ProjectManifest project;
  final MapEnvironmentSession session;
  final bool freeView;
  final GridPos origin;
  final EnvironmentPaintTool tool;
  final MapEncounterCellStroke stroke;
  GridPos end;
  void paint(GridPos cell) {
    end = cell;
    stroke.paint(cell);
  }

  Iterable<GridPos> get cells sync* {
    if (tool != EnvironmentPaintTool.rectangle) {
      yield* stroke.cells;
      return;
    }
    for (
      var y = math.min(origin.y, end.y).clamp(0, source.size.height - 1);
      y <= math.max(origin.y, end.y).clamp(0, source.size.height - 1);
      y++
    ) {
      for (
        var x = math.min(origin.x, end.x).clamp(0, source.size.width - 1);
        x <= math.max(origin.x, end.x).clamp(0, source.size.width - 1);
        x++
      ) {
        yield GridPos(x: x, y: y);
      }
    }
  }
}

extension _SpatialEnvironmentEditing on _SpatialMapEditorState {
  bool get environmentGestureValid {
    final gesture = environmentGesture;
    return gesture != null &&
        !locked &&
        widget.view.tool == StudioMapTool.environment &&
        identical(gesture.source, editingDocument.current) &&
        identical(gesture.project, widget.project) &&
        identical(gesture.session, widget.view.environment) &&
        gesture.tool == gesture.session.tool &&
        gesture.freeView == widget.view.spatialFreeView;
  }

  bool startEnvironment(GridPos cell) {
    final session = widget.view.environment;
    if (session == null) {
      editingDocument.error =
          'Choisissez ou créez une zone dans Environnements.';
      widget.onChanged();
      return false;
    }
    final commands = EnvironmentEditingCommands(
      editingDocument,
      widget.project,
    );
    final layer = editingDocument.current.layers
        .whereType<EnvironmentLayer>()
        .where((layer) => layer.id == session.layerId)
        .firstOrNull;
    if (layer?.content.targetsSpatialTerrain != true ||
        commands.area(session) == null ||
        cell.x < 0 ||
        cell.y < 0 ||
        cell.x >= editingDocument.current.size.width ||
        cell.y >= editingDocument.current.size.height) {
      return false;
    }
    environmentGesture = _SpatialEnvironmentGesture(
      source: editingDocument.current,
      project: widget.project,
      session: session,
      freeView: widget.view.spatialFreeView,
      origin: cell,
    );
    session.clearPreview();
    widget.onChanged();
    return true;
  }

  void finishEnvironment() {
    final gesture = environmentGesture!;
    final commands = EnvironmentEditingCommands(
      editingDocument,
      widget.project,
    );
    try {
      if (gesture.tool == EnvironmentPaintTool.rectangle) {
        commands.paintRectangle(gesture.session, gesture.origin, gesture.end);
      } else {
        commands.paint(
          gesture.session,
          gesture.stroke.cells,
          erase: gesture.tool == EnvironmentPaintTool.erase,
        );
      }
    } on Object catch (failure) {
      editingDocument.error = environmentEditingMessage(failure);
    }
    discardGesture();
    widget.onChanged();
  }

  MapData? get environmentPreview {
    final session = widget.view.environment;
    if (widget.view.tool != StudioMapTool.environment ||
        session == null ||
        !identical(session.previewSource, editingDocument.current) ||
        !identical(session.previewProject, widget.project)) {
      return null;
    }
    return session.previewResult;
  }

  List<SpatialCellOverlay> environmentOverlays(ColorScheme colors) {
    if (widget.view.tool != StudioMapTool.environment) return const [];
    final session = widget.view.environment;
    final area = session == null
        ? null
        : EnvironmentEditingCommands(
            editingDocument,
            widget.project,
          ).area(session);
    final stroke = environmentGestureValid ? environmentGesture : null;
    final targets = stroke?.cells.toSet() ?? const <GridPos>{};
    return [
      if (area != null)
        for (var y = 0; y < area.mask.height; y++)
          for (var x = 0; x < area.mask.width; x++)
            if (area.mask.isActiveAt(x, y) &&
                !targets.contains(GridPos(x: x, y: y)))
              SpatialCellOverlay(
                id: 'environment:${area.id}:$x:$y',
                cell: (x, y),
                kind: SpatialCellOverlayKind.preview,
                color: colors.secondary,
              ),
      for (final cell in targets)
        SpatialCellOverlay(
          id: 'environment-stroke:${cell.x}:${cell.y}',
          cell: (cell.x, cell.y),
          kind: SpatialCellOverlayKind.preview,
          color: stroke!.tool == EnvironmentPaintTool.erase
              ? colors.error
              : colors.primary,
        ),
    ];
  }
}
