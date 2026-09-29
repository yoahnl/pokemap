import '../collision/pixel_rect.dart';
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
}) => _mapPlacedElementsIntersecting(
  map,
  manifest,
  PixelRect(
    leftPx: position.x * manifest.settings.tileWidth,
    topPx: position.y * manifest.settings.tileHeight,
    widthPx: manifest.settings.tileWidth,
    heightPx: manifest.settings.tileHeight,
  ),
  layerId: layerId,
);

List<MapPlacedElement> mapPlacedElementsAtPixel(
  MapData map,
  ProjectManifest manifest,
  PixelPosition position, {
  String? layerId,
}) => _mapPlacedElementsIntersecting(
  map,
  manifest,
  PixelRect(
    leftPx: position.leftPx,
    topPx: position.topPx,
    widthPx: 1,
    heightPx: 1,
  ),
  layerId: layerId,
);

List<MapPlacedElement> _mapPlacedElementsIntersecting(
  MapData map,
  ProjectManifest manifest,
  PixelRect selection, {
  String? layerId,
}) {
  final tileSize = PixelSize(
    width: manifest.settings.tileWidth,
    height: manifest.settings.tileHeight,
  );
  final elements = {
    for (final element in manifest.elements) element.id: element,
  };
  final sources = {
    for (final tileset in manifest.tilesets) tileset.id: tileset.source,
  };
  final hitRects = <String, PixelRect>{};
  final hits = sortMapPlacedElementsForPainting(
    map.placedElements.where((instance) {
      if (instance.opacity <= 0) return false;
      if (layerId != null && instance.layerId != layerId) return false;
      final element = elements[instance.elementId];
      if (element == null || element.frames.isEmpty) return false;
      final geometry = resolveMapPlacedElementGeometry(
        instance: instance,
        element: element,
        tileSize: tileSize,
      );
      for (final frame in element.frames) {
        final tilesetId = frame.tilesetId.trim().isEmpty
            ? element.tilesetId.trim()
            : frame.tilesetId.trim();
        final rect = resolveMapPlacedElementVisualRect(
          geometry: geometry,
          tilesetSource: sources[tilesetId],
        );
        if (selection.leftPx < rect.leftPx + rect.widthPx &&
            selection.topPx < rect.topPx + rect.heightPx &&
            selection.leftPx + selection.widthPx > rect.leftPx &&
            selection.topPx + selection.heightPx > rect.topPx) {
          hitRects[instance.id] = rect;
          return true;
        }
      }
      return false;
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
  final phases = <String, int>{};
  for (final (index, hit) in hits.indexed) {
    final layer = byLayer[hit.layerId];
    if (layer == null) continue;
    if (mapTileLayerIsExplicitForeground(layer)) {
      phases[hit.id] = 1;
      continue;
    }
    final element = elements[hit.elementId]!;
    final collision = element.collisionProfile;
    final frame = element.frames.primarySource;
    if (!hit.applyCollision ||
        collision?.occlusionMask != null ||
        collision?.cells.isNotEmpty != true ||
        (frame.width <= 1 && frame.height <= 1)) {
      phases[hit.id] = 0;
      continue;
    }
    final transform = resolveMapPlacedElementFootprint(
      instance: hit,
      element: element,
    );
    final rect = hitRects[hit.id]!;
    final source =
        QuarterTurnPixelTransform(
          sourcePixelSize: transform.sourceSize,
          destinationPixelSize: GridSize(
            width: rect.widthPx,
            height: rect.heightPx,
          ),
          quarterTurns: hit.quarterTurns,
        ).destinationPixelToSourcePixel(
          GridPos(
            x: (selection.leftPx + selection.widthPx ~/ 2 - rect.leftPx).clamp(
              0,
              rect.widthPx - 1,
            ),
            y: (selection.topPx + selection.heightPx ~/ 2 - rect.topPx).clamp(
              0,
              rect.heightPx - 1,
            ),
          ),
        );
    final covered = hits
        .skip(index + 1)
        .any((candidate) => candidate.layerId == hit.layerId);
    phases[hit.id] = collision!.cells.contains(source) || covered ? 0 : 1;
  }
  result.sort((a, b) {
    final phase = phases[a.id]!.compareTo(phases[b.id]!);
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
  PixelPosition? atPixel,
}) {
  if (at != null && atPixel != null) {
    throw const ValidationException(
      'Provide one visual-order selection position',
    );
  }
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
  final Set<String> localIds;
  if (at == null && atPixel == null) {
    final tilesetSources = {
      for (final tileset in manifest.tilesets) tileset.id: tileset.source,
    };
    final sourceBounds = resolveMapPlacedElementVisualBounds(
      instance: source,
      element: sourceElement,
      manifest: manifest,
      tilesetSources: tilesetSources,
    );
    localIds = {
      for (final candidate in candidates)
        if (candidate.id == source.id ||
            _overlaps(
              sourceBounds,
              resolveMapPlacedElementVisualBounds(
                instance: candidate,
                element: elements[candidate.elementId]!,
                manifest: manifest,
                tilesetSources: tilesetSources,
              ),
            ))
          candidate.id,
    };
  } else {
    localIds =
        (atPixel == null
                ? mapPlacedElementsAt(
                    map,
                    manifest,
                    at!,
                    layerId: source.layerId,
                  )
                : mapPlacedElementsAtPixel(
                    map,
                    manifest,
                    atPixel,
                    layerId: source.layerId,
                  ))
            .map((e) => e.id)
            .toSet();
  }
  if (!localIds.contains(source.id)) return map;
  final local = candidates.where((e) => localIds.contains(e.id)).toList();
  final index = local.indexWhere((e) => e.id == source.id);
  final neighborIndex = index + (forward ? 1 : -1);
  if (neighborIndex < 0 || neighborIndex >= local.length) return map;
  final neighbor = local[neighborIndex];
  final sourceIndex = candidates.indexWhere((e) => e.id == source.id);
  final targetIndex = candidates.indexWhere((e) => e.id == neighbor.id);
  final reordered = List<MapPlacedElement>.of(candidates);
  reordered[sourceIndex] = neighbor;
  reordered[targetIndex] = source;
  final distinctRanks =
      candidates.map((entry) => entry.visualOrder).toSet().length ==
      candidates.length;
  final ranks = {
    for (final (index, value) in reordered.indexed)
      value.id: distinctRanks ? candidates[index].visualOrder : index,
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

bool _overlaps(PixelRect aRect, PixelRect bRect) {
  return aRect.leftPx < bRect.leftPx + bRect.widthPx &&
      bRect.leftPx < aRect.leftPx + aRect.widthPx &&
      aRect.topPx < bRect.topPx + bRect.heightPx &&
      bRect.topPx < aRect.topPx + aRect.heightPx;
}
