part of 'map_builder_page.dart';

typedef _StoryOrigin = ({
  StudioRailSection section,
  MapBuilderSpace space,
  SceneFocusController? scene,
  String? mapId,
});

extension _MapBuilderStoryNavigation on _MapBuilderPageState {
  void _rememberStoryOrigin() {
    final origin = (
      section: _section,
      space: _space,
      scene: _activeScene,
      mapId: _maps.active?.base.mapId,
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
    if (_disposed || navigation != _storyNavigation) return;
    _section = origin.section;
    _setSpace(origin.space);
    _sceneShown = origin.scene != null;
    if (origin.scene != null) _sceneFocus = origin.scene;
    _changed();
  }

  Future<bool> _storyDestinationUnavailable() async {
    await _returnToStoryOrigin();
    if (!mounted || _disposed) return false;
    _storyNavigationProblem = context.l10n.storyDestinationUnavailable;
    _changed();
    return false;
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
                  : context.l10n.storyReturnHistory,
              icon: Icons.arrow_back,
              variant: StudioButtonVariant.quiet,
              onPressed: () => unawaited(_returnToStoryOrigin()),
            ),
          if (problem != null)
            Expanded(child: StudioNotice(problem, isError: true)),
        ],
      ),
    );
  }
}
