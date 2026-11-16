part of 'map_builder_page.dart';

extension _MapBuilderPageStory on _MapBuilderPageState {
  void _setSection(StudioRailSection section, {bool navigation = false}) {
    if (!navigation) {
      _storyNavigation++;
      _storyOrigins.clear();
      _storyNavigationProblem = null;
    }
    if (section == _section && !_sceneShown) return;
    unawaited(_commitTyping());
    if (section != StudioRailSection.map) _resources.release();
    _sceneShown = false;
    _section = section;
    _storyShown |= section == StudioRailSection.story;
    _changed();
  }

  Widget _storyPage() {
    if (!_storyShown) return const SizedBox.shrink();
    return StoryPage(
      key: ValueKey('studio-story-${widget.session.sessionId}'),
      port: _stories.narrative,
      staging: _stories.memory,
      maps: _maps.project?.maps ?? const [],
      loadMap: switch (_stories.world) {
        final WorldMapSelectionPort port => port.loadMap,
        _ => null,
      },
      behaviours: (
        available: (id) => _behaviourEntry(id) != null,
        open: _openBehaviour,
      ),
      behaviourSource: _stories.behaviours,
      trame: _story.trame,
      catalog: _stories.scenes,
      behaviourCatalog: _stories.catalog,
      openMap: () {
        _rememberStoryOrigin();
        _setSection(StudioRailSection.map, navigation: true);
        _setSpace(MapBuilderSpace.story);
      },
      verification: _stories.verification,
      unsaved: _draft.unsaved,
      saveError: switch (_story.saveError) {
        final error? when _story.dirty => mapBuilderStoryError(
          error,
          context.l10n,
        ),
        _ => null,
      },
      openScene: _openScene,
      beforeNavigation: _commitTyping,
      onHistoryScopeChanged: (scope) {
        if (scope == _storyScope) return;
        _storyScope = scope;
        _changed();
      },
      simulate: (id) async {
        final opened = await _openBehaviour(id);
        if (opened) _story.toggleSimulation(id);
        return opened;
      },
      openMapEntry: (mapId) async {
        final entry = _maps.project?.maps
            .where((entry) => entry.id == mapId)
            .firstOrNull;
        if (entry == null) return false;
        await _commitTyping();
        if (_disposed) return false;
        _rememberStoryOrigin();
        _setSection(StudioRailSection.map, navigation: true);
        if (_maps.active?.base.mapId != entry.id) await _maps.activate(entry);
        return true;
      },
    );
  }

  Future<ProjectManifest?> _verificationProject() async {
    await _maps.ensureWorkshop(MapWorkspaceWorkshop.verification);
    return _maps.project;
  }

  (ProjectMapEntry, MapStoryElementTarget, String)? _behaviourEntry(
    String eventId,
  ) {
    final project = _maps.project;
    final record =
        (project == null ? null : _story.behaviours.registry(project))?.records
            .where((record) => record.id == eventId)
            .firstOrNull;
    final at = record == null ? null : mapStoryLocation(record);
    final entry = at == null
        ? null
        : project!.maps.where((entry) => entry.id == at.$1).firstOrNull;
    return entry == null ? null : (entry, at!.$2, at.$3);
  }

  Future<bool> _openBehaviour(String eventId) async {
    await _commitTyping();
    if (!mounted || _disposed) return false;
    final target = _behaviourEntry(eventId);
    if (target == null) {
      _storyNavigationProblem = context.l10n.storyDestinationUnavailable;
      _changed();
      return false;
    }
    final (entry, kind, id) = target;
    if (_activeScene != null || _section == StudioRailSection.story) {
      _rememberStoryOrigin();
    }
    final navigation = ++_storyNavigation;
    _setSection(StudioRailSection.map, navigation: true);
    _setSpace(MapBuilderSpace.story);
    if (_maps.active?.base.mapId != entry.id) await _maps.activate(entry);
    await _story.prepare();
    if (!mounted || _disposed || navigation != _storyNavigation) return false;
    if (_maps.active?.base.mapId != entry.id ||
        _behaviourEntry(eventId) == null) {
      return _storyDestinationUnavailable();
    }
    final element = _story.elements?.byKey('${kind.name}:$id');
    final index =
        element?.behaviours.indexWhere((item) => item.id == eventId) ?? -1;
    if (element == null || index < 0) {
      _storyNavigationProblem = context.l10n.storyDestinationUnavailable;
      _changed();
      return false;
    }
    _story
      ..select(element)
      ..openBehaviour(index)
      ..openTab(MapStoryTab.behaviour);
    return true;
  }
}
