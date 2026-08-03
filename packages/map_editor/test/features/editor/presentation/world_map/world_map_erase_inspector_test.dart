import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_erase_inspector.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/theme/theme.dart';

void main() {
  testWidgets(
    'edits an independent 1..16 footprint and resets to exactly 1x1',
    (tester) async {
      final harness = _EraseHarness();
      addTearDown(harness.dispose);
      await harness.pump(tester);

      expect(
        _fieldText(tester, const ValueKey<String>('world-map-eraser-width')),
        '3',
      );
      expect(
        _fieldText(tester, const ValueKey<String>('world-map-eraser-height')),
        '2',
      );
      expect(
        harness.notifier.state.activeBrush,
        const EditorBrush.projectElement(elementId: 'house'),
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('world-map-eraser-width')),
        '$kMaxEditorEraserFootprintDimension',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('world-map-eraser-height')),
        '$kMaxEditorEraserFootprintDimension',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('world-map-eraser-apply')),
      );
      await tester.pump();

      expect(
        harness.notifier.state.eraserFootprint,
        const EditorEraserFootprint.custom(
          size: GridSize(
            width: kMaxEditorEraserFootprintDimension,
            height: kMaxEditorEraserFootprintDimension,
          ),
        ),
      );
      _expectTransientOnly(harness);

      await tester.tap(
        find.byKey(const ValueKey<String>('world-map-eraser-reset')),
      );
      await tester.pump();

      expect(
        harness.notifier.state.eraserFootprint,
        const EditorEraserFootprint.singleTile(),
      );
      expect(
        _fieldText(tester, const ValueKey<String>('world-map-eraser-width')),
        '1',
      );
      expect(
        _fieldText(tester, const ValueKey<String>('world-map-eraser-height')),
        '1',
      );
      _expectTransientOnly(harness);
    },
  );

  testWidgets('rejects invalid dimensions without any editor-state mutation',
      (tester) async {
    final harness = _EraseHarness();
    addTearDown(harness.dispose);
    await harness.pump(tester);
    final before = harness.notifier.state;

    await tester.enterText(
      find.byKey(const ValueKey<String>('world-map-eraser-width')),
      '0',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('world-map-eraser-height')),
      '${kMaxEditorEraserFootprintDimension + 1}',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('world-map-eraser-apply')),
    );
    await tester.pump();

    expect(harness.notifier.state, same(before));
    expect(
      find.text('Chaque dimension doit être comprise entre 1 et 16.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('world-map-eraser-width')),
      'abc',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('world-map-eraser-apply')),
    );
    await tester.pump();

    expect(harness.notifier.state, same(before));
    expect(
      find.text('Saisissez une largeur et une hauteur entières.'),
      findsOneWidget,
    );
  });
}

String _fieldText(WidgetTester tester, Key key) {
  return tester.widget<TextField>(find.byKey(key)).controller!.text;
}

void _expectTransientOnly(_EraseHarness harness) {
  final state = harness.notifier.state;
  expect(state.activeMap, same(_map));
  expect(
      state.activeBrush, const EditorBrush.projectElement(elementId: 'house'));
  expect(state.mapUndoStack, isEmpty);
  expect(state.mapRedoStack, isEmpty);
  expect(state.isDirty, isFalse);
}

class _EraseHarness {
  _EraseHarness() {
    keepAlive = container.listen(editorNotifierProvider, (_, __) {});
    notifier.state = const EditorState(
      project: _project,
      activeMap: _map,
      activeLayerId: 'ground',
      activeTool: EditorToolType.eraser,
      activeBrush: EditorBrush.projectElement(elementId: 'house'),
      eraserFootprint: EditorEraserFootprint.custom(
        size: GridSize(width: 3, height: 2),
      ),
      savedMapSnapshot: _map,
    );
  }

  final ProviderContainer container = ProviderContainer();
  late final ProviderSubscription<EditorState> keepAlive;

  EditorNotifier get notifier =>
      container.read(editorNotifierProvider.notifier);

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: PokeMapTheme.light(),
          home: const Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: WorldMapEraseInspector(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  void dispose() {
    keepAlive.close();
    container.dispose();
  }
}

const _project = ProjectManifest(
  name: 'Erase inspector',
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[],
  elements: <ProjectElementEntry>[
    ProjectElementEntry(
      id: 'house',
      name: 'House',
      tilesetId: 'world',
      categoryId: 'building',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 8, height: 9),
        ),
      ],
    ),
  ],
);

const _map = MapData(
  id: 'map',
  name: 'Map',
  size: GridSize(width: 4, height: 4),
  layers: <MapLayer>[
    TileLayer(
      id: 'ground',
      name: 'Ground',
      tilesetId: 'world',
      tiles: <int>[
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
      ],
    ),
  ],
);
