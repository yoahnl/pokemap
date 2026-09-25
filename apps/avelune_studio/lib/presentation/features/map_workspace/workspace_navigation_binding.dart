part of 'map_workspace_screen.dart';

extension _WorkspaceNavigationBinding on _MapWorkspaceScreenState {
  Future<void> _openPokemonReference(String kind, String id) async {
    if (!await _allowLeavePokemon() || !mounted) return;
    if (kind == 'scene') {
      await _openScene(id);
      return;
    }
    if (kind == 'map') {
      final entry = _controller.project?.maps
          .where((value) => value.id == id)
          .firstOrNull;
      if (entry == null) return;
      _show(WorkspaceSpace.map);
      await _controller.activate(entry);
    }
  }

  void _toolChanged() {
    _gestureGeneration++;
    retainWorkspaceBrush(_visuals, _view);
    _changed();
  }

  void _show(WorkspaceSpace space) {
    if (_space == WorkspaceSpace.pokemon &&
        space != _space &&
        (_pokemon?.hasPendingChanges == true ||
            _pokemon?.mutationActive == true)) {
      unawaited(_leavePokemonThenShow(space));
      return;
    }
    if (_space == WorkspaceSpace.gameExport &&
        space != _space &&
        _gameExport?.operationActive == true) {
      return;
    }
    final inPresentation = _space == WorkspaceSpace.presentation;
    if (inPresentation && space != _space) {
      _presentations?.suspendPreview?.call();
    }
    if (inPresentation && _presentations?.flushEdits?.call() == false) return;
    if (_space == WorkspaceSpace.cinematic) {
      _cinematics?.transport.pause();
      FocusManager.instance.primaryFocus?.unfocus();
      FocusManager.instance.applyFocusChangesIfNeeded();
    }
    if (space != WorkspaceSpace.map) _cinematicMapReturn = false;
    if (_space == WorkspaceSpace.dialogue) {
      FocusManager.instance.primaryFocus?.unfocus();
      FocusManager.instance.applyFocusChangesIfNeeded();
    }
    if (space != WorkspaceSpace.map) _eventMapReturn = false;
    if (space != WorkspaceSpace.map) _verificationMapReturn = false;
    if (_space == WorkspaceSpace.events) {
      FocusManager.instance.primaryFocus?.unfocus();
      FocusManager.instance.applyFocusChangesIfNeeded();
    }
    if (_space == WorkspaceSpace.progression) {
      FocusManager.instance.primaryFocus?.unfocus();
      FocusManager.instance.applyFocusChangesIfNeeded();
      if (space == WorkspaceSpace.story) {
        _storyViewState.storyId = _stories?.activeId;
        _storyViewState.stepId = null;
      }
    }
    _closeContextMenu();
    _navigationRequest++;
    _interactionNotice?.close();
    _narrative?.cancelOpening();
    _enterSpace(space);
  }

  Future<void> _leavePokemonThenShow(WorkspaceSpace destination) async {
    if (!await _allowLeavePokemon() || !mounted) return;
    _show(destination);
  }

  Future<bool> _allowLeavePokemon() async {
    final pokemon = _pokemon;
    if (pokemon == null) return true;
    if (pokemon.mutationActive) return false;
    if (!pokemon.hasPendingChanges) return true;
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Conserver le brouillon Pokémon ?'),
        content: const Text(
          'La fiche contient des modifications non enregistrées.',
        ),
        actions: [
          StudioButton(
            label: 'Rester',
            secondary: true,
            onPressed: () => Navigator.pop(dialogContext, 'stay'),
          ),
          StudioButton(
            label: 'Annuler les modifications',
            secondary: true,
            onPressed: () => Navigator.pop(dialogContext, 'discard'),
          ),
          StudioButton(
            label: 'Enregistrer',
            onPressed: () => Navigator.pop(dialogContext, 'save'),
          ),
        ],
      ),
    );
    if (!mounted) return false;
    if (choice == 'save') return pokemon.save();
    if (choice == 'discard') {
      pokemon.discardSelected();
      return true;
    }
    return false;
  }
}
