part of 'map_editing_commands.dart';

extension MapDecorCopyCommands on MapEditingCommands {
  String insertCopy(MapPlacedElement source, GridPos position) {
    final element = project.elements
        .where((entry) => entry.id == source.elementId)
        .firstOrNull;
    if (element == null) {
      throw StateError('Ce décor n’est plus disponible dans le projet.');
    }
    var map = document.current;
    var layerId = source.layerId;
    if (!map.layers.any((layer) => layer.id == layerId)) {
      final (withLayer, layer) = _withSupportLayer(map, element);
      map = withLayer;
      layerId = layer.id;
    }
    final copy = source.copyWith(
      id: _freshElementId(map),
      layerId: layerId,
      pos: position,
      visualOrder: _topVisualOrder(map, layerId) + 1,
      properties: {
        ...source.properties,
        pokemapPlacementOriginProperty: pokemapPlacementOriginAuthored,
      },
    );
    if (!_fits(copy, element)) {
      throw StateError('Ce décor dépasse les limites de la carte.');
    }
    document.commit(upsertMapPlacedElement(map, instance: copy));
    return copy.id;
  }
}
