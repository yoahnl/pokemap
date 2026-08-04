import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/design_system/pokemap_badge.dart';

import 'shell_chrome_test_harness.dart';

void main() {
  testWidgets(
    'eraser hover shows one footprint preview and a non-interactive size badge',
    (tester) async {
      final map = buildShellChromeMap(
        width: 4,
        height: 4,
        layers: const <MapLayer>[
          MapLayer.tile(
            id: 'tiles',
            name: 'Tiles',
            cells: <int>[
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
      final initialState = EditorState(
        project: buildShellChromeProject(),
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: map,
        activeLayerId: 'tiles',
        activeTool: EditorToolType.eraser,
        eraserFootprint: const EditorEraserFootprint.custom(
          size: GridSize(width: 3, height: 2),
        ),
        savedMapSnapshot: map,
      );
      final container = await pumpEditorCanvasHostHarness(
        tester,
        initialState: initialState,
        surfaceSize: const Size(900, 700),
      );

      expect(find.text('Gomme 3×2'), findsNothing);

      final mapBox = tester.getRect(find.byType(MapCanvas));
      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      addTearDown(gesture.removePointer);
      await gesture.addPointer(
        location: mapBox.topLeft + const Offset(48, 48),
      );
      await gesture.moveTo(mapBox.topLeft + const Offset(48, 48));
      await tester.pump();

      expect(find.text('Gomme 3×2'), findsOneWidget);
      final badgeOverlay = find.byKey(
        const ValueKey<String>('eraser-footprint-cursor-badge'),
      );
      expect(
        find.descendant(
          of: badgeOverlay,
          matching: find.byType(PokeMapBadge),
        ),
        findsOneWidget,
      );
      final ignorePointer = tester.widget<IgnorePointer>(badgeOverlay);
      expect(ignorePointer.ignoring, isTrue);

      final customPaint = tester.widget<CustomPaint>(
        find.byWidgetPredicate(
          (widget) => widget is CustomPaint && widget.painter is MapGridPainter,
        ),
      );
      final painter = customPaint.painter as MapGridPainter;
      expect(
        painter.toolPreview?.size,
        const GridSize(width: 3, height: 2),
      );
      expect(
        painter.hoveredTile,
        isNull,
        reason: 'The rectangular eraser preview replaces the generic 1x1 hover',
      );
      expect(container.read(editorNotifierProvider).isDirty, isFalse);

      container.read(editorNotifierProvider.notifier).state =
          initialState.copyWith(activeTool: EditorToolType.selection);
      await tester.pump();

      expect(find.text('Gomme 3×2'), findsNothing);
      final selectionPaint = tester.widget<CustomPaint>(
        find.byWidgetPredicate(
          (widget) => widget is CustomPaint && widget.painter is MapGridPainter,
        ),
      );
      expect(
        (selectionPaint.painter as MapGridPainter).hoveredTile,
        const GridPos(x: 1, y: 1),
      );
    },
  );
}
