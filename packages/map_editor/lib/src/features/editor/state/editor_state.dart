import 'dart:ui' show Offset;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:map_core/map_core.dart';

import '../../../application/models/map_history_snapshot.dart';
import '../tools/editor_tool.dart';

part 'editor_state.freezed.dart';

enum EditorWorkspaceMode {
  map,
  tileset,
}

enum CollisionBrushSizeMode {
  brushFootprint,
  singleTile,
}

enum TerrainSelectionMode {
  terrain,
  path,
}

@freezed
sealed class EditorBrush with _$EditorBrush {
  const factory EditorBrush.none() = NoEditorBrush;
  const factory EditorBrush.tile({
    required int tileId,
    required String tilesetId,
  }) = TileEditorBrush;
  const factory EditorBrush.paletteEntry({
    required String entryId,
    required String tilesetId,
  }) = PaletteEntryEditorBrush;
  const factory EditorBrush.projectElement({
    required String elementId,
  }) = ProjectElementEditorBrush;
}

@freezed
class EditorState with _$EditorState {
  const factory EditorState({
    // Context
    String? projectRootPath,
    ProjectManifest? project,
    @Default(EditorWorkspaceMode.map) EditorWorkspaceMode workspaceMode,

    // Active Map
    MapData? activeMap,
    String? activeMapPath,

    // Active Tools & Selection
    @Default(EditorToolType.selection) EditorToolType activeTool,
    String? activeLayerId,
    GridPos? hoveredTile,
    @Default(EditorBrush.none()) EditorBrush activeBrush,
    @Default(TerrainSelectionMode.terrain)
    TerrainSelectionMode terrainSelectionMode,
    @Default(TerrainType.grass) TerrainType selectedTerrainType,
    @Default(MapEntityKind.npc) MapEntityKind selectedEntityKind,
    String? selectedTerrainPresetId,
    String? selectedPathPresetId,
    @Default({}) Map<TerrainType, String> selectedTerrainPresetByType,
    @Default(CollisionBrushSizeMode.brushFootprint)
    CollisionBrushSizeMode collisionBrushSizeMode,
    String? selectedEntityId,
    String? selectedWarpId,
    String? selectedTriggerId,
    String? selectedGameplayZoneId,
    /// Zone en cours de tracé par clic+glisser (fantôme, pas encore persistée).
    MapRect? gameplayZoneDraftArea,
    String? selectedTilesetEditorId,
    String? selectedTilesetElementGroupId,
    /// Dialogue projet sélectionné dans l’explorateur (bibliothèque).
    String? selectedProjectDialogueId,
    /// Dresseur sélectionné dans la bibliothèque dresseurs.
    String? selectedTrainerId,
    /// Personnage sélectionné dans la bibliothèque personnages.
    String? selectedCharacterId,
    PaletteCategory? paletteCategoryFilter,

    // Viewport
    @Default(1.0) double zoom,
    @Default(Offset.zero) Offset panOffset,

    // Status
    @Default([]) List<MapHistorySnapshot> mapUndoStack,
    @Default([]) List<MapHistorySnapshot> mapRedoStack,
    MapHistorySnapshot? mapStrokeStart,
    MapData? savedMapSnapshot,
    @Default(false) bool canUndoMap,
    @Default(false) bool canRedoMap,
    @Default(false) bool isDirty,
    @Default(false) bool isSaving,
    String? statusMessage,
    String? errorMessage,
  }) = _EditorState;
}
