part of 'map_builder_page.dart';

extension _MapBuilderPageResources on _MapBuilderPageState {
  Widget _resourceLibrary(ProjectLibraryManagement? management) =>
      ProjectLibraryPage(
        active: _section == StudioRailSection.resources && !_sceneShown,
        maps: _maps,
        visuals: _visuals,
        management: _editable ? management : null,
        onModelWorkshopPublished: (receipt) =>
            _projection.acceptModelWorkshopReceipt(_maps, receipt),
        onOpenMap: _openMapFromResources,
      );

  Future<bool> _openMapFromResources(String mapId) async {
    final sectionGeneration = _storyNavigation;
    bool current() =>
        mounted &&
        !_disposed &&
        _section == StudioRailSection.resources &&
        sectionGeneration == _storyNavigation &&
        !_sceneShown;

    if (!current() || _maps.loading) return false;
    final entry = _maps.project?.maps
        .where((entry) => entry.id == mapId)
        .firstOrNull;
    if (entry == null) return false;
    await _commitTyping();
    if (!current() || _maps.loading) return false;
    if (_maps.active?.base.mapId != mapId) {
      await _maps.activate(entry, isCurrent: current);
    }
    if (!current() || _maps.active?.base.mapId != mapId) return false;
    _setSection(StudioRailSection.map);
    _setSpace(MapBuilderSpace.construction);
    return true;
  }
}
