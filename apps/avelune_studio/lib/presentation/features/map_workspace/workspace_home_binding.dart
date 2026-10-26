part of 'map_workspace_screen.dart';

extension _WorkspaceHomeBinding on _MapWorkspaceScreenState {
  Future<void> _useResource(ResourceItem item) async {
    if (item.environment case final preset?) {
      await _drawEnvironment(preset);
      return;
    }
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
    if (!_controller.hasWorkshop(MapWorkspaceWorkshop.resources) &&
        widget.resourceLibraryBuilder != null) {
      _show(WorkspaceSpace.resources);
      return;
    }
    final family = element == null
        ? _resources?.library.family ?? ResourceLibraryFamily.decors
        : ResourceLibraryFamily.decors;
    if (!_controller.hasWorkshop(MapWorkspaceWorkshop.resources) ||
        !_controller.hasResourceKind(family.canonicalKind)) {
      unawaited(
        _openResourceWorkshop(
          () => _resources?.openElement(element, edit: edit),
          family: family,
        ),
      );
      return;
    }
    if (_resources == null) return;
    _resources!.openElement(element, edit: edit);
    _show(WorkspaceSpace.resources);
  }

  Future<void> _openResourceTools() async {
    await _openResourceWorkshop(() => _resources?.showLibrary());
  }

  Future<void> _openResourceWorkshop(
    VoidCallback prepare, {
    ResourceLibraryFamily? family,
  }) async {
    final guard = _libraryExitGuard;
    if (guard != null && !await guard()) return;
    if (!mounted || !identical(guard, _libraryExitGuard)) return;
    await _openWorkshop(
      WorkspaceSpace.resources,
      MapWorkspaceWorkshop.resources,
      prepare: prepare,
      loadDependencies: () => _controller.ensureResourceKind(
        (family ?? _resources?.library.family ?? ResourceLibraryFamily.decors)
            .canonicalKind,
      ),
    );
  }

  void _openBorders() {
    if (!_controller.hasWorkshop(MapWorkspaceWorkshop.resources) ||
        !_controller.hasResourceKind('borderBlueprint')) {
      unawaited(
        _openResourceWorkshop(
          () => _resources?.openBorders(),
          family: ResourceLibraryFamily.borders,
        ),
      );
      return;
    }
    if (_resources == null) return;
    _resources!.openBorders();
    _show(WorkspaceSpace.resources);
  }

  void _goHome({bool search = false}) {
    if (_gameExport?.operationActive == true) return;
    if (_presentations?.flushEdits?.call() == false) return;
    if (_space == WorkspaceSpace.gameExport) _show(WorkspaceSpace.map);
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
        library: _controller.hasCompleteProject ? _controller.project : null,
        testAvailable: _controller.active != null && !_actions.busy,
        previewBuilder: (id) => StudioHomeMapPreview(
          key: ValueKey(
            'home-map-preview-${_controller.session.sessionId}-$id',
          ),
          controller: _controller,
          visuals: _visuals!,
          mapId: id,
        ),
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
      case 'projectSettings':
        _show(WorkspaceSpace.projectSettings);
      case 'createMap':
        _openMap();
        unawaited(_createMap());
      case 'regionalMap':
        _show(WorkspaceSpace.regionalMap);
      case 'resources':
        _openResources();
      case 'terrains':
        if (!_controller.hasWorkshop(MapWorkspaceWorkshop.resources) &&
            widget.resourceLibraryBuilder != null) {
          _openResources();
          return;
        }
        unawaited(
          _openResourceWorkshop(() {
            _resources?.library.kind = ResourceKind.terrains;
            _resources?.showLibrary();
          }, family: ResourceLibraryFamily.terrains),
        );
      case 'characters':
        _view?.prepareCharacterPlacement();
        _view?.revealPalette = true;
        _palette = true;
        _openMap();
        _toolChanged();
      case 'story':
        _show(WorkspaceSpace.story);
      case 'testGame':
        if (_controller.active != null &&
            !_actions.busy &&
            widget.projectRuntimeBuilder != null) {
          unawaited(_actions.test(fullProject: true));
        }
      case 'test':
        if (_controller.active != null && !_actions.busy) {
          unawaited(_actions.test());
        }
      case 'gameExport':
        _openGameExport();
      default:
        _openMap();
    }
  }
}
