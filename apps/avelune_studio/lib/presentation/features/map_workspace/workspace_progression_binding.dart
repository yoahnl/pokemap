part of 'map_workspace_screen.dart';

extension _WorkspaceProgressionBinding on _MapWorkspaceScreenState {
  void _initializeStories() {
    final narrative = _narrative;
    final port = widget.storyPort;
    if (narrative == null || port == null) return;
    _stories = StoryWorkspaceController(
      narrative,
      port,
      changed: _changed,
      sceneDrafts: () => _scenes?.scenes ?? narrative.project.scenes,
    );
  }

  void _openProgression() {
    final stories = _stories;
    if (stories == null) return;
    final selected = _storyViewState.storyId;
    final id = selected != null && stories.stories.any((s) => s.id == selected)
        ? selected
        : stories.activeId ?? stories.stories.firstOrNull?.id;
    if (id != null) stories.open(id);
    _show(WorkspaceSpace.progression);
  }
}
