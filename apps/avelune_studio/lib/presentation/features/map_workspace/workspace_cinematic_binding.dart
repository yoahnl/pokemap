part of 'map_workspace_screen.dart';

extension _WorkspaceCinematicBinding on _MapWorkspaceScreenState {
  void _initializeCinematics() {
    final narrative = _narrative, port = widget.cinematicPort;
    if (narrative == null || port == null) return;
    _cinematics = CinematicWorkspaceController(
      narrative,
      port,
      changed: _changed,
      sceneDrafts: () =>
          _scenes?.sessions.values.map((s) => s.current).toList() ?? [],
    );
  }

  void _openCinematics() {
    _cinematicOrigin = WorkspaceSpace.story;
    _show(WorkspaceSpace.cinematic);
  }

  Future<void> _openSceneCinematic(SceneCinematicPayload payload) async {
    final owner = _cinematics;
    if (owner == null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    _cinematicOrigin = WorkspaceSpace.scene;
    _show(WorkspaceSpace.cinematic);
    await owner.open(payload.cinematicId);
  }

  Future<void> _openCinematicDialogue(String id) async {
    if (_dialogues == null) return;
    _dialogueOrigin = WorkspaceSpace.cinematic;
    _show(WorkspaceSpace.dialogue);
    await _dialogues!.open(id);
  }

  Future<String?> _locateCinematic(String id) async {
    final entries =
        _controller.project?.maps.where((m) => m.id == id).toList() ?? [];
    if (entries.length != 1) return 'Cette carte est absente ou ambiguë.';
    final request = ++_navigationRequest;
    bool current() =>
        mounted &&
        request == _navigationRequest &&
        _space == WorkspaceSpace.cinematic;
    await _controller.activate(entries.single, isCurrent: current);
    if (!current()) return null;
    if (_controller.active?.current.id != id) {
      return _controller.error ?? 'Carte indisponible.';
    }
    _view?.tool = StudioMapTool.select;
    _controller.active?.selectedId = null;
    _cinematicMapReturn = true;
    _show(WorkspaceSpace.map);
    _toolChanged();
    return null;
  }
}
