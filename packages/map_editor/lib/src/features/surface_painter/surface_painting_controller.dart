import 'package:map_core/map_core.dart';

/// Result of a Surface paint/erase operation.
///
/// The editor needs both the updated map and the concrete target layer id
/// because V0 can create the sparse SurfaceLayer lazily on the first paint.
final class SurfacePaintingResult {
  const SurfacePaintingResult({
    required this.map,
    required this.layerId,
    required this.changed,
  });

  final MapData map;
  final String? layerId;
  final bool changed;
}

/// Pure editor-side orchestration for sparse Surface placements.
///
/// The sparse write/replace/erase rules live in `map_core`; this controller
/// only chooses the target SurfaceLayer and applies the returned layer back to
/// the active map. It does not render water, resolve autotile roles, or inspect
/// animations because those are later Surface Engine lots.
final class SurfacePaintingController {
  const SurfacePaintingController();

  SurfacePaintingResult ensureSurfaceLayer({
    required MapData map,
    String? preferredLayerId,
  }) {
    final target = _resolveTargetSurfaceLayer(map, preferredLayerId);
    if (target != null) {
      return SurfacePaintingResult(
        map: map,
        layerId: target.layer.id,
        changed: false,
      );
    }

    final layerId = _generateSurfaceLayerId(map);
    final layer = MapLayer.surface(
      id: layerId,
      name: 'Surfaces',
    );
    final updated = map.copyWith(
      layers: List<MapLayer>.unmodifiable([...map.layers, layer]),
    );
    MapValidator.validate(updated);
    return SurfacePaintingResult(
      map: updated,
      layerId: layerId,
      changed: updated != map,
    );
  }

  SurfacePaintingResult paint({
    required MapData map,
    required String? targetLayerId,
    required String? surfacePresetId,
    required GridPos pos,
  }) {
    final normalizedPresetId = surfacePresetId?.trim();
    if (normalizedPresetId == null || normalizedPresetId.isEmpty) {
      return SurfacePaintingResult(map: map, layerId: null, changed: false);
    }

    final ensured = ensureSurfaceLayer(
      map: map,
      preferredLayerId: targetLayerId,
    );
    final nextMap = ensured.map;
    final layerId = ensured.layerId;
    if (layerId == null) {
      return ensured;
    }

    final target = _resolveTargetSurfaceLayer(nextMap, layerId);
    if (target == null) {
      return ensured;
    }
    final updatedLayer = paintSurfacePlacement(
      layer: target.layer,
      mapSize: nextMap.size,
      x: pos.x,
      y: pos.y,
      surfacePresetId: normalizedPresetId,
    );
    final updatedMap = _replaceLayerAt(
      nextMap,
      index: target.index,
      layer: updatedLayer,
    );
    MapValidator.validate(updatedMap);
    return SurfacePaintingResult(
      map: updatedMap,
      layerId: layerId,
      changed: updatedMap != map,
    );
  }

  SurfacePaintingResult erase({
    required MapData map,
    required String? targetLayerId,
    required GridPos pos,
  }) {
    final target = _resolveTargetSurfaceLayer(map, targetLayerId);
    if (target == null) {
      return SurfacePaintingResult(map: map, layerId: null, changed: false);
    }
    final updatedLayer = eraseSurfacePlacement(
      layer: target.layer,
      x: pos.x,
      y: pos.y,
    );
    if (updatedLayer == target.layer) {
      return SurfacePaintingResult(
        map: map,
        layerId: target.layer.id,
        changed: false,
      );
    }
    final updatedMap = _replaceLayerAt(
      map,
      index: target.index,
      layer: updatedLayer,
    );
    MapValidator.validate(updatedMap);
    return SurfacePaintingResult(
      map: updatedMap,
      layerId: target.layer.id,
      changed: updatedMap != map,
    );
  }

  _SurfaceLayerTarget? _resolveTargetSurfaceLayer(
    MapData map,
    String? preferredLayerId,
  ) {
    final normalizedLayerId = preferredLayerId?.trim();
    if (normalizedLayerId != null && normalizedLayerId.isNotEmpty) {
      final preferredIndex = map.layers.indexWhere(
        (layer) => layer.id == normalizedLayerId,
      );
      if (preferredIndex >= 0) {
        final layer = map.layers[preferredIndex];
        if (layer is SurfaceLayer) {
          return _SurfaceLayerTarget(index: preferredIndex, layer: layer);
        }
      }
    }

    for (var i = 0; i < map.layers.length; i++) {
      final layer = map.layers[i];
      if (layer is SurfaceLayer) {
        return _SurfaceLayerTarget(index: i, layer: layer);
      }
    }
    return null;
  }

  MapData _replaceLayerAt(
    MapData map, {
    required int index,
    required MapLayer layer,
  }) {
    final layers = List<MapLayer>.from(map.layers, growable: false);
    layers[index] = layer;
    return map.copyWith(layers: List<MapLayer>.unmodifiable(layers));
  }

  String _generateSurfaceLayerId(MapData map) {
    final existing = map.layers.map((layer) => layer.id).toSet();
    const base = 'surface-main';
    if (!existing.contains(base)) {
      return base;
    }
    var suffix = 2;
    while (existing.contains('surface-$suffix')) {
      suffix++;
    }
    return 'surface-$suffix';
  }
}

final class _SurfaceLayerTarget {
  const _SurfaceLayerTarget({
    required this.index,
    required this.layer,
  });

  final int index;
  final SurfaceLayer layer;
}
