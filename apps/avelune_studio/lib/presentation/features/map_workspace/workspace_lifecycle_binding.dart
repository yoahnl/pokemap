part of 'map_workspace_screen.dart';

extension _WorkspaceLifecycle on _MapWorkspaceScreenState {
  void _bindResourceManagement(ResourceNavigation? resources) {
    _resources = resources;
    resources?.additionalCharacterOwners = _characterDraftOwners;
    resources?.characterSourceProblem = (ids) =>
        _dialogues?.characterSourceProblem(ids) ??
        _narrativeCharacterSourceProblem(ids);
    resources?.characterSourcesChanged = (ids) {
      final project = _controller.project;
      if (project != null) {
        _pokemon?.combat?.reconcileCharacterReferences(
          project,
          resources.pendingReceipt?.changedMaps ?? const {},
        );
      }
      _dialogues?.invalidateCharacterSources(ids);
      for (final id in ids) {
        _narrative?.invalidateCleanDialogueSessions(id);
      }
    };
    resources?.borderDrawingOwner = (blueprintId) {
      for (final entry in _views.entries) {
        if (entry.value.borderDraft?.blueprintId == blueprintId) {
          final name =
              _controller.documents[entry.key]?.current.name ?? entry.key;
          return 'Carte · $name · tracé de bordure en cours';
        }
      }
      return null;
    };
  }

  List<String> _characterDraftOwners(String characterId) => [
    ?_pokemon?.combat?.characterDraftOwner(characterId),
    ...?_dialogues?.characterDraftOwners(characterId),
    if (_narrative != null)
      for (final session in _narrative!.sessions.values)
        if (session.dirty &&
            [session.current, session.saved].any(
              (state) => state.dialogue.branches.any(
                (branch) =>
                    branch.lines.any((line) => line.speakerId == characterId),
              ),
            ))
          'Interaction · ${session.current.dialogue.entry.name}',
    for (final asset in _cinematics?.entries ?? <CinematicAsset>[])
      if (_cinematics?.accessProblem(asset.id) != null &&
          [
            asset,
            ...?_controller.project?.cinematics.where((c) => c.id == asset.id),
          ].any(
            (value) =>
                value.stageContext?.actorAppearanceBindings.any(
                  (binding) => binding.characterId == characterId,
                ) ??
                false,
          ))
        'Cinématique · ${asset.title}',
  ];

  String? _narrativeCharacterSourceProblem(Set<String> ids) {
    for (final id in ids) {
      final problem = _narrative?.dialogueInteractionAccessProblem(id);
      if (problem != null) return problem;
    }
    return null;
  }

  void _reconcileResourceBrushes() {
    final project = _controller.project;
    if (project == null) return;
    var changed = false;
    for (final view in _views.values) {
      final characterId = view.character?.id;
      if (characterId != null) {
        final before = view.character;
        view.character = project.characters
            .where((character) => character.id == characterId)
            .firstOrNull;
        changed |= before != view.character;
        if (view.character == null && view.tool == StudioMapTool.character) {
          view.tool = StudioMapTool.select;
        }
      }
      final brushId = view.brush?.id;
      if (brushId != null) {
        final before = view.brush;
        view.brush = project.elements
            .where((element) => element.id == brushId)
            .firstOrNull;
        changed |= before != view.brush;
        if (view.brush == null && view.tool == StudioMapTool.place) {
          view.tool = StudioMapTool.select;
        }
      }
      final tileId = view.tile?.tilesetId;
      if (tileId != null && !project.tilesets.any((t) => t.id == tileId)) {
        view.tile = null;
        changed = true;
        if (view.tool == StudioMapTool.paint) view.tool = StudioMapTool.select;
      }
      final terrainId = view.terrain?.id;
      if (terrainId != null) {
        final before = view.terrain;
        view.terrain = project.smartTileCatalog.presets
            .where((preset) => preset.id == terrainId)
            .firstOrNull;
        changed |= before != view.terrain;
        if (view.terrain == null && view.tool == StudioMapTool.terrain) {
          view.tool = StudioMapTool.select;
        }
      }
      final borderId = view.borderBlueprintId;
      if (borderId != null &&
          !project.borderCatalog.records.any(
            (record) =>
                record.id == borderId &&
                !record.isDeprecated &&
                record.latestPublished != null,
          )) {
        view.borderBlueprintId = null;
        changed = true;
        if (view.tool == StudioMapTool.border) view.tool = StudioMapTool.select;
      }
    }
    if (changed) retainWorkspaceBrush(_visuals, _view);
  }

  void _initializePokemon() {
    final port = widget.pokemonPort;
    if (port != null) {
      _pokemon = PokemonWorkspaceController(
        port,
        changed: _changed,
        commerce: widget.pokemonCommercePort == null
            ? null
            : PokemonCommerceController(
                widget.pokemonCommercePort!,
                changed: _changed,
              ),
        combat: widget.pokemonCombatPort == null
            ? null
            : PokemonCombatController(
                widget.pokemonCombatPort!,
                changed: _changed,
                projectChanged: (manifest) {
                  final current = _controller.project;
                  if (current != null && current != manifest) {
                    _controller.acceptResources(current, manifest);
                  }
                },
              ),
      );
    }
  }

  /// Releases every controller, view store and visual this host owns.
  void disposeWorkspace() {
    widget.registerExitGuard(null);
    _controller.removeListener(_changed);
    _controller.historyGuard = null;
    final visuals = _visuals;
    if (visuals != null) {
      visuals.removeListener(_changed);
      unawaited(visuals.dispose());
    }
    _resources?.removeListener(_changed);
    _resources?.dispose();
    _pokemon?.dispose();
    _narrative?.dispose();
    _scenes?.dispose();
    _stories?.dispose();
    _events?.dispose();
    _dialogues?.dispose();
    _presentations?.dispose();
    _world?.dispose();
    _worldView.dispose();
    _verification?.dispose();
    _verificationView.dispose();
    _presentationViews.dispose();
    if (_presentationVisuals != null) unawaited(_presentationVisuals!.close());
    _cinematics?.dispose();
    _cinematicViews.dispose();
    _dialogueViews.dispose();
    _eventView.dispose();
    _progressionViews.dispose();
    _sceneViews.dispose();
    _storyViewState.dispose();
    _search.dispose();
    _homeSearch.dispose();
    for (final view in _views.values) {
      view.dispose();
    }
  }
}
