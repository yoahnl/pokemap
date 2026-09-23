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
                    _resources?.busy == true ||
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
                          visuals: _visuals,
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
                          onMap: _openMap,
                          onStory: _narrative == null
                              ? null
                              : () => _show(WorkspaceSpace.story),
                          onEditInteraction: _editInteraction,
                          onZoneDrawn: _narrative == null ? null : _zone,
                          referenceGuard: _draftReferences.guard,
                          onContextMenu: _openContextMenu,
                          movingHint: _view?.moveHint,
                          onOpenElement: (element) => _openResources(element),
                          onEditElement: (element) =>
                              _openResources(element, true),
                          onExport: () {
                            if (_gameExport != null) {
                              _show(WorkspaceSpace.gameExport);
                            }
                          },
                          resourceContent: _space == WorkspaceSpace.gameExport
                              ? StudioGameExportPage(
                                  controller: _gameExport!,
                                  prepare: _prepareGameExport,
                                  preparationFailure: () =>
                                      _actions.exportPreparationFailure,
                                  hasPendingChanges: () =>
                                      _actions.hasPendingChanges,
                                  isCurrentProject: () =>
                                      mounted &&
                                      !_controller.isDisposed &&
                                      _controller.session.directoryPath ==
                                          widget
                                              .controller
                                              .session
                                              .directoryPath,
                                  pickFile: widget.gameExportPicker!,
                                )
                              : _space == WorkspaceSpace.verification
                              ? _verificationPage()
                              : _space == WorkspaceSpace.world
                              ? _worldPage()
                              : _space == WorkspaceSpace.presentation
                              ? _presentationPage()
                              : workspaceSecondaryContent(
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
}
