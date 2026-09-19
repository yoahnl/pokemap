import '../exceptions/map_exceptions.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/project_manifest.dart';
import 'map_placed_element_footprint.dart';
import 'map_visual_composition.dart';

List<MapPlacedElement> sortMapPlacedElementsForPainting(
  Iterable<MapPlacedElement> instances,
) {
  final indexed = instances.indexed.toList();
  indexed.sort((a, b) {
    final order = a.$2.visualOrder.compareTo(b.$2.visualOrder);
    return order == 0 ? a.$1.compareTo(b.$1) : order;
  });
  return List.unmodifiable(indexed.map((entry) => entry.$2));
}

List<MapPlacedElement> mapPlacedElementsAt(
  MapData map,
  ProjectManifest manifest,
  GridPos position, {
  String? layerId,
}) {
  final elements = {
    for (final element in manifest.elements) element.id: element,
  };
  final hits = sortMapPlacedElementsForPainting(
    map.placedElements.where((instance) {
      if (instance.opacity <= 0) return false;
      if (layerId != null && instance.layerId != layerId) return false;
      final element = elements[instance.elementId];
      if (element == null || element.frames.isEmpty) return false;
      final size = resolveMapPlacedElementFootprint(
        instance: instance,
        element: element,
      ).destinationSize;
      return position.x >= instance.pos.x &&
          position.y >= instance.pos.y &&
          position.x < instance.pos.x + size.width &&
          position.y < instance.pos.y + size.height;
    }),
  );
  if (layerId != null) return hits;
  final layers = buildMapVisualCompositionPlan(
    map,
  ).plan?.visibleTileLayersInPaintOrder;
  if (layers == null) return const [];
  final byLayer = {
    for (final layer in layers.where((layer) => layer.opacity > 0))
      layer.id: layer,
  };
  final layerRanks = {
    for (final (index, layer) in layers.indexed) layer.id: index,
  };
  final result = hits.where((e) => byLayer.containsKey(e.layerId)).toList();
  final stableRanks = {for (final (index, hit) in hits.indexed) hit.id: index};
  result.sort((a, b) {
    final phase =
        _foregroundAt(
          a,
          elements[a.elementId]!,
          byLayer[a.layerId]!,
          position,
        ).compareTo(
          _foregroundAt(
            b,
            elements[b.elementId]!,
            byLayer[b.layerId]!,
            position,
          ),
        );
    if (phase != 0) return phase;
    final layer = layerRanks[a.layerId]!.compareTo(layerRanks[b.layerId]!);
    return layer != 0
        ? layer
        : stableRanks[a.id]!.compareTo(stableRanks[b.id]!);
  });
  return List.unmodifiable(result);
}

MapData moveMapPlacedElementVisualOrder(
  MapData map, {
  required ProjectManifest manifest,
  required String instanceId,
  required bool forward,
  GridPos? at,
}) {
  final source = map.placedElements
      .where((e) => e.id == instanceId)
      .firstOrNull;
  if (source == null) {
    throw ValidationException('Placed element instance not found: $instanceId');
  }
  final elements = {
    for (final element in manifest.elements) element.id: element,
  };
  final sourceElement = elements[source.elementId];
  if (sourceElement == null || sourceElement.frames.isEmpty) {
    throw const ValidationException(
      'Placed element visual definition is missing',
    );
  }
  final candidates = sortMapPlacedElementsForPainting(
    map.placedElements.where((candidate) {
      final element = elements[candidate.elementId];
      return candidate.layerId == source.layerId &&
          element != null &&
          element.frames.isNotEmpty;
    }),
  );
  final localIds = at == null
      ? candidates
            .where(
              (candidate) => _overlaps(
                source,
                sourceElement,
                candidate,
                elements[candidate.elementId]!,
              ),
            )
            .map((e) => e.id)
            .toSet()
      : mapPlacedElementsAt(
          map,
          manifest,
          at,
          layerId: source.layerId,
        ).map((e) => e.id).toSet();
  if (!localIds.contains(source.id)) return map;
  final local = candidates.where((e) => localIds.contains(e.id)).toList();
  final index = local.indexWhere((e) => e.id == source.id);
  final neighborIndex = index + (forward ? 1 : -1);
  if (neighborIndex < 0 || neighborIndex >= local.length) return map;
  final neighbor = local[neighborIndex];
  if (_context(neighbor, elements[neighbor.elementId]!) !=
      _context(source, sourceElement)) {
    return map;
  }
  final sourceIndex = candidates.indexWhere((e) => e.id == source.id);
  final targetIndex = candidates.indexWhere((e) => e.id == neighbor.id);
  final reordered = List<MapPlacedElement>.of(candidates);
  reordered.removeAt(sourceIndex);
  reordered.insert(targetIndex, source);
  final ranks = {
    for (final (index, value) in reordered.indexed) value.id: index,
  };
  return map.copyWith(
    placedElements: [
      for (final instance in map.placedElements)
        if (ranks.containsKey(instance.id))
          instance.copyWith(visualOrder: ranks[instance.id]!)
        else
          instance,
    ],
  );
}

bool mapTileLayerIsExplicitForeground(MapLayer layer) {
  const markers = {
    'foreground',
    'fg',
    'above',
    'overlay',
    'front',
    'roof',
    'toit',
    'overhead',
    'occlusion',
  };
  for (final text in [layer.id, layer.name]) {
    final value = text.trim().toLowerCase();
    if (markers.any(
      (marker) =>
          value == marker ||
          value.startsWith('${marker}_') ||
          value.endsWith('_$marker') ||
          value.contains('_${marker}_'),
    )) {
      return true;
    }
  }
  return false;
}

int _foregroundAt(
  MapPlacedElement instance,
  ProjectElementEntry element,
  MapLayer layer,
  GridPos position,
) {
  if (mapTileLayerIsExplicitForeground(layer)) return 1;
  if (_context(instance, element) != 1) return 0;
  final transform = resolveMapPlacedElementFootprint(
    instance: instance,
    element: element,
  );
  final source = transform.destinationToSource(
    GridPos(x: position.x - instance.pos.x, y: position.y - instance.pos.y),
  );
  return element.collisionProfile!.cells.contains(source) ? 0 : 1;
}

int _context(MapPlacedElement instance, ProjectElementEntry element) {
  if (element.collisionProfile?.occlusionMask != null) return 2;
  final frame = element.frames.primarySource;
  return instance.applyCollision &&
          (frame.width > 1 || frame.height > 1) &&
          element.collisionProfile?.cells.isNotEmpty == true
      ? 1
      : 0;
}

bool _overlaps(
  MapPlacedElement a,
  ProjectElementEntry aElement,
  MapPlacedElement b,
  ProjectElementEntry bElement,
) {
  final aSize = resolveMapPlacedElementFootprint(
    instance: a,
    element: aElement,
  ).destinationSize;
  final bSize = resolveMapPlacedElementFootprint(
    instance: b,
    element: bElement,
  ).destinationSize;
  return a.pos.x < b.pos.x + bSize.width &&
      b.pos.x < a.pos.x + aSize.width &&
      a.pos.y < b.pos.y + bSize.height &&
      b.pos.y < a.pos.y + aSize.height;
}
