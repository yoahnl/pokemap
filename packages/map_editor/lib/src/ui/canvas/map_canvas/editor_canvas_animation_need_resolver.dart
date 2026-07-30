import 'package:map_core/map_core.dart';

import '../../../application/models/path_autotile_set.dart';
import '../../../features/border_map_editing/application/border_preview_transaction.dart';
import '../../../features/border_map_editing/presentation/border_preview_painter.dart';
import '../../../features/surface_painter/surface_tile_preview_resolver.dart';
import '../entity_editor_element_visual.dart';

bool editorCanvasNeedsAnimation({
  required MapData map,
  required ProjectManifest? project,
  required Map<String, PathAutotileSet> pathAutotileSetsByPresetId,
  required Map<TerrainType, ProjectTerrainPreset> terrainPresetsByType,
  required BorderPreviewTransaction? borderPreview,
}) {
  if (mapEntitiesNeedEditorFrameAnimation(map, project)) {
    return true;
  }
  if (_visiblePlacedElementsNeedAnimation(map, project)) {
    return true;
  }

  final surfaceCatalog = project?.surfaceCatalog;
  if (surfaceCatalog != null &&
      surfaceTilePreviewNeedsAnimation(map: map, catalog: surfaceCatalog)) {
    return true;
  }

  final visibleTerrainTypes = <TerrainType>{
    for (final layer in map.layers.whereType<TerrainLayer>())
      if (layer.isVisible && layer.opacity > 0)
        for (final terrain in layer.terrains)
          if (terrain != TerrainType.none) terrain,
  };
  for (final terrain in visibleTerrainTypes) {
    final preset = terrainPresetsByType[terrain];
    if (preset != null &&
        preset.variants.any((variant) => variant.frames.length > 1)) {
      return true;
    }
  }

  final visibleAnimatedPathPresetIds = <String>{
    for (final layer in map.layers.whereType<PathLayer>())
      if (layer.isVisible &&
          layer.opacity > 0 &&
          layer.animationMode == PathAnimationMode.alwaysActive &&
          layer.cells.contains(true) &&
          layer.presetId.trim().isNotEmpty)
        layer.presetId.trim(),
  };
  for (final presetId in visibleAnimatedPathPresetIds) {
    final autotileSet = pathAutotileSetsByPresetId[presetId];
    if (autotileSet != null &&
        autotileSet.variants.values.any((frames) => frames.length > 1)) {
      return true;
    }
    if (project != null &&
        project.pathPatternPresets
            .where((preset) => preset.basePathPresetId == presetId)
            .any(
              (preset) => preset.centerPattern.cells
                  .any((cell) => cell.frames.length > 1),
            )) {
      return true;
    }
  }

  if (project != null) {
    for (final entry in buildEditorBorderPaintEntries(
      map: map,
      preview: borderPreview,
    )) {
      final snapshot =
          project.borderCatalog.visualSnapshotById(entry.snapshotId);
      if (snapshot != null && snapshot.frames.length > 1) {
        return true;
      }
    }
  }
  return false;
}

bool _visiblePlacedElementsNeedAnimation(
  MapData map,
  ProjectManifest? project,
) {
  if (project == null || map.placedElements.isEmpty) {
    return false;
  }
  final visibleLayerIds = <String>{
    for (final layer in map.layers.whereType<TileLayer>())
      if (layer.isVisible && layer.opacity > 0) layer.id,
  };
  final elementsById = <String, ProjectElementEntry>{
    for (final element in project.elements) element.id: element,
  };
  return map.placedElements.any((instance) {
    if (instance.opacity <= 0 ||
        !visibleLayerIds.contains(instance.layerId.trim())) {
      return false;
    }
    return (elementsById[instance.elementId.trim()]?.frames.length ?? 0) > 1;
  });
}
