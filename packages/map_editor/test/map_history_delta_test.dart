import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/map_history_delta.dart';
import 'package:map_editor/src/application/models/map_history_entry.dart';
import 'package:map_editor/src/application/services/map_history_coordinator.dart';

void main() {
  group('MapHistoryDelta', () {
    test('retains a sparse tile edit instead of two full map snapshots', () {
      final before = _tileMap(extent: 1024);
      final cells = List<int>.from((before.layers.single as TileLayer).cells);
      cells[812345] = 7;
      final after = before.copyWith(
        layers: <MapLayer>[
          (before.layers.single as TileLayer).copyWith(cells: cells),
        ],
      );

      final delta = MapHistoryDelta.between(before, after);

      expect(delta.changedValueCount, 1);
      expect(delta.retainedBytes, lessThan(1024));
      expect(delta.applyBackward(after), before);
      expect(delta.applyForward(before), after);
      expect(
        jsonEncode(delta.applyBackward(after).toJson()),
        jsonEncode(before.toJson()),
      );
    });

    test('keeps simultaneous tile palette and cell edits sparse', () {
      final before = _tileMap(extent: 1024);
      final layer = before.layers.single as TileLayer;
      final cells = List<int>.from(layer.cells)..[812345] = 1;
      final after = before.copyWith(
        layers: <MapLayer>[
          layer.copyWith(
            palette: const <TileLayerPaletteEntry>[
              TileLayerPaletteEntry(tilesetId: 'tileset', localTileId: 7),
            ],
            cells: cells,
          ),
        ],
      );

      final delta = MapHistoryDelta.between(before, after);

      expect(delta.changedValueCount, 2);
      expect(delta.retainedBytes, lessThan(4096));
      expect(delta.applyBackward(after), before);
      expect(delta.applyForward(before), after);
    });

    test('keeps simultaneous Smart Tile palette and field edits sparse', () {
      const extent = 256;
      final before = MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: extent, height: extent),
        layers: <MapLayer>[
          SmartTileLayer(
            id: 'smart',
            name: 'Smart',
            presetId: 'preset',
            usage: SmartTileUsage.terrain,
            field: SmartTileField.cell(
              semanticCells: List<int>.filled(extent * extent, 0),
            ),
          ),
        ],
      );
      final layer = before.layers.single as SmartTileLayer;
      final semanticCells = List<int>.from(
        (layer.field as SmartTileCellField).semanticCells,
      )..[12345] = 1;
      final after = before.copyWith(
        layers: <MapLayer>[
          layer.copyWith(
            materialPalette: const <String>['', 'grass'],
            field: SmartTileField.cell(semanticCells: semanticCells),
          ),
        ],
      );

      final delta = MapHistoryDelta.between(before, after);

      expect(delta.changedValueCount, 2);
      expect(delta.retainedBytes, lessThan(4096));
      expect(delta.applyBackward(after), before);
      expect(delta.applyForward(before), after);
    });

    test('patches collision and every Smart Tile lattice reversibly', () {
      const before = MapData(
        id: 'map',
        name: 'Map',
        size: GridSize(width: 2, height: 2),
        layers: <MapLayer>[
          CollisionLayer(
            id: 'collision',
            name: 'Collision',
            collisions: <bool>[false, false, false, false],
          ),
          SmartTileLayer(
            id: 'smart',
            name: 'Smart',
            presetId: 'preset',
            usage: SmartTileUsage.terrain,
            field: SmartTileField.mixed(
              semanticCells: <int>[0, 0, 0, 0],
              horizontalEdges: <int>[0, 0, 0, 0, 0, 0],
              verticalEdges: <int>[0, 0, 0, 0, 0, 0],
              corners: <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
            ),
          ),
        ],
      );
      const after = MapData(
        id: 'map',
        name: 'Map',
        size: GridSize(width: 2, height: 2),
        layers: <MapLayer>[
          CollisionLayer(
            id: 'collision',
            name: 'Collision',
            collisions: <bool>[false, true, false, false],
          ),
          SmartTileLayer(
            id: 'smart',
            name: 'Smart',
            presetId: 'preset',
            usage: SmartTileUsage.terrain,
            field: SmartTileField.mixed(
              semanticCells: <int>[0, 0, 2, 0],
              horizontalEdges: <int>[0, 3, 0, 0, 0, 0],
              verticalEdges: <int>[0, 0, 0, 4, 0, 0],
              corners: <int>[0, 0, 0, 0, 5, 0, 0, 0, 0],
            ),
          ),
        ],
      );

      final delta = MapHistoryDelta.between(before, after);

      expect(delta.changedValueCount, 5);
      expect(delta.applyBackward(after), before);
      expect(delta.applyForward(before), after);
    });

    test('retains only the changed member of a ten-thousand entity list', () {
      final before = _entityMap(10000);
      final entities = List<MapEntity>.from(before.entities);
      entities[5000] = entities[5000].copyWith(
        pos: const GridPos(x: 99, y: 77),
      );
      final after = before.copyWith(entities: entities);

      final delta = MapHistoryDelta.between(before, after);

      expect(delta.changedValueCount, 1);
      expect(delta.retainedBytes, lessThan(4096));
      expect(delta.applyBackward(after), before);
      expect(delta.applyForward(before), after);
    });

    test('composes sequential deltas and their inverses', () {
      final first = _tileMap(extent: 4);
      final secondCells = List<int>.from(
        (first.layers.single as TileLayer).cells,
      )..[2] = 3;
      final second = first.copyWith(
        layers: <MapLayer>[
          (first.layers.single as TileLayer).copyWith(cells: secondCells),
        ],
      );
      final thirdCells = List<int>.from(
        (second.layers.single as TileLayer).cells,
      )..[9] = 8;
      final third = second.copyWith(
        layers: <MapLayer>[
          (second.layers.single as TileLayer).copyWith(cells: thirdCells),
        ],
      );
      final firstDelta = MapHistoryDelta.between(first, second);
      final secondDelta = MapHistoryDelta.between(second, third);

      expect(secondDelta.applyForward(firstDelta.applyForward(first)), third);
      expect(firstDelta.applyBackward(secondDelta.applyBackward(third)), first);
    });
  });

  group('MapHistoryCoordinator bounded timeline', () {
    const selection = MapHistorySelection();

    test('keeps one thousand strokes inside the configured byte budget', () {
      const coordinator = MapHistoryCoordinator(
        maxEntries: 1000,
        maxRetainedBytes: 24 * 1024,
        checkpointInterval: 0,
      );
      var map = _tileMap(extent: 64);
      var undo = const <MapHistoryEntry>[];
      var redo = const <MapHistoryEntry>[];

      for (var index = 0; index < 1000; index++) {
        final cells = List<int>.from((map.layers.single as TileLayer).cells);
        cells[index % cells.length] = index + 1;
        final next = map.copyWith(
          layers: <MapLayer>[
            (map.layers.single as TileLayer).copyWith(cells: cells),
          ],
        );
        final result = coordinator.recordMutation(
          before: map,
          after: next,
          selectionBefore: selection,
          undoStack: undo,
          redoStack: redo,
        );
        map = next;
        undo = result.undoStack;
        redo = result.redoStack;
      }

      expect(coordinator.retainedBytes(undo), lessThanOrEqualTo(24 * 1024));
      expect(undo.length, lessThan(1000));
      expect(undo, everyElement(isA<MapHistoryDeltaEntry>()));
    });

    test('bounds ten thousand placed-element movements by bytes', () {
      const coordinator = MapHistoryCoordinator(
        maxEntries: 10000,
        maxRetainedBytes: 256 * 1024,
        checkpointInterval: 0,
      );
      var map = _placedElementMap(100);
      var undo = const <MapHistoryEntry>[];
      var redo = const <MapHistoryEntry>[];

      for (var operation = 0; operation < 10000; operation++) {
        final index = operation % map.placedElements.length;
        final instances = List<MapPlacedElement>.from(map.placedElements);
        final current = instances[index];
        instances[index] = current.copyWith(
          pos: GridPos(x: (operation + 1) % 128, y: (operation ~/ 128) % 128),
        );
        final next = map.copyWith(placedElements: instances);
        if (next == map) continue;
        final result = coordinator.recordMutation(
          before: map,
          after: next,
          selectionBefore: selection,
          undoStack: undo,
          redoStack: redo,
        );
        map = next;
        undo = result.undoStack;
        redo = result.redoStack;
      }

      expect(coordinator.retainedBytes(undo), lessThanOrEqualTo(256 * 1024));
      expect(undo.length, lessThan(10000));
      expect(undo, everyElement(isA<MapHistoryDeltaEntry>()));
    });

    test('alternating undo and redo preserves bit-for-bit MapData', () {
      const coordinator = MapHistoryCoordinator(
        maxEntries: 20,
        maxRetainedBytes: 64 * 1024,
        checkpointInterval: 0,
      );
      final before = _tileMap(extent: 8);
      final cells = List<int>.from((before.layers.single as TileLayer).cells)
        ..[17] = 9;
      final after = before.copyWith(
        layers: <MapLayer>[
          (before.layers.single as TileLayer).copyWith(cells: cells),
        ],
      );
      final recorded = coordinator.recordMutation(
        before: before,
        after: after,
        selectionBefore: selection,
        undoStack: const <MapHistoryEntry>[],
        redoStack: const <MapHistoryEntry>[],
      );
      var current = after;
      var undo = recorded.undoStack;
      var redo = recorded.redoStack;

      for (var index = 0; index < 100; index++) {
        final undone = coordinator.undo(
          currentMap: current,
          currentSelection: selection,
          undoStack: undo,
          redoStack: redo,
        )!;
        expect(
          jsonEncode(undone.restoredSnapshot.map.toJson()),
          jsonEncode(before.toJson()),
        );
        final redone = coordinator.redo(
          currentMap: undone.restoredSnapshot.map,
          currentSelection: selection,
          undoStack: undone.undoStack,
          redoStack: undone.redoStack,
        )!;
        expect(
          jsonEncode(redone.restoredSnapshot.map.toJson()),
          jsonEncode(after.toJson()),
        );
        current = redone.restoredSnapshot.map;
        undo = redone.undoStack;
        redo = redone.redoStack;
      }
    });

    test('periodic checkpoint recovers a diverged current layer', () {
      const coordinator = MapHistoryCoordinator(
        maxEntries: 20,
        maxRetainedBytes: 1024 * 1024,
        checkpointInterval: 1,
      );
      final before = _tileMap(extent: 8);
      final cells = List<int>.from((before.layers.single as TileLayer).cells)
        ..[17] = 9;
      final after = before.copyWith(
        layers: <MapLayer>[
          (before.layers.single as TileLayer).copyWith(cells: cells),
        ],
      );
      final recorded = coordinator.recordMutation(
        before: before,
        after: after,
        selectionBefore: selection,
        undoStack: const <MapHistoryEntry>[],
        redoStack: const <MapHistoryEntry>[],
      );
      final diverged = after.copyWith(
        layers: const <MapLayer>[
          TileLayer(id: 'ground', name: 'Ground', cells: <int>[1]),
        ],
      );

      final undone = coordinator.undo(
        currentMap: diverged,
        currentSelection: selection,
        undoStack: recorded.undoStack,
        redoStack: recorded.redoStack,
      );

      expect(undone!.restoredSnapshot.map, before);
      expect(recorded.undoStack.single, isA<MapHistoryDeltaEntry>());
      expect(
        (recorded.undoStack.single as MapHistoryDeltaEntry).checkpoint,
        isNotNull,
      );
    });

    test('fails closed on divergence when no checkpoint is available', () {
      const coordinator = MapHistoryCoordinator(
        maxEntries: 20,
        maxRetainedBytes: 1024 * 1024,
        checkpointInterval: 0,
      );
      final before = _tileMap(extent: 8);
      final cells = List<int>.from((before.layers.single as TileLayer).cells)
        ..[17] = 9;
      final after = before.copyWith(
        layers: <MapLayer>[
          (before.layers.single as TileLayer).copyWith(cells: cells),
        ],
      );
      final recorded = coordinator.recordMutation(
        before: before,
        after: after,
        selectionBefore: selection,
        undoStack: const <MapHistoryEntry>[],
        redoStack: const <MapHistoryEntry>[],
      );
      final diverged = after.copyWith(
        layers: const <MapLayer>[
          TileLayer(id: 'ground', name: 'Ground', cells: <int>[1]),
        ],
      );

      expect(
        () => coordinator.undo(
          currentMap: diverged,
          currentSelection: selection,
          undoStack: recorded.undoStack,
          redoStack: recorded.redoStack,
        ),
        throwsA(isA<MapHistoryDivergence>()),
      );
    });

    test('drops a command that cannot fit inside the byte budget', () {
      const coordinator = MapHistoryCoordinator(
        maxEntries: 20,
        maxRetainedBytes: 1,
        checkpointInterval: 0,
      );
      final before = _tileMap(extent: 8);
      final cells = List<int>.from((before.layers.single as TileLayer).cells)
        ..[17] = 9;
      final after = before.copyWith(
        layers: <MapLayer>[
          (before.layers.single as TileLayer).copyWith(cells: cells),
        ],
      );

      final recorded = coordinator.recordMutation(
        before: before,
        after: after,
        selectionBefore: selection,
        undoStack: const <MapHistoryEntry>[],
        redoStack: const <MapHistoryEntry>[],
      );

      expect(recorded.undoStack, isEmpty);
      expect(recorded.canUndoMap, isFalse);
    });

    test('charges retained layer metadata against the byte budget', () {
      const coordinator = MapHistoryCoordinator(
        maxEntries: 20,
        maxRetainedBytes: 4096,
        checkpointInterval: 0,
      );
      final suffix = List<String>.filled(128, 'x').join();
      final before = _tileMap(extent: 8);
      final layer = (before.layers.single as TileLayer).copyWith(
        palette: List<TileLayerPaletteEntry>.generate(
          128,
          (index) => TileLayerPaletteEntry(
            tilesetId: 'tileset-$index-$suffix',
            localTileId: index,
          ),
        ),
      );
      final mapWithPalette = before.copyWith(layers: <MapLayer>[layer]);
      final cells = List<int>.from(layer.cells)..[17] = 9;
      final after = mapWithPalette.copyWith(
        layers: <MapLayer>[layer.copyWith(cells: cells)],
      );

      final recorded = coordinator.recordMutation(
        before: mapWithPalette,
        after: after,
        selectionBefore: selection,
        undoStack: const <MapHistoryEntry>[],
        redoStack: const <MapHistoryEntry>[],
      );

      expect(recorded.undoStack, isEmpty);
      expect(recorded.canUndoMap, isFalse);
    });

    test('charges retained selection identifiers against the byte budget', () {
      const coordinator = MapHistoryCoordinator(
        maxEntries: 20,
        maxRetainedBytes: 4096,
        checkpointInterval: 0,
      );
      final before = _tileMap(extent: 8);
      final cells = List<int>.from((before.layers.single as TileLayer).cells)
        ..[17] = 9;
      final after = before.copyWith(
        layers: <MapLayer>[
          (before.layers.single as TileLayer).copyWith(cells: cells),
        ],
      );
      final retainedIdentifier = List<String>.filled(5000, 'x').join();

      final recorded = coordinator.recordMutation(
        before: before,
        after: after,
        selectionBefore: MapHistorySelection(activeLayerId: retainedIdentifier),
        undoStack: const <MapHistoryEntry>[],
        redoStack: const <MapHistoryEntry>[],
      );

      expect(recorded.undoStack, isEmpty);
      expect(recorded.canUndoMap, isFalse);
    });

    test('keeps the delta when its periodic checkpoint exceeds the budget', () {
      const coordinator = MapHistoryCoordinator(
        maxEntries: 20,
        maxRetainedBytes: 1024,
        checkpointInterval: 1,
      );
      final before = _tileMap(extent: 64);
      final cells = List<int>.from((before.layers.single as TileLayer).cells)
        ..[17] = 9;
      final after = before.copyWith(
        layers: <MapLayer>[
          (before.layers.single as TileLayer).copyWith(cells: cells),
        ],
      );

      final recorded = coordinator.recordMutation(
        before: before,
        after: after,
        selectionBefore: selection,
        undoStack: const <MapHistoryEntry>[],
        redoStack: const <MapHistoryEntry>[],
      );

      expect(recorded.undoStack, hasLength(1));
      expect(
        (recorded.undoStack.single as MapHistoryDeltaEntry).checkpoint,
        isNull,
      );
      expect(
        coordinator.retainedBytes(recorded.undoStack),
        lessThanOrEqualTo(1024),
      );
    });
  });
}

MapData _tileMap({required int extent}) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: GridSize(width: extent, height: extent),
    layers: <MapLayer>[
      TileLayer(
        id: 'ground',
        name: 'Ground',
        cells: List<int>.filled(extent * extent, 0),
      ),
    ],
  );
}

MapData _entityMap(int count) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 128, height: 128),
    entities: List<MapEntity>.generate(
      count,
      (index) => MapEntity(
        id: 'entity_$index',
        name: 'Entity $index',
        kind: MapEntityKind.custom,
        pos: GridPos(x: index % 128, y: index ~/ 128),
      ),
    ),
  );
}

MapData _placedElementMap(int count) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 128, height: 128),
    layers: const <MapLayer>[TileLayer(id: 'ground', name: 'Ground')],
    placedElements: List<MapPlacedElement>.generate(
      count,
      (index) => MapPlacedElement(
        id: 'instance_$index',
        layerId: 'ground',
        elementId: 'element_${index % 10}',
        pos: GridPos(x: index % 128, y: index ~/ 128),
      ),
    ),
  );
}
