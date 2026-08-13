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
  if (map.layers.whereType<TileLayer>().any(
    (layer) => editorTileLayerNeedsAnimation(layer, project),
  )) {
    return true;
  }

  if (map.layers.whereType<SmartTileLayer>().any(
    (layer) => editorSmartTileLayerNeedsAnimation(layer, project),
  )) {
    return true;
  }

  if (editorCanvasBorderNeedsAnimation(
    map: map,
    project: project,
    borderPreview: borderPreview,
  )) {
    return true;
  }
  return false;
}

bool editorTileLayerNeedsAnimation(TileLayer layer, ProjectManifest? project) {
  if (!layer.isVisible || layer.opacity <= 0 || project == null) return false;
  final sources = <String, ProjectTilesetSource>{
    for (final tileset in project.tilesets) tileset.id: ?tileset.source,
  };
  for (final entry in layer.palette) {
    if (_tilesetVisualNeedsAnimation(
      sources[entry.tilesetId],
      entry.localTileId,
    )) {
      return true;
    }
  }
  return false;
}

bool editorObjectLayerNeedsAnimation(
  ObjectLayer layer,
  ProjectManifest? project,
) {
  if (!layer.isVisible || layer.opacity <= 0 || project == null) return false;
  final sources = <String, ProjectTilesetSource>{
    for (final tileset in project.tilesets) tileset.id: ?tileset.source,
  };
  for (final object in layer.tileObjects) {
    if (object.isVisible &&
        object.opacity > 0 &&
        _tilesetVisualNeedsAnimation(
          sources[object.tile.tilesetId],
          object.tile.localTileId,
        )) {
      return true;
    }
  }
  return false;
}

bool editorSmartTileLayerNeedsAnimation(
  SmartTileLayer layer,
  ProjectManifest? project,
) =>
    layer.isVisible &&
    layer.opacity > 0 &&
    layer.animationActivation == SmartTileAnimationActivation.always &&
    (project?.smartTileCatalog.animations.isNotEmpty ?? false);

bool editorPlacedElementLayerNeedsAnimation(
  MapData map,
  TileLayer layer,
  ProjectManifest? project,
) {
  if (!layer.isVisible || layer.opacity <= 0 || project == null) return false;
  final elementsById = <String, ProjectElementEntry>{
    for (final element in project.elements) element.id: element,
  };
  return map.placedElements.any(
    (instance) =>
        instance.layerId == layer.id &&
        instance.opacity > 0 &&
        (elementsById[instance.elementId]?.frames.length ?? 0) > 1,
  );
}

bool editorCanvasBorderNeedsAnimation({
  required MapData map,
  required ProjectManifest? project,
  required BorderPreviewTransaction? borderPreview,
}) {
  if (project == null) return false;
  for (final entry in buildEditorBorderPaintEntries(
    map: map,
    preview: borderPreview,
  )) {
    final snapshot = project.borderCatalog.visualSnapshotById(entry.snapshotId);
    if (snapshot != null && snapshot.frames.length > 1) return true;
  }
  return false;
}

bool _tilesetVisualNeedsAnimation(ProjectTilesetSource? source, int tileId) =>
    switch (source) {
      ProjectRegularAtlasTilesetSource(:final tileAnimations) =>
        tileAnimations.any(
          (animation) =>
              animation.tileId == tileId && animation.frames.length > 1,
        ),
      ProjectImageCollectionTilesetSource(:final tileDefinitions) =>
        tileDefinitions.any(
          (definition) =>
              definition.tileId == tileId && definition.animation.length > 1,
        ),
      null => false,
    };

int resolveEditorSmartTileAnimationElapsedMs({
  required SmartTileAnimationActivation activation,
  required int elapsedMs,
}) {
  return switch (activation) {
    SmartTileAnimationActivation.always => elapsedMs,
    SmartTileAnimationActivation.onEnter => 0,
  };
}

bool _visiblePlacedTilesNeedAnimation(MapData map, ProjectManifest? project) {
  if (project == null) return false;
  final sourceByTilesetId = <String, ProjectTilesetSource>{
    for (final tileset in project.tilesets) tileset.id: ?tileset.source,
  };
  for (final layer in map.layers.whereType<ObjectLayer>()) {
    if (!layer.isVisible || layer.opacity <= 0) continue;
    for (final object in layer.tileObjects) {
      if (!object.isVisible || object.opacity <= 0) continue;
      if (_tilesetVisualNeedsAnimation(
        sourceByTilesetId[object.tile.tilesetId],
        object.tile.localTileId,
      )) {
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
