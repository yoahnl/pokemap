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
    _progressionOrigin = WorkspaceReturn.story;
    final selected = _storyViewState.storyId;
    final id = selected != null && stories.stories.any((s) => s.id == selected)
        ? selected
        : stories.activeId ?? stories.stories.firstOrNull?.id;
    if (id != null) stories.open(id);
    _show(WorkspaceSpace.progression);
  }

  void _openProgressionStep(String storyId, String stepId) {
    final stories = _stories;
    if (stories == null || !stories.open(storyId)) return;
    final projection = buildStorylineProgressionProjection(
      project: stories.project,
      storylineId: storyId,
    );
    final node = projection.nodes
        .where((item) => item.stepId == stepId)
        .firstOrNull;
    if (node != null) {
      _progressionViews.forStory(stories.project, storyId).selection =
          StoryGraphSelection.node(node);
    }
    _progressionOrigin = WorkspaceReturn.story;
    _show(WorkspaceSpace.progression);
  }
}
