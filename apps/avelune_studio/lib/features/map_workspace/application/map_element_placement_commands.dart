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
    String id;
    do {
      id =
          'studio-${DateTime.now().microsecondsSinceEpoch}-${MapEditingCommands._nextId++}';
    } while (map.placedElements.any((element) => element.id == id));
    final instance = MapPlacedElement(
      id: id,
      layerId: layer.id,
      elementId: element.id,
      pos: position,
      properties: const {
        pokemapPlacementOriginProperty: pokemapPlacementOriginAuthored,
      },
      visualOrder:
          map.placedElements
              .where((e) => e.layerId == layer.id)
              .fold(
                0,
                (rank, e) => e.visualOrder > rank ? e.visualOrder : rank,
              ) +
          1,
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
}
