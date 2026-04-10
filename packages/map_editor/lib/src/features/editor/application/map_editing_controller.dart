import 'package:map_core/map_core.dart';

import '../../../application/services/editor_map_mutation_coordinator.dart';
import '../state/editor_state.dart';

/// Contrôleur pur des transitions d'édition sur le document map actif.
///
/// Il encapsule la mécanique d'historique/stroke/undo-redo et le recalcul
/// des sélections cohérentes après mutation. Le notifier reste responsable
/// d'appeler les use cases/services métier qui produisent les `MapData`.
class MapEditingController {
  const MapEditingController({
    required EditorMapMutationCoordinator mutationCoordinator,
  }) : _mutationCoordinator = mutationCoordinator;

  final EditorMapMutationCoordinator _mutationCoordinator;

  EditorState beginStroke(EditorState current) {
    final map = current.activeMap;
    if (map == null || current.mapStrokeStart != null) {
      return current;
    }
    final history = _mutationCoordinator.beginStroke(
      map: map,
      activeLayerId: current.activeLayerId,
      selectedEntityId: current.selectedEntityId,
      selectedWarpId: current.selectedWarpId,
      selectedTriggerId: current.selectedTriggerId,
      undoStack: current.mapUndoStack,
      redoStack: current.mapRedoStack,
      strokeStart: current.mapStrokeStart,
      currentDirty: current.isDirty,
    );
    return current.copyWith(
      mapUndoStack: history.undoStack,
      mapRedoStack: history.redoStack,
      mapStrokeStart: history.strokeStart,
      canUndoMap: history.canUndoMap,
      canRedoMap: history.canRedoMap,
      isDirty: history.isDirty,
    );
  }

  EditorState endStroke(EditorState current) {
    if (current.mapStrokeStart == null) {
      return current;
    }
    final history = _mutationCoordinator.finalizeStroke(
      currentMap: current.activeMap,
      undoStack: current.mapUndoStack,
      redoStack: current.mapRedoStack,
      strokeStart: current.mapStrokeStart,
      savedMapSnapshot: current.savedMapSnapshot,
      currentDirty: current.isDirty,
    );
    return current.copyWith(
      mapUndoStack: history.undoStack,
      mapRedoStack: history.redoStack,
      mapStrokeStart: history.strokeStart,
      canUndoMap: history.canUndoMap,
      canRedoMap: history.canRedoMap,
      isDirty: history.isDirty,
      errorMessage: null,
    );
  }

  EditorState? undo(EditorState current) {
    final map = current.activeMap;
    if (map == null) {
      return null;
    }
    final restored = _mutationCoordinator.undo(
      currentMap: map,
      activeLayerId: current.activeLayerId,
      selectedEntityId: current.selectedEntityId,
      selectedWarpId: current.selectedWarpId,
      selectedTriggerId: current.selectedTriggerId,
      undoStack: current.mapUndoStack,
      redoStack: current.mapRedoStack,
      savedMapSnapshot: current.savedMapSnapshot,
    );
    if (restored == null) {
      return null;
    }
    final nextPlacedSelectionId = _resolvePlacedElementSelectionAfterMutation(
      currentSelectionId: current.selectedPlacedElementInstanceId,
      nextMap: restored.activeMap,
      nextActiveLayerId: restored.activeLayerId,
    );
    final nextMapEventSelectionId = _resolveMapEventSelectionAfterMutation(
      currentSelectionId: current.selectedMapEventId,
      preferredSelectionId: null,
      nextMap: restored.activeMap,
    );
    return current.copyWith(
      activeMap: restored.activeMap,
      activeLayerId: restored.activeLayerId,
      selectedEntityId: restored.selectedEntityId,
      selectedMapEventId: nextMapEventSelectionId,
      selectedWarpId: restored.selectedWarpId,
      selectedTriggerId: restored.selectedTriggerId,
      selectedPlacedElementInstanceId: nextPlacedSelectionId,
      selectedTilesetEditorId: restored.selectedTilesetEditorId,
      mapUndoStack: restored.undoStack,
      mapRedoStack: restored.redoStack,
      mapStrokeStart: restored.strokeStart,
      canUndoMap: restored.canUndoMap,
      canRedoMap: restored.canRedoMap,
      savedMapSnapshot: restored.savedMapSnapshot,
      isDirty: restored.isDirty,
      statusMessage: 'Undo',
      errorMessage: null,
    );
  }

  EditorState? redo(EditorState current) {
    final map = current.activeMap;
    if (map == null) {
      return null;
    }
    final restored = _mutationCoordinator.redo(
      currentMap: map,
      activeLayerId: current.activeLayerId,
      selectedEntityId: current.selectedEntityId,
      selectedWarpId: current.selectedWarpId,
      selectedTriggerId: current.selectedTriggerId,
      undoStack: current.mapUndoStack,
      redoStack: current.mapRedoStack,
      savedMapSnapshot: current.savedMapSnapshot,
    );
    if (restored == null) {
      return null;
    }
    final nextPlacedSelectionId = _resolvePlacedElementSelectionAfterMutation(
      currentSelectionId: current.selectedPlacedElementInstanceId,
      nextMap: restored.activeMap,
      nextActiveLayerId: restored.activeLayerId,
    );
    final nextMapEventSelectionId = _resolveMapEventSelectionAfterMutation(
      currentSelectionId: current.selectedMapEventId,
      preferredSelectionId: null,
      nextMap: restored.activeMap,
    );
    return current.copyWith(
      activeMap: restored.activeMap,
      activeLayerId: restored.activeLayerId,
      selectedEntityId: restored.selectedEntityId,
      selectedMapEventId: nextMapEventSelectionId,
      selectedWarpId: restored.selectedWarpId,
      selectedTriggerId: restored.selectedTriggerId,
      selectedPlacedElementInstanceId: nextPlacedSelectionId,
      selectedTilesetEditorId: restored.selectedTilesetEditorId,
      mapUndoStack: restored.undoStack,
      mapRedoStack: restored.redoStack,
      mapStrokeStart: restored.strokeStart,
      canUndoMap: restored.canUndoMap,
      canRedoMap: restored.canRedoMap,
      savedMapSnapshot: restored.savedMapSnapshot,
      isDirty: restored.isDirty,
      statusMessage: 'Redo',
      errorMessage: null,
    );
  }

  EditorState applyMutation({
    required EditorState current,
    required MapData previousMap,
    required MapData updatedMap,
    required String? preferredActiveLayerId,
    String? preferredSelectedEntityId,
    String? preferredSelectedMapEventId,
    String? preferredSelectedWarpId,
    String? preferredSelectedTriggerId,
    bool partOfStroke = false,
    bool updateSavedSnapshot = false,
    GridPos? hoveredTile,
    bool updateHoveredTile = false,
    String? statusMessage,
  }) {
    if (identical(previousMap, updatedMap) || previousMap == updatedMap) {
      return current;
    }

    var state = current;
    if (!partOfStroke && state.mapStrokeStart != null) {
      state = endStroke(state);
    }

    final mutation = _mutationCoordinator.applyMutation(
      previousMap: previousMap,
      updatedMap: updatedMap,
      activeLayerId: state.activeLayerId,
      selectedEntityId: state.selectedEntityId,
      selectedWarpId: state.selectedWarpId,
      selectedTriggerId: state.selectedTriggerId,
      selectedTilesetEditorId: state.selectedTilesetEditorId,
      undoStack: state.mapUndoStack,
      redoStack: state.mapRedoStack,
      strokeStart: state.mapStrokeStart,
      preferredActiveLayerId: preferredActiveLayerId,
      preferredSelectedEntityId: preferredSelectedEntityId,
      preferredSelectedWarpId: preferredSelectedWarpId,
      preferredSelectedTriggerId: preferredSelectedTriggerId,
      savedMapSnapshot: state.savedMapSnapshot,
      partOfStroke: partOfStroke,
      updateSavedSnapshot: updateSavedSnapshot,
    );
    final nextPlacedSelectionId = _resolvePlacedElementSelectionAfterMutation(
      currentSelectionId: state.selectedPlacedElementInstanceId,
      nextMap: mutation.activeMap,
      nextActiveLayerId: mutation.activeLayerId,
    );
    final nextMapEventSelectionId = _resolveMapEventSelectionAfterMutation(
      currentSelectionId: state.selectedMapEventId,
      preferredSelectionId: preferredSelectedMapEventId,
      nextMap: mutation.activeMap,
    );
    final nextNpcWaypointPlacementEntityId =
        _resolveNpcWaypointPlacementAfterMutation(
      nextMap: mutation.activeMap,
      currentPlacementEntityId: state.npcWaypointPlacementEntityId,
    );
    return state.copyWith(
      activeMap: mutation.activeMap,
      activeLayerId: mutation.activeLayerId,
      selectedEntityId: mutation.selectedEntityId,
      npcWaypointPlacementEntityId: nextNpcWaypointPlacementEntityId,
      selectedMapEventId: nextMapEventSelectionId,
      selectedWarpId: mutation.selectedWarpId,
      selectedTriggerId: mutation.selectedTriggerId,
      selectedPlacedElementInstanceId: nextPlacedSelectionId,
      selectedTilesetEditorId: mutation.selectedTilesetEditorId,
      hoveredTile: updateHoveredTile ? hoveredTile : state.hoveredTile,
      mapUndoStack: mutation.undoStack,
      mapRedoStack: mutation.redoStack,
      mapStrokeStart: mutation.strokeStart,
      savedMapSnapshot: mutation.savedMapSnapshot,
      canUndoMap: mutation.canUndoMap,
      canRedoMap: mutation.canRedoMap,
      isDirty: mutation.isDirty,
      statusMessage: statusMessage ?? state.statusMessage,
      errorMessage: null,
    );
  }

  String? _resolveNpcWaypointPlacementAfterMutation({
    required MapData nextMap,
    required String? currentPlacementEntityId,
  }) {
    final normalized = currentPlacementEntityId?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    for (final entity in nextMap.entities) {
      if (entity.id != normalized || entity.kind != MapEntityKind.npc) {
        continue;
      }
      final movement =
          entity.npc?.movement ?? const MapEntityNpcMovementConfig();
      if (movement.mode == MapEntityNpcMovementMode.patrol) {
        return normalized;
      }
      return null;
    }
    return null;
  }

  String? _resolvePlacedElementSelectionAfterMutation({
    required String? currentSelectionId,
    required MapData nextMap,
    required String? nextActiveLayerId,
  }) {
    final normalizedSelection = currentSelectionId?.trim();
    if (normalizedSelection == null || normalizedSelection.isEmpty) {
      return null;
    }
    if (nextActiveLayerId == null || nextActiveLayerId.isEmpty) {
      return null;
    }
    for (final instance in nextMap.placedElements) {
      if (instance.id != normalizedSelection) {
        continue;
      }
      if (instance.layerId != nextActiveLayerId) {
        return null;
      }
      return normalizedSelection;
    }
    return null;
  }

  String? _resolveMapEventSelectionAfterMutation({
    required String? currentSelectionId,
    required String? preferredSelectionId,
    required MapData nextMap,
  }) {
    final preferred = preferredSelectionId?.trim();
    if (preferred != null && preferred.isNotEmpty) {
      for (final event in nextMap.events) {
        if (event.id == preferred) {
          return preferred;
        }
      }
      return null;
    }
    final current = currentSelectionId?.trim();
    if (current == null || current.isEmpty) {
      return null;
    }
    for (final event in nextMap.events) {
      if (event.id == current) {
        return current;
      }
    }
    return null;
  }
}
