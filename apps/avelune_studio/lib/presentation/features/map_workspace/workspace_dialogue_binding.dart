part of 'map_workspace_screen.dart';

extension _WorkspaceDialogueBinding on _MapWorkspaceScreenState {
  void _initializeDialogues() {
    final narrative = _narrative, port = widget.dialoguePort;
    if (narrative == null || port == null) return;
    _dialogues = DialogueWorkspaceController(
      narrative,
      port,
      changed: _changed,
      sceneDrafts: () =>
          _scenes?.sessions.values.map((s) => s.current).toList() ?? [],
    );
    _dialogues!.onPublished = (id, revision) =>
        _scenes?.refreshDialogueResults(id);
  }

  void _openDialogues() {
    _dialogueOrigin = WorkspaceSpace.story;
    _show(WorkspaceSpace.dialogue);
  }

  Future<void> _openSceneDialogue(SceneYarnDialoguePayload payload) async {
    final owner = _dialogues;
    if (owner == null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    _dialogueOrigin = WorkspaceSpace.scene;
    _show(WorkspaceSpace.dialogue);
    await owner.open(payload.dialogueId, startNode: payload.yarnNodeName);
  }
}
