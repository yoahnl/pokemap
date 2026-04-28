import 'dart:ui' show Offset;

import 'package:map_core/map_core.dart';

import '../../../../application/models/map_history_snapshot.dart';
import '../../../../application/models/terrain_selection_mode.dart';
import '../../tools/editor_tool.dart';
import '../editor_state.dart';

const Object _editorStateGroupsUnset = Object();

/// Vue groupée de la session projet/document.
///
/// Cette structure n'introduit pas un second store ; elle sert uniquement à
/// rendre l'état plat plus lisible et à préparer les futures extractions hors
/// de `EditorNotifier`.
class EditorProjectSessionState {
  const EditorProjectSessionState({
    required this.projectRootPath,
    required this.project,
    required this.workspaceMode,
    required this.activeMap,
    required this.activeMapPath,
  });

  final String? projectRootPath;
  final ProjectManifest? project;
  final EditorWorkspaceMode workspaceMode;
  final MapData? activeMap;
  final String? activeMapPath;

  EditorProjectSessionState copyWith({
    String? projectRootPath,
    Object? project = _editorStateGroupsUnset,
    EditorWorkspaceMode? workspaceMode,
    Object? activeMap = _editorStateGroupsUnset,
    Object? activeMapPath = _editorStateGroupsUnset,
  }) {
    return EditorProjectSessionState(
      projectRootPath: projectRootPath ?? this.projectRootPath,
      project: identical(project, _editorStateGroupsUnset)
          ? this.project
          : project as ProjectManifest?,
      workspaceMode: workspaceMode ?? this.workspaceMode,
      activeMap: identical(activeMap, _editorStateGroupsUnset)
          ? this.activeMap
          : activeMap as MapData?,
      activeMapPath: identical(activeMapPath, _editorStateGroupsUnset)
          ? this.activeMapPath
          : activeMapPath as String?,
    );
  }
}

/// Vue groupée des outils, sélections d'édition et sélections de bibliothèques.
class EditorSelectionState {
  const EditorSelectionState({
    required this.activeTool,
    required this.activeLayerId,
    required this.hoveredTile,
    required this.activeBrush,
    required this.terrainSelectionMode,
    required this.selectedTerrainType,
    required this.selectedEntityKind,
    required this.selectedTerrainPresetId,
    required this.selectedPathPresetId,
    required this.selectedSurfacePresetId,
    required this.selectedTerrainPresetByType,
    required this.collisionBrushSizeMode,
    required this.selectedEntityId,
    required this.npcWaypointPlacementEntityId,
    required this.selectedMapEventId,
    required this.selectedWarpId,
    required this.selectedTriggerId,
    required this.selectedGameplayZoneId,
    required this.gameplayZoneDraftArea,
    required this.selectedTilesetEditorId,
    required this.selectedTilesetElementGroupId,
    required this.tilesElementsPanelMode,
    required this.selectedPlacedElementInstanceId,
    required this.selectedProjectDialogueId,
    required this.selectedTrainerId,
    required this.selectedCharacterId,
    required this.paletteCategoryFilter,
  });

  final EditorToolType activeTool;
  final String? activeLayerId;
  final GridPos? hoveredTile;
  final EditorBrush activeBrush;
  final TerrainSelectionMode terrainSelectionMode;
  final TerrainType selectedTerrainType;
  final MapEntityKind selectedEntityKind;
  final String? selectedTerrainPresetId;
  final String? selectedPathPresetId;
  final String? selectedSurfacePresetId;
  final Map<TerrainType, String> selectedTerrainPresetByType;
  final CollisionBrushSizeMode collisionBrushSizeMode;
  final String? selectedEntityId;
  final String? npcWaypointPlacementEntityId;
  final String? selectedMapEventId;
  final String? selectedWarpId;
  final String? selectedTriggerId;
  final String? selectedGameplayZoneId;
  final MapRect? gameplayZoneDraftArea;
  final String? selectedTilesetEditorId;
  final String? selectedTilesetElementGroupId;
  final TilesElementsPanelMode tilesElementsPanelMode;
  final String? selectedPlacedElementInstanceId;
  final String? selectedProjectDialogueId;
  final String? selectedTrainerId;
  final String? selectedCharacterId;
  final PaletteCategory? paletteCategoryFilter;

  EditorSelectionState copyWith({
    EditorToolType? activeTool,
    Object? activeLayerId = _editorStateGroupsUnset,
    Object? hoveredTile = _editorStateGroupsUnset,
    EditorBrush? activeBrush,
    TerrainSelectionMode? terrainSelectionMode,
    TerrainType? selectedTerrainType,
    MapEntityKind? selectedEntityKind,
    Object? selectedTerrainPresetId = _editorStateGroupsUnset,
    Object? selectedPathPresetId = _editorStateGroupsUnset,
    Object? selectedSurfacePresetId = _editorStateGroupsUnset,
    Map<TerrainType, String>? selectedTerrainPresetByType,
    CollisionBrushSizeMode? collisionBrushSizeMode,
    Object? selectedEntityId = _editorStateGroupsUnset,
    Object? npcWaypointPlacementEntityId = _editorStateGroupsUnset,
    Object? selectedMapEventId = _editorStateGroupsUnset,
    Object? selectedWarpId = _editorStateGroupsUnset,
    Object? selectedTriggerId = _editorStateGroupsUnset,
    Object? selectedGameplayZoneId = _editorStateGroupsUnset,
    Object? gameplayZoneDraftArea = _editorStateGroupsUnset,
    Object? selectedTilesetEditorId = _editorStateGroupsUnset,
    Object? selectedTilesetElementGroupId = _editorStateGroupsUnset,
    TilesElementsPanelMode? tilesElementsPanelMode,
    Object? selectedPlacedElementInstanceId = _editorStateGroupsUnset,
    Object? selectedProjectDialogueId = _editorStateGroupsUnset,
    Object? selectedTrainerId = _editorStateGroupsUnset,
    Object? selectedCharacterId = _editorStateGroupsUnset,
    Object? paletteCategoryFilter = _editorStateGroupsUnset,
  }) {
    return EditorSelectionState(
      activeTool: activeTool ?? this.activeTool,
      activeLayerId: identical(activeLayerId, _editorStateGroupsUnset)
          ? this.activeLayerId
          : activeLayerId as String?,
      hoveredTile: identical(hoveredTile, _editorStateGroupsUnset)
          ? this.hoveredTile
          : hoveredTile as GridPos?,
      activeBrush: activeBrush ?? this.activeBrush,
      terrainSelectionMode: terrainSelectionMode ?? this.terrainSelectionMode,
      selectedTerrainType: selectedTerrainType ?? this.selectedTerrainType,
      selectedEntityKind: selectedEntityKind ?? this.selectedEntityKind,
      selectedTerrainPresetId:
          identical(selectedTerrainPresetId, _editorStateGroupsUnset)
              ? this.selectedTerrainPresetId
              : selectedTerrainPresetId as String?,
      selectedPathPresetId:
          identical(selectedPathPresetId, _editorStateGroupsUnset)
              ? this.selectedPathPresetId
              : selectedPathPresetId as String?,
      selectedSurfacePresetId:
          identical(selectedSurfacePresetId, _editorStateGroupsUnset)
              ? this.selectedSurfacePresetId
              : selectedSurfacePresetId as String?,
      selectedTerrainPresetByType:
          selectedTerrainPresetByType ?? this.selectedTerrainPresetByType,
      collisionBrushSizeMode:
          collisionBrushSizeMode ?? this.collisionBrushSizeMode,
      selectedEntityId: identical(selectedEntityId, _editorStateGroupsUnset)
          ? this.selectedEntityId
          : selectedEntityId as String?,
      npcWaypointPlacementEntityId:
          identical(npcWaypointPlacementEntityId, _editorStateGroupsUnset)
              ? this.npcWaypointPlacementEntityId
              : npcWaypointPlacementEntityId as String?,
      selectedMapEventId: identical(selectedMapEventId, _editorStateGroupsUnset)
          ? this.selectedMapEventId
          : selectedMapEventId as String?,
      selectedWarpId: identical(selectedWarpId, _editorStateGroupsUnset)
          ? this.selectedWarpId
          : selectedWarpId as String?,
      selectedTriggerId: identical(selectedTriggerId, _editorStateGroupsUnset)
          ? this.selectedTriggerId
          : selectedTriggerId as String?,
      selectedGameplayZoneId:
          identical(selectedGameplayZoneId, _editorStateGroupsUnset)
              ? this.selectedGameplayZoneId
              : selectedGameplayZoneId as String?,
      gameplayZoneDraftArea:
          identical(gameplayZoneDraftArea, _editorStateGroupsUnset)
              ? this.gameplayZoneDraftArea
              : gameplayZoneDraftArea as MapRect?,
      selectedTilesetEditorId:
          identical(selectedTilesetEditorId, _editorStateGroupsUnset)
              ? this.selectedTilesetEditorId
              : selectedTilesetEditorId as String?,
      selectedTilesetElementGroupId:
          identical(selectedTilesetElementGroupId, _editorStateGroupsUnset)
              ? this.selectedTilesetElementGroupId
              : selectedTilesetElementGroupId as String?,
      tilesElementsPanelMode:
          tilesElementsPanelMode ?? this.tilesElementsPanelMode,
      selectedPlacedElementInstanceId:
          identical(selectedPlacedElementInstanceId, _editorStateGroupsUnset)
              ? this.selectedPlacedElementInstanceId
              : selectedPlacedElementInstanceId as String?,
      selectedProjectDialogueId:
          identical(selectedProjectDialogueId, _editorStateGroupsUnset)
              ? this.selectedProjectDialogueId
              : selectedProjectDialogueId as String?,
      selectedTrainerId: identical(selectedTrainerId, _editorStateGroupsUnset)
          ? this.selectedTrainerId
          : selectedTrainerId as String?,
      selectedCharacterId:
          identical(selectedCharacterId, _editorStateGroupsUnset)
              ? this.selectedCharacterId
              : selectedCharacterId as String?,
      paletteCategoryFilter:
          identical(paletteCategoryFilter, _editorStateGroupsUnset)
              ? this.paletteCategoryFilter
              : paletteCategoryFilter as PaletteCategory?,
    );
  }
}

/// Vue groupée du viewport canvas.
class EditorViewportState {
  const EditorViewportState({
    required this.zoom,
    required this.panOffset,
  });

  final double zoom;
  final Offset panOffset;

  EditorViewportState copyWith({
    double? zoom,
    Offset? panOffset,
  }) {
    return EditorViewportState(
      zoom: zoom ?? this.zoom,
      panOffset: panOffset ?? this.panOffset,
    );
  }
}

/// Vue groupée du statut document/historique.
class EditorDocumentStatusState {
  const EditorDocumentStatusState({
    required this.mapUndoStack,
    required this.mapRedoStack,
    required this.mapStrokeStart,
    required this.savedMapSnapshot,
    required this.canUndoMap,
    required this.canRedoMap,
    required this.isDirty,
    required this.isSaving,
    required this.statusMessage,
    required this.errorMessage,
  });

  final List<MapHistorySnapshot> mapUndoStack;
  final List<MapHistorySnapshot> mapRedoStack;
  final MapHistorySnapshot? mapStrokeStart;
  final MapData? savedMapSnapshot;
  final bool canUndoMap;
  final bool canRedoMap;
  final bool isDirty;
  final bool isSaving;
  final String? statusMessage;
  final String? errorMessage;

  EditorDocumentStatusState copyWith({
    List<MapHistorySnapshot>? mapUndoStack,
    List<MapHistorySnapshot>? mapRedoStack,
    Object? mapStrokeStart = _editorStateGroupsUnset,
    Object? savedMapSnapshot = _editorStateGroupsUnset,
    bool? canUndoMap,
    bool? canRedoMap,
    bool? isDirty,
    bool? isSaving,
    Object? statusMessage = _editorStateGroupsUnset,
    Object? errorMessage = _editorStateGroupsUnset,
  }) {
    return EditorDocumentStatusState(
      mapUndoStack: mapUndoStack ?? this.mapUndoStack,
      mapRedoStack: mapRedoStack ?? this.mapRedoStack,
      mapStrokeStart: identical(mapStrokeStart, _editorStateGroupsUnset)
          ? this.mapStrokeStart
          : mapStrokeStart as MapHistorySnapshot?,
      savedMapSnapshot: identical(savedMapSnapshot, _editorStateGroupsUnset)
          ? this.savedMapSnapshot
          : savedMapSnapshot as MapData?,
      canUndoMap: canUndoMap ?? this.canUndoMap,
      canRedoMap: canRedoMap ?? this.canRedoMap,
      isDirty: isDirty ?? this.isDirty,
      isSaving: isSaving ?? this.isSaving,
      statusMessage: identical(statusMessage, _editorStateGroupsUnset)
          ? this.statusMessage
          : statusMessage as String?,
      errorMessage: identical(errorMessage, _editorStateGroupsUnset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

/// Helpers de projection/copier-coller ciblé pour `EditorState`.
///
/// L'objectif n'est pas de créer une abstraction magique, mais d'éviter que
/// tout le code futur manipule encore un "sac à propriétés" plat sans repères.
extension EditorStateGroups on EditorState {
  EditorProjectSessionState get projectSession => EditorProjectSessionState(
        projectRootPath: projectRootPath,
        project: project,
        workspaceMode: workspaceMode,
        activeMap: activeMap,
        activeMapPath: activeMapPath,
      );

  EditorSelectionState get selection => EditorSelectionState(
        activeTool: activeTool,
        activeLayerId: activeLayerId,
        hoveredTile: hoveredTile,
        activeBrush: activeBrush,
        terrainSelectionMode: terrainSelectionMode,
        selectedTerrainType: selectedTerrainType,
        selectedEntityKind: selectedEntityKind,
        selectedTerrainPresetId: selectedTerrainPresetId,
        selectedPathPresetId: selectedPathPresetId,
        selectedSurfacePresetId: selectedSurfacePresetId,
        selectedTerrainPresetByType: selectedTerrainPresetByType,
        collisionBrushSizeMode: collisionBrushSizeMode,
        selectedEntityId: selectedEntityId,
        npcWaypointPlacementEntityId: npcWaypointPlacementEntityId,
        selectedMapEventId: selectedMapEventId,
        selectedWarpId: selectedWarpId,
        selectedTriggerId: selectedTriggerId,
        selectedGameplayZoneId: selectedGameplayZoneId,
        gameplayZoneDraftArea: gameplayZoneDraftArea,
        selectedTilesetEditorId: selectedTilesetEditorId,
        selectedTilesetElementGroupId: selectedTilesetElementGroupId,
        tilesElementsPanelMode: tilesElementsPanelMode,
        selectedPlacedElementInstanceId: selectedPlacedElementInstanceId,
        selectedProjectDialogueId: selectedProjectDialogueId,
        selectedTrainerId: selectedTrainerId,
        selectedCharacterId: selectedCharacterId,
        paletteCategoryFilter: paletteCategoryFilter,
      );

  EditorViewportState get viewport => EditorViewportState(
        zoom: zoom,
        panOffset: panOffset,
      );

  EditorDocumentStatusState get documentStatus => EditorDocumentStatusState(
        mapUndoStack: mapUndoStack,
        mapRedoStack: mapRedoStack,
        mapStrokeStart: mapStrokeStart,
        savedMapSnapshot: savedMapSnapshot,
        canUndoMap: canUndoMap,
        canRedoMap: canRedoMap,
        isDirty: isDirty,
        isSaving: isSaving,
        statusMessage: statusMessage,
        errorMessage: errorMessage,
      );

  EditorState copyWithProjectSession(EditorProjectSessionState next) {
    return copyWith(
      projectRootPath: next.projectRootPath,
      project: next.project,
      workspaceMode: next.workspaceMode,
      activeMap: next.activeMap,
      activeMapPath: next.activeMapPath,
    );
  }

  EditorState copyWithSelection(EditorSelectionState next) {
    return copyWith(
      activeTool: next.activeTool,
      activeLayerId: next.activeLayerId,
      hoveredTile: next.hoveredTile,
      activeBrush: next.activeBrush,
      terrainSelectionMode: next.terrainSelectionMode,
      selectedTerrainType: next.selectedTerrainType,
      selectedEntityKind: next.selectedEntityKind,
      selectedTerrainPresetId: next.selectedTerrainPresetId,
      selectedPathPresetId: next.selectedPathPresetId,
      selectedSurfacePresetId: next.selectedSurfacePresetId,
      selectedTerrainPresetByType: next.selectedTerrainPresetByType,
      collisionBrushSizeMode: next.collisionBrushSizeMode,
      selectedEntityId: next.selectedEntityId,
      npcWaypointPlacementEntityId: next.npcWaypointPlacementEntityId,
      selectedMapEventId: next.selectedMapEventId,
      selectedWarpId: next.selectedWarpId,
      selectedTriggerId: next.selectedTriggerId,
      selectedGameplayZoneId: next.selectedGameplayZoneId,
      gameplayZoneDraftArea: next.gameplayZoneDraftArea,
      selectedTilesetEditorId: next.selectedTilesetEditorId,
      selectedTilesetElementGroupId: next.selectedTilesetElementGroupId,
      tilesElementsPanelMode: next.tilesElementsPanelMode,
      selectedPlacedElementInstanceId: next.selectedPlacedElementInstanceId,
      selectedProjectDialogueId: next.selectedProjectDialogueId,
      selectedTrainerId: next.selectedTrainerId,
      selectedCharacterId: next.selectedCharacterId,
      paletteCategoryFilter: next.paletteCategoryFilter,
    );
  }

  EditorState copyWithViewport(EditorViewportState next) {
    return copyWith(
      zoom: next.zoom,
      panOffset: next.panOffset,
    );
  }

  EditorState copyWithDocumentStatus(EditorDocumentStatusState next) {
    return copyWith(
      mapUndoStack: next.mapUndoStack,
      mapRedoStack: next.mapRedoStack,
      mapStrokeStart: next.mapStrokeStart,
      savedMapSnapshot: next.savedMapSnapshot,
      canUndoMap: next.canUndoMap,
      canRedoMap: next.canRedoMap,
      isDirty: next.isDirty,
      isSaving: next.isSaving,
      statusMessage: next.statusMessage,
      errorMessage: next.errorMessage,
    );
  }
}
