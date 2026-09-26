part of 'studio_map_resources.dart';

extension StudioMapResourcesHelpers on StudioMapResources {
  void _setActiveMap(MapData map) {
    if (_disposed) return;
    _activeMap = map;
    borderPreview.setActiveMap(manifest, map);
    final ids = mapResourceIds(map);
    activeResourceIds = {
      ...ids,
      if (borderPreview.hasBorderFeatures) 'border:${map.id}',
    };
    store.priority = {...ids, ..._brushIds};
    store.retain(_activeOwner, ids);
    _notify();
  }

  void _setBrush(ProjectElementEntry? element, TileLayerPaletteEntry? tile) {
    if (_disposed) return;
    _brushElement = element;
    _brushTile = tile;
    _terrainPreset = null;
    _characterBrush = null;
    _brushIds = element != null
        ? elementResourceIds(element)
        : tile != null
        ? tileResourceIds(tile)
        : {};
    store.priority = {...activeResourceIds, ..._brushIds};
    store.retain(_brushOwner, _brushIds);
  }

  Set<String> elementResourceIds(ProjectElementEntry element) =>
      _index.forElement(element);

  Set<String> characterResourceIds(ProjectCharacterEntry character) =>
      _index.forCharacter(character);

  Set<String> tileResourceIds(TileLayerPaletteEntry tile) =>
      _index.forTile(tile);

  Set<String> mapResourceIds(MapData map) => _index.forMap(map);

  bool hasFailure(Iterable<String> ids) => ids.any(_diagnostics.containsKey);

  RuntimeAuthoringMapRenderer renderer(MapData map) {
    if (_disposed) throw StateError('Ressources fermées');
    return createStudioMapRenderer(map, this);
  }
}
