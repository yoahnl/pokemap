import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';

part 'map_element_placement_commands.dart';

class MapEditingCommands {
  MapEditingCommands(this.document, this.project);
  final EditableMapDocument document;
  final ProjectManifest project;
  static int _nextId = 0;

  String? place(ProjectElementEntry element, GridPos position) =>
      _placeElement(element, position);

  void move(String id, GridPos position) {
    final instance = document.current.placedElements
        .where((element) => element.id == id)
        .firstOrNull;
    if (instance == null) return;
    if (environmentOwnedMapPlacedElementIds(document.current).contains(id) ||
        instance.properties[pokemapPlacementOriginProperty]?.trim() ==
            pokemapPlacementOriginEnvironment) {
      document.error = 'Ce décor est piloté par une zone d’environnement.';
      return;
    }
    final element = project.elements
        .where((element) => element.id == instance.elementId)
        .firstOrNull;
    if (element == null) {
      document.error = 'Ce décor n’est plus disponible dans le projet.';
      return;
    }
    if (!_fits(instance.copyWith(pos: position), element)) {
      document.error = 'Ce décor dépasse les limites de la carte.';
      return;
    }
    document.commit(
      upsertMapPlacedElement(
        document.current,
        instance: instance.copyWith(pos: position),
      ),
    );
    document.stackPosition = position;
    document.stackPixelPosition = null;
  }

  void deleteSelected() {
    final id = document.selectedId;
    if (id == null) return;
    document.commit(removeMapPlacedElement(document.current, instanceId: id));
  }

  bool setGeometry(
    String id, {
    required int x,
    required int y,
    required PixelSize? size,
  }) {
    try {
      document.commit(
        setMapPlacedElementGeometry(
          document.current,
          manifest: project,
          instanceId: id,
          pixelX: x,
          pixelY: y,
          pixelSize: size,
        ),
      );
      document.stackPosition = document.selected?.pos;
      document.stackPixelPosition = PixelPosition(leftPx: x, topPx: y);
      return true;
    } on ValidationException {
      document.error =
          'Ce décor dépasse les limites de la carte ou sa taille autorisée.';
      return false;
    }
  }

  void detach(String id) {
    try {
      document.commit(
        detachMapPlacedElementFromTileProjection(
          document.current,
          instanceId: id,
        ),
      );
    } on ValidationException {
      document.error = 'Ce décor est piloté par une zone d’environnement.';
    }
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
    final pixel = document.stackPosition == at
        ? document.stackPixelPosition
        : null;
    final peers = pixel != null
        ? mapPlacedElementsAtPixel(
            document.current,
            project,
            pixel,
            layerId: source.layerId,
          )
        : mapPlacedElementsAt(
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
      return 'Aucun autre décor réordonnable à cet emplacement.';
    }
    return forward
        ? 'Ce décor est déjà devant les autres décors de ce calque.'
        : 'Ce décor est déjà derrière les autres décors de ce calque.';
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
        at: document.stackPosition == at && document.stackPixelPosition != null
            ? null
            : at,
        atPixel: document.stackPosition == at
            ? document.stackPixelPosition
            : null,
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
        at: document.stackPixelPosition == null ? document.stackPosition : null,
        atPixel: document.stackPixelPosition,
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

  List<MapPlacedElement> stackAtPixel(PixelPosition position) =>
      mapPlacedElementsAtPixel(
        document.current,
        project,
        position,
      ).reversed.toList();

  List<MapPlacedElement> contextStack(GridPos position) =>
      document.stackPosition == position && document.stackPixelPosition != null
      ? stackAtPixel(document.stackPixelPosition!)
      : stack(position);

  TileLayer supportLayer(MapData map, {String? preferredLayerId}) {
    final preferred = map.layers
        .whereType<TileLayer>()
        .where(
          (layer) =>
              layer.id == preferredLayerId &&
              layer.isVisible &&
              layer.purpose == MapLayerPurpose.visual,
        )
        .firstOrNull;
    if (preferred != null) return preferred;
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
    final tileSize = PixelSize(
      width: project.settings.tileWidth,
      height: project.settings.tileHeight,
    );
    try {
      validateMapPlacedElementGeometryBounds(
        geometry: resolveMapPlacedElementGeometry(
          instance: instance,
          element: entry,
          tileSize: tileSize,
        ),
        mapSize: document.current.size,
        tileSize: tileSize,
      );
      return true;
    } on ValidationException {
      return false;
    }
  }
}
