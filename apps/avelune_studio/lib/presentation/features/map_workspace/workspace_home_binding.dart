part of 'map_workspace_screen.dart';

extension _WorkspaceHomeBinding on _MapWorkspaceScreenState {
  Future<void> _useResource(ResourceItem item) async {
    final used = await useResourceOnMap(
      context: context,
      workspace: _controller,
      item: item,
      visuals: _visuals!,
      view: () => _view,
    );
    if (!mounted || !used) return;
    if (item.terrain != null) _search.clear();
    _openMap();
    _toolChanged();
  }

  void _openResources([ProjectElementEntry? element, bool edit = false]) {
    if (_resources == null) return;
    _resources!.openElement(element, edit: edit);
    _show(WorkspaceSpace.resources);
  }

  void _goHome({bool search = false}) {
    if (_presentations?.flushEdits?.call() == false) return;
    _presentations?.suspendPreview?.call();
    _cinematics?.transport.pause();
    FocusManager.instance.primaryFocus?.unfocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    _navigationRequest++;
    _narrative?.cancelOpening();
    search ? widget.home?.searchHome() : widget.home?.showHome();
  }

  void _openMap() {
    _show(WorkspaceSpace.map);
  }

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
        guard: _allowCloseWithExport,
      );
    });
  }

  void _navigateFromHome(String destination, String? mapId) {
    _navigationRequest++;
    _narrative?.cancelOpening();
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
        _view?.prepareCharacterPlacement();
        _view?.revealPalette = true;
        _palette = true;
        _openMap();
        _toolChanged();
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
