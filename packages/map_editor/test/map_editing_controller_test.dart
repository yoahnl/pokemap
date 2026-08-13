import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/map_history_snapshot.dart';
import 'package:map_editor/src/application/services/editor_map_mutation_coordinator.dart';
import 'package:map_editor/src/application/services/editor_map_session_coordinator.dart';
import 'package:map_editor/src/application/services/map_history_coordinator.dart';
import 'package:map_editor/src/features/editor/application/map_editing_controller.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  group('MapHistoryCoordinator stroke invariant', () {
    test('rejects an orphan partOfStroke mutation', () {
      const map = MapData(
        id: 'map_1',
        name: 'Map 1',
        size: GridSize(width: 1, height: 1),
      );

      expect(
        () => const MapHistoryCoordinator().applyMutation(
          previousMap: map,
          updatedMap: map,
          activeLayerId: null,
          selectedEntityId: null,
          selectedWarpId: null,
          selectedTriggerId: null,
          undoStack: const <MapHistorySnapshot>[],
          redoStack: const <MapHistorySnapshot>[],
          strokeStart: null,
          partOfStroke: true,
        ),
        throwsStateError,
      );
    });
  });

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
          TileLayer(id: 'ground', name: 'Ground', cells: [0]),
        ],
      );
      const updatedMap = MapData(
        id: 'map_1',
        name: 'Map 1',
        size: GridSize(width: 4, height: 4),
        layers: [
          TileLayer(id: 'ground', name: 'Ground', cells: [1]),
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
          TileLayer(id: 'ground', name: 'Ground', cells: [0]),
        ],
      );
      const updatedMap = MapData(
        id: 'map_1',
        name: 'Map 1',
        size: GridSize(width: 4, height: 4),
        layers: [
          TileLayer(id: 'ground', name: 'Ground', cells: [1]),
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

    test('map history never overwrites the independent Tileset Studio source',
        () {
      const previousMap = MapData(
        id: 'map_1',
        name: 'Map 1',
        size: GridSize(width: 1, height: 1),
        layers: [
          TileLayer(
            id: 'ground',
            name: 'Ground',
            cells: [0],
          ),
        ],
      );
      const updatedMap = MapData(
        id: 'map_1',
        name: 'Map 1',
        size: GridSize(width: 1, height: 1),
        layers: [
          TileLayer(
            id: 'ground',
            name: 'Ground',
            cells: [1],
          ),
        ],
      );
      const current = EditorState(
        activeMap: previousMap,
        activeLayerId: 'ground',
        selectedTilesetEditorId: 'studio_tiles',
      );

      final mutated = controller.applyMutation(
        current: current,
        previousMap: previousMap,
        updatedMap: updatedMap,
        preferredActiveLayerId: 'ground',
      );
      final undone = controller.undo(mutated)!;
      final redone = controller.redo(undone)!;

      expect(mutated.selectedTilesetEditorId, 'studio_tiles');
      expect(undone.selectedTilesetEditorId, 'studio_tiles');
      expect(redone.selectedTilesetEditorId, 'studio_tiles');
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

    test('cancelStroke restores the checkpoint without touching history', () {
      const original = MapData(
        id: 'map_1',
        name: 'Map 1',
        size: GridSize(width: 2, height: 1),
        layers: [
          TileLayer(id: 'ground', name: 'Ground', cells: [0, 0]),
        ],
      );
      const firstSample = MapData(
        id: 'map_1',
        name: 'Map 1',
        size: GridSize(width: 2, height: 1),
        layers: [
          TileLayer(id: 'ground', name: 'Ground', cells: [1, 0]),
        ],
      );
      const secondSample = MapData(
        id: 'map_1',
        name: 'Map 1',
        size: GridSize(width: 2, height: 1),
        layers: [
          TileLayer(id: 'ground', name: 'Ground', cells: [1, 1]),
        ],
      );
      const historical = MapHistorySnapshot(
        map: original,
        activeLayerId: 'ground',
      );
      final started = controller.beginStroke(
        const EditorState(
          activeMap: original,
          activeLayerId: 'ground',
          savedMapSnapshot: original,
          mapUndoStack: [historical],
          canUndoMap: true,
        ),
      );
      final first = controller.applyMutation(
        current: started,
        previousMap: original,
        updatedMap: firstSample,
        preferredActiveLayerId: 'ground',
        partOfStroke: true,
      );
      final second = controller.applyMutation(
        current: first,
        previousMap: firstSample,
        updatedMap: secondSample,
        preferredActiveLayerId: 'ground',
        partOfStroke: true,
      );

      final cancelled = controller.cancelStroke(second);

      expect(cancelled.activeMap, original);
      expect(cancelled.activeLayerId, 'ground');
      expect(cancelled.mapStrokeStart, isNull);
      expect(cancelled.mapUndoStack, [historical]);
      expect(cancelled.mapRedoStack, isEmpty);
      expect(cancelled.canUndoMap, isTrue);
      expect(cancelled.canRedoMap, isFalse);
      expect(cancelled.isDirty, isFalse);
    });

    test(
      'cancelStroke restores pre-stroke dirty and placed-element selection',
      () {
        const original = MapData(
          id: 'map_1',
          name: 'Map 1',
          size: GridSize(width: 1, height: 1),
          layers: [
            TileLayer(id: 'ground', name: 'Ground', cells: [1]),
          ],
          placedElements: [
            MapPlacedElement(
              id: 'tree',
              layerId: 'ground',
              elementId: 'tree_element',
              pos: GridPos(x: 0, y: 0),
            ),
          ],
        );
        const erased = MapData(
          id: 'map_1',
          name: 'Map 1',
          size: GridSize(width: 1, height: 1),
          layers: [
            TileLayer(id: 'ground', name: 'Ground', cells: [0]),
          ],
        );
        final started = controller.beginStroke(
          const EditorState(
            activeMap: original,
            activeLayerId: 'ground',
            selectedPlacedElementInstanceId: 'tree',
            isDirty: false,
          ),
        );
        final mutated = controller.applyMutation(
          current: started,
          previousMap: original,
          updatedMap: erased,
          preferredActiveLayerId: 'ground',
          partOfStroke: true,
        );

        expect(mutated.selectedPlacedElementInstanceId, isNull);
        expect(mutated.isDirty, isTrue);

        final cancelled = controller.cancelStroke(mutated);

        expect(cancelled.activeMap, original);
        expect(cancelled.selectedPlacedElementInstanceId, 'tree');
        expect(cancelled.isDirty, isFalse);
      },
    );

    test('partOfStroke auto-captures a complete rollback checkpoint', () {
      const original = MapData(
        id: 'map_1',
        name: 'Map 1',
        size: GridSize(width: 2, height: 1),
        layers: [
          TileLayer(id: 'ground', name: 'Ground', cells: [0, 0]),
        ],
        entities: [
          MapEntity(
            id: 'npc',
            name: 'NPC',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 0, y: 0),
          ),
        ],
        warps: [
          MapWarp(
            id: 'warp',
            pos: GridPos(x: 0, y: 0),
            targetMapId: 'map_1',
            targetPos: GridPos(x: 1, y: 0),
          ),
        ],
        triggers: [
          MapTrigger(
            id: 'trigger',
            name: 'Trigger',
            type: TriggerType.event,
            area: MapRect(
              pos: GridPos(x: 0, y: 0),
              size: GridSize(width: 1, height: 1),
            ),
          ),
        ],
      );
      final firstSample = original.copyWith(
        layers: const [
          TileLayer(id: 'ground', name: 'Ground', cells: [1, 0]),
        ],
      );
      const current = EditorState(
        activeMap: original,
        activeLayerId: 'ground',
        selectedEntityId: 'npc',
        npcWaypointPlacementEntityId: 'npc',
        selectedMapEventId: 'event',
        selectedWarpId: 'warp',
        selectedTriggerId: 'trigger',
        selectedGameplayZoneId: 'zone',
        selectedPlacedElementInstanceId: 'placement',
        isDirty: true,
      );

      // The controller is a public boundary and must fail safely even when an
      // older caller marks a sample as part of a stroke without beginning it.
      final mutated = controller.applyMutation(
        current: current,
        previousMap: original,
        updatedMap: firstSample,
        preferredActiveLayerId: 'ground',
        partOfStroke: true,
      );

      expect(mutated.mapStrokeStart, isNotNull);
      final cancelled = controller.cancelStroke(mutated);
      expect(cancelled.activeMap, original);
      expect(cancelled.activeLayerId, current.activeLayerId);
      expect(cancelled.selectedEntityId, current.selectedEntityId);
      expect(
        cancelled.npcWaypointPlacementEntityId,
        current.npcWaypointPlacementEntityId,
      );
      expect(cancelled.selectedMapEventId, current.selectedMapEventId);
      expect(cancelled.selectedWarpId, current.selectedWarpId);
      expect(cancelled.selectedTriggerId, current.selectedTriggerId);
      expect(
        cancelled.selectedGameplayZoneId,
        current.selectedGameplayZoneId,
      );
      expect(
        cancelled.selectedPlacedElementInstanceId,
        current.selectedPlacedElementInstanceId,
      );
      expect(cancelled.isDirty, isTrue);
    });

    test('a multi-sample stroke creates exactly one undo entry', () {
      const original = MapData(
        id: 'map_1',
        name: 'Map 1',
        size: GridSize(width: 2, height: 1),
        layers: [
          TileLayer(id: 'ground', name: 'Ground', cells: [0, 0]),
        ],
      );
      const firstSample = MapData(
        id: 'map_1',
        name: 'Map 1',
        size: GridSize(width: 2, height: 1),
        layers: [
          TileLayer(id: 'ground', name: 'Ground', cells: [1, 0]),
        ],
      );
      const secondSample = MapData(
        id: 'map_1',
        name: 'Map 1',
        size: GridSize(width: 2, height: 1),
        layers: [
          TileLayer(id: 'ground', name: 'Ground', cells: [1, 1]),
        ],
      );
      final started = controller.beginStroke(
        const EditorState(
          activeMap: original,
          activeLayerId: 'ground',
          savedMapSnapshot: original,
        ),
      );
      final first = controller.applyMutation(
        current: started,
        previousMap: original,
        updatedMap: firstSample,
        preferredActiveLayerId: 'ground',
        partOfStroke: true,
      );
      final second = controller.applyMutation(
        current: first,
        previousMap: firstSample,
        updatedMap: secondSample,
        preferredActiveLayerId: 'ground',
        partOfStroke: true,
      );

      final committed = controller.endStroke(second);
      final undone = controller.undo(committed);

      expect(committed.mapUndoStack, hasLength(1));
      expect(committed.canUndoMap, isTrue);
      expect(undone?.activeMap, original);
    });
  });
}
