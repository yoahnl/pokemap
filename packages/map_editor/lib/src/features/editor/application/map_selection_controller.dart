import 'package:map_core/map_core.dart';

import '../../../application/models/terrain_selection_mode.dart';
import '../../../application/services/terrain_preset_selection_coordinator.dart';
import '../state/editor_state.dart';
import '../tools/editor_tool.dart';

/// Contrôleur pur pour les changements d'outil et de sélection.
///
/// Il centralise les transitions d'état qui n'ont pas besoin d'accéder au
/// disque, aux repositories ou à Riverpod. L'objectif est de sortir une
/// première tranche cohérente de `EditorNotifier` sans changer le scope
/// fonctionnel.
class MapSelectionController {
  const MapSelectionController({
    required TerrainPresetSelectionCoordinator
        terrainPresetSelectionCoordinator,
  }) : _terrainPresetSelectionCoordinator = terrainPresetSelectionCoordinator;

  final TerrainPresetSelectionCoordinator _terrainPresetSelectionCoordinator;

  EditorState selectTool({
    required EditorState current,
    required EditorToolType tool,
  }) {
    var terrainMode = current.terrainSelectionMode;
    if (tool == EditorToolType.terrainPaint) {
      final map = current.activeMap;
      final id = current.activeLayerId;
      if (map != null && id != null) {
        final layer = _findLayerById(map, id);
        if (layer is TerrainLayer) {
          terrainMode = TerrainSelectionMode.terrain;
        } else if (layer is PathLayer) {
          terrainMode = TerrainSelectionMode.path;
        }
      }
    }
    return current.copyWith(
      activeTool: tool,
      terrainSelectionMode: terrainMode,
      // Lot Environment-22 : un outil toolbar classique sort du mode masque.
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

  EditorState selectTerrainType({
    required EditorState current,
    required TerrainType terrain,
  }) {
    if (current.selectedTerrainType == terrain &&
        current.terrainSelectionMode == TerrainSelectionMode.terrain) {
      return current;
    }
    final selection = _terrainPresetSelectionCoordinator.forTerrainType(
      project: current.project,
      current: _currentTerrainPresetSelection(current),
      terrainType: terrain,
      preferredTerrainPresetId: current.selectedTerrainPresetByType[terrain] ??
          current.selectedTerrainPresetId,
    );
    return _copyStateWithTerrainPresetSelection(
      current,
      selection,
      statusMessage: 'Terrain type: ${terrain.name}',
      errorMessage: null,
    );
  }

  EditorState selectTerrainPreset({
    required EditorState current,
    required ProjectTerrainPreset? preset,
  }) {
    if (preset == null) {
      return current.copyWith(errorMessage: 'Terrain preset not found');
    }
    final selection =
        _terrainPresetSelectionCoordinator.forTerrainPresetSelected(
      current: _currentTerrainPresetSelection(current),
      preset: preset,
    );
    return _copyStateWithTerrainPresetSelection(
      current,
      selection,
      activeTool: EditorToolType.terrainPaint,
      statusMessage: 'Terrain preset: ${preset.name}',
      errorMessage: null,
    );
  }

  EditorState selectPathPreset({
    required EditorState current,
    required ProjectPathPreset? preset,
  }) {
    if (preset == null) {
      return current.copyWith(errorMessage: 'Path preset not found');
    }
    final selection = _terrainPresetSelectionCoordinator.forPathPresetSelected(
      current: _currentTerrainPresetSelection(current),
      preset: preset,
    );
    return _copyStateWithTerrainPresetSelection(
      current,
      selection,
      activeTool: EditorToolType.terrainPaint,
      statusMessage: 'Path preset: ${preset.name}',
      errorMessage: null,
    );
  }

  EditorState selectTerrainPaintMode({
    required EditorState current,
    TerrainType? terrainType,
  }) {
    final nextTerrain = terrainType ?? current.selectedTerrainType;
    final selection = _terrainPresetSelectionCoordinator.forTerrainType(
      project: current.project,
      current: _currentTerrainPresetSelection(current),
      terrainType: nextTerrain,
      preferredTerrainPresetId:
          current.selectedTerrainPresetByType[nextTerrain] ??
              current.selectedTerrainPresetId,
    );
    return _copyStateWithTerrainPresetSelection(
      current,
      selection,
      activeTool: EditorToolType.terrainPaint,
      statusMessage: 'Terrain type: ${nextTerrain.name}',
      errorMessage: null,
    );
  }

  EditorState selectPathPaintMode({
    required EditorState current,
    required ProjectPathPreset? selectedPathPreset,
  }) {
    final currentSelection = _currentTerrainPresetSelection(current);
    final selection = selectedPathPreset == null
        ? TerrainPresetSelection(
            selectionMode: TerrainSelectionMode.path,
            selectedTerrainType: currentSelection.selectedTerrainType,
            selectedTerrainPresetId: currentSelection.selectedTerrainPresetId,
            selectedPathPresetId: currentSelection.selectedPathPresetId,
            selectedTerrainPresetByType:
                currentSelection.selectedTerrainPresetByType,
          )
        : _terrainPresetSelectionCoordinator.forPathPresetSelected(
            current: currentSelection,
            preset: selectedPathPreset,
          );
    return _copyStateWithTerrainPresetSelection(
      current,
      selection,
      activeTool: EditorToolType.terrainPaint,
      statusMessage: selectedPathPreset == null
          ? 'Path paint mode'
          : 'Path preset: ${selectedPathPreset.name}',
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

  TerrainPresetSelection _currentTerrainPresetSelection(EditorState state) {
    return TerrainPresetSelection(
      selectionMode: state.terrainSelectionMode,
      selectedTerrainType: state.selectedTerrainType,
      selectedTerrainPresetId: state.selectedTerrainPresetId,
      selectedPathPresetId: state.selectedPathPresetId,
      selectedTerrainPresetByType: state.selectedTerrainPresetByType,
    );
  }

  EditorState _copyStateWithTerrainPresetSelection(
    EditorState source,
    TerrainPresetSelection selection, {
    String? statusMessage,
    String? errorMessage,
    EditorToolType? activeTool,
  }) {
    return source.copyWith(
      terrainSelectionMode: selection.selectionMode,
      selectedTerrainType: selection.selectedTerrainType,
      selectedTerrainPresetId: selection.selectedTerrainPresetId,
      selectedPathPresetId: selection.selectedPathPresetId,
      selectedTerrainPresetByType: selection.selectedTerrainPresetByType,
      activeTool: activeTool ?? source.activeTool,
      statusMessage: statusMessage,
      errorMessage: errorMessage,
    );
  }

  bool _isToolCompatibleWithActiveLayer(
    EditorToolType tool,
    MapLayer? layer,
  ) {
    switch (tool) {
      case EditorToolType.selection:
      case EditorToolType.entityPlacement:
      case EditorToolType.eventPlacement:
      case EditorToolType.triggerPlacement:
      case EditorToolType.warpPlacement:
      case EditorToolType.gameplayZonePlacement:
        return true;
      case EditorToolType.tilePaint:
        return layer is TileLayer;
      case EditorToolType.collisionPaint:
        return layer is CollisionLayer;
      case EditorToolType.terrainPaint:
        return layer is TerrainLayer || layer is PathLayer;
      case EditorToolType.surfacePaint:
        return layer is SurfaceLayer;
      case EditorToolType.eraser:
        return layer is TileLayer ||
            layer is CollisionLayer ||
            layer is TerrainLayer ||
            layer is PathLayer ||
            layer is SurfaceLayer;
    }
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
