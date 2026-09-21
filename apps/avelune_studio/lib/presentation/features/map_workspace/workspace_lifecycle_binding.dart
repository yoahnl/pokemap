part of 'map_workspace_screen.dart';

extension _WorkspaceLifecycle on _MapWorkspaceScreenState {
  /// Releases every controller, view store and visual this host owns.
  void disposeWorkspace() {
    widget.registerExitGuard(null);
    _controller.removeListener(_changed);
    _controller.historyGuard = null;
    final visuals = _visuals;
    if (visuals != null) {
      visuals.removeListener(_changed);
      unawaited(visuals.dispose());
    }
    _resources?.removeListener(_changed);
    _resources?.dispose();
    _narrative?.dispose();
    _scenes?.dispose();
    _stories?.dispose();
    _events?.dispose();
    _dialogues?.dispose();
    _presentations?.dispose();
    _world?.dispose();
    _worldView.dispose();
    _presentationViews.dispose();
    if (_presentationVisuals != null) unawaited(_presentationVisuals!.close());
    _cinematics?.dispose();
    _cinematicViews.dispose();
    _dialogueViews.dispose();
    _eventView.dispose();
    _progressionViews.dispose();
    _sceneViews.dispose();
    _storyViewState.dispose();
    _search.dispose();
    _homeSearch.dispose();
    for (final view in _views.values) {
      view.dispose();
    }
  }
}
