import 'dart:ui' show Offset;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:map_core/map_core.dart';

import '../../../application/models/map_history_snapshot.dart';
import '../../../application/models/terrain_selection_mode.dart';
import '../tools/editor_tool.dart';

part 'editor_state.freezed.dart';

enum EditorWorkspaceMode {
  map,
  tileset,

  // Workspace Pokédex minimal branché dans l'éditeur.
  //
  // Intention produit:
  // - rendre visible une vraie entree Pokédex dans l'editeur ;
  // - ouvrir un workspace central dedie ;
  // - permettre d'afficher une liste simple des especes importees.
  //
  // Important:
  // ce mode reste volontairement limite :
  // - pas de recherche ;
  // - pas de filtres ;
  // - pas de fiche detail ;
  // - pas d'edition.
  pokedex,

  // Workspaces narratifs centraux.
  //
  // Intention produit (non négociable):
  // - ces surfaces vivent dans l'îlot central, comme des workspaces de
  //   premier plan (pas comme des "petits panneaux" latéraux).
  // - la colonne gauche sert à naviguer/ouvrir.
  // - la colonne droite sert à inspecter le contexte sélectionné.
  globalStory,
  step,
  cutscene,

  /// Studio de conversation (dialogues `.yarn` en blocs visuels).
  dialogue,
}

enum CollisionBrushSizeMode {
  brushFootprint,
  singleTile,
}

enum TilesElementsPanelMode {
  palette,
  placedInstances,
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

    /// Session de placement visuel de waypoint NPC active.
    ///
    /// - `null` : aucun mode placement waypoint actif.
    /// - non null : id de l'entité NPC ciblée par les clics map.
    ///
    /// Le clic map est alors re-routé vers "ajout waypoint", au lieu du flux
    /// d'outil normal (paint/place/select), tant que la session est valide.
    String? npcWaypointPlacementEntityId,
    String? selectedMapEventId,
    String? selectedWarpId,
    String? selectedTriggerId,
    String? selectedGameplayZoneId,

    /// Zone en cours de tracé par clic+glisser (fantôme, pas encore persistée).
    MapRect? gameplayZoneDraftArea,
    String? selectedTilesetEditorId,
    String? selectedTilesetElementGroupId,
    @Default(TilesElementsPanelMode.palette)
    TilesElementsPanelMode tilesElementsPanelMode,
    String? selectedPlacedElementInstanceId,

    /// Dialogue projet sélectionné dans l’explorateur (bibliothèque).
    String? selectedProjectDialogueId,
    // Rollback complet scénario/scripts:
    // Les sélections dédiées au graphe scénario et à la bibliothèque de scripts
    // runtime sont supprimées de l’état éditeur. Cela évite de conserver des
    // états fantômes pour des surfaces UI désormais retirées.

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
