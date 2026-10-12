import 'package:map_core/map_core_domain.dart';

MapData applyTerrainStroke({
  required MapData map,
  required ProjectManifest manifest,
  required ProjectSmartTilePreset preset,
  required Iterable<GridPos> cells,
  bool erase = false,
  String? materialId,
}) {
  final chosenMaterial = materialId ?? preset.defaultMaterialId;
  if (!erase && !preset.allowedMaterialIds.contains(chosenMaterial)) {
    throw StateError('Choisissez une matière autorisée pour ce terrain.');
  }
  final positions = cells.toSet();
  if (positions.isEmpty) return map;
  final prepared = prepareTerrainStrokeLayer(
    map: map,
    manifest: manifest,
    preset: preset,
    erase: erase,
  );
  if (prepared == null) return map;
  return applySmartTileMapMaterialGesture(
    prepared.map,
    layer: prepared.layer,
    catalog: manifest.smartTileCatalog,
    cells: positions,
    materialId: erase ? null : chosenMaterial,
  );
}

({MapData map, SmartTileLayer layer})? prepareTerrainStrokeLayer({
  required MapData map,
  required ProjectManifest manifest,
  required ProjectSmartTilePreset preset,
  bool erase = false,
}) {
  var next = map;
  var layer = map.layers
      .whereType<SmartTileLayer>()
      .where((layer) => layer.presetId == preset.id && layer.isVisible)
      .firstOrNull;
  if (layer == null) {
    if (erase) return null;
    final entry = manifest.maps
        .where((entry) => entry.id == map.id)
        .firstOrNull;
    if (entry == null) {
      throw StateError('La carte ne figure plus dans le projet.');
    }
    var suffix = 1;
    var id = 'terrain-${preset.id}';
    while (map.layers.any((layer) => layer.id == id)) {
      id = 'terrain-${preset.id}-${suffix++}';
    }
    final support = buildMapVisualCompositionPlan(map)
        .plan
        ?.visibleTileLayersInPaintOrder
        .where((layer) => !mapTileLayerIsExplicitForeground(layer))
        .lastOrNull;
    final result = planNativeSmartTileLayerCreationForMap(
      map: map,
      manifest: manifest,
      preset: preset,
      layerId: id,
      layerName: preset.name,
      insertIndex: resolveAuthoredLayerInsertIndex(
        map,
        activeLayerId: support?.id,
      ),
    );
    if (result is SmartTileLayerCreationFailure) {
      throw StateError(result.message);
    }
    next = (result as SmartTileLayerCreationSuccess).map;
    layer = next.layers.whereType<SmartTileLayer>().firstWhere(
      (layer) => layer.id == id,
    );
    layer = layer.copyWith(
      field: switch (layer.field) {
        SmartTileCellField(:final semanticCells) => SmartTileField.cell(
          semanticCells: List.filled(semanticCells.length, 0),
        ),
        SmartTileCornerField(:final semanticCells, :final corners) =>
          SmartTileField.corner(
            semanticCells: List.filled(semanticCells.length, 0),
            corners: List.filled(corners.length, 0),
          ),
        SmartTileEdgeField(
          :final semanticCells,
          :final horizontalEdges,
          :final verticalEdges,
        ) =>
          SmartTileField.edge(
            semanticCells: List.filled(semanticCells.length, 0),
            horizontalEdges: List.filled(horizontalEdges.length, 0),
            verticalEdges: List.filled(verticalEdges.length, 0),
          ),
        SmartTileMixedField(
          :final semanticCells,
          :final horizontalEdges,
          :final verticalEdges,
          :final corners,
        ) =>
          SmartTileField.mixed(
            semanticCells: List.filled(semanticCells.length, 0),
            horizontalEdges: List.filled(horizontalEdges.length, 0),
            verticalEdges: List.filled(verticalEdges.length, 0),
            corners: List.filled(corners.length, 0),
          ),
      },
    );
    next = replaceSmartTileLayer(next, layer: layer);
  }
  return (map: next, layer: layer);
}
