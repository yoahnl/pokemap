part of 'map_workspace_screen.dart';

extension _WorkspaceNavigationBinding on _MapWorkspaceScreenState {
  Future<void> _close() async {
    if (await _allowCloseWithExport() && mounted) await widget.onClose();
  }

  Future<void> _openPokemonReference(
    String kind,
    String id, [
    String? detailId,
  ]) async {
    if (!await _allowLeavePokemon() || !mounted) return;
    if (kind == 'scene') {
      final before = _scenes?.sessions[id]?.current;
      final error = await _openScene(
        id,
        nodeId: detailId,
        origin: const WorkspaceReturn(WorkspaceSpace.pokemon),
      );
      if (error == null && _space == WorkspaceSpace.scene) {
        _pokemonReferenceUnchanged = () {
          final session = _scenes?.sessions[id];
          return session != null &&
              !session.dirty &&
              (before == null || identical(session.current, before));
        };
      }
      return;
    }
    if (kind == 'map') {
      final entry = _controller.project?.maps
          .where((value) => value.id == id)
          .firstOrNull;
      if (entry == null) return;
      _show(WorkspaceSpace.map);
      await _controller.activate(entry);
      final document = _controller.active;
      if (!mounted || document == null || document.current.id != id) return;
      if (detailId != null) _selectMapEntity(document, detailId);
      final opened = document.current;
      _pokemonReferenceUnchanged = () =>
          identical(_controller.active, document) &&
          !document.dirty &&
          identical(document.current, opened);
      _pokemonMapReturn = true;
      _changed();
    }
  }

  void _returnToPokemonReference() {
    final keepAnalysis = _pokemonReferenceUnchanged?.call() ?? false;
    _pokemonReferenceUnchanged = null;
    _show(WorkspaceSpace.pokemon, keepCombatAnalysis: keepAnalysis);
  }

  void _toolChanged() {
    if (_view?.tool == StudioMapTool.connection && _controller.active != null) {
      _view?.clearSelection(_controller.active!);
    }
    _gestureGeneration++;
    retainWorkspaceBrush(_visuals, _view);
    _changed();
  }

  void _show(
    WorkspaceSpace space, {
    bool libraryGuarded = false,
    bool keepCombatAnalysis = false,
  }) => _destinations.show(
    space,
    libraryGuarded: libraryGuarded,
    keepCombatAnalysis: keepCombatAnalysis,
  );

  Future<bool> _allowLeavePokemon() => _pokemonExitWorkflow.requestLeave();
}
