import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/editor_map_mutation_coordinator.dart';
import 'package:map_editor/src/application/services/editor_map_session_coordinator.dart';
import 'package:map_editor/src/application/services/map_history_coordinator.dart';
import 'package:map_editor/src/features/editor/application/map_editing_controller.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  group('MapEditingController', () {
    const controller = MapEditingController(
      mutationCoordinator: EditorMapMutationCoordinator(
        historyCoordinator: MapHistoryCoordinator(maxEntries: 100),
        sessionCoordinator: EditorMapSessionCoordinator(),
      ),
    );

    test('applyMutation updates the active map and records undo history', () {
      const previousMap = MapData(
        id: 'map_1',
        name: 'Map 1',
        size: GridSize(width: 4, height: 4),
        layers: [
          TileLayer(id: 'ground', name: 'Ground', tiles: [0]),
        ],
      );
      const updatedMap = MapData(
        id: 'map_1',
        name: 'Map 1',
        size: GridSize(width: 4, height: 4),
        layers: [
          TileLayer(id: 'ground', name: 'Ground', tiles: [1]),
        ],
        events: [
          MapEventDefinition(
            id: 'event_1',
            pages: [
              MapEventPage(pageNumber: 0),
            ],
            position: EventPosition(
              layerId: 'ground',
              x: 1,
              y: 1,
            ),
          ),
        ],
      );
      const current = EditorState(
        activeMap: previousMap,
        activeLayerId: 'ground',
        selectedMapEventId: 'event_1',
      );

      final next = controller.applyMutation(
        current: current,
        previousMap: previousMap,
        updatedMap: updatedMap,
        preferredActiveLayerId: 'ground',
        preferredSelectedMapEventId: 'event_1',
        statusMessage: 'Updated',
      );

      expect(next.activeMap, updatedMap);
      expect(next.activeLayerId, 'ground');
      expect(next.selectedMapEventId, 'event_1');
      expect(next.mapUndoStack, isNotEmpty);
      expect(next.mapRedoStack, isEmpty);
      expect(next.isDirty, isTrue);
      expect(next.statusMessage, 'Updated');
      expect(next.errorMessage, isNull);
    });

    test('undo and redo restore document state around a mutation', () {
      const previousMap = MapData(
        id: 'map_1',
        name: 'Map 1',
        size: GridSize(width: 4, height: 4),
        layers: [
          TileLayer(id: 'ground', name: 'Ground', tiles: [0]),
        ],
      );
      const updatedMap = MapData(
        id: 'map_1',
        name: 'Map 1',
        size: GridSize(width: 4, height: 4),
        layers: [
          TileLayer(id: 'ground', name: 'Ground', tiles: [1]),
        ],
      );
      const current = EditorState(
        activeMap: previousMap,
        activeLayerId: 'ground',
      );

      final mutated = controller.applyMutation(
        current: current,
        previousMap: previousMap,
        updatedMap: updatedMap,
        preferredActiveLayerId: 'ground',
      );
      final undone = controller.undo(mutated);
      final redone = controller.redo(undone!);

      expect(undone.activeMap, previousMap);
      expect(undone.statusMessage, 'Undo');
      expect(redone!.activeMap, updatedMap);
      expect(redone.statusMessage, 'Redo');
    });

    test('endStroke clears the transient stroke marker', () {
      const map = MapData(
        id: 'map_1',
        name: 'Map 1',
        size: GridSize(width: 4, height: 4),
        layers: [],
      );
      final started = controller.beginStroke(
        const EditorState(
          activeMap: map,
          activeLayerId: 'ground',
        ),
      );

      final ended = controller.endStroke(started);

      expect(started.mapStrokeStart, isNotNull);
      expect(ended.mapStrokeStart, isNull);
    });
  });
}
