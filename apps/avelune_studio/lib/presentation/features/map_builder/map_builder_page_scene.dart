part of 'map_builder_page.dart';

extension _MapBuilderPageScene on _MapBuilderPageState {
  void _openScene(String sceneId, String? behaviourId) {
    final port = _stories.narrative;
    if (port == null) return;
    _commitTyping();
    final focus = SceneFocusController(
      port: port,
      draft: MapBuilderSceneFocusDraft(_story, isEditable: () => _editable),
      source: () => _stories.behaviours,
      sceneId: sceneId,
      behaviourId: behaviourId,
      changed: _changed,
    );
    _sceneFocus = focus;
    unawaited(focus.open());
    if (_editable) unawaited(_story.prepare());
    _changed();
  }

  void _closeScene() {
    _sceneFocus = null;
    _changed();
  }

  Widget? _scenePage() => switch (_sceneFocus) {
    final focus? => SceneFocusPage(
      key: ValueKey('scene-focus-${focus.sceneId}'),
      focus: focus,
      project: _maps.project,
      map: _story.map,
      onClose: _closeScene,
      onDetached: (id) => _openScene(id, focus.behaviourId),
    ),
    null => null,
  };
}
