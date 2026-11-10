part of 'map_workspace_screen.dart';

extension _WorkspaceLifecycle on _MapWorkspaceScreenState {
  void _bindResourceManagement(ResourceNavigation? resources) {
    _resources = resources;
    _resourceOwners.bind(resources);
  }

  void _reconcileResourceBrushes() => _resourceOwners.reconcileBrushes();

  void _initializePokemon() => _sessions.initializePokemon();

  /// Releases every controller, view store and visual this host owns.
  void disposeWorkspace() {
    widget.registerExitGuard(null);
    _controller.removeListener(_changed);
    _mapCatalogBindings.dispose();
    unawaited(
      _sessions.dispose(
        releasePresentationViews: _presentationViews.dispose,
      ),
    );
    _cinematicViews.dispose();
    _dialogueViews.dispose();
    _eventView.dispose();
    _sceneViews.dispose();
    _storyViewState.dispose();
    _search.dispose();
    _homeSearch.dispose();
    for (final view in _views.values) {
      view.dispose();
    }
  }

  Future<void> _initialize() async {
    try {
      final loaded = await loadWorkspaceSession(
        workspace: _controller,
        loadVisuals: widget.loadVisuals,
        narrativePort: widget.narrativePort,
        resourcePort: widget.resourcePort,
        resourcePackPort: widget.resourcePackPort,
        resourcePackPicker: widget.resourcePackPicker,
        resourcePackLicensePicker: widget.resourcePackLicensePicker,
        resourcePackExportSink: widget.resourcePackExportSink,
        isActive: () => mounted,
        changed: _changed,
        onUse: _useResource,
        openUsage: _openResourceUsage,
        canOpenUsage: _canOpenResourceUsage,
        additionalDraftOwners: _resourceUsageDraftOwners,
      );
      if (loaded == null) return;
      if (!mounted) {
        await loaded.dispose();
        return;
      }
      _visuals = loaded.visuals;
      _visualCatalog = _controller.visualProject;
      _bindResourceManagement(loaded.resources);
      _sessions.initializeLoaded(loaded);
      _changed();
    } catch (_) {
      if (mounted) {
        _resourceError = 'Impossible de charger les ressources de ce projet.';
        _changed();
      }
    }
  }
}
