import 'package:map_core/map_core.dart';

import '../state/editor_state.dart';
import '../tools/editor_tool.dart';

/// Contrôleur pur pour les changements d'outil et de sélection.
class MapSelectionController {
  const MapSelectionController();

  EditorState selectTool({
    required EditorState current,
    required EditorToolType tool,
  }) {
    return current.copyWith(
      activeTool: tool,
      selectedEnvironmentAreaId: null,
      environmentMaskEditMode: null,
    );
  }

  EditorState selectEntityKind({
    required EditorState current,
    required MapEntityKind kind,
  }) {
    return current.copyWith(
      selectedEntityKind: kind,
      statusMessage: 'Entity kind: ${kind.name}',
      errorMessage: null,
    );
  }

  EditorState coerceActiveToolIfIncompatibleWithLayer(EditorState current) {
    final map = current.activeMap;
    final layerId = current.activeLayerId;
    MapLayer? layer;
    if (map != null && layerId != null) {
      layer = _findLayerById(map, layerId);
    }
    if (_isToolCompatibleWithActiveLayer(current.activeTool, layer)) {
      return current;
    }
    return current.copyWith(activeTool: EditorToolType.selection);
  }

  bool _isToolCompatibleWithActiveLayer(
    EditorToolType tool,
    MapLayer? layer,
  ) {
    return switch (tool) {
      EditorToolType.selection ||
      EditorToolType.entityPlacement ||
      EditorToolType.eventPlacement ||
      EditorToolType.triggerPlacement ||
      EditorToolType.warpPlacement ||
      EditorToolType.gameplayZonePlacement =>
        true,
      EditorToolType.tilePaint => layer is TileLayer,
      EditorToolType.collisionPaint => layer is CollisionLayer,
      EditorToolType.terrainPaint => layer is SmartTileLayer,
      EditorToolType.borderPaint ||
      EditorToolType.borderErase =>
        layer is BorderLayer,
      EditorToolType.eraser => layer is TileLayer ||
          layer is CollisionLayer ||
          layer is SmartTileLayer,
    };
  }

  MapLayer? _findLayerById(MapData map, String layerId) {
    for (final layer in map.layers) {
      if (layer.id == layerId) {
        return layer;
      }
    }
    return null;
  }
}
