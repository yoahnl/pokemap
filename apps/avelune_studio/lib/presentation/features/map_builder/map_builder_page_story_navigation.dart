part of 'map_builder_page.dart';

typedef _StoryOrigin = ({
  StudioRailSection section,
  StorySection? workspace,
  MapBuilderSpace space,
  SceneFocusController? scene,
  String? mapId,
  String query,
  MapStoryElementKind? filter,
  MapStoryTab tab,
  int behaviour,
  String? element,
  List<MapSelectionTarget> selection,
  Matrix4? transform,
  StudioMapTool? tool,
});

extension _MapBuilderStoryNavigation on _MapBuilderPageState {
  void _rememberStoryOrigin() {
    final origin = (
      section: _section,
      workspace: _section == StudioRailSection.story ? _storySection : null,
      space: _space,
      scene: _activeScene,
      mapId: _maps.active?.base.mapId,
      query: _story.query,
      filter: _story.filter,
      tab: _story.tab,
      behaviour: _story.behaviour,
      element: _story.selected?.key,
      selection:
          _view?.selectionIn(_maps.active!.base.mapId) ??
          const <MapSelectionTarget>[],
      transform: _view?.transform.value.clone(),
      tool: _view?.tool,
    );
    if (_storyOrigins.lastOrNull != origin) _storyOrigins.add(origin);
    _storyNavigationProblem = null;
  }

  Future<void> _returnToStoryOrigin() async {
    await _commitTyping();
    if (_disposed || _storyOrigins.isEmpty) return;
    final origin = _storyOrigins.removeLast();
    final navigation = ++_storyNavigation;
    final entry = _maps.project?.maps
        .where((entry) => entry.id == origin.mapId)
        .firstOrNull;
    if (entry != null && _maps.active?.base.mapId != entry.id) {
      await _maps.activate(entry);
    }
    if (!mounted || _disposed || navigation != _storyNavigation) return;
    if (origin.mapId != null && _maps.active?.base.mapId != origin.mapId) {
      _storyOrigins.add(origin);
      _storyNavigationProblem = (eventId: null);
      _changed();
      return;
    }
    _section = origin.section;
    _dialogueRequest = null;
    if (origin.workspace case final section?) {
      _storySectionRequest = (section: section, token: navigation);
    }
    _setSpace(origin.space);
    _story.restoreSelection(origin.element, origin.selection);
    _story
      ..query = origin.query
      ..filter = origin.filter
      ..tab = origin.tab
      ..behaviour = origin.behaviour;
    if (origin.transform case final transform?) {
      _view?.transform.value = transform.clone();
    }
    if (origin.tool case final tool?) {
      _view?.tool = tool;
    }
    _sceneShown = origin.scene != null;
    if (origin.scene != null) _sceneFocus = origin.scene;
    _changed();
  }

  Future<bool> _storyDestinationUnavailable([String? eventId]) async {
    await _returnToStoryOrigin();
    if (!mounted || _disposed) return false;
    _storyNavigationProblem = (eventId: eventId);
    _changed();
    return false;
  }

  void _reconcileStoryNavigationProblem() {
    final eventId = _storyNavigationProblem?.eventId;
    if (eventId == null) return;
    final target = _behaviourEntry(eventId);
    if (target == null || _maps.active?.base.mapId != target.$1.id) return;
    if (_story.elements?.byKey('${target.$2.name}:${target.$3}') != null) {
      _storyNavigationProblem = null;
    }
  }

  Widget? _storyReturnBar() {
    if (_activeScene != null) return null;
    final origin = _storyOrigins.lastOrNull;
    final problem = _storyNavigationProblem;
    if (origin == null && problem == null) return null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.l),
      child: Row(
        children: [
          if (origin != null)
            StudioButton(
              key: const ValueKey('story-return'),
              label: origin.scene != null
                  ? context.l10n.storyReturnScene
                  : origin.section == StudioRailSection.map
                  ? context.l10n.interactionReturnMap
                  : context.l10n.storyReturnHistory,
              icon: Icons.arrow_back,
              variant: StudioButtonVariant.quiet,
              onPressed: () => unawaited(_returnToStoryOrigin()),
            ),
          if (problem != null)
            Expanded(
              child: StudioNotice(
                context.l10n.storyDestinationUnavailable,
                isError: true,
              ),
            ),
        ],
      ),
    );
  }
}
