import 'package:map_core/map_core.dart';

import '../../../features/border_map_editing/application/border_preview_transaction.dart';
import '../../../features/border_map_editing/presentation/border_preview_painter.dart';
import '../entity_editor_element_visual.dart';

bool editorCanvasNeedsAnimation({
  required MapData map,
  required ProjectManifest? project,
  required BorderPreviewTransaction? borderPreview,
}) {
  if (mapEntitiesNeedEditorFrameAnimation(map, project)) {
    return true;
  }
  if (_visiblePlacedElementsNeedAnimation(map, project)) {
    return true;
  }
  if (_visiblePlacedTilesNeedAnimation(map, project)) {
    return true;
  }

  if (project != null &&
      project.smartTileCatalog.animations.isNotEmpty &&
      map.layers.whereType<SmartTileLayer>().any(
            (layer) => layer.isVisible && layer.opacity > 0,
          )) {
    return true;
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

bool _visiblePlacedTilesNeedAnimation(
  MapData map,
  ProjectManifest? project,
) {
  if (project == null) return false;
  final sourceByTilesetId = <String, ProjectTilesetSource>{
    for (final tileset in project.tilesets)
      if (tileset.source case final source?) tileset.id: source,
  };
  for (final layer in map.layers.whereType<ObjectLayer>()) {
    if (!layer.isVisible || layer.opacity <= 0) continue;
    for (final object in layer.tileObjects) {
      if (!object.isVisible || object.opacity <= 0) continue;
      final source = sourceByTilesetId[object.tile.tilesetId];
      if (source is! ProjectImageCollectionTilesetSource) continue;
      for (final definition in source.tileDefinitions) {
        if (definition.tileId == object.tile.localTileId &&
            definition.animation.length > 1) {
          return true;
        }
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
