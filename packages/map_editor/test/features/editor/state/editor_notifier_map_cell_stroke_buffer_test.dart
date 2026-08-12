import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';

void main() {
  test(
    'tile stroke publishes one immutable map and one undo entry on release',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final source = MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 8, height: 8),
        layers: <MapLayer>[
          MapLayer.tile(
            id: 'ground',
            name: 'Ground',
            cells: List<int>.filled(64, 0, growable: false),
          ),
        ],
      );
      notifier.state = EditorState(
        activeMap: source,
        activeLayerId: 'ground',
        activeTool: EditorToolType.tilePaint,
        activeBrush: const EditorBrush.tile(tileId: 7, tilesetId: 'world'),
        savedMapSnapshot: source,
      );

      notifier.beginMapStroke();
      await notifier.paintSelectedBrushAt(
        const GridPos(x: 1, y: 2),
        tilesetColumnsById: const <String, int>{},
        partOfStroke: true,
      );
      await notifier.paintSelectedBrushAt(
        const GridPos(x: 5, y: 2),
        tilesetColumnsById: const <String, int>{},
        partOfStroke: true,
      );

      expect(notifier.state.activeMap, same(source));
      expect(notifier.state.mapUndoStack, isEmpty);
      final preview = notifier.activeMapCellStrokePreview!;
      expect(preview.fullLayerCopyCount, 0);
      expect(preview.mapMaterializationCount, 0);
      expect(preview.validationCount, 0);

      notifier.endMapStroke();

      expect(preview.fullLayerCopyCount, 1);
      expect(preview.mapMaterializationCount, 1);
      expect(preview.validationCount, 1);
      final committed = notifier.state.activeMap!;
      expect(committed, isNot(same(source)));
      expect(notifier.state.mapUndoStack, hasLength(1));
      expect(notifier.state.isDirty, isTrue);
      final layer = committed.layers.single as TileLayer;
      expect(resolveTileLayerCell(layer, 2 * 8 + 1), isNotNull);
      expect(resolveTileLayerCell(layer, 2 * 8 + 5), isNotNull);

      notifier.undoMap();
      expect(notifier.state.activeMap, source);
      notifier.redoMap();
      expect(notifier.state.activeMap, committed);
    },
  );

  test('collision stroke cancel discards its sparse preview', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    final source = MapData(
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 8, height: 8),
      layers: <MapLayer>[
        MapLayer.collision(
          id: 'collision',
          name: 'Collision',
          collisions: List<bool>.filled(64, false, growable: false),
        ),
      ],
    );
    notifier.state = EditorState(
      activeMap: source,
      activeLayerId: 'collision',
      activeTool: EditorToolType.collisionPaint,
      savedMapSnapshot: source,
    );

    notifier.beginMapStroke();
    notifier.paintCollisionAt(const GridPos(x: 2, y: 2));
    notifier.paintCollisionAt(const GridPos(x: 5, y: 2));

    expect(notifier.state.activeMap, same(source));
    expect(notifier.activeMapCellStrokePreview, isNotNull);
    expect(notifier.activeMapCellStrokePreview!.collisionAt(2 * 8 + 4), isTrue);

    notifier.cancelMapStroke();

    expect(notifier.activeMapCellStrokePreview, isNull);
    expect(notifier.state.activeMap, same(source));
    expect(notifier.state.mapUndoStack, isEmpty);
    expect(notifier.state.isDirty, isFalse);
  });

  test('collision stroke commits once and remains atomic through history', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    final source = MapData(
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 8, height: 8),
      layers: <MapLayer>[
        MapLayer.collision(
          id: 'collision',
          name: 'Collision',
          collisions: List<bool>.filled(64, false, growable: false),
        ),
      ],
    );
    notifier.state = EditorState(
      activeMap: source,
      activeLayerId: 'collision',
      activeTool: EditorToolType.collisionPaint,
      savedMapSnapshot: source,
    );

    notifier.beginMapStroke();
    notifier.paintCollisionAt(const GridPos(x: 1, y: 4));
    notifier.paintCollisionAt(const GridPos(x: 6, y: 4));
    final preview = notifier.activeMapCellStrokePreview!;
    notifier.endMapStroke();

    final committed = notifier.state.activeMap!;
    expect(preview.fullLayerCopyCount, 1);
    expect(preview.mapMaterializationCount, 1);
    expect(preview.validationCount, 1);
    expect(notifier.state.mapUndoStack, hasLength(1));
    final collisions = (committed.layers.single as CollisionLayer).collisions;
    for (var x = 1; x <= 6; x++) {
      expect(collisions[4 * 8 + x], isTrue);
    }

    notifier.undoMap();
    expect(notifier.state.activeMap, source);
    notifier.redoMap();
    expect(notifier.state.activeMap, committed);
  });
}
