part of 'map_editing_commands.dart';

extension _MapElementPlacementCommands on MapEditingCommands {
  String? _placeElement(ProjectElementEntry element, GridPos position) {
    final current = project.elements
        .where((entry) => entry.id == element.id)
        .firstOrNull;
    if (current == null) {
      document.error = 'Ce décor n’est plus disponible dans le projet.';
      return null;
    }
    element = current;
    var map = document.current;
    final layer = supportLayer(
      map,
      preferredLayerId: element.recommendedLayerId,
    );
    if (!map.layers.any((entry) => entry.id == layer.id)) {
      final layers = [...map.layers];
      layers.insert(
        resolveAuthoredLayerInsertIndex(map, activeLayerId: null),
        layer,
      );
      map = map.copyWith(layers: layers);
    }
    final id = _freshElementId(map);
    final instance = MapPlacedElement(
      id: id,
      layerId: layer.id,
      elementId: element.id,
      pos: position,
      properties: const {
        pokemapPlacementOriginProperty: pokemapPlacementOriginAuthored,
      },
      visualOrder: _topVisualOrder(map, layer.id) + 1,
    );
    if (!_fits(instance, element)) {
      document.error = 'Ce décor dépasse les limites de la carte.';
      return null;
    }
    document.commit(upsertMapPlacedElement(map, instance: instance));
    document.selectedId = id;
    document.stackPosition = position;
    document.stackPixelPosition = null;
    return id;
  }

  String? _cloneElement(String sourceId) {
    final map = document.current;
    final source = map.placedElements
        .where((element) => element.id == sourceId)
        .firstOrNull;
    if (source == null) return null;
    final element = project.elements
        .where((entry) => entry.id == source.elementId)
        .firstOrNull;
    if (element == null) {
      document.error = 'Ce décor n’est plus disponible dans le projet.';
      return null;
    }
    final id = _freshElementId(map);
    final copy = source.copyWith(
      id: id,
      visualOrder: _topVisualOrder(map, source.layerId) + 1,
      properties: {
        ...source.properties,
        pokemapPlacementOriginProperty: pokemapPlacementOriginAuthored,
      },
    );
    if (!_fits(copy, element)) {
      document.error = 'Ce décor dépasse les limites de la carte.';
      return null;
    }
    document.commit(upsertMapPlacedElement(map, instance: copy));
    document.selectedId = id;
    document.stackPosition = copy.pos;
    document.stackPixelPosition = null;
    return id;
  }

  String _freshElementId(MapData map) {
    String id;
    do {
      id =
          'studio-${DateTime.now().microsecondsSinceEpoch}-${MapEditingCommands._nextId++}';
    } while (map.placedElements.any((element) => element.id == id));
    return id;
  }

  int _topVisualOrder(MapData map, String layerId) => map.placedElements
      .where((element) => element.layerId == layerId)
      .fold(
        0,
        (rank, element) =>
            element.visualOrder > rank ? element.visualOrder : rank,
      );
}
