part of 'map_workspace_screen.dart';

extension _WorkspaceCommandBinding on _MapWorkspaceScreenState {
  MapCommandContext get _commandContext {
    final document = _controller.active;
    final exterior = document?.exteriorDecoration;
    final editing = exterior?.editingExterior == true;
    final view = _view;
    final spatial = document?.current.spatialScene != null;
    return MapCommandContext(
      spatial: spatial,
      exterior: editing,
      storyAvailable: _narrative != null,
      canUndo: editing ? exterior!.canUndo : document?.canUndo == true,
      canRedo: editing ? exterior!.canRedo : document?.canRedo == true,
      paintReady:
          view != null &&
          (view.tile != null ||
              view.brush != null ||
              view.terrain != null ||
              (spatial && view.paletteTab == 'Terrains')),
    );
  }

  Future<void> _openCommandPalette() async {
    final document = _controller.active;
    if (document == null || _view == null) return;
    final chosen = await showStudioCommandPalette(
      context,
      entries: mapCommandPaletteEntries(_commandContext)
          .where((entry) => entry.id != 'map.ambiance')
          .toList(),
    );
    if (!mounted || chosen == null) return;
    final view = _view;
    final active = _controller.active;
    if (view == null || active == null || active != document) return;
    final command = mapWorkspaceCommand(chosen);
    if (mapCommandUnavailable(command.id, _commandContext) != null) return;
    switch (command.id) {
      case 'map.undo':
        _controller.restore(redo: false);
        _changed();
      case 'map.redo':
        _controller.restore(redo: true);
        _changed();
      default:
        MapToolCommandRunner(
          view: view,
          spatial: active.current.spatialScene != null,
          paletteVisible: _palette,
          onChanged: _toolChanged,
          onMoreTools: () {
            _palette = true;
            _changed();
          },
          onResources: _openResources,
        ).run(command);
    }
  }
}
