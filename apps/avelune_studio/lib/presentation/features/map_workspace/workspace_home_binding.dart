part of 'map_workspace_screen.dart';

extension _WorkspaceHomeBinding on _MapWorkspaceScreenState {
  void _openResources([ProjectElementEntry? element, bool edit = false]) {
    if (_resources == null) return;
    _resources!.openElement(element, edit: edit);
    _show(WorkspaceSpace.resources);
  }

  void _openMap() => _show(WorkspaceSpace.map);

  void _publishHome() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _visuals == null) return;
      widget.home?.publish(
        availableMaps: [
          for (final entry in _controller.project?.maps ?? <ProjectMapEntry>[])
            (id: entry.id, name: entry.name),
        ],
        testAvailable: _controller.active != null && !_actions.busy,
        navigate: _navigateFromHome,
        guard: _actions.allowClose,
      );
    });
  }

  void _navigateFromHome(String destination, String? mapId) {
    if (mapId != null) {
      final entries = _controller.project?.maps.where((e) => e.id == mapId);
      if (entries != null && entries.isNotEmpty) {
        unawaited(_controller.activate(entries.first));
      }
    }
    switch (destination) {
      case 'resources':
        _openResources();
      case 'terrains':
        _resources?.library.kind = ResourceKind.terrains;
        _resources?.showLibrary();
        _show(WorkspaceSpace.resources);
      case 'characters':
        _view?.paletteTab = 'Personnages';
        _palette = true;
        _openMap();
      case 'story':
        if (_narrative != null) _show(WorkspaceSpace.story);
      case 'test':
        if (_controller.active != null && !_actions.busy) {
          unawaited(_actions.test());
        }
      default:
        _openMap();
    }
  }
}
