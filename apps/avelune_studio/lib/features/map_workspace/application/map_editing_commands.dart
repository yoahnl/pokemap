import 'dart:math' as math;

import 'package:map_core/map_core_domain.dart';
import 'package:map_authoring/map_authoring_editing.dart';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';

import 'map_decor_order_context.dart';

part 'map_element_placement_commands.dart';
part 'map_decor_geometry_commands.dart';
part 'map_decor_order_commands.dart';

class MapEditingCommands {
  MapEditingCommands(this.document, this.project);
  final EditableMapDocument document;
  final ProjectManifest project;
  static int _nextId = 0;

  String? place(ProjectElementEntry element, GridPos position) =>
      _placeElement(element, position);

  String? clone(String id) => _cloneElement(id);

  void move(String id, GridPos position) {
    if (document.isElementUnavailable('decor', id)) return;
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
    try {
      document.commit(
        const MovingPropEditing().reconcilePlacementChanges(
          before: document.current,
          project: project,
          after: upsertMapPlacedElement(
            document.current,
            instance: instance.copyWith(pos: position),
          ),
        ),
      );
    } on FormatException {
      document.error =
          'Le décor mobile ou son rail dépasse les limites de la carte.';
      return;
    }
    document.stackPosition = position;
    document.stackPixelPosition = null;
  }

  bool replace(String id, ProjectElementEntry element) {
    if (document.isElementUnavailable('decor', id)) return false;
    final entry = project.elements
        .where((candidate) => candidate.id == element.id)
        .firstOrNull;
    const missingResource = 'Cette ressource n’existe plus.';
    try {
      final next = replaceMapPlacedElementResource(
        document.current,
        instanceId: id,
        element: entry ?? element,
        tileSize: PixelSize(
          width: project.settings.tileWidth,
          height: project.settings.tileHeight,
        ),
      );
      if (entry == null) {
        document.error = missingResource;
        return false;
      }
      document.commit(next);
      return true;
    } on MapResourceReplacementException catch (refusal) {
      document.error = switch (refusal.reason) {
        MapResourceReplacementRefusal.environmentOwned =>
          'Ce décor est piloté par une zone d’environnement.',
        MapResourceReplacementRefusal.movingProp =>
          'Retirez le déplacement du décor avant de changer son visuel.',
        MapResourceReplacementRefusal.outOfBounds =>
          entry == null
              ? missingResource
              : 'Ce décor dépasse les limites de la carte.',
        _ => 'Ce décor n’existe plus.',
      };
      return false;
    }
  }

  void deleteSelected() {
    final id = document.selectedId;
    if (id == null) return;
    if (document.isElementUnavailable('decor', id)) return;
    if (document.current.movingProps.any(
      (prop) => prop.placedElementId == id,
    )) {
      document.error =
          'Retirez le déplacement du décor avant de supprimer son visuel.';
      return;
    }
    document.commit(removeMapPlacedElement(document.current, instanceId: id));
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
    ) as TileLayer;
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
