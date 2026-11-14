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
      port: _storyPorts.narrative.read(),
      staging: _storyMemory,
      maps: _maps.project?.maps ?? const [],
      loadMap: switch (_storyPorts.world.read()) {
        final WorldMapSelectionPort port => port.loadMap,
        _ => null,
      },
      behaviours: (
        available: (id) => _behaviourEntry(id) != null,
        open: (id) => unawaited(_openBehaviour(id)),
      ),
    );
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

  Future<void> _openBehaviour(String eventId) async {
    final target = _behaviourEntry(eventId);
    if (target == null || !_editable) return;
    final (entry, kind, id) = target;
    _setSection(StudioRailSection.map);
    _setSpace(MapBuilderSpace.story);
    if (_maps.active?.base.mapId != entry.id) await _maps.activate(entry);
    await _story.prepare();
    if (_disposed || _maps.active?.base.mapId != entry.id) return;
    final element = _story.elements?.byKey('${kind.name}:$id');
    if (element == null) return;
    _story.select(element);
    final index = element.behaviours.indexWhere((item) => item.id == eventId);
    if (index >= 0) _story.openBehaviour(index);
    _story.openTab(MapStoryTab.behaviour);
  }
}
