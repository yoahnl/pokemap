part of 'map_workspace_screen.dart';

extension _WorkspaceProgressionBinding on _MapWorkspaceScreenState {
  void _openProgression() =>
      _navigation.openProgression(preferredStoryId: _storyViewState.storyId);

  void _openProgressionStep(String storyId, String stepId) =>
      _navigation.openProgressionStep(storyId, stepId);
}
