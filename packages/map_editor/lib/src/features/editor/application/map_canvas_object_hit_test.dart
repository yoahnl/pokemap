import 'package:map_core/map_core.dart';

import 'project_element_frame_resolver.dart';

/// Object families that can be selected directly from the world-map canvas.
enum MapCanvasObjectKind {
  placedElement,
  entity,
  mapEvent,
  gameplayZone,
  trigger,
  warp,
}

/// Stable identity and grid bounds of one authorable canvas object.
final class MapCanvasObjectTarget {
  const MapCanvasObjectTarget({
    required this.kind,
    required this.id,
    required this.anchor,
    required this.size,
    this.layerId,
  });

  final MapCanvasObjectKind kind;
  final String id;
  final String? layerId;
  final GridPos anchor;
  final GridSize size;

  @override
  bool operator ==(Object other) {
    return other is MapCanvasObjectTarget &&
        other.kind == kind &&
        other.id == id;
  }

  @override
  int get hashCode => Object.hash(kind, id);
}

/// Resolves persisted editor selection IDs into one logical canvas target.
///
/// This deliberately differs from [MapCanvasObjectHitTest.hitStack]: a selected
/// placed element remains inspectable when its visual frame is unavailable.
/// If stale IDs overlap, the same topmost-first family order as the visual hit
/// stack wins.
MapCanvasObjectTarget? resolveSelectedCanvasObjectTarget({
  required MapData map,
  required ProjectManifest? project,
  required String? selectedPlacedElementInstanceId,
  required String? selectedEntityId,
  required String? selectedMapEventId,
  required String? selectedWarpId,
  required String? selectedTriggerId,
  required String? selectedGameplayZoneId,
  int editorAnimationTimeMs = 0,
}) {
  for (final warp in map.warps) {
    if (warp.id == selectedWarpId) {
      return _warpTarget(warp);
    }
  }
  for (final trigger in map.triggers) {
    if (trigger.id == selectedTriggerId) {
      return _triggerTarget(trigger);
    }
  }
  for (final event in map.events) {
    if (event.id == selectedMapEventId) {
      return _mapEventTarget(event);
    }
  }
  for (final zone in map.gameplayZones) {
    if (zone.id == selectedGameplayZoneId) {
      return _gameplayZoneTarget(zone);
    }
  }
  for (final entity in map.entities) {
    if (entity.id == selectedEntityId) {
      return _entityTarget(entity);
    }
  }
  for (final instance in map.placedElements) {
    if (instance.id != selectedPlacedElementInstanceId) continue;
    ProjectElementEntry? entry;
    for (final candidate
        in project?.elements ?? const <ProjectElementEntry>[]) {
      if (candidate.id == instance.elementId.trim()) {
        entry = candidate;
        break;
      }
    }
    return _placedElementTarget(
      instance,
      entry: entry,
      editorAnimationTimeMs: editorAnimationTimeMs,
    );
  }
  return null;
}

/// Resolves object hits in the same bottom-to-top phases as [MapGridPainter].
///
/// The result is topmost-first. Layer order and visibility come from the shared
/// visual-composition plan; editor-only overlays keep the painter's explicit
/// order (zone, event, trigger, then warp).
final class MapCanvasObjectHitTest {
  const MapCanvasObjectHitTest();

  List<MapCanvasObjectTarget> hitStack({
    required MapData map,
    required ProjectManifest? project,
    required GridPos position,
    int editorAnimationTimeMs = 0,
  }) {
    if (!_containsCell(
      position,
      const GridPos(x: 0, y: 0),
      map.size,
    )) {
      return const <MapCanvasObjectTarget>[];
    }

    final plan = buildMapVisualCompositionPlan(map).plan;
    if (plan == null) {
      return const <MapCanvasObjectTarget>[];
    }

    final painted = <MapCanvasObjectTarget>[];
    final elementsById = project == null
        ? const <String, ProjectElementEntry>{}
        : <String, ProjectElementEntry>{
            for (final entry in project.elements) entry.id: entry,
          };

    for (final step in plan.steps) {
      switch (step.kind) {
        case MapVisualCompositionStepKind.placedElements:
          _appendPlacedElementHits(
            painted,
            map: map,
            layer: step.layer! as TileLayer,
            elementsById: elementsById,
            position: position,
            foregroundPass: false,
            editorAnimationTimeMs: editorAnimationTimeMs,
          );
        case MapVisualCompositionStepKind.backgroundEntities:
          _appendEntityHits(
            painted,
            map: map,
            position: position,
            foregroundPass: false,
          );
        case MapVisualCompositionStepKind.foregroundTilesAndPlacedElements:
          for (final layer in plan.visibleTileLayersInPaintOrder) {
            _appendPlacedElementHits(
              painted,
              map: map,
              layer: layer,
              elementsById: elementsById,
              position: position,
              foregroundPass: true,
              editorAnimationTimeMs: editorAnimationTimeMs,
            );
          }
        case MapVisualCompositionStepKind.foregroundEntities:
          _appendEntityHits(
            painted,
            map: map,
            position: position,
            foregroundPass: true,
          );
        case MapVisualCompositionStepKind.terrainLayer:
        case MapVisualCompositionStepKind.pathLayer:
        case MapVisualCompositionStepKind.surfaceLayer:
        case MapVisualCompositionStepKind.tileBackgroundLayer:
        case MapVisualCompositionStepKind.borderLayer:
        case MapVisualCompositionStepKind.shadows:
        case MapVisualCompositionStepKind.collisionOverlay:
        case MapVisualCompositionStepKind.objectNoop:
        case MapVisualCompositionStepKind.environmentNoop:
          break;
      }
    }

    _appendGameplayZoneHits(painted, map: map, position: position);
    _appendMapEventHits(painted, map: map, position: position);
    _appendTriggerHits(painted, map: map, position: position);
    _appendWarpHits(painted, map: map, position: position);

    return painted.reversed.toList(growable: false);
  }

  MapCanvasObjectTarget? cycleTarget({
    required List<MapCanvasObjectTarget> hits,
    required MapCanvasObjectTarget? current,
  }) {
    if (hits.isEmpty) {
      return null;
    }
    if (current == null) {
      return hits.first;
    }
    final index = hits.indexOf(current);
    if (index < 0) {
      return hits.first;
    }
    return hits[(index + 1) % hits.length];
  }

  void _appendPlacedElementHits(
    List<MapCanvasObjectTarget> out, {
    required MapData map,
    required TileLayer layer,
    required Map<String, ProjectElementEntry> elementsById,
    required GridPos position,
    required bool foregroundPass,
    required int editorAnimationTimeMs,
  }) {
    if (layer.opacity <= 0) {
      return;
    }
    final explicitForeground = _isExplicitForegroundLayer(layer);
    for (final instance in map.placedElements) {
      if (instance.layerId.trim() != layer.id.trim() || instance.opacity <= 0) {
        continue;
      }
      final entry = elementsById[instance.elementId.trim()];
      if (entry == null || entry.frames.isEmpty) {
        continue;
      }
      final target = _placedElementTarget(
        instance,
        entry: entry,
        layerId: layer.id,
        editorAnimationTimeMs: editorAnimationTimeMs,
      );
      final size = target.size;
      if (!_containsCell(position, instance.pos, size)) {
        continue;
      }
      final localX = position.x - instance.pos.x;
      final localY = position.y - instance.pos.y;
      if (!_isPlacedCellInPass(
        instance: instance,
        entry: entry,
        localX: localX,
        localY: localY,
        explicitForeground: explicitForeground,
        foregroundPass: foregroundPass,
      )) {
        continue;
      }
      out.add(target);
    }
  }

  void _appendEntityHits(
    List<MapCanvasObjectTarget> out, {
    required MapData map,
    required GridPos position,
    required bool foregroundPass,
  }) {
    for (final entity in map.entities) {
      if (entity.shouldRenderProjectElementInForeground != foregroundPass ||
          !_containsCell(position, entity.pos, entity.size)) {
        continue;
      }
      out.add(_entityTarget(entity));
    }
  }

  void _appendGameplayZoneHits(
    List<MapCanvasObjectTarget> out, {
    required MapData map,
    required GridPos position,
  }) {
    for (final zone in map.gameplayZones) {
      if (!_containsCell(position, zone.area.pos, zone.area.size)) {
        continue;
      }
      out.add(_gameplayZoneTarget(zone));
    }
  }

  void _appendMapEventHits(
    List<MapCanvasObjectTarget> out, {
    required MapData map,
    required GridPos position,
  }) {
    final layerVisibility = <String, bool>{
      for (final layer in map.layers) layer.id: layer.isVisible,
    };
    for (final event in map.events) {
      final layerId = event.position.layerId.trim();
      if (layerVisibility[layerId] != true ||
          event.position.x != position.x ||
          event.position.y != position.y) {
        continue;
      }
      out.add(_mapEventTarget(event));
    }
  }

  void _appendTriggerHits(
    List<MapCanvasObjectTarget> out, {
    required MapData map,
    required GridPos position,
  }) {
    for (final trigger in map.triggers) {
      if (!_containsCell(position, trigger.area.pos, trigger.area.size)) {
        continue;
      }
      out.add(_triggerTarget(trigger));
    }
  }

  void _appendWarpHits(
    List<MapCanvasObjectTarget> out, {
    required MapData map,
    required GridPos position,
  }) {
    for (final warp in map.warps) {
      if (warp.pos != position) {
        continue;
      }
      out.add(_warpTarget(warp));
    }
  }

  bool _isPlacedCellInPass({
    required MapPlacedElement instance,
    required ProjectElementEntry entry,
    required int localX,
    required int localY,
    required bool explicitForeground,
    required bool foregroundPass,
  }) {
    if (explicitForeground) {
      return foregroundPass;
    }
    final collisionCells =
        instance.applyCollision ? entry.collisionProfile?.cells : null;
    if (collisionCells == null || collisionCells.isEmpty) {
      return !foregroundPass;
    }
    final isCollisionCell = collisionCells.any(
      (cell) => cell.x == localX && cell.y == localY,
    );
    return foregroundPass ? !isCollisionCell : isCollisionCell;
  }

  bool _isExplicitForegroundLayer(TileLayer layer) {
    final id = layer.id.trim().toLowerCase();
    final name = layer.name.trim().toLowerCase();
    const markers = <String>{
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
    return markers.any(
      (marker) =>
          _containsLayerMarker(id, marker) ||
          _containsLayerMarker(name, marker),
    );
  }

  bool _containsLayerMarker(String value, String marker) {
    return value == marker ||
        value.startsWith('${marker}_') ||
        value.endsWith('_$marker') ||
        value.contains('_${marker}_');
  }

  bool _containsCell(GridPos cell, GridPos anchor, GridSize size) {
    return cell.x >= anchor.x &&
        cell.y >= anchor.y &&
        cell.x < anchor.x + size.width &&
        cell.y < anchor.y + size.height;
  }
}

MapCanvasObjectTarget _placedElementTarget(
  MapPlacedElement instance, {
  required ProjectElementEntry? entry,
  required int editorAnimationTimeMs,
  String? layerId,
}) {
  final source = entry == null || entry.frames.isEmpty
      ? null
      : pickProjectElementFrame(entry.frames, editorAnimationTimeMs).source;
  return MapCanvasObjectTarget(
    kind: MapCanvasObjectKind.placedElement,
    id: instance.id,
    layerId: layerId ?? instance.layerId.trim(),
    anchor: instance.pos,
    size: GridSize(
      width: source == null || source.width <= 0 ? 1 : source.width,
      height: source == null || source.height <= 0 ? 1 : source.height,
    ),
  );
}

MapCanvasObjectTarget _entityTarget(MapEntity entity) {
  return MapCanvasObjectTarget(
    kind: MapCanvasObjectKind.entity,
    id: entity.id,
    anchor: entity.pos,
    size: entity.size,
  );
}

MapCanvasObjectTarget _mapEventTarget(MapEventDefinition event) {
  final layerId = event.position.layerId.trim();
  return MapCanvasObjectTarget(
    kind: MapCanvasObjectKind.mapEvent,
    id: event.id,
    layerId: layerId.isEmpty ? null : layerId,
    anchor: GridPos(x: event.position.x, y: event.position.y),
    size: const GridSize(width: 1, height: 1),
  );
}

MapCanvasObjectTarget _gameplayZoneTarget(MapGameplayZone zone) {
  return MapCanvasObjectTarget(
    kind: MapCanvasObjectKind.gameplayZone,
    id: zone.id,
    anchor: zone.area.pos,
    size: zone.area.size,
  );
}

MapCanvasObjectTarget _triggerTarget(MapTrigger trigger) {
  return MapCanvasObjectTarget(
    kind: MapCanvasObjectKind.trigger,
    id: trigger.id,
    anchor: trigger.area.pos,
    size: trigger.area.size,
  );
}

MapCanvasObjectTarget _warpTarget(MapWarp warp) {
  return MapCanvasObjectTarget(
    kind: MapCanvasObjectKind.warp,
    id: warp.id,
    anchor: warp.pos,
    size: const GridSize(width: 1, height: 1),
  );
}
