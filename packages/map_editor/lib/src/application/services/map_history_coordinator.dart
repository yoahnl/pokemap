import 'package:map_core/map_core.dart';

import '../models/map_history_snapshot.dart';

class MapHistoryMutationResult {
  const MapHistoryMutationResult({
    required this.undoStack,
    required this.redoStack,
    required this.strokeStart,
  });

  final List<MapHistorySnapshot> undoStack;
  final List<MapHistorySnapshot> redoStack;
  final MapHistorySnapshot? strokeStart;

  bool get canUndoMap => undoStack.isNotEmpty;
  bool get canRedoMap => redoStack.isNotEmpty;
}

class MapHistoryStrokeFinalizeResult extends MapHistoryMutationResult {
  const MapHistoryStrokeFinalizeResult({
    required super.undoStack,
    required super.redoStack,
    required super.strokeStart,
    required this.committed,
  });

  final bool committed;
}

class MapHistoryRestoreResult extends MapHistoryMutationResult {
  const MapHistoryRestoreResult({
    required super.undoStack,
    required super.redoStack,
    required super.strokeStart,
    required this.restoredSnapshot,
  });

  final MapHistorySnapshot restoredSnapshot;
}

class MapHistoryCoordinator {
  const MapHistoryCoordinator({
    this.maxEntries = 100,
  });

  final int maxEntries;

  MapHistoryMutationResult beginStroke({
    required MapData map,
    required String? activeLayerId,
    required String? selectedWarpId,
    required String? selectedTriggerId,
    required List<MapHistorySnapshot> undoStack,
    required List<MapHistorySnapshot> redoStack,
    required MapHistorySnapshot? strokeStart,
  }) {
    if (strokeStart != null) {
      return MapHistoryMutationResult(
        undoStack: undoStack,
        redoStack: redoStack,
        strokeStart: strokeStart,
      );
    }
    return MapHistoryMutationResult(
      undoStack: undoStack,
      redoStack: redoStack,
      strokeStart: MapHistorySnapshot(
        map: map,
        activeLayerId: activeLayerId,
        selectedWarpId: selectedWarpId,
        selectedTriggerId: selectedTriggerId,
      ),
    );
  }

  MapHistoryStrokeFinalizeResult finalizeStroke({
    required MapData? currentMap,
    required List<MapHistorySnapshot> undoStack,
    required List<MapHistorySnapshot> redoStack,
    required MapHistorySnapshot? strokeStart,
  }) {
    if (strokeStart == null) {
      return MapHistoryStrokeFinalizeResult(
        undoStack: undoStack,
        redoStack: redoStack,
        strokeStart: null,
        committed: false,
      );
    }
    if (currentMap == null || currentMap == strokeStart.map) {
      return MapHistoryStrokeFinalizeResult(
        undoStack: undoStack,
        redoStack: redoStack,
        strokeStart: null,
        committed: false,
      );
    }
    final nextUndo = pushSnapshot(undoStack, strokeStart);
    return MapHistoryStrokeFinalizeResult(
      undoStack: nextUndo,
      redoStack: const [],
      strokeStart: null,
      committed: true,
    );
  }

  MapHistoryMutationResult applyMutation({
    required MapData previousMap,
    required String? activeLayerId,
    required String? selectedWarpId,
    required String? selectedTriggerId,
    required List<MapHistorySnapshot> undoStack,
    required List<MapHistorySnapshot> redoStack,
    required MapHistorySnapshot? strokeStart,
    required bool partOfStroke,
  }) {
    if (partOfStroke) {
      return MapHistoryMutationResult(
        undoStack: undoStack,
        redoStack: redoStack,
        strokeStart: strokeStart ??
            MapHistorySnapshot(
              map: previousMap,
              activeLayerId: activeLayerId,
              selectedWarpId: selectedWarpId,
              selectedTriggerId: selectedTriggerId,
            ),
      );
    }
    final nextUndo = pushSnapshot(
      undoStack,
      MapHistorySnapshot(
        map: previousMap,
        activeLayerId: activeLayerId,
        selectedWarpId: selectedWarpId,
        selectedTriggerId: selectedTriggerId,
      ),
    );
    return MapHistoryMutationResult(
      undoStack: nextUndo,
      redoStack: const [],
      strokeStart: null,
    );
  }

  MapHistoryRestoreResult? undo({
    required MapData currentMap,
    required String? activeLayerId,
    required String? selectedWarpId,
    required String? selectedTriggerId,
    required List<MapHistorySnapshot> undoStack,
    required List<MapHistorySnapshot> redoStack,
  }) {
    if (undoStack.isEmpty) return null;
    final nextUndo = List<MapHistorySnapshot>.from(undoStack);
    final restoredSnapshot = nextUndo.removeLast();
    final nextRedo = pushSnapshot(
      redoStack,
      MapHistorySnapshot(
        map: currentMap,
        activeLayerId: activeLayerId,
        selectedWarpId: selectedWarpId,
        selectedTriggerId: selectedTriggerId,
      ),
    );
    return MapHistoryRestoreResult(
      undoStack: List<MapHistorySnapshot>.unmodifiable(nextUndo),
      redoStack: nextRedo,
      strokeStart: null,
      restoredSnapshot: restoredSnapshot,
    );
  }

  MapHistoryRestoreResult? redo({
    required MapData currentMap,
    required String? activeLayerId,
    required String? selectedWarpId,
    required String? selectedTriggerId,
    required List<MapHistorySnapshot> undoStack,
    required List<MapHistorySnapshot> redoStack,
  }) {
    if (redoStack.isEmpty) return null;
    final nextRedo = List<MapHistorySnapshot>.from(redoStack);
    final restoredSnapshot = nextRedo.removeLast();
    final nextUndo = pushSnapshot(
      undoStack,
      MapHistorySnapshot(
        map: currentMap,
        activeLayerId: activeLayerId,
        selectedWarpId: selectedWarpId,
        selectedTriggerId: selectedTriggerId,
      ),
    );
    return MapHistoryRestoreResult(
      undoStack: nextUndo,
      redoStack: List<MapHistorySnapshot>.unmodifiable(nextRedo),
      strokeStart: null,
      restoredSnapshot: restoredSnapshot,
    );
  }

  List<MapHistorySnapshot> pushSnapshot(
    List<MapHistorySnapshot> source,
    MapHistorySnapshot snapshot,
  ) {
    if (source.isNotEmpty) {
      final last = source.last;
      if (last.map == snapshot.map &&
          last.activeLayerId == snapshot.activeLayerId &&
          last.selectedWarpId == snapshot.selectedWarpId &&
          last.selectedTriggerId == snapshot.selectedTriggerId) {
        return source;
      }
    }
    final next = List<MapHistorySnapshot>.from(source)..add(snapshot);
    if (next.length > maxEntries) {
      next.removeRange(0, next.length - maxEntries);
    }
    return List<MapHistorySnapshot>.unmodifiable(next);
  }
}
