import 'package:map_core/map_core.dart';

import '../models/map_history_snapshot.dart';
import 'editor_map_session_coordinator.dart';
import 'map_history_coordinator.dart';

class EditorMapHistoryState {
  const EditorMapHistoryState({
    required this.undoStack,
    required this.redoStack,
    required this.strokeStart,
    required this.canUndoMap,
    required this.canRedoMap,
    required this.isDirty,
  });

  final List<MapHistorySnapshot> undoStack;
  final List<MapHistorySnapshot> redoStack;
  final MapHistorySnapshot? strokeStart;
  final bool canUndoMap;
  final bool canRedoMap;
  final bool isDirty;
}

class EditorMapMutationState extends EditorMapHistoryState {
  const EditorMapMutationState({
    required this.activeMap,
    required this.activeLayerId,
    required this.selectedWarpId,
    required this.selectedTilesetEditorId,
    required this.savedMapSnapshot,
    required super.undoStack,
    required super.redoStack,
    required super.strokeStart,
    required super.canUndoMap,
    required super.canRedoMap,
    required super.isDirty,
  });

  final MapData activeMap;
  final String? activeLayerId;
  final String? selectedWarpId;
  final String? selectedTilesetEditorId;
  final MapData? savedMapSnapshot;
}

class EditorMapMutationCoordinator {
  const EditorMapMutationCoordinator({
    required MapHistoryCoordinator historyCoordinator,
    required EditorMapSessionCoordinator sessionCoordinator,
  })  : _historyCoordinator = historyCoordinator,
        _sessionCoordinator = sessionCoordinator;

  final MapHistoryCoordinator _historyCoordinator;
  final EditorMapSessionCoordinator _sessionCoordinator;

  EditorMapHistoryState beginStroke({
    required MapData map,
    required String? activeLayerId,
    required String? selectedWarpId,
    required List<MapHistorySnapshot> undoStack,
    required List<MapHistorySnapshot> redoStack,
    required MapHistorySnapshot? strokeStart,
    required bool currentDirty,
  }) {
    final history = _historyCoordinator.beginStroke(
      map: map,
      activeLayerId: activeLayerId,
      selectedWarpId: selectedWarpId,
      undoStack: undoStack,
      redoStack: redoStack,
      strokeStart: strokeStart,
    );
    return EditorMapHistoryState(
      undoStack: history.undoStack,
      redoStack: history.redoStack,
      strokeStart: history.strokeStart,
      canUndoMap: history.canUndoMap,
      canRedoMap: history.canRedoMap,
      isDirty: currentDirty,
    );
  }

  EditorMapHistoryState finalizeStroke({
    required MapData? currentMap,
    required List<MapHistorySnapshot> undoStack,
    required List<MapHistorySnapshot> redoStack,
    required MapHistorySnapshot? strokeStart,
    required MapData? savedMapSnapshot,
    required bool currentDirty,
  }) {
    final history = _historyCoordinator.finalizeStroke(
      currentMap: currentMap,
      undoStack: undoStack,
      redoStack: redoStack,
      strokeStart: strokeStart,
    );
    return EditorMapHistoryState(
      undoStack: history.undoStack,
      redoStack: history.redoStack,
      strokeStart: history.strokeStart,
      canUndoMap: history.canUndoMap,
      canRedoMap: history.canRedoMap,
      isDirty: history.committed
          ? (savedMapSnapshot == null ? true : currentMap != savedMapSnapshot)
          : currentDirty,
    );
  }

  EditorMapMutationState applyMutation({
    required MapData previousMap,
    required MapData updatedMap,
    required String? activeLayerId,
    required String? selectedWarpId,
    required String? selectedTilesetEditorId,
    required List<MapHistorySnapshot> undoStack,
    required List<MapHistorySnapshot> redoStack,
    required MapHistorySnapshot? strokeStart,
    required String? preferredActiveLayerId,
    required String? preferredSelectedWarpId,
    required MapData? savedMapSnapshot,
    required bool partOfStroke,
    required bool updateSavedSnapshot,
  }) {
    final history = _historyCoordinator.applyMutation(
      previousMap: previousMap,
      activeLayerId: activeLayerId,
      selectedWarpId: selectedWarpId,
      undoStack: undoStack,
      redoStack: redoStack,
      strokeStart: strokeStart,
      partOfStroke: partOfStroke,
    );
    final session = _sessionCoordinator.resolveSelectionForMap(
      updatedMap,
      preferredLayerId: preferredActiveLayerId,
      preferredWarpId: preferredSelectedWarpId ?? selectedWarpId,
      currentSelectedTilesetEditorId: selectedTilesetEditorId,
    );
    final nextSavedSnapshot =
        updateSavedSnapshot ? updatedMap : savedMapSnapshot;
    return EditorMapMutationState(
      activeMap: updatedMap,
      activeLayerId: session.activeLayerId,
      selectedWarpId: session.selectedWarpId,
      selectedTilesetEditorId: session.selectedTilesetEditorId,
      savedMapSnapshot: nextSavedSnapshot,
      undoStack: history.undoStack,
      redoStack: history.redoStack,
      strokeStart: history.strokeStart,
      canUndoMap: history.canUndoMap,
      canRedoMap: history.canRedoMap,
      isDirty:
          nextSavedSnapshot == null ? true : updatedMap != nextSavedSnapshot,
    );
  }

  EditorMapMutationState? undo({
    required MapData currentMap,
    required String? activeLayerId,
    required String? selectedWarpId,
    required List<MapHistorySnapshot> undoStack,
    required List<MapHistorySnapshot> redoStack,
    required MapData? savedMapSnapshot,
  }) {
    final history = _historyCoordinator.undo(
      currentMap: currentMap,
      activeLayerId: activeLayerId,
      selectedWarpId: selectedWarpId,
      undoStack: undoStack,
      redoStack: redoStack,
    );
    if (history == null) return null;
    final restoredMap = history.restoredSnapshot.map;
    final session = _sessionCoordinator.resolveSelectionForMap(
      restoredMap,
      preferredLayerId: history.restoredSnapshot.activeLayerId,
      preferredWarpId: history.restoredSnapshot.selectedWarpId,
      currentSelectedTilesetEditorId: null,
    );
    return EditorMapMutationState(
      activeMap: restoredMap,
      activeLayerId: session.activeLayerId,
      selectedWarpId: session.selectedWarpId,
      selectedTilesetEditorId: session.selectedTilesetEditorId,
      savedMapSnapshot: savedMapSnapshot,
      undoStack: history.undoStack,
      redoStack: history.redoStack,
      strokeStart: history.strokeStart,
      canUndoMap: history.canUndoMap,
      canRedoMap: history.canRedoMap,
      isDirty:
          savedMapSnapshot == null ? true : restoredMap != savedMapSnapshot,
    );
  }

  EditorMapMutationState? redo({
    required MapData currentMap,
    required String? activeLayerId,
    required String? selectedWarpId,
    required List<MapHistorySnapshot> undoStack,
    required List<MapHistorySnapshot> redoStack,
    required MapData? savedMapSnapshot,
  }) {
    final history = _historyCoordinator.redo(
      currentMap: currentMap,
      activeLayerId: activeLayerId,
      selectedWarpId: selectedWarpId,
      undoStack: undoStack,
      redoStack: redoStack,
    );
    if (history == null) return null;
    final restoredMap = history.restoredSnapshot.map;
    final session = _sessionCoordinator.resolveSelectionForMap(
      restoredMap,
      preferredLayerId: history.restoredSnapshot.activeLayerId,
      preferredWarpId: history.restoredSnapshot.selectedWarpId,
      currentSelectedTilesetEditorId: null,
    );
    return EditorMapMutationState(
      activeMap: restoredMap,
      activeLayerId: session.activeLayerId,
      selectedWarpId: session.selectedWarpId,
      selectedTilesetEditorId: session.selectedTilesetEditorId,
      savedMapSnapshot: savedMapSnapshot,
      undoStack: history.undoStack,
      redoStack: history.redoStack,
      strokeStart: history.strokeStart,
      canUndoMap: history.canUndoMap,
      canRedoMap: history.canRedoMap,
      isDirty:
          savedMapSnapshot == null ? true : restoredMap != savedMapSnapshot,
    );
  }
}
