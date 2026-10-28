part of 'map_workspace_screen.dart';

extension _WorkspaceScreenBody on _MapWorkspaceScreenState {
  Widget _buildWorkspace(BuildContext context) {
    final document = _controller.active;
    final error =
        workspaceNarrativeError(
          _narrative,
          narrativePage: _space == WorkspaceSpace.interaction,
        ) ??
        _controller.error ??
        document?.error ??
        _connectionError ??
        _resourceError;
    return CallbackShortcuts(
      bindings: workspaceShortcuts(
        _controller,
        _view,
        _keyboard,
        onSave: _saveWorkspaceDocument,
        guardedWhileTyping: _keyboardWhileTyping,
        onContextMenu: _openContextMenuFromKeyboard,
        contextAt: _contextAt,
      ),
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Stack(
            children: [
              AbsorbPointer(
                key: const ValueKey('workspace-preparing'),
                absorbing:
                    _actions.testing ||
                    _actions.closing ||
                    _openingWorkshop ||
                    _controller.catalogBusy ||
                    _resources?.busy == true ||
                    _connectionBusy ||
                    _narrative?.saving == true,
                child: SafeArea(
                  child: Column(
                    children: [
                      if (_cinematicMapReturn && _space == WorkspaceSpace.map)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: StudioButton(
                            label: 'Retour à la cinématique',
                            secondary: true,
                            icon: Icons.arrow_back,
                            onPressed: () {
                              _cinematicMapReturn = false;
                              _show(WorkspaceSpace.cinematic);
                            },
                          ),
                        ),
                      if (_verificationMapReturn &&
                          _space == WorkspaceSpace.map)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: StudioButton(
                            label: 'Retour à la vérification',
                            secondary: true,
                            icon: Icons.arrow_back,
                            onPressed: () {
                              _verificationMapReturn = false;
                              _show(WorkspaceSpace.verification);
                            },
                          ),
                        ),
                      if (_eventMapReturn && _space == WorkspaceSpace.map)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: StudioButton(
                            label: 'Retour à l’événement',
                            secondary: true,
                            icon: Icons.arrow_back,
                            onPressed: () {
                              _eventMapReturn = false;
                              _show(WorkspaceSpace.events);
                            },
                          ),
                        ),
                      Expanded(
                        child: MapWorkspaceLayout(
                          homeSearch: widget.home?.search ?? _homeSearch,
                          onSearch: (_) => _goHome(search: true),
                          onHome: widget.home == null ? null : _goHome,
                          activeSpace: _space.name,
                          controller: _controller,
                          view: _view,
                          visuals: _projectionVisualsLoading ? null : _visuals,
                          search: _search,
                          error: error,
                          palette: _palette,
                          inspector: _inspector,
                          generation: _gestureGeneration,
                          onPalette: () {
                            _palette = !_palette;
                            _changed();
                          },
                          onInspector: () {
                            _inspector = !(_inspector ?? true);
                            _changed();
                          },
                          onChanged: _changed,
                          onToolChanged: _toolChanged,
                          onActivate: (entry) {
                            _interactionNotice?.close();
                            _narrative?.cancelOpening();
                            _gestureGeneration++;
                            unawaited(_controller.activate(entry));
                          },
                          onOrganizeMaps:
                              !_controller.hasCompleteProject ||
                                  _controller.catalogPort == null
                              ? null
                              : _organizeMaps,
                          onLinkMaps:
                              !_controller.hasCompleteProject ||
                                  widget.mapConnectionPort == null
                              ? null
                              : _linkMaps,
                          onUnlinkMaps:
                              !_controller.hasCompleteProject ||
                                  widget.mapConnectionPort == null
                              ? null
                              : _unlinkMaps,
                          onSave: document == null || document.saving
                              ? null
                              : _saveWorkspaceDocument,
                          onTest:
                              document == null ||
                                  _actions.testing ||
                                  document.saving
                              ? null
                              : _actions.test,
                          onClose: _close,
                          onResources: _openResources,
                          onPickResource: _useResource,
                          onEnvironments: _openEnvironments,
                          onBorders: _openBorders,
                          onMap: _openMap,
                          onProjectSettings: () =>
                              _show(WorkspaceSpace.projectSettings),
                          onRegionalMap: () =>
                              _show(WorkspaceSpace.regionalMap),
                          onExport: _openGameExport,
                          onPokemon: () {
                            _show(WorkspaceSpace.pokemon);
                            unawaited(_pokemon?.load());
                          },
                          exportActive: _gameExport?.operationActive == true,
                          onStory: () => _show(WorkspaceSpace.story),
                          onEditInteraction: _editInteraction,
                          onEventSource: _events == null
                              ? null
                              : _openEventSource,
                          onZoneDrawn: _narrative == null ? null : _zone,
                          referenceGuard: _draftReferences.guard,
                          onContextMenu: _openContextMenu,
                          movingHint: _view?.moveHint,
                          onOpenElement: (element) => _openResources(element),
                          onEditElement: (element) =>
                              _openResources(element, true),
                          resourceContent: _openingWorkshop
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    semanticsLabel: 'Ouverture de l’atelier',
                                  ),
                                )
                              : _space == WorkspaceSpace.resources &&
                                    !_controller.hasWorkshop(
                                      MapWorkspaceWorkshop.resources,
                                    ) &&
                                    widget.resourceLibraryBuilder != null
                              ? _resourceLibrary ??=
                                    widget.resourceLibraryBuilder!(
                                      context,
                                      (guard) => _libraryExitGuard = guard,
                                      _controller.refreshCatalogSelection,
                                      _openResourceTools,
                                      _replaceCatalogModelSource,
                                    )
                              : _space == WorkspaceSpace.projectSettings &&
                                    _controller.port is ProjectVisualsPort
                              ? ProjectSettingsPage(
                                  key: ValueKey(_controller.session.sessionId),
                                  workspace: _controller,
                                  owner: _visualOwner,
                                  surfOwner: _surfOwner,
                                  csOwner: _csOwner,
                                  audioOwner: _audioOwner,
                                  pickMedia: widget.presentationMediaPicker,
                                  loadItems: _loadSceneItems,
                                  testBuilder: widget.visualTestBuilder,
                                )
                              : _space == WorkspaceSpace.regionalMap &&
                                    _regionalMap != null
                              ? RegionalMapPage(controller: _regionalMap!)
                              : _space == WorkspaceSpace.gameExport
                              ? _gameExportPage()
                              : _space == WorkspaceSpace.pokemon
                              ? PokemonWorkspacePage(
                                  controller: _pokemon,
                                  pickJson: widget.pokemonJsonPicker,
                                  pickPng: widget.pokemonPngPicker,
                                  onOpenReference: _openPokemonReference,
                                )
                              : _space == WorkspaceSpace.verification
                              ? _verificationPage()
                              : _space == WorkspaceSpace.world
                              ? _worldPage()
                              : _space == WorkspaceSpace.presentation
                              ? _presentationPage()
                              : workspaceSecondaryContent(
                                  loadSceneMoves: _loadSceneMoves,
                                  loadSceneItems: _loadSceneItems,
                                  loadSceneCaptureItems: _loadSceneCaptureItems,
                                  loadSceneSpecies: _loadSceneSpecies,
                                  space: _space,
                                  presentations: _presentations,
                                  onPresentations: _presentations == null
                                      ? null
                                      : _openPresentations,
                                  onScenePresentation: _presentations == null
                                      ? null
                                      : _openScenePresentation,
                                  onReturnPresentation: _presentations == null
                                      ? null
                                      : _returnToPresentation,
                                  onCreatePresentation: _presentations == null
                                      ? null
                                      : _createScenePresentation,
                                  cinematics: _cinematics,
                                  cinematicViews: _cinematicViews,
                                  cinematicOrigin: _cinematicOrigin,
                                  onCinematics: _openCinematics,
                                  onCinematicBack: () =>
                                      _show(_cinematicOrigin),
                                  onSceneCinematic: _openSceneCinematic,
                                  onCinematicDialogue: _openCinematicDialogue,
                                  onCinematicLocate: _locateCinematic,
                                  dialogues: _dialogues,
                                  dialogueViews: _dialogueViews,
                                  dialogueOrigin: _dialogueOrigin,
                                  onDialogues: _openDialogues,
                                  onSceneDialogue: _openSceneDialogue,
                                  onDialogueBack: () => _show(_dialogueOrigin),
                                  events: _events,
                                  eventView: _eventView,
                                  eventMaps: _eventMaps,
                                  onEvents: _openEvents,
                                  onReturnEvents: () =>
                                      _show(WorkspaceSpace.events),
                                  onEventBack: () => _show(_eventOrigin),
                                  onEventLocate: _locateEvent,
                                  onEventTest: _testEvent,
                                  narrative: _narrative,
                                  verification: _verification,
                                  scenes: _scenes,
                                  sceneViews: _sceneViews,
                                  stories: _stories,
                                  progressionViews: _progressionViews,
                                  sceneOrigin: _sceneOrigin,
                                  onProgression: _openProgression,
                                  onReturnProgression: () =>
                                      _show(WorkspaceSpace.progression),
                                  onScenes: _openScenes,
                                  onWorld: _world == null ? null : _openWorld,
                                  onProgressionBack: () =>
                                      _show(_progressionOrigin.space),
                                  onReturnVerification: _verification == null
                                      ? null
                                      : () =>
                                            _show(WorkspaceSpace.verification),
                                  progressionBackLabel:
                                      _progressionOrigin.space ==
                                          WorkspaceSpace.verification
                                      ? 'Vérification'
                                      : 'Histoire',
                                  onVerification: _verification == null
                                      ? null
                                      : _openVerification,
                                  onOpenScene: _openScene,
                                  onOpenStep: _openProgressionStep,
                                  onOpenDialogue: _openNarrativeDialogue,
                                  onOpenEvent: _openNarrativeEvent,
                                  onOpenMap: _openNarrativeMap,
                                  resources: _resources,
                                  visuals: _visuals,
                                  onMap: _openMap,
                                  storyViewState: _storyViewState,
                                  interactionOrigin: _interactionOrigin,
                                  onStory: () => _show(WorkspaceSpace.story),
                                  onOpenInteraction: _openStoryInteraction,
                                  onLocateInteraction: _locateStoryInteraction,
                                  onCreateInteraction: _createStoryInteraction,
                                  onTest: _actions.test,
                                  imagePicker: widget.imagePicker,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ?_contextMenuOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<PokemonSpeciesSummary>> _loadSceneSpecies() async {
    final owner = _pokemon;
    if (owner == null) throw StateError('Catalogue indisponible.');
    final index = await owner.port.loadIndex();
    if (!mounted || !identical(owner, _pokemon)) {
      throw StateError('Le projet a changé.');
    }
    if (!index.enabled) throw StateError('Catalogue Pokémon désactivé.');
    return index.entries;
  }

  Future<Map<String, String>> _loadSceneMoves() async {
    final owner = _pokemon;
    if (owner == null) throw StateError('Catalogue indisponible.');
    await owner.load(refresh: true);
    if (!mounted || !identical(owner, _pokemon)) {
      throw StateError('Le projet a changé.');
    }
    final moves = owner.index?.moves;
    if (owner.error != null ||
        moves == null ||
        !moves.available ||
        moves.diagnostics.isNotEmpty) {
      throw StateError(
        'Le catalogue des capacités est indisponible ou ambigu.',
      );
    }
    return {for (final move in moves.entries) move.id: move.name};
  }

  Future<Map<String, String>> _loadSceneCaptureItems() =>
      _loadSceneItems(captureOnly: true);

  Future<Map<String, String>> _loadSceneItems({
    bool captureOnly = false,
  }) async {
    final owner = _pokemon;
    if (owner == null) throw StateError('Catalogue indisponible.');
    final index = await owner.port.loadIndex();
    if (!mounted || !identical(owner, _pokemon)) {
      throw StateError('Le projet a changé.');
    }
    if (!index.enabled) throw StateError('Catalogue Pokémon désactivé.');
    final catalog = index.itemCatalog;
    final itemIds = <String>{};
    if (catalog == null ||
        catalog.entries.any(
          (item) =>
              item.id.isEmpty ||
              item.id.trim() != item.id ||
              item.displayName.trim().isEmpty ||
              !itemIds.add(item.id),
        )) {
      throw StateError('Le catalogue des objets est indisponible ou ambigu.');
    }
    return {
      for (final item in catalog.entries)
        if (!captureOnly || item.capture != null) item.id: item.displayName,
    };
  }
}
