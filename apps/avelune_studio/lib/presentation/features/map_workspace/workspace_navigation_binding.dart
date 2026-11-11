part of 'map_workspace_screen.dart';

extension _WorkspaceNavigationBinding on _MapWorkspaceScreenState {
  Future<void> _close() async {
    if (await _allowCloseWithExport() && mounted) await widget.onClose();
  }

  Future<void> _openPokemonReference(
    String kind,
    String id, [
    String? detailId,
  ]) => _pokemonReferences.open(kind, id, detailId);

  void _returnToPokemonReference() => _show(
    WorkspaceSpace.pokemon,
    keepCombatAnalysis: _pokemonReferences.takeUnchanged(),
  );

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
