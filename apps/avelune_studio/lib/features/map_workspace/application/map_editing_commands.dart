import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';

class MapEditingCommands {
  MapEditingCommands(this.document, this.project);
  final EditableMapDocument document;
  final ProjectManifest project;
  static int _nextId = 0;

  String? place(ProjectElementEntry element, GridPos position) {
    var map = document.current;
    final layer = supportLayer(map);
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
      id = 'studio-${DateTime.now().microsecondsSinceEpoch}-${_nextId++}';
    } while (map.placedElements.any((element) => element.id == id));
    final instance = MapPlacedElement(
      id: id,
      layerId: layer.id,
      elementId: element.id,
      pos: position,
      visualOrder:
          map.placedElements
              .where((e) => e.layerId == layer.id)
              .fold(
                0,
                (rank, e) => e.visualOrder > rank ? e.visualOrder : rank,
              ) +
          1,
    );
    if (!_fits(instance, element)) return null;
    document.commit(upsertMapPlacedElement(map, instance: instance));
    document.selectedId = id;
    document.stackPosition = position;
    return id;
  }

  void move(String id, GridPos position) {
    final instance = document.current.placedElements
        .where((element) => element.id == id)
        .firstOrNull;
    if (instance == null) return;
    final element = project.elements
        .where((element) => element.id == instance.elementId)
        .firstOrNull;
    if (element == null || !_fits(instance.copyWith(pos: position), element)) {
      return;
    }
    document.commit(
      upsertMapPlacedElement(
        document.current,
        instance: instance.copyWith(pos: position),
      ),
    );
    document.stackPosition = position;
  }

  void deleteSelected() {
    final id = document.selectedId;
    if (id == null) return;
    document.commit(removeMapPlacedElement(document.current, instanceId: id));
  }

  void reorder({required bool forward}) {
    document.commit(_reordered(forward: forward));
  }

  bool canReorder({required bool forward}) =>
      _reordered(forward: forward) != document.current;

  bool canReorderAt({
    required String instanceId,
    required GridPos at,
    required bool forward,
  }) =>
      _reorderedAt(instanceId: instanceId, at: at, forward: forward) !=
      document.current;

  String? reorderProblemAt({
    required String instanceId,
    required GridPos at,
    required bool forward,
  }) {
    if (canReorderAt(instanceId: instanceId, at: at, forward: forward)) {
      return null;
    }
    final source = document.current.placedElements
        .where((element) => element.id == instanceId)
        .firstOrNull;
    if (source == null) return 'Ce décor n’est plus sur la carte.';
    final peers = mapPlacedElementsAt(
      document.current,
      project,
      at,
      layerId: source.layerId,
    );
    if (!peers.any((element) => element.id == instanceId)) {
      return 'Ce décor n’occupe plus cet emplacement.';
    }
    if (peers.length == 1) {
      return 'Aucun autre décor sur ce calque à cet emplacement.';
    }
    if (!canReorderAt(instanceId: instanceId, at: at, forward: !forward)) {
      return 'Les autres décors de ce calque ont un comportement de rendu non interchangeable.';
    }
    return forward
        ? 'Ce décor est déjà devant ses voisins réordonnables.'
        : 'Ce décor est déjà derrière ses voisins réordonnables.';
  }

  void reorderAt({
    required String instanceId,
    required GridPos at,
    required bool forward,
  }) => document.commit(
    _reorderedAt(instanceId: instanceId, at: at, forward: forward),
  );

  MapData _reorderedAt({
    required String instanceId,
    required GridPos at,
    required bool forward,
  }) {
    try {
      return moveMapPlacedElementVisualOrder(
        document.current,
        manifest: project,
        instanceId: instanceId,
        forward: forward,
        at: at,
      );
    } on ValidationException {
      return document.current;
    }
  }

  MapData _reordered({required bool forward}) {
    final id = document.selectedId;
    if (id == null) return document.current;
    try {
      return moveMapPlacedElementVisualOrder(
        document.current,
        manifest: project,
        instanceId: id,
        forward: forward,
        at: document.stackPosition,
      );
    } on ValidationException {
      return document.current;
    }
  }

  List<MapPlacedElement> stack(GridPos position) => mapPlacedElementsAt(
    document.current,
    project,
    position,
  ).reversed.toList();

  TileLayer supportLayer(MapData map) {
    final plan = buildMapVisualCompositionPlan(map).plan;
    final layers = plan?.visibleTileLayersInPaintOrder ?? <TileLayer>[];
    for (final layer in layers.reversed) {
      if (layer.purpose == MapLayerPurpose.visual &&
          !mapTileLayerIsExplicitForeground(layer)) {
        return layer;
      }
    }
    var id = 'studio-decors';
    var suffix = 1;
    while (map.layers.any((layer) => layer.id == id)) {
      id = 'studio-decors-${suffix++}';
    }
    return MapLayer.tile(
          id: id,
          name: 'Décors',
          cells: List.filled(map.size.width * map.size.height, 0),
        )
        as TileLayer;
  }

  bool _fits(MapPlacedElement instance, ProjectElementEntry entry) {
    final size = resolveMapPlacedElementFootprint(
      instance: instance,
      element: entry,
    ).destinationSize;
    return instance.pos.x >= 0 &&
        instance.pos.y >= 0 &&
        instance.pos.x + size.width <= document.current.size.width &&
        instance.pos.y + size.height <= document.current.size.height;
  }
}
