part of 'map_builder_page.dart';

class _MapBuilderPageState extends ConsumerState<MapBuilderPage> {
  late final ProviderSubscription<MapWorkspaceController> _subscription;
  late final ProviderSubscription<MapConnectionPort> _connections;
  late final ProviderSubscription<StoryPublicationGatewayFactory> _publications;
  ProviderSubscription<StudioRuntimeBuilder>? _runtime;
  late final MapWorkspaceController _maps;
  late final MapEditingInputSession _input;
  late final StudioExitGuard _exitGuard;
  late final _draft = ProjectDraft([MapWorkspaceDraft(_maps), _story]);
  final _pageFocus = FocusNode(debugLabel: 'map-builder', skipTraversal: true);
  late final _textTransactions = EditorTextTransactions(_changed);
  var _hadTyping = false;
  var _guarded = false;
  Future<bool>? _leaving;
  final _views = <String, MapEditingViewportSession>{};
  final _mapTreeMemory = MapBuilderMapTreeMemory();
  MapWorkspaceVisuals? _visuals;
  String? _visualsError;
  var _saveFailed = false;
  var _testing = false;
  SceneFocusController? _sceneFocus;
  var _sceneShown = false;
  final _storyOrigins = <_StoryOrigin>[];
  var _storyNavigation = 0;
  ({String? eventId})? _storyNavigationProblem;
  ({String id, int token})? _dialogueRequest;
  ({String? id, String mapId, int token})? _behaviourRequest;

  SceneFocusController? get _activeScene => _sceneShown ? _sceneFocus : null;
  late final _projection = WorkspaceVisualProjectionQueue(
    currentVisuals: () => _visuals,
    activeMap: () => _maps.active?.current,
    isActive: () => !_disposed,
    prepared: (_) {},
    failed: (failure) => _visualsError = context.l10n.mapResourcesUnavailable(
      mapFailureMessage(failure),
    ),
    changed: _changed,
  );
  late final _resources = MapBuilderResourceBinding(
    maps: _maps,
    view: () => _view,
    visuals: () => _visuals,
    isActive: () => !_disposed,
    changed: _changed,
  );
  late final _gameplay = MapBuilderGameplayBinding(
    maps: _maps,
    view: () => _view,
    port: configuredConnectionPort(_connections.read),
    isActive: () => !_disposed,
    changed: _changed,
    labels: () => context.l10n,
    entityDeletionProblem: (id) =>
        _story.deletionProblem(MapStoryElementTarget.entity, id),
    storyProject: (project) => _story.behaviours.project(project),
  );
  late final _story = MapBuilderStoryBinding(
    maps: _maps,
    changed: _changed,
    view: () => _view,
    zoneName: () => context.l10n.storyNewZone,
    behaviourName: (index) => context.l10n.storyBehaviourName(index),
    conflictMessage: (names) =>
        context.l10n.leaveGuardStoryConflict(names.join(', ')),
    deletionRefusal: (name, behaviours) => context.l10n.storyElementInUse(
      name,
      behaviours.length,
      behaviours.join(', '),
    ),
    gateway: (draft, saved) => _publications.read()(draft, saved),
    loadDialogue: ref.read(storyDialogueLoaderProvider(widget.session)),
    loadMedia: (project) async =>
        switch (ref.read(eventPortProvider(widget.session))) {
          final EventPresentationCatalogPort port =>
            await port.loadPresentationMediaCatalog(project),
          _ => null,
        },
  );
  late final _ambiance = MapBuilderAmbianceBinding(
    maps: _maps,
    changed: _changed,
    view: () => _view,
  );
  late final _opening = MapBuilderOpening(widget.progress);
  late final _stories = MapBuilderStoryServices(
    ref: ref,
    session: widget.session,
    story: _story,
    editable: () => _editable,
    changed: _changed,
    verificationProject: _verificationProject,
  );
  var _section = StudioRailSection.map;
  var _storyShown = false;
  var _storyScope = const StoryHistoryScope.empty();
  var _space = MapBuilderSpace.construction;
  var _inspectorOpen = true;
  var _disposed = false;

  @override
  void initState() {
    super.initState();
    _subscription = ref.listenManual(
      mapWorkspaceControllerProvider(widget.session),
      (_, _) {},
    );
    _maps = _subscription.read();
    _publications = ref.listenManual(
      storyPublicationGatewayProvider(widget.session),
      (_, _) {},
    );
    _maps.modelDeletionGuard = _story.modelDeletionProblem;
    _stories.attach();
    _story.openScene = _openScene;
    _story.openInStory = _openTriggerInStory;
    _story.openMapInStory = () => _openTriggerInStory(null);
    _connections = ref.listenManual(
      mapConnectionPortProvider(widget.session),
      (_, _) {},
    );
    _input = MapBuilderInputSession(
      controller: _maps,
      view: () => _view,
      story: _story,
    );
    _exitGuard = ref.read(studioExitGuardProvider);
    _maps.addListener(_changed);
    FocusManager.instance.addListener(_focusChanged);
    unawaited(_open());
  }

  Future<void> _open() async {
    _opening.loadingMap();
    await _maps.initialize();
    final project = _maps.project;
    if (_disposed) return;
    _opening.mapSettled(failed: _maps.error != null);
    if (project == null) return;
    try {
      final visuals = await ref.read(workspaceVisualsLoaderProvider)(
        widget.session,
        project,
      );
      if (_disposed) {
        unawaited(visuals.dispose());
        return;
      }
      visuals.addListener(_changed);
      _visuals = visuals;
      _opening.resourcesReady();
      _changed();
      _opening.awaitScene(hasMap: _maps.active != null);
      unawaited(
        _resources.load().then((_) {
          if (_disposed) return;
          _opening.paletteSettled(
            failed: _resources.problem == MapBuilderResourceProblem.loadFailed,
          );
        }),
      );
    } catch (failure) {
      _opening.resourcesFailed();
      if (!_disposed) {
        setState(
          () => _visualsError = context.l10n.mapResourcesUnavailable(
            mapFailureMessage(failure),
          ),
        );
      }
    }
  }

  void _changed() {
    if (_disposed) return;
    pruneMissingMapSelection(_views, _maps.active);
    releaseStaleMapMoves(_views, _maps.active);
    _projection.synchronize(_maps.visualProject);
    _resources.follow(_activeEntry);
    _resources.reconcileTool();
    _gameplay.reconcile();
    _ambiance.reconcile();
    _story.reconcile();
    _reconcileStoryNavigationProblem();
    _protect();
    if (mounted) setState(() {});
  }

  void _focusChanged() {
    final typing = _typing;
    if (typing) _protect();
    if (_hadTyping == typing) return;
    _hadTyping = typing;
    _changed();
  }

  Future<bool> _save() async {
    await _commitTyping();
    if (_disposed) return false;
    setState(() => _saveFailed = false);
    final saved = await _draft.save();
    if (!_disposed) setState(() => _saveFailed = !saved);
    return saved;
  }

  Future<bool> _confirmLeave() =>
      _leaving ??= _askToLeave().whenComplete(() => _leaving = null);

  Future<void> _testMap() async {
    final document = _maps.active;
    final entry = _activeEntry;
    if (document == null || entry == null || _testing) return;
    await _commitTyping();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _testing = true;
      _saveFailed = false;
    });
    try {
      if (_draft.unsaved) {
        final saved = await _draft.save();
        if (!mounted) return;
        if (!saved) {
          setState(() => _saveFailed = true);
          return;
        }
      }
      if (!mounted || !identical(_maps.active, document) || _maps.loading) {
        return;
      }
      if (_maps.dirty) {
        document.error = context.l10n.testMapChangedAgain;
        _changed();
        return;
      }
      final runtime = (_runtime ??= ref.listenManual(
        sessionRuntimeBuilderProvider(widget.session),
        (_, _) {},
      )).read();
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (route) => MapBuilderPlaytestPage(
            entry: entry,
            revision: document.base.revision,
            runtime: runtime,
            onClose: () => Navigator.of(route).pop(),
          ),
        ),
      );
    } finally {
      if (!_disposed) setState(() => _testing = false);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    FocusManager.instance.removeListener(_focusChanged);
    if (_guarded) {
      _exitGuard.register(widget.session.sessionId, null);
    }
    _pageFocus.dispose();
    _ambiance.dispose();
    if (_maps.modelDeletionGuard == _story.modelDeletionProblem) {
      _maps.modelDeletionGuard = null;
    }
    _maps.removeListener(_changed);
    _input.dispose();
    for (final view in _views.values) {
      view.dispose();
    }
    final visuals = _visuals;
    if (visuals != null) {
      visuals.removeListener(_changed);
      unawaited(visuals.dispose());
    }
    _runtime?.close();
    _stories.close();
    _publications.close();
    _connections.close();
    _subscription.close();
    super.dispose();
  }

  void _setSpace(MapBuilderSpace space) {
    if (space != MapBuilderSpace.construction) _resources.release();
    if (space != MapBuilderSpace.gameplay) _gameplay.leave();
    if (space != MapBuilderSpace.story) {
      _story
        ..cancelAdding()
        ..choosing = false;
    } else {
      unawaited(_story.prepare());
    }
    _gameplay
      ..shown = space == MapBuilderSpace.gameplay
      ..reconcile();
    _ambiance
      ..shown = space == MapBuilderSpace.ambiance
      ..reconcile();
    for (final view in _views.values) {
      view.ambiencePreview = space == MapBuilderSpace.ambiance;
    }
    setState(() => _space = space);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('map-builder'),
      body: _keyboard(
        StoryDialogueNavigation(
          open: _openDialogue,
          loadLanguages: _stories.dialogues?.languages,
          child: _layout(
            onToggleInspector: () =>
                setState(() => _inspectorOpen = !_inspectorOpen),
            onCollapse: () => setState(() => _inspectorOpen = false),
          ),
        ),
      ),
    );
  }
}
