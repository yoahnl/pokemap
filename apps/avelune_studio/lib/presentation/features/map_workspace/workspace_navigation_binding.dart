part of 'map_workspace_screen.dart';

extension _WorkspaceNavigationBinding on _MapWorkspaceScreenState {
  void _enterSpace(WorkspaceSpace space) {
    if (mounted) {
      _space = space;
      _changed();
    }
  }

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
  }) {
    if (_space == WorkspaceSpace.resources &&
        space != _space &&
        _libraryExitGuard != null &&
        !libraryGuarded) {
      unawaited(_leaveLibraryThenShow(space));
      return;
    }
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
    final workshop = switch (space) {
      WorkspaceSpace.map || WorkspaceSpace.interaction || WorkspaceSpace.projectSettings => null,
      WorkspaceSpace.resources
          when widget.resourceLibraryBuilder != null &&
              !_controller.hasWorkshop(MapWorkspaceWorkshop.resources) =>
        null,
      _ => MapWorkspaceWorkshop.values.byName(space.name),
    };
    if (workshop != null && !_controller.hasWorkshop(workshop)) {
      unawaited(_openWorkshop(space, workshop));
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
    if (space != WorkspaceSpace.map) _pokemonMapReturn = false;
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
    _openingWorkshop = false;
    _interactionNotice?.close();
    _interactionNotice = null;
    _narrative?.cancelOpening();
    final refreshCommerce =
        space == WorkspaceSpace.pokemon &&
        _space != WorkspaceSpace.pokemon &&
        _pokemon?.commerce?.snapshot != null;
    final refreshCombat =
        space == WorkspaceSpace.pokemon &&
        _space != WorkspaceSpace.pokemon &&
        _pokemon?.combat?.snapshot != null &&
        !(keepCombatAnalysis &&
            _pokemon?.combat?.snapshot?.referencesComplete == true);
    _enterSpace(space);
    if (space == WorkspaceSpace.regionalMap) unawaited(_regionalMap?.load());
    if (refreshCommerce) {
      unawaited(_pokemon!.commerce!.load(refresh: true));
    }
    if (refreshCombat) {
      unawaited(_pokemon!.combat!.load(refresh: true));
    }
  }

  Future<void> _leaveLibraryThenShow(WorkspaceSpace destination) async {
    final guard = _libraryExitGuard;
    if (await guard!() && mounted && identical(guard, _libraryExitGuard)) {
      _resourceLibrary = null;
      _show(destination, libraryGuarded: true);
    }
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
    final choice = await showPokemonDraftDialog(context);
    if (!mounted) return false;
    if (choice == PokemonDraftDecision.save) {
      return await pokemon.saveActiveOwner() && !pokemon.hasPendingChanges;
    }
    if (choice == PokemonDraftDecision.discard) {
      return pokemon.discardActiveOwner() && !pokemon.hasPendingChanges;
    }
    return false;
  }
}
