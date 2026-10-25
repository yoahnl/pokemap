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
    final request = await _prepareWorkshopRoute(MapWorkspaceWorkshop.dialogue);
    if (request == null) return;
    final owner = _dialogues;
    if (owner == null) return;
    final opened = await owner.open(id, startNode: startNode);
    if (!mounted || request != _navigationRequest) return;
    if (!opened) {
      _resourceError = owner.error;
      _changed();
      return;
    }
    _dialogueOrigin = origin;
    _show(WorkspaceSpace.dialogue);
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
