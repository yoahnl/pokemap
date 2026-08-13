import 'package:map_core/map_core.dart';

import '../models/map_history_delta.dart';
import '../models/map_history_entry.dart';
import '../models/map_history_snapshot.dart';

const int kMapHistoryMaxEntries = 100;
const int kMapHistoryMaxRetainedBytes = 16 * 1024 * 1024;
const int kMapHistoryCheckpointInterval = 25;

class MapHistoryMutationResult {
  const MapHistoryMutationResult({
    required this.undoStack,
    required this.redoStack,
    required this.strokeStart,
  });

  final List<MapHistoryEntry> undoStack;
  final List<MapHistoryEntry> redoStack;
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
    this.maxEntries = kMapHistoryMaxEntries,
    this.maxRetainedBytes = kMapHistoryMaxRetainedBytes,
    this.checkpointInterval = kMapHistoryCheckpointInterval,
  }) : assert(maxEntries >= 0),
       assert(maxRetainedBytes >= 0),
       assert(checkpointInterval >= 0);

  final int maxEntries;
  final int maxRetainedBytes;
  final int checkpointInterval;

  static final Expando<int> _retainedBytesByStack = Expando<int>();

  MapHistoryMutationResult beginStroke({
    required MapData map,
    required String? activeLayerId,
    required String? selectedEntityId,
    required String? selectedWarpId,
    required String? selectedTriggerId,
    required String? selectedMapEventId,
    required String? selectedGameplayZoneId,
    required String? selectedPlacedElementInstanceId,
    required String? npcWaypointPlacementEntityId,
    required List<MapHistoryEntry> undoStack,
    required List<MapHistoryEntry> redoStack,
    required MapHistorySnapshot? strokeStart,
    required bool currentDirty,
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
        selectedEntityId: selectedEntityId,
        selectedWarpId: selectedWarpId,
        selectedTriggerId: selectedTriggerId,
        selectedMapEventId: selectedMapEventId,
        selectedGameplayZoneId: selectedGameplayZoneId,
        selectedPlacedElementInstanceId: selectedPlacedElementInstanceId,
        npcWaypointPlacementEntityId: npcWaypointPlacementEntityId,
        wasDirty: currentDirty,
      ),
    );
  }

  MapHistoryStrokeFinalizeResult finalizeStroke({
    required MapData? currentMap,
    required List<MapHistoryEntry> undoStack,
    required List<MapHistoryEntry> redoStack,
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
    final recorded = recordMutation(
      before: strokeStart.map,
      after: currentMap,
      selectionBefore: MapHistorySelection(
        activeLayerId: strokeStart.activeLayerId,
        selectedEntityId: strokeStart.selectedEntityId,
        selectedWarpId: strokeStart.selectedWarpId,
        selectedTriggerId: strokeStart.selectedTriggerId,
      ),
      undoStack: undoStack,
      redoStack: redoStack,
    );
    return MapHistoryStrokeFinalizeResult(
      undoStack: recorded.undoStack,
      redoStack: recorded.redoStack,
      strokeStart: null,
      committed: true,
    );
  }

  MapHistoryRestoreResult? rollbackStroke({
    required List<MapHistoryEntry> undoStack,
    required List<MapHistoryEntry> redoStack,
    required MapHistorySnapshot? strokeStart,
  }) {
    if (strokeStart == null) return null;
    return MapHistoryRestoreResult(
      undoStack: undoStack,
      redoStack: redoStack,
      strokeStart: null,
      restoredSnapshot: strokeStart,
    );
  }

  MapHistoryMutationResult applyMutation({
    required MapData previousMap,
    required MapData updatedMap,
    required String? activeLayerId,
    required String? selectedEntityId,
    required String? selectedWarpId,
    required String? selectedTriggerId,
    required List<MapHistoryEntry> undoStack,
    required List<MapHistoryEntry> redoStack,
    required MapHistorySnapshot? strokeStart,
    required bool partOfStroke,
  }) {
    if (partOfStroke) {
      if (strokeStart == null) {
        throw StateError(
          'partOfStroke mutations require a complete stroke checkpoint',
        );
      }
      return MapHistoryMutationResult(
        undoStack: undoStack,
        redoStack: redoStack,
        strokeStart: strokeStart,
      );
    }
    return recordMutation(
      before: previousMap,
      after: updatedMap,
      selectionBefore: MapHistorySelection(
        activeLayerId: activeLayerId,
        selectedEntityId: selectedEntityId,
        selectedWarpId: selectedWarpId,
        selectedTriggerId: selectedTriggerId,
      ),
      undoStack: undoStack,
      redoStack: redoStack,
    );
  }

  MapHistoryMutationResult recordMutation({
    required MapData before,
    required MapData after,
    required MapHistorySelection selectionBefore,
    required List<MapHistoryEntry> undoStack,
    required List<MapHistoryEntry> redoStack,
  }) {
    final delta = MapHistoryDelta.between(before, after);
    if (delta.isEmpty) {
      return MapHistoryMutationResult(
        undoStack: undoStack,
        redoStack: redoStack,
        strokeStart: null,
      );
    }
    final sequence = undoStack.isEmpty ? 1 : undoStack.last.sequence + 1;
    final checkpoint =
        checkpointInterval > 0 && sequence % checkpointInterval == 0
        ? MapHistoryCheckpoint.between(before, after)
        : null;
    var entry = MapHistoryDeltaEntry(
      delta: delta,
      direction: MapHistoryDirection.backward,
      targetSelection: selectionBefore,
      sequence: sequence,
      checkpoint: checkpoint,
    );
    if (checkpoint != null && entry.retainedBytes > maxRetainedBytes) {
      entry = MapHistoryDeltaEntry(
        delta: delta,
        direction: MapHistoryDirection.backward,
        targetSelection: selectionBefore,
        sequence: sequence,
      );
    }
    return MapHistoryMutationResult(
      undoStack: pushEntry(undoStack, entry),
      redoStack: const <MapHistoryEntry>[],
      strokeStart: null,
    );
  }

  MapHistoryRestoreResult? undo({
    required MapData currentMap,
    MapHistorySelection? currentSelection,
    String? activeLayerId,
    String? selectedEntityId,
    String? selectedWarpId,
    String? selectedTriggerId,
    required List<MapHistoryEntry> undoStack,
    required List<MapHistoryEntry> redoStack,
  }) {
    if (undoStack.isEmpty) return null;
    final selection =
        currentSelection ??
        MapHistorySelection(
          activeLayerId: activeLayerId,
          selectedEntityId: selectedEntityId,
          selectedWarpId: selectedWarpId,
          selectedTriggerId: selectedTriggerId,
        );
    final nextUndo = List<MapHistoryEntry>.from(undoStack);
    final entry = nextUndo.removeLast();
    final restored = _restore(entry, currentMap);
    final reverse = _reverse(entry, currentMap, selection);
    return MapHistoryRestoreResult(
      undoStack: List<MapHistoryEntry>.unmodifiable(nextUndo),
      redoStack: pushEntry(redoStack, reverse),
      strokeStart: null,
      restoredSnapshot: restored,
    );
  }

  MapHistoryRestoreResult? redo({
    required MapData currentMap,
    MapHistorySelection? currentSelection,
    String? activeLayerId,
    String? selectedEntityId,
    String? selectedWarpId,
    String? selectedTriggerId,
    required List<MapHistoryEntry> undoStack,
    required List<MapHistoryEntry> redoStack,
  }) {
    if (redoStack.isEmpty) return null;
    final selection =
        currentSelection ??
        MapHistorySelection(
          activeLayerId: activeLayerId,
          selectedEntityId: selectedEntityId,
          selectedWarpId: selectedWarpId,
          selectedTriggerId: selectedTriggerId,
        );
    final nextRedo = List<MapHistoryEntry>.from(redoStack);
    final entry = nextRedo.removeLast();
    final restored = _restore(entry, currentMap);
    final reverse = _reverse(entry, currentMap, selection);
    return MapHistoryRestoreResult(
      undoStack: pushEntry(undoStack, reverse),
      redoStack: List<MapHistoryEntry>.unmodifiable(nextRedo),
      strokeStart: null,
      restoredSnapshot: restored,
    );
  }

  int retainedBytes(Iterable<MapHistoryEntry> entries) {
    if (entries case final List<MapHistoryEntry> list) {
      final cached = _retainedBytesByStack[list];
      if (cached != null) return cached;
    }
    final bytes = entries.fold<int>(
      0,
      (total, entry) => total + entry.retainedBytes,
    );
    return bytes;
  }

  List<MapHistoryEntry> pushEntry(
    List<MapHistoryEntry> source,
    MapHistoryEntry entry,
  ) {
    if (maxEntries == 0 || entry.retainedBytes > maxRetainedBytes) {
      return const <MapHistoryEntry>[];
    }
    final next = List<MapHistoryEntry>.from(source)..add(entry);
    var bytes = retainedBytes(source) + entry.retainedBytes;
    var removeCount = 0;
    while (next.length - removeCount > maxEntries || bytes > maxRetainedBytes) {
      bytes -= next[removeCount].retainedBytes;
      removeCount++;
    }
    final bounded = List<MapHistoryEntry>.unmodifiable(
      removeCount == 0 ? next : next.sublist(removeCount),
    );
    _retainedBytesByStack[bounded] = bytes;
    return bounded;
  }

  MapHistorySnapshot _restore(MapHistoryEntry entry, MapData currentMap) {
    if (entry is MapHistorySnapshot) return entry;
    final delta = entry as MapHistoryDeltaEntry;
    return MapHistorySnapshot(
      map: delta.restore(currentMap),
      activeLayerId: delta.activeLayerId,
      selectedEntityId: delta.selectedEntityId,
      selectedWarpId: delta.selectedWarpId,
      selectedTriggerId: delta.selectedTriggerId,
    );
  }

  MapHistoryEntry _reverse(
    MapHistoryEntry entry,
    MapData currentMap,
    MapHistorySelection currentSelection,
  ) {
    if (entry is MapHistoryDeltaEntry) {
      return entry.reversed(currentSelection);
    }
    return MapHistorySnapshot(
      map: currentMap,
      activeLayerId: currentSelection.activeLayerId,
      selectedEntityId: currentSelection.selectedEntityId,
      selectedWarpId: currentSelection.selectedWarpId,
      selectedTriggerId: currentSelection.selectedTriggerId,
    );
  }
}
