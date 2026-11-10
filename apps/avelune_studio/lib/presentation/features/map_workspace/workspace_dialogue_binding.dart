part of 'map_workspace_screen.dart';

extension _WorkspaceDialogueBinding on _MapWorkspaceScreenState {
  void _openMapDialogue(String id) {
    unawaited(_openDialogueRoute(id, WorkspaceSpace.map));
  }

  void _openDialogues() {
    _dialogueOrigin = WorkspaceSpace.story;
    _show(WorkspaceSpace.dialogue);
  }

  void _openNarrativeDialogue(String id) {
    unawaited(_openDialogueRoute(id, WorkspaceSpace.story));
  }

  Future<void> _openDialogueRoute(
    String id,
    WorkspaceSpace origin, {
    String? startNode,
  }) async {
    final problem = await _navigation.openDialogue(
      id,
      origin,
      startNode: startNode,
    );
    if (problem != null && mounted) {
      _resourceError = problem;
      _changed();
    }
  }

  Future<void> _openSceneDialogue(SceneYarnDialoguePayload payload) async {
    FocusManager.instance.primaryFocus?.unfocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    await _openDialogueRoute(
      payload.dialogueId,
      WorkspaceSpace.scene,
      startNode: payload.yarnNodeName,
    );
  }
}
