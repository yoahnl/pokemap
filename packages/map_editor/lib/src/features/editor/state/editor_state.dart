import 'dart:ui' show Offset;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:map_core/map_core.dart';

import '../../../application/models/map_history_entry.dart';
import '../../../application/models/map_history_snapshot.dart';
import '../../smart_tiles_studio/application/smart_tile_studio_launch_context.dart';
import 'models/encounter_studio_section.dart';
import 'models/editor_ui_modes.dart';
import 'models/editor_palette_session.dart';
import 'models/editor_workspace_mode.dart';
import 'models/pokemon_catalog_section.dart';
import '../tools/editor_tool.dart';

export 'models/editor_state_groups.dart';
export 'models/encounter_studio_section.dart';
export 'models/editor_ui_modes.dart';
export 'models/editor_palette_session.dart';
export 'models/editor_workspace_mode.dart';
export 'models/pokemon_catalog_section.dart';

part 'editor_state.freezed.dart';

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
  const factory EditorBrush.projectElement({required String elementId}) =
      ProjectElementEditorBrush;
}

/// Maximum width or height accepted by the editor eraser.
///
/// The same safety bound protects both custom sizes and brush snapshots so a
/// malformed or unexpectedly large brush cannot trigger an unbounded erase.
const int kMaxEditorEraserFootprintDimension = 16;

@freezed
sealed class EditorEraserFootprint with _$EditorEraserFootprint {
  const factory EditorEraserFootprint.singleTile() =
      SingleTileEditorEraserFootprint;
  const factory EditorEraserFootprint.previousBrush({required GridSize size}) =
      PreviousBrushEditorEraserFootprint;
  const factory EditorEraserFootprint.custom({required GridSize size}) =
      CustomEditorEraserFootprint;
}

extension EditorEraserFootprintSize on EditorEraserFootprint {
  GridSize get size => switch (this) {
    SingleTileEditorEraserFootprint() => const GridSize(width: 1, height: 1),
    PreviousBrushEditorEraserFootprint(:final size) => size,
    CustomEditorEraserFootprint(:final size) => size,
  };
}

@freezed
abstract class EditorState with _$EditorState {
  const factory EditorState({
    // Session projet / document ouvert
    String? projectRootPath,
    ProjectManifest? project,
    @Default(EditorWorkspaceMode.map) EditorWorkspaceMode workspaceMode,
    @Default(EncounterStudioSection.wildEncounters)
    EncounterStudioSection encounterStudioSection,
    String? encounterStudioTableId,
    @Default(SmartTilesStudioLaunchContext.library())
    SmartTilesStudioLaunchContext smartTilesStudioLaunchContext,
    @Default(PokemonCatalogSection.pokedex)
    PokemonCatalogSection pokemonCatalogSection,

    // Document map actif
    MapData? activeMap,
    String? activeMapPath,

    // Outils et sélections d'édition
    @Default(EditorToolType.selection) EditorToolType activeTool,
    String? activeLayerId,
    GridPos? hoveredTile,
    @Default(EditorBrush.none()) EditorBrush activeBrush,
    @Default(MapEntityKind.npc) MapEntityKind selectedEntityKind,
    @Default(EditorEraserFootprint.singleTile())
    EditorEraserFootprint eraserFootprint,
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

    /// Lot Environment-22 : area dont le masque est édité (layer actif = Environment).
    String? selectedEnvironmentAreaId,
    EnvironmentMaskEditMode? environmentMaskEditMode,

    /// Zone en cours de tracé par clic+glisser (fantôme, pas encore persistée).
    MapRect? gameplayZoneDraftArea,
    String? selectedTilesetEditorId,
    String? selectedTilesetElementGroupId,
    @Default(EditorPaletteSession()) EditorPaletteSession paletteSession,
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

    // Viewport canvas
    @Default(1.0) double zoom,
    @Default(Offset.zero) Offset panOffset,

    // Statut document / historique
    @Default([]) List<MapHistoryEntry> mapUndoStack,
    @Default([]) List<MapHistoryEntry> mapRedoStack,
    MapHistorySnapshot? mapStrokeStart,
    MapData? savedMapSnapshot,
    @Default(false) bool canUndoMap,
    @Default(false) bool canRedoMap,
    @Default(false) bool isDirty,
    @Default(false) bool isProjectDirty,
    @Default(false) bool isSaving,
    String? statusMessage,
    String? errorMessage,
  }) = _EditorState;
}
