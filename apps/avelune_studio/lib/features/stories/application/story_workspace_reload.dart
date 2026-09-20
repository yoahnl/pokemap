part of 'story_workspace_controller.dart';

extension StoryWorkspaceReload on StoryWorkspaceController {
  Future<bool> _reloadStory(String id, {StorylineAsset? expectedStory}) async {
    if (_closed || busy || narrative.saving) return false;
    final expected =
        expectedStory ?? stories.where((s) => s.id == id).firstOrNull;
    final previous = workspace.project;
    if (previous == null || expected == null) return false;
    busy = true;
    error = null;
    changed();
    try {
      final current = await workspace.port.loadProject(workspace.session);
      if (_closed) return false;
      final latest = stories.where((s) => s.id == id).firstOrNull;
      if (latest != expected || workspace.project != previous) {
        throw const StoryFailure(
          'Le brouillon ou le catalogue a changé pendant la lecture ; il est conservé.',
        );
      }
      workspace.acceptResources(previous, current);
      _discardStory(id);
      return true;
    } catch (failure) {
      if (!_closed) error = failure.toString();
      return false;
    } finally {
      busy = false;
      if (!_closed) {
        reconcile();
        changed();
      }
    }
  }
}
