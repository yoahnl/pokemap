part of 'map_builder_page.dart';

extension _MapBuilderPageScene on _MapBuilderPageState {
  Future<void> _openScene(
    String sceneId,
    String? behaviourId, {
    bool replace = false,
  }) async {
    await _commitTyping();
    if (_disposed) return;
    final port = _stories.narrative;
    if (port == null) return;
    if (!replace) _rememberStoryOrigin();
    final focus = SceneFocusController(
      port: port,
      draft: MapBuilderSceneFocusDraft(_story, isEditable: () => _editable),
      source: () => _stories.behaviours,
      sceneId: sceneId,
      behaviourId: behaviourId,
      changed: _changed,
    );
    _sceneFocus = focus;
    _sceneShown = true;
    unawaited(_loadScene(focus));
    if (_editable) unawaited(_story.prepare());
    _changed();
  }

  void _closeScene() => unawaited(_returnToStoryOrigin());

  Future<void> _loadScene(SceneFocusController focus) async {
    await focus.open();
    if (_disposed ||
        !identical(_activeScene, focus) ||
        focus.document.problem == null) {
      return;
    }
    try {
      final titles = await focus.port.titles(NarrativeTitleKind.scenes);
      if (_disposed || !identical(_activeScene, focus)) return;
      if (!titles.any((title) => title.id == focus.sceneId)) {
        await _storyDestinationUnavailable();
      }
    } on Object {
      return;
    }
  }

  Widget? _scenePage() => switch (_sceneFocus) {
    final focus? => Offstage(
      offstage: !_sceneShown,
      child: _retainedSurface(
        visible: _sceneShown,
        child: FocusScope(
          canRequestFocus: _sceneShown,
          descendantsAreFocusable: _sceneShown,
          child: SceneFocusPage(
            key: ValueKey('scene-focus-${focus.sceneId}'),
            focus: focus,
            project: _maps.project,
            map: _story.map,
            onClose: _closeScene,
            onDetached: (id) =>
                _openScene(id, focus.behaviourId, replace: true),
            onOpenBehaviour: _openBehaviour,
          ),
        ),
      ),
    ),
    null => null,
  };
}
