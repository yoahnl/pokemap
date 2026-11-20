part of 'map_builder_page.dart';

extension _MapBuilderPageResources on _MapBuilderPageState {
  Widget _resourceLibrary(ProjectLibraryManagement? management) {
    final packPort =
        widget.session.storage == ProjectSessionStorage.workingCatalog
        ? ref.watch(resourcePackPortProvider(widget.session))
        : null;
    return ProjectLibraryPage(
      active: _section == StudioRailSection.resources && !_sceneShown,
      maps: _maps,
      visuals: _visuals,
      management: _editable ? management : null,
      onModelWorkshopPublished: (receipt) =>
          _projection.acceptModelWorkshopReceipt(_maps, receipt),
      onOpenMap: _openMapFromResources,
      packPort: packPort,
      pickPack: packPort == null ? null : ref.watch(resourcePackPickerProvider),
      onPackDialogChanged: _setPackDialogOpen,
    );
  }

  void _setPackDialogOpen(bool value) {
    _packDialogOpen = value;
    if (value) _protect();
  }

  Future<bool> _openMapFromResources(String mapId) =>
      _openMapFromSection(mapId, StudioRailSection.resources);

  Future<bool> _openMapFromSection(
    String mapId,
    StudioRailSection source,
  ) async {
    final sectionGeneration = _storyNavigation;
    bool current() =>
        mounted &&
        !_disposed &&
        _section == source &&
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
