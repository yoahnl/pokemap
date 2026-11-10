part of 'map_workspace_screen.dart';

extension _WorkspaceCinematicBinding on _MapWorkspaceScreenState {
  void _openCinematics() {
    _cinematicOrigin = WorkspaceSpace.story;
    _show(WorkspaceSpace.cinematic);
  }

  Future<void> _openSceneCinematic(SceneCinematicPayload payload) =>
      _navigation.openSceneCinematic(
        payload,
        flushFocus: () {
          FocusManager.instance.primaryFocus?.unfocus();
          FocusManager.instance.applyFocusChangesIfNeeded();
        },
      );

  Future<void> _openCinematicDialogue(String id) async {
    await _openDialogueRoute(id, WorkspaceSpace.cinematic);
  }

  Future<String?> _locateCinematic(String id) => _navigation.locateCinematic(
    id,
    mapReturn: () => _cinematicMapReturn = true,
  );
}
