part of 'map_builder_page.dart';

extension _MapBuilderPageSelection on _MapBuilderPageState {
  void _showCanvasMenu(GridPos cell, Offset globalPosition) {
    final document = _maps.active;
    final view = _view;
    final actionContext = _input.contextAt(cell);
    if (document == null ||
        view == null ||
        actionContext == null ||
        !_editable) {
      return;
    }
    final target = mapContextTargetsAt(
      actionContext.document,
      actionContext.project,
      cell,
    ).firstOrNull;
    if (target != null) {
      final family = selectionFamilyOf(target.family);
      if (!view.isSelected(document.current.id, family, target.id)) {
        view.select(document, family, target.id);
      }
    }
    _changed();
    unawaited(
      StudioContextMenu.showAt(
        context,
        position: globalPosition,
        items: mapBuilderCanvasMenu(
          l10n: context.l10n,
          actions: MapSelectionActions(
            _maps,
            view,
            contextAt: _input.contextAt,
          ),
          cell: cell,
          target: target,
          targetActions: target == null
              ? const []
              : mapContextActionsFor(target, actionContext),
          onProperties: () {
            _inspectorOpen = true;
            _changed();
          },
          onCommand: (command) {
            _input
              ..open(cell, selected: target)
              ..run(command);
          },
          changed: _changed,
        ),
      ),
    );
  }

  Widget? _selectionInspector(MapEditingViewportSession? view) {
    final document = _maps.active;
    final project = _maps.project;
    if (view == null ||
        document == null ||
        project == null ||
        _space != MapBuilderSpace.construction ||
        view.tool != StudioMapTool.select) {
      return null;
    }
    final properties = mapSelectionProperties(
      document,
      project,
      view.selectionIn(document.current.id),
    );
    if (properties == null) return null;
    final commands = MapSelectionPropertyCommands(document, project);
    bool apply(void Function() change) {
      try {
        change();
        return true;
      } catch (failure) {
        document.error = mapFailureMessage(failure);
        return false;
      } finally {
        _changed();
      }
    }

    return MapBuilderSelectionInspector(
      properties: properties,
      enabled: _editable,
      onSpatial: (model, {x, y, z, rotation, scale}) => apply(
        () => commands.setSpatial(
          model.id,
          x: x,
          y: y,
          z: z,
          rotation: rotation,
          scale: scale,
        ),
      ),
      onAnimated: (model, animated) =>
          apply(() => commands.setAnimated(model.id, animated: animated)),
      onGrid: (element, position) =>
          apply(() => commands.setGrid(element, position)),
      onInvalid: () {
        document.error = context.l10n.selectionInvalidNumber;
        _changed();
      },
    );
  }
}
