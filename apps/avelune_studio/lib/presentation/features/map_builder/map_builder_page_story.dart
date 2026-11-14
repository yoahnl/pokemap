part of 'map_builder_page.dart';

extension _MapBuilderPageStory on _MapBuilderPageState {
  void _setSection(StudioRailSection section) {
    if (section == _section) return;
    _commitTyping();
    if (section != StudioRailSection.map) _resources.release();
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
      openMap: () {
        _setSection(StudioRailSection.map);
        _setSpace(MapBuilderSpace.story);
      },
      verification: _stories.verification,
      unsaved: _draft.unsaved,
      simulate: (id) async {
        final opened = await _openBehaviour(id);
        if (opened) _story.toggleSimulation(id);
        return opened;
      },
      openMapEntry: (mapId) async {
        final entry = _maps.project?.maps
            .where((entry) => entry.id == mapId)
            .firstOrNull;
        if (entry == null || !_editable) return false;
        _setSection(StudioRailSection.map);
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
    final record = project?.eventRegistry?.records
        .where((record) => record.id == eventId)
        .firstOrNull;
    final at = record == null ? null : mapStoryLocation(record);
    final entry = at == null
        ? null
        : project!.maps.where((entry) => entry.id == at.$1).firstOrNull;
    return entry == null ? null : (entry, at!.$2, at.$3);
  }

  Future<bool> _openBehaviour(String eventId) async {
    final target = _behaviourEntry(eventId);
    if (target == null || !_editable) return false;
    final (entry, kind, id) = target;
    _setSection(StudioRailSection.map);
    _setSpace(MapBuilderSpace.story);
    if (_maps.active?.base.mapId != entry.id) await _maps.activate(entry);
    await _story.prepare();
    if (_disposed || _maps.active?.base.mapId != entry.id) return false;
    final element = _story.elements?.byKey('${kind.name}:$id');
    final index =
        element?.behaviours.indexWhere((item) => item.id == eventId) ?? -1;
    if (element == null || index < 0) {
      _setSection(StudioRailSection.story);
      return false;
    }
    _story
      ..select(element)
      ..openBehaviour(index)
      ..openTab(MapStoryTab.behaviour);
    return true;
  }
}
