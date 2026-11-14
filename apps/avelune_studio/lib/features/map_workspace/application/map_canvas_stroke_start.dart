part of 'map_canvas_stroke.dart';

MapCanvasStroke? _startMapCanvasStroke({
  required MapData map,
  required ProjectManifest project,
  required MapWorkspaceEditingState view,
  required MapEditingCommands commands,
  required GridPos origin,
}) {
  if (origin.x < 0 ||
      origin.y < 0 ||
      origin.x >= map.size.width ||
      origin.y >= map.size.height) {
    return null;
  }
  final erase = view.tool == StudioMapTool.erase;
  final erasingPattern = view.terrain != null && view.terrainPatternId != null;
  final collision =
      view.tool == StudioMapTool.collisionPaint ||
      view.tool == StudioMapTool.collisionErase;
  if (erase && map.spatialScene != null && erasingPattern) {
    final selected = view.terrainPatternFor(project, map);
    if (selected != null && _isSmallModelStamp(selected)) {
      final layers = mapPaintsFirstLayerInFront(map)
          ? map.layers
          : map.layers.reversed;
      SmartTileLayer? layer;
      for (final candidate in layers.whereType<SmartTileLayer>()) {
        if (!candidate.isVisible || candidate.presetId != view.terrain?.id) {
          continue;
        }
        final owner = _spatialPatternOwnerAt(
          layer: candidate,
          project: project,
          cell: origin,
        );
        if (owner == null) continue;
        if (owner.pattern.id != selected.id ||
            !_isSmallStampStroke(owner.pattern, owner.stroke)) {
          return null;
        }
        layer = candidate;
        break;
      }
      if (layer == null) return null;
      final stroke = MapCanvasStroke._(
        MapCellStrokeBuffer.smartTile(sourceMap: map, layerId: layer.id),
        project,
        true,
        null,
        null,
        true,
        false,
        patternErase: true,
        erasePatternId: selected.id,
        atomicPatternErase: true,
      );
      stroke.paint(origin);
      return stroke;
    }
  }
  if (collision) {
    var prepared = map;
    var layer = prepared.layers
        .whereType<CollisionLayer>()
        .where((item) => item.isVisible)
        .lastOrNull;
    if (layer == null && view.tool == StudioMapTool.collisionErase) {
      return null;
    }
    if (layer == null) {
      var id = 'studio-collisions';
      var suffix = 1;
      while (prepared.layers.any((item) => item.id == id)) {
        id = 'studio-collisions-${suffix++}';
      }
      prepared = addMapLayer(
        prepared,
        kind: MapLayerKind.collision,
        id: id,
        name: 'Collisions',
      );
      layer = prepared.layers.whereType<CollisionLayer>().last;
    }
    final stroke = MapCanvasStroke._(
      MapCellStrokeBuffer.collision(sourceMap: prepared, layerId: layer.id),
      project,
      view.tool == StudioMapTool.collisionErase,
      null,
      null,
      false,
      true,
    );
    stroke.paint(origin);
    return stroke;
  }
  if (erase) {
    final selectedSpatialPresetId = map.spatialScene != null
        ? view.terrain?.id
        : null;
    final layers = mapPaintsFirstLayerInFront(map)
        ? map.layers
        : map.layers.reversed;
    final layer = layers
        .whereType<SmartTileLayer>()
        .where(
          (item) =>
              item.isVisible &&
              (selectedSpatialPresetId == null ||
                  item.presetId == selectedSpatialPresetId) &&
              (map.spatialScene != null ||
                  !erasingPattern ||
                  item.presetId == view.terrain?.id) &&
              (smartTileMaterialIdAt(
                        item,
                        mapSize: map.size,
                        x: origin.x,
                        y: origin.y,
                      ) !=
                      null ||
                  (map.spatialScene != null || erasingPattern) &&
                      (map.spatialScene != null
                          ? _hasSpatialPatternPartAt(
                              layer: item,
                              project: project,
                              cell: origin,
                            )
                          : item.patternStrokes.any(
                              (stroke) => stroke.cells.contains(origin),
                            ))),
        )
        .firstOrNull;
    if (layer != null) {
      final stroke = MapCanvasStroke._(
        MapCellStrokeBuffer.smartTile(sourceMap: map, layerId: layer.id),
        project,
        true,
        null,
        null,
        true,
        false,
        patternErase: erasingPattern && layer.presetId == view.terrain?.id,
        erasePatternId: erasingPattern ? view.terrainPatternId : null,
      );
      stroke.paint(origin);
      return stroke;
    }
    if (selectedSpatialPresetId != null ||
        map.spatialScene == null && erasingPattern) {
      return null;
    }
  }
  final preset = view.terrain;
  if (preset != null && view.tool == StudioMapTool.terrain) {
    if (view.terrainPatternId != null) {
      final pattern = view.terrainPatternFor(project, map);
      if (pattern == null) {
        throw StateError('Ce motif n’est plus disponible pour ce terrain.');
      }
      final prepared = prepareTerrainStrokeLayer(
        map: map,
        manifest: project,
        preset: preset,
      )!;
      var suffix = 1;
      var id = 'studio-pattern-${pattern.id}-$suffix';
      while (prepared.layer.patternStrokes.any((stroke) => stroke.id == id)) {
        id = 'studio-pattern-${pattern.id}-${++suffix}';
      }
      final stroke = MapCanvasStroke._(
        MapCellStrokeBuffer.smartTile(
          sourceMap: prepared.map,
          layerId: prepared.layer.id,
        ),
        project,
        false,
        null,
        view.terrainMaterialId ?? preset.defaultMaterialId,
        true,
        false,
        pattern: pattern,
        patternMode: view.terrainPatternMode,
        patternOrigin: origin,
        patternStrokeId: id,
      );
      stroke.paint(origin);
      return stroke;
    }
    final prepared = applyTerrainStroke(
      map: map,
      manifest: project,
      preset: preset,
      cells: [origin],
      erase: false,
      materialId: view.terrainMaterialId,
    );
    final layer = prepared.layers
        .whereType<SmartTileLayer>()
        .where((layer) => layer.presetId == preset.id && layer.isVisible)
        .firstOrNull;
    if (layer == null) return null;
    final stroke = MapCanvasStroke._(
      MapCellStrokeBuffer.smartTile(sourceMap: prepared, layerId: layer.id),
      project,
      erase,
      null,
      view.terrainMaterialId ?? preset.defaultMaterialId,
      true,
      false,
    );
    stroke.paint(origin);
    return stroke;
  }
  if (view.tool != StudioMapTool.paint && !erase) return null;
  if (!erase && view.tile == null) return null;
  final plan = buildMapVisualCompositionPlan(map).plan;
  final occupied = plan?.visibleTileLayersInPaintOrder.reversed
      .where(
        (layer) =>
            resolveTileLayerCell(layer, origin.y * map.size.width + origin.x) !=
            null,
      )
      .firstOrNull;
  if (erase && occupied == null) return null;
  final layer = erase && occupied != null
      ? occupied
      : commands.supportLayer(map);
  if (!map.layers.any((entry) => entry.id == layer.id)) {
    final layers = [...map.layers];
    layers.insert(
      resolveAuthoredLayerInsertIndex(map, activeLayerId: null),
      layer,
    );
    map = map.copyWith(layers: layers);
  }
  final stroke = MapCanvasStroke._(
    MapCellStrokeBuffer.tile(sourceMap: map, layerId: layer.id),
    project,
    erase,
    view.tile,
    null,
    false,
    false,
  );
  stroke.paint(origin);
  return stroke;
}
