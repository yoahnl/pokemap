import 'package:map_core/map_core.dart';

import '../state/editor_state.dart';
import 'map_canvas_object_hit_test.dart';
import 'map_context_target.dart';

final class MapContextTargetResolver {
  const MapContextTargetResolver({
    this.objectHitTest = const MapCanvasObjectHitTest(),
  });

  final MapCanvasObjectHitTest objectHitTest;

  MapContextTarget resolveCanvasTarget({
    required MapData map,
    required ProjectManifest? project,
    required GridPos position,
    required String? activeLayerId,
    int editorAnimationTimeMs = 0,
  }) {
    final hits = objectHitTest.hitStack(
      map: map,
      project: project,
      position: position,
      editorAnimationTimeMs: editorAnimationTimeMs,
    );
    if (hits.isNotEmpty) {
      return MapObjectContextTarget(hits.first);
    }

    for (final layer in _paintableLayersTopFirst(map)) {
      if (_isPaintedAt(layer, map.size, position)) {
        return MapCellContextTarget(
          position: position,
          layerId: layer.id,
          isPainted: true,
        );
      }
    }

    final activeLayer = _layerById(map, activeLayerId);
    return MapCellContextTarget(
      position: position,
      layerId: activeLayer != null && _isCellPaintLayer(activeLayer)
          ? activeLayer.id
          : null,
      isPainted: false,
    );
  }

  MapObjectContextTarget? resolveSelectedObject({
    required MapData map,
    required ProjectManifest? project,
    required EditorState editor,
    int editorAnimationTimeMs = 0,
  }) {
    final target = resolveSelectedCanvasObjectTarget(
      map: map,
      project: project,
      selectedPlacedElementInstanceId: editor.selectedPlacedElementInstanceId,
      selectedEntityId: editor.selectedEntityId,
      selectedMapEventId: editor.selectedMapEventId,
      selectedWarpId: editor.selectedWarpId,
      selectedTriggerId: editor.selectedTriggerId,
      selectedGameplayZoneId: editor.selectedGameplayZoneId,
      editorAnimationTimeMs: editorAnimationTimeMs,
    );
    return target == null ? null : MapObjectContextTarget(target);
  }
}

Iterable<MapLayer> _paintableLayersTopFirst(MapData map) sync* {
  final plan = buildMapVisualCompositionPlan(map).plan;
  if (plan == null) {
    return;
  }

  yield* plan.visibleCollisionLayersInPaintOrder.reversed;
  yield* plan.authoredLayerSteps
      .map((step) => step.layer)
      .whereType<MapLayer>()
      .where(_isCellPaintLayer)
      .toList(growable: false)
      .reversed;
}

bool _isCellPaintLayer(MapLayer layer) {
  return layer is TileLayer ||
      layer is CollisionLayer ||
      layer is SmartTileLayer;
}

bool _isPaintedAt(MapLayer layer, GridSize mapSize, GridPos position) {
  if (position.x < 0 ||
      position.y < 0 ||
      position.x >= mapSize.width ||
      position.y >= mapSize.height) {
    return false;
  }
  final index = position.y * mapSize.width + position.x;
  return switch (layer) {
    TileLayer(:final cells) => index < cells.length && cells[index] != 0,
    CollisionLayer(:final collisions) =>
      index < collisions.length && collisions[index],
    SmartTileLayer smartTileLayer => smartTileCellHasAuthoredValue(
        smartTileLayer,
        mapSize: mapSize,
        x: position.x,
        y: position.y,
      ),
    ObjectLayer() || EnvironmentLayer() || BorderLayer() => false,
  };
}

MapLayer? _layerById(MapData map, String? layerId) {
  if (layerId == null) {
    return null;
  }
  for (final layer in map.layers) {
    if (layer.id == layerId) {
      return layer;
    }
  }
  return null;
}
