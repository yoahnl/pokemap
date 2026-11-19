part of 'map_builder_page.dart';

extension _MapBuilderPageLayout on _MapBuilderPageState {
  MapEditingViewportSession? get _view {
    final document = _maps.active;
    if (document == null) return null;
    return _views.putIfAbsent(
      document.base.mapId,
      () =>
          MapEditingViewportSession()
            ..ambiencePreview = _space == MapBuilderSpace.ambiance,
    );
  }

  bool get _editable =>
      !_exporting && !_maps.loading && !_maps.catalogBusy && !_maps.saving;

  ProjectMapEntry? get _activeEntry {
    final id = _maps.active?.base.mapId;
    return _maps.project?.maps.where((item) => item.id == id).firstOrNull;
  }

  void _setTool(StudioMapTool tool) {
    final view = _view;
    if (view == null) return;
    if (tool == StudioMapTool.select) {
      _resources.release();
      return;
    }
    view.tool = tool;
    if (tool == StudioMapTool.relief) unawaited(_prepareRelief(view));
    if (tool == StudioMapTool.stair) unawaited(_prepareStair(view));
    _changed();
  }

  Widget _layout({
    required VoidCallback onToggleInspector,
    required VoidCallback onCollapse,
  }) {
    final libraryWidth = (MediaQuery.sizeOf(context).width - studioRailWidth)
        .clamp(0.0, double.infinity)
        .toDouble();
    final project = _maps.project;
    final document = _maps.active;
    final entry = _activeEntry;
    final view = _view;
    final intent = view == null
        ? null
        : mapPaletteIntent(
            view,
            spatial: document?.current.spatialScene != null,
            project: _resources.catalog,
          );
    final toolLabel = view == null
        ? null
        : context.l10n.toolAction(
            view,
            spatial: document?.current.spatialScene != null,
          );
    return MinimumSizeViewport(
      minimum: mapBuilderMinimumSize,
      child: Column(
        children: [
          MapBuilderHeader(
            maps: _maps,
            draft: _draft,
            projectName: project?.name ?? widget.session.name,
            editable: _editable,
            saveFailed: _saveFailed,
            onSave: () => unawaited(_save()),
            onTestMap: () => unawaited(_testMap()),
            onExportGame: project == null
                ? null
                : () => unawaited(_exportGame()),
            testing: _testing,
            ambiance: _historyAmbiance,
            story: _historyStory,
            history: _historyOpen,
            scope: _historyScope,
            pendingInput: _typing || _textTransactions.pending,
            onHistoryStep: (redo) => unawaited(_stepHistory(redo: redo)),
          ),
          ?_storyReturnBar(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StudioRail(
                  onHome: () => unawaited(widget.onHome()),
                  section: _section,
                  onSection: _setSection,
                ),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      IndexedStack(
                        index: _section.index,
                        sizing: StackFit.expand,
                        children: [
                          _retainedSurface(
                            visible:
                                _section == StudioRailSection.map &&
                                !_sceneShown,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                MapBuilderSidePanel(
                                  space: _space,
                                  story: _story,
                                  gameplay: _gameplay,
                                  ambiance: _ambiance,
                                  resources: _resources,
                                  maps: _maps,
                                  visuals: _visuals,
                                  enabled: _editable,
                                  mapTreeMemory: _mapTreeMemory,
                                ),
                                Expanded(
                                  child: MapBuilderCanvas(
                                    space: _space,
                                    onSpace: _setSpace,
                                    entry: entry,
                                    tool: view?.tool ?? StudioMapTool.select,
                                    onTool: _setTool,
                                    inspectorOpen: _inspectorOpen,
                                    onToggleInspector: onToggleInspector,
                                    error:
                                        _maps.error ??
                                        _visualsError ??
                                        _resourceProblem() ??
                                        document?.error,
                                    borderWarnings:
                                        document?.borderWarnings ?? const {},
                                    reliefAvailable: _reliefAvailable,
                                    reliefPalette: _reliefPalette(view),
                                    reliefNotice: _constructionNotice(view),
                                    surface: _surface(),
                                    statusBar: MapBuilderStatusBar(
                                      toolLabel:
                                          _resources.armed != null ||
                                              _gameplay.placing ||
                                              const {
                                                StudioMapTool.relief,
                                                StudioMapTool.slope,
                                                StudioMapTool.stair,
                                              }.contains(view?.tool)
                                          ? toolLabel ??
                                                context.l10n.statusBuilding
                                          : view?.tool == StudioMapTool.pan
                                          ? context.l10n.toolPan
                                          : context.l10n.toolSelect,
                                      view: view,
                                      spatial:
                                          document?.current.spatialScene !=
                                          null,
                                      onChanged: _changed,
                                    ),
                                  ),
                                ),
                                if (_inspectorOpen)
                                  MapBuilderInspector(
                                    entry: entry,
                                    projectName:
                                        project?.name ?? widget.session.name,
                                    space: _space,
                                    armed: _resources.armed,
                                    toolLabel: toolLabel,
                                    toolHint: view == null
                                        ? null
                                        : context.l10n.toolHint(
                                            view,
                                            armed: intent?.armed ?? false,
                                          ),
                                    onRelease: _resources.release,
                                    onCollapse: onCollapse,
                                    body:
                                        _constructionInspector(view) ??
                                        _selectionInspector(view) ??
                                        mapBuilderSpaceInspector(
                                          _space,
                                          _gameplay,
                                          _ambiance,
                                          context.l10n,
                                          enabled: _editable,
                                          story: _story,
                                        ),
                                  ),
                              ],
                            ),
                          ),
                          _retainedSurface(
                            visible:
                                _section == StudioRailSection.story &&
                                !_sceneShown,
                            child: _storyPage(),
                          ),
                          Align(
                            alignment: AlignmentDirectional.topStart,
                            child: SizedBox(
                              width: libraryWidth,
                              height: double.infinity,
                              child: ProjectLibraryPage(
                                active:
                                    _section == StudioRailSection.resources &&
                                    !_sceneShown,
                                maps: _maps,
                                visuals: _visuals,
                              ),
                            ),
                          ),
                        ],
                      ),
                      ?_scenePage(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _retainedSurface({required bool visible, required Widget child}) =>
      TickerMode(
        enabled: visible,
        child: TooltipVisibility(
          visible: visible && TooltipVisibility.of(context),
          child: child,
        ),
      );

  Widget _keyboard(Widget child) => CallbackShortcuts(
    bindings: textAwareEditorShortcuts({
      for (final meta in [true, false]) ...{
        SingleActivator(
          LogicalKeyboardKey.keyS,
          meta: meta,
          control: !meta,
        ): () {
          if (_editable) unawaited(_save());
        },
        SingleActivator(
          LogicalKeyboardKey.keyZ,
          meta: meta,
          control: !meta,
        ): () =>
            _stepHistory(redo: false),
        SingleActivator(
          LogicalKeyboardKey.keyZ,
          meta: meta,
          control: !meta,
          shift: true,
        ): () =>
            _stepHistory(redo: true),
      },
    }),
    child: EditorTextTransactionsScope(
      transactions: _textTransactions,
      child: FocusScope(
        autofocus: true,
        child: Focus(focusNode: _pageFocus, child: child),
      ),
    ),
  );

  Future<void> _stepHistory({required bool redo}) async {
    await _commitTyping();
    if (_disposed) return;
    final step = _historyStep(redo: redo);
    if (step == null) return;
    step();
    _changed();
  }

  String? _resourceProblem() => switch (_resources.problem) {
    MapBuilderResourceProblem.loadFailed => context.l10n.resourcesUnavailable(
      '${_resources.problemCause}',
    ),
    MapBuilderResourceProblem.tileUnavailable =>
      context.l10n.tileChoiceUnavailable,
    null => _resources.error,
  };

  Widget? _surface() {
    final visuals = _visuals;
    final view = _view;
    if (visuals == null || view == null || _maps.active == null) return null;
    return MapCanvasReadinessScope(
      readiness: _opening.readiness,
      child: MapEditingSurface(
        controller: _maps,
        visuals: visuals,
        view: view,
        input: _input,
        onChanged: _changed,
        onSave: () => unawaited(_save()),
        onUndo: () => unawaited(_stepHistory(redo: false)),
        onRedo: () => unawaited(_stepHistory(redo: true)),
        onCanvasMenu: _showCanvasMenu,
        onZoneDrawn: _space == MapBuilderSpace.story ? _story.addZone : null,
        busy: !_editable,
      ),
    );
  }

  VoidCallback? _historyStep({required bool redo}) => mapBuilderHistoryStep(
    _maps,
    redo: redo,
    editable: _editable && _historyOpen,
    ambiance: _historyAmbiance,
    story: _historyStory,
    scope: _historyScope,
  );

  bool get _historyOpen =>
      _activeScene != null ||
      _section == StudioRailSection.map ||
      _section == StudioRailSection.story;

  StoryHistoryScope? get _historyScope => switch (_activeScene) {
    final focus? => StoryHistoryScope({
      (kind: StoryDraftKind.scene, id: focus.sceneId),
      if (focus.behaviourId case final id?)
        (kind: StoryDraftKind.event, id: id),
    }),
    null when _section == StudioRailSection.story => _storyScope,
    _ => null,
  };

  MapBuilderAmbianceBinding? get _historyAmbiance =>
      _activeScene == null && _space == MapBuilderSpace.ambiance
      ? _ambiance
      : null;

  MapBuilderStoryBinding? get _historyStory =>
      _activeScene != null ||
          _section == StudioRailSection.story ||
          _space == MapBuilderSpace.story
      ? _story
      : null;
}
