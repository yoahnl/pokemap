import 'package:map_core/map_core.dart';

import '../state/editor_state.dart';
import 'project_session_models.dart';

/// Contrôleur pur des transitions "session projet / document".
///
/// Il ne lit ni le disque ni Riverpod. Son rôle est uniquement de reconstruire
/// des morceaux cohérents de `EditorState` quand on ouvre, sauvegarde, renomme
/// ou supprime le document actif.
class ProjectSessionController {
  const ProjectSessionController();

  EditorState openProjectSession({
    required EditorState current,
    required ProjectSessionLoadResult session,
    required String statusMessage,
  }) {
    return current
        .copyWithProjectSession(
          current.projectSession.copyWith(
            projectRootPath: session.projectRootPath,
            project: session.project,
            workspaceMode: EditorWorkspaceMode.map,
            activeMap: null,
            activeMapPath: null,
          ),
        )
        .copyWithSelection(
          current.selection.copyWith(
            activeLayerId: null,
            activeBrush: const EditorBrush.none(),
            terrainSelectionMode: session.presetSelection.selectionMode,
            selectedTerrainType: session.presetSelection.selectedTerrainType,
            selectedEntityKind: MapEntityKind.npc,
            selectedTerrainPresetId:
                session.presetSelection.selectedTerrainPresetId,
            selectedPathPresetId: session.presetSelection.selectedPathPresetId,
            selectedTerrainPresetByType:
                session.presetSelection.selectedTerrainPresetByType,
            selectedEntityId: null,
            npcWaypointPlacementEntityId: null,
            selectedMapEventId: null,
            selectedWarpId: null,
            selectedTriggerId: null,
            selectedGameplayZoneId: null,
            gameplayZoneDraftArea: null,
            selectedTilesetEditorId: null,
            selectedTilesetElementGroupId: null,
            tilesElementsPanelMode: TilesElementsPanelMode.palette,
            selectedPlacedElementInstanceId: null,
            selectedProjectDialogueId: null,
            selectedTrainerId: null,
            selectedCharacterId: null,
            paletteCategoryFilter: null,
          ),
        )
        .copyWithDocumentStatus(
          current.documentStatus.copyWith(
            mapUndoStack: const [],
            mapRedoStack: const [],
            mapStrokeStart: null,
            savedMapSnapshot: null,
            canUndoMap: false,
            canRedoMap: false,
            isDirty: false,
            isSaving: false,
            statusMessage: statusMessage,
            errorMessage: null,
          ),
        )
        .copyWith(isProjectDirty: false);
  }

  EditorState openMapDocument({
    required EditorState current,
    required MapDocumentLoadResult document,
    required String statusMessage,
  }) {
    return current
        .copyWithProjectSession(
          current.projectSession.copyWith(
            workspaceMode: EditorWorkspaceMode.map,
            activeMap: document.map,
            activeMapPath: document.activeMapPath,
          ),
        )
        .copyWithSelection(
          current.selection.copyWith(
            activeLayerId: _resolveActiveLayerId(document.map),
            activeBrush: const EditorBrush.none(),
            terrainSelectionMode: document.presetSelection.selectionMode,
            selectedTerrainType: document.presetSelection.selectedTerrainType,
            selectedTerrainPresetId:
                document.presetSelection.selectedTerrainPresetId,
            selectedPathPresetId: document.presetSelection.selectedPathPresetId,
            selectedTerrainPresetByType:
                document.presetSelection.selectedTerrainPresetByType,
            selectedEntityId: null,
            npcWaypointPlacementEntityId: null,
            selectedMapEventId: null,
            selectedWarpId: null,
            selectedTriggerId: null,
            selectedGameplayZoneId: null,
            gameplayZoneDraftArea: null,
            selectedTilesetEditorId: document.selectedTilesetEditorId,
            selectedTilesetElementGroupId: null,
            tilesElementsPanelMode: TilesElementsPanelMode.palette,
            selectedPlacedElementInstanceId: null,
            paletteCategoryFilter: null,
          ),
        )
        .copyWithDocumentStatus(
          current.documentStatus.copyWith(
            mapUndoStack: const [],
            mapRedoStack: const [],
            mapStrokeStart: null,
            savedMapSnapshot: document.map,
            canUndoMap: false,
            canRedoMap: false,
            isDirty: false,
            isSaving: false,
            statusMessage: statusMessage,
            errorMessage: null,
          ),
        )
        .copyWith(isProjectDirty: false);
  }

  EditorState markMapSaved({
    required EditorState current,
    required MapData map,
    required String statusMessage,
  }) {
    return current.copyWithDocumentStatus(
      current.documentStatus.copyWith(
        isSaving: false,
        isDirty: false,
        savedMapSnapshot: map,
        statusMessage: statusMessage,
        errorMessage: null,
      ),
    );
  }

  EditorState markMapSaving(EditorState current) {
    return current.copyWithDocumentStatus(
      current.documentStatus.copyWith(isSaving: true),
    );
  }

  EditorState markMapSaveFailed({
    required EditorState current,
    required String errorMessage,
  }) {
    return current.copyWithDocumentStatus(
      current.documentStatus.copyWith(
        isSaving: false,
        errorMessage: errorMessage,
      ),
    );
  }

  EditorState afterMapRenamed({
    required EditorState current,
    required ProjectManifest updatedProject,
    required String oldId,
    required String newId,
    required String newPath,
    required String statusMessage,
  }) {
    final session = current.projectSession;
    final documentStatus = current.documentStatus;
    if (session.activeMap?.id != oldId) {
      return current
          .copyWithProjectSession(session.copyWith(project: updatedProject))
          .copyWithDocumentStatus(
            documentStatus.copyWith(
              statusMessage: statusMessage,
              errorMessage: null,
            ),
          );
    }

    final renamedMap = session.activeMap!.copyWith(id: newId, name: newId);
    return current
        .copyWithProjectSession(
          session.copyWith(
            project: updatedProject,
            activeMap: renamedMap,
            activeMapPath: newPath,
          ),
        )
        .copyWithDocumentStatus(
          documentStatus.copyWith(
            mapUndoStack: const [],
            mapRedoStack: const [],
            mapStrokeStart: null,
            savedMapSnapshot: renamedMap,
            canUndoMap: false,
            canRedoMap: false,
            isDirty: false,
            statusMessage: statusMessage,
            errorMessage: null,
          ),
        );
  }

  EditorState afterMapDeleted({
    required EditorState current,
    required ProjectManifest updatedProject,
    required String deletedMapId,
    required String statusMessage,
  }) {
    final session = current.projectSession;
    final selection = current.selection;
    final documentStatus = current.documentStatus;
    if (session.activeMap?.id != deletedMapId) {
      return current
          .copyWithProjectSession(session.copyWith(project: updatedProject))
          .copyWithDocumentStatus(
            documentStatus.copyWith(
              statusMessage: statusMessage,
              errorMessage: null,
            ),
          );
    }

    return current
        .copyWithProjectSession(
          session.copyWith(
            project: updatedProject,
            activeMap: null,
            activeMapPath: null,
          ),
        )
        .copyWithSelection(
          selection.copyWith(
            activeLayerId: null,
            activeBrush: const EditorBrush.none(),
            selectedEntityId: null,
            selectedMapEventId: null,
            selectedWarpId: null,
            selectedTriggerId: null,
            selectedTilesetEditorId: null,
            selectedTilesetElementGroupId: null,
            paletteCategoryFilter: null,
          ),
        )
        .copyWithDocumentStatus(
          documentStatus.copyWith(
            mapUndoStack: const [],
            mapRedoStack: const [],
            mapStrokeStart: null,
            savedMapSnapshot: null,
            canUndoMap: false,
            canRedoMap: false,
            isDirty: false,
            statusMessage: statusMessage,
            errorMessage: null,
          ),
        );
  }

  String? _resolveActiveLayerId(MapData map) {
    if (map.layers.isEmpty) {
      return null;
    }
    return map.layers.first.id;
  }
}
