import 'package:map_core/map_core.dart';

import '../../../application/services/placed_element_instance_indexer.dart';
import 'map_canvas_object_hit_test.dart';

enum MapCanvasObjectMoveRejection {
  targetNotFound,
  boundsUnavailable,
  sourceOutOfBounds,
  destinationOutOfBounds,
  environmentGeneratedPlacement,
  tileIndexedSourceInvalid,
  tileIndexedDestinationOccupied,
  tileIndexedProjectionInvalid,
}

final class MapCanvasObjectMovePlan {
  const MapCanvasObjectMovePlan._({
    required this.sourceMap,
    required this.sourceTarget,
    required this.previewTarget,
    required this.candidateMap,
    required this.isNoOp,
    required this.rejection,
  });

  factory MapCanvasObjectMovePlan.ready({
    required MapData sourceMap,
    required MapCanvasObjectTarget sourceTarget,
    required MapCanvasObjectTarget previewTarget,
    required MapData candidateMap,
  }) {
    return MapCanvasObjectMovePlan._(
      sourceMap: sourceMap,
      sourceTarget: sourceTarget,
      previewTarget: previewTarget,
      candidateMap: candidateMap,
      isNoOp: false,
      rejection: null,
    );
  }

  factory MapCanvasObjectMovePlan.noOp({
    required MapData sourceMap,
    required MapCanvasObjectTarget sourceTarget,
  }) {
    return MapCanvasObjectMovePlan._(
      sourceMap: sourceMap,
      sourceTarget: sourceTarget,
      previewTarget: sourceTarget,
      candidateMap: null,
      isNoOp: true,
      rejection: null,
    );
  }

  factory MapCanvasObjectMovePlan.rejected({
    required MapData sourceMap,
    required MapCanvasObjectMoveRejection rejection,
    MapCanvasObjectTarget? sourceTarget,
    MapCanvasObjectTarget? previewTarget,
  }) {
    return MapCanvasObjectMovePlan._(
      sourceMap: sourceMap,
      sourceTarget: sourceTarget,
      previewTarget: previewTarget,
      candidateMap: null,
      isNoOp: false,
      rejection: rejection,
    );
  }

  final MapData sourceMap;
  final MapCanvasObjectTarget? sourceTarget;
  final MapCanvasObjectTarget? previewTarget;
  final MapData? candidateMap;
  final bool isNoOp;
  final MapCanvasObjectMoveRejection? rejection;

  bool get canCommit => candidateMap != null && !isNoOp && rejection == null;
}

final class MapCanvasObjectMovePlanner {
  const MapCanvasObjectMovePlanner({
    PlacedElementInstanceIndexer indexer = const PlacedElementInstanceIndexer(),
  }) : _indexer = indexer;

  final PlacedElementInstanceIndexer _indexer;

  MapCanvasObjectMovePlan plan({
    required MapData map,
    required ProjectManifest? project,
    required MapCanvasObjectTarget target,
    required GridPos destinationAnchor,
  }) {
    final placed = target.kind == MapCanvasObjectKind.placedElement
        ? _findPlacedElement(map, target.id)
        : null;
    if (placed != null && _isEnvironmentGenerated(map, placed.id)) {
      final moveSize = _placedElementMoveSize(
        project: project,
        placed: placed,
        requested: target,
      );
      final sourceTarget = MapCanvasObjectTarget(
        kind: MapCanvasObjectKind.placedElement,
        id: placed.id,
        layerId: placed.layerId,
        anchor: placed.pos,
        size: moveSize ?? const GridSize(width: 1, height: 1),
      );
      return MapCanvasObjectMovePlan.rejected(
        sourceMap: map,
        sourceTarget: sourceTarget,
        previewTarget: _atAnchor(sourceTarget, destinationAnchor),
        rejection: MapCanvasObjectMoveRejection.environmentGeneratedPlacement,
      );
    }

    final sourceTarget = _resolveTarget(
      map: map,
      project: project,
      requested: target,
    );
    if (sourceTarget == null) {
      return MapCanvasObjectMovePlan.rejected(
        sourceMap: map,
        rejection: placed == null
            ? MapCanvasObjectMoveRejection.targetNotFound
            : MapCanvasObjectMoveRejection.boundsUnavailable,
      );
    }
    final previewTarget = _atAnchor(sourceTarget, destinationAnchor);
    if (!_isInBounds(sourceTarget.anchor, sourceTarget.size, map.size)) {
      return MapCanvasObjectMovePlan.rejected(
        sourceMap: map,
        sourceTarget: sourceTarget,
        previewTarget: previewTarget,
        rejection: MapCanvasObjectMoveRejection.sourceOutOfBounds,
      );
    }
    if (!_isInBounds(destinationAnchor, sourceTarget.size, map.size)) {
      return MapCanvasObjectMovePlan.rejected(
        sourceMap: map,
        sourceTarget: sourceTarget,
        previewTarget: previewTarget,
        rejection: MapCanvasObjectMoveRejection.destinationOutOfBounds,
      );
    }
    if (destinationAnchor == sourceTarget.anchor) {
      return MapCanvasObjectMovePlan.noOp(
        sourceMap: map,
        sourceTarget: sourceTarget,
      );
    }

    if (placed?.properties[pokemapPlacementOriginProperty] ==
        pokemapPlacementOriginTileIndex) {
      return _planTileIndexedMove(
        map: map,
        project: project!,
        placed: placed!,
        sourceTarget: sourceTarget,
        previewTarget: previewTarget,
        destinationAnchor: destinationAnchor,
      );
    }

    final candidate = _movePositionOnly(
      map: map,
      target: sourceTarget,
      destinationAnchor: destinationAnchor,
    );
    if (candidate == null) {
      return MapCanvasObjectMovePlan.rejected(
        sourceMap: map,
        sourceTarget: sourceTarget,
        previewTarget: previewTarget,
        rejection: MapCanvasObjectMoveRejection.targetNotFound,
      );
    }
    return MapCanvasObjectMovePlan.ready(
      sourceMap: map,
      sourceTarget: sourceTarget,
      previewTarget: previewTarget,
      candidateMap: candidate,
    );
  }

  MapCanvasObjectMovePlan _planTileIndexedMove({
    required MapData map,
    required ProjectManifest project,
    required MapPlacedElement placed,
    required MapCanvasObjectTarget sourceTarget,
    required MapCanvasObjectTarget previewTarget,
    required GridPos destinationAnchor,
  }) {
    final tilePatternSize = _placedElementSize(project, placed);
    if (tilePatternSize == null ||
        !_isInBounds(placed.pos, tilePatternSize, map.size)) {
      return MapCanvasObjectMovePlan.rejected(
        sourceMap: map,
        sourceTarget: sourceTarget,
        previewTarget: previewTarget,
        rejection: MapCanvasObjectMoveRejection.tileIndexedSourceInvalid,
      );
    }
    if (!_isInBounds(destinationAnchor, tilePatternSize, map.size)) {
      return MapCanvasObjectMovePlan.rejected(
        sourceMap: map,
        sourceTarget: sourceTarget,
        previewTarget: previewTarget,
        rejection: MapCanvasObjectMoveRejection.destinationOutOfBounds,
      );
    }
    final tilePatternTarget = MapCanvasObjectTarget(
      kind: sourceTarget.kind,
      id: sourceTarget.id,
      layerId: sourceTarget.layerId,
      anchor: placed.pos,
      size: tilePatternSize,
    );
    final layerIndex =
        map.layers.indexWhere((entry) => entry.id == placed.layerId);
    if (layerIndex < 0 || map.layers[layerIndex] is! TileLayer) {
      return MapCanvasObjectMovePlan.rejected(
        sourceMap: map,
        sourceTarget: sourceTarget,
        previewTarget: previewTarget,
        rejection: MapCanvasObjectMoveRejection.tileIndexedSourceInvalid,
      );
    }
    final layer = map.layers[layerIndex] as TileLayer;
    final synchronized = _indexer.syncLayer(
      map: map,
      project: project,
      layerId: layer.id,
    );
    final synchronizedPlaced = _findPlacedElement(synchronized, placed.id);
    if (synchronizedPlaced == null ||
        synchronizedPlaced.layerId != placed.layerId ||
        synchronizedPlaced.elementId != placed.elementId ||
        synchronizedPlaced.pos != placed.pos ||
        synchronizedPlaced.properties[pokemapPlacementOriginProperty] !=
            pokemapPlacementOriginTileIndex) {
      return MapCanvasObjectMovePlan.rejected(
        sourceMap: map,
        sourceTarget: sourceTarget,
        previewTarget: previewTarget,
        rejection: MapCanvasObjectMoveRejection.tileIndexedSourceInvalid,
      );
    }

    for (var localY = 0; localY < tilePatternSize.height; localY++) {
      for (var localX = 0; localX < tilePatternSize.width; localX++) {
        final destination = GridPos(
          x: destinationAnchor.x + localX,
          y: destinationAnchor.y + localY,
        );
        if (_contains(tilePatternTarget, destination)) continue;
        if (_tileAt(layer.tiles, map.size, destination) != 0) {
          return MapCanvasObjectMovePlan.rejected(
            sourceMap: map,
            sourceTarget: sourceTarget,
            previewTarget: previewTarget,
            rejection:
                MapCanvasObjectMoveRejection.tileIndexedDestinationOccupied,
          );
        }
      }
    }

    final pattern = <int>[
      for (var localY = 0; localY < tilePatternSize.height; localY++)
        for (var localX = 0; localX < tilePatternSize.width; localX++)
          _tileAt(
            layer.tiles,
            map.size,
            GridPos(
              x: placed.pos.x + localX,
              y: placed.pos.y + localY,
            ),
          ),
    ];
    final expectedTileCount = map.size.width * map.size.height;
    final nextTiles = List<int>.filled(expectedTileCount, 0, growable: false);
    final copyCount = layer.tiles.length < expectedTileCount
        ? layer.tiles.length
        : expectedTileCount;
    for (var index = 0; index < copyCount; index++) {
      nextTiles[index] = layer.tiles[index];
    }
    for (var localY = 0; localY < tilePatternSize.height; localY++) {
      for (var localX = 0; localX < tilePatternSize.width; localX++) {
        final x = placed.pos.x + localX;
        final y = placed.pos.y + localY;
        nextTiles[y * map.size.width + x] = 0;
      }
    }
    for (var localY = 0; localY < tilePatternSize.height; localY++) {
      for (var localX = 0; localX < tilePatternSize.width; localX++) {
        final x = destinationAnchor.x + localX;
        final y = destinationAnchor.y + localY;
        final patternIndex = localY * tilePatternSize.width + localX;
        nextTiles[y * map.size.width + x] = pattern[patternIndex];
      }
    }

    final nextLayers = List<MapLayer>.from(map.layers, growable: false);
    nextLayers[layerIndex] = layer.copyWith(tiles: nextTiles);
    final withMovedTiles = map.copyWith(layers: nextLayers);
    final candidate = _movePositionOnly(
      map: withMovedTiles,
      target: sourceTarget,
      destinationAnchor: destinationAnchor,
    );
    if (candidate == null) {
      return MapCanvasObjectMovePlan.rejected(
        sourceMap: map,
        sourceTarget: sourceTarget,
        previewTarget: previewTarget,
        rejection: MapCanvasObjectMoveRejection.targetNotFound,
      );
    }

    final verified = _indexer.syncLayer(
      map: candidate,
      project: project,
      layerId: layer.id,
    );
    final moved = _findPlacedElement(candidate, placed.id);
    final verifiedMoved = _findPlacedElement(verified, placed.id);
    if (moved == null || verifiedMoved != moved) {
      return MapCanvasObjectMovePlan.rejected(
        sourceMap: map,
        sourceTarget: sourceTarget,
        previewTarget: previewTarget,
        rejection: MapCanvasObjectMoveRejection.tileIndexedProjectionInvalid,
      );
    }
    return MapCanvasObjectMovePlan.ready(
      sourceMap: map,
      sourceTarget: sourceTarget,
      previewTarget: previewTarget,
      candidateMap: candidate,
    );
  }
}

MapCanvasObjectTarget? _resolveTarget({
  required MapData map,
  required ProjectManifest? project,
  required MapCanvasObjectTarget requested,
}) {
  switch (requested.kind) {
    case MapCanvasObjectKind.placedElement:
      final placed = _findPlacedElement(map, requested.id);
      final size = placed == null
          ? null
          : _placedElementMoveSize(
              project: project,
              placed: placed,
              requested: requested,
            );
      if (placed == null || size == null) return null;
      return MapCanvasObjectTarget(
        kind: requested.kind,
        id: placed.id,
        layerId: placed.layerId,
        anchor: placed.pos,
        size: size,
      );
    case MapCanvasObjectKind.entity:
      final entity = _findById(map.entities, requested.id, (entry) => entry.id);
      if (entity == null) return null;
      return MapCanvasObjectTarget(
        kind: requested.kind,
        id: entity.id,
        anchor: entity.pos,
        size: entity.size,
      );
    case MapCanvasObjectKind.mapEvent:
      final event = _findById(map.events, requested.id, (entry) => entry.id);
      if (event == null) return null;
      return MapCanvasObjectTarget(
        kind: requested.kind,
        id: event.id,
        layerId: event.position.layerId,
        anchor: GridPos(x: event.position.x, y: event.position.y),
        size: const GridSize(width: 1, height: 1),
      );
    case MapCanvasObjectKind.gameplayZone:
      final zone =
          _findById(map.gameplayZones, requested.id, (entry) => entry.id);
      if (zone == null) return null;
      return MapCanvasObjectTarget(
        kind: requested.kind,
        id: zone.id,
        anchor: zone.area.pos,
        size: zone.area.size,
      );
    case MapCanvasObjectKind.trigger:
      final trigger =
          _findById(map.triggers, requested.id, (entry) => entry.id);
      if (trigger == null) return null;
      return MapCanvasObjectTarget(
        kind: requested.kind,
        id: trigger.id,
        anchor: trigger.area.pos,
        size: trigger.area.size,
      );
    case MapCanvasObjectKind.warp:
      final warp = _findById(map.warps, requested.id, (entry) => entry.id);
      if (warp == null) return null;
      return MapCanvasObjectTarget(
        kind: requested.kind,
        id: warp.id,
        anchor: warp.pos,
        size: const GridSize(width: 1, height: 1),
      );
  }
}

MapData? _movePositionOnly({
  required MapData map,
  required MapCanvasObjectTarget target,
  required GridPos destinationAnchor,
}) {
  switch (target.kind) {
    case MapCanvasObjectKind.placedElement:
      final index =
          map.placedElements.indexWhere((entry) => entry.id == target.id);
      if (index < 0) return null;
      final next =
          List<MapPlacedElement>.from(map.placedElements, growable: false);
      next[index] = next[index].copyWith(pos: destinationAnchor);
      return map.copyWith(placedElements: next);
    case MapCanvasObjectKind.entity:
      final index = map.entities.indexWhere((entry) => entry.id == target.id);
      if (index < 0) return null;
      final next = List<MapEntity>.from(map.entities, growable: false);
      next[index] = next[index].copyWith(pos: destinationAnchor);
      return map.copyWith(entities: next);
    case MapCanvasObjectKind.mapEvent:
      final index = map.events.indexWhere((entry) => entry.id == target.id);
      if (index < 0) return null;
      final next = List<MapEventDefinition>.from(map.events, growable: false);
      final event = next[index];
      next[index] = event.copyWith(
        position: event.position.copyWith(
          x: destinationAnchor.x,
          y: destinationAnchor.y,
        ),
      );
      return map.copyWith(events: next);
    case MapCanvasObjectKind.gameplayZone:
      final index =
          map.gameplayZones.indexWhere((entry) => entry.id == target.id);
      if (index < 0) return null;
      final next =
          List<MapGameplayZone>.from(map.gameplayZones, growable: false);
      final zone = next[index];
      next[index] = zone.copyWith(
        area: zone.area.copyWith(pos: destinationAnchor),
      );
      return map.copyWith(gameplayZones: next);
    case MapCanvasObjectKind.trigger:
      final index = map.triggers.indexWhere((entry) => entry.id == target.id);
      if (index < 0) return null;
      final next = List<MapTrigger>.from(map.triggers, growable: false);
      final trigger = next[index];
      next[index] = trigger.copyWith(
        area: trigger.area.copyWith(pos: destinationAnchor),
      );
      return map.copyWith(triggers: next);
    case MapCanvasObjectKind.warp:
      final index = map.warps.indexWhere((entry) => entry.id == target.id);
      if (index < 0) return null;
      final next = List<MapWarp>.from(map.warps, growable: false);
      next[index] = next[index].copyWith(pos: destinationAnchor);
      return map.copyWith(warps: next);
  }
}

MapPlacedElement? _findPlacedElement(MapData map, String id) {
  return _findById(map.placedElements, id, (entry) => entry.id);
}

GridSize? _placedElementSize(
  ProjectManifest? project,
  MapPlacedElement placed,
) {
  if (project == null) return null;
  final element =
      _findById(project.elements, placed.elementId, (entry) => entry.id);
  if (element == null || element.frames.isEmpty) return null;
  final source = element.frames.primarySource;
  return GridSize(
    width: source.width <= 0 ? 1 : source.width,
    height: source.height <= 0 ? 1 : source.height,
  );
}

GridSize? _placedElementMoveSize({
  required ProjectManifest? project,
  required MapPlacedElement placed,
  required MapCanvasObjectTarget requested,
}) {
  final primarySize = _placedElementSize(project, placed);
  if (primarySize == null) return null;
  if (requested.size.width <= 0 || requested.size.height <= 0) {
    return primarySize;
  }
  return requested.size;
}

bool _isEnvironmentGenerated(MapData map, String placementId) {
  for (final layer in map.layers.whereType<EnvironmentLayer>()) {
    for (final area in layer.content.areas) {
      if (area.generatedPlacementIds.contains(placementId)) return true;
    }
  }
  return false;
}

MapCanvasObjectTarget _atAnchor(
  MapCanvasObjectTarget source,
  GridPos anchor,
) {
  return MapCanvasObjectTarget(
    kind: source.kind,
    id: source.id,
    layerId: source.layerId,
    anchor: anchor,
    size: source.size,
  );
}

T? _findById<T>(List<T> entries, String id, String Function(T) readId) {
  for (final entry in entries) {
    if (readId(entry) == id) return entry;
  }
  return null;
}

bool _contains(MapCanvasObjectTarget target, GridPos position) {
  return position.x >= target.anchor.x &&
      position.y >= target.anchor.y &&
      position.x < target.anchor.x + target.size.width &&
      position.y < target.anchor.y + target.size.height;
}

int _tileAt(List<int> tiles, GridSize mapSize, GridPos position) {
  final index = position.y * mapSize.width + position.x;
  if (index < 0 || index >= tiles.length) return 0;
  return tiles[index];
}

bool _isInBounds(GridPos anchor, GridSize size, GridSize mapSize) {
  return size.width > 0 &&
      size.height > 0 &&
      anchor.x >= 0 &&
      anchor.y >= 0 &&
      anchor.x + size.width <= mapSize.width &&
      anchor.y + size.height <= mapSize.height;
}
