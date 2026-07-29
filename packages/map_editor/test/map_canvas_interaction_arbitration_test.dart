import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/map_history_snapshot.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';

void main() {
  group('MapCanvas interaction arbitration', () {
    testWidgets(
      'pointer cancellation restores the exact stroke checkpoint and history',
      (tester) async {
        final container = _createContainer();
        const undoCheckpoint = MapHistorySnapshot(
          map: _historicalUndoMap,
          activeLayerId: 'collision',
        );
        const redoCheckpoint = MapHistorySnapshot(
          map: _historicalRedoMap,
          activeLayerId: 'collision',
        );
        container.read(editorNotifierProvider.notifier).state =
            const EditorState(
          project: _project,
          activeMap: _activeMap,
          activeLayerId: 'collision',
          activeTool: EditorToolType.collisionPaint,
          savedMapSnapshot: _activeMap,
          mapUndoStack: <MapHistorySnapshot>[undoCheckpoint],
          mapRedoStack: <MapHistorySnapshot>[redoCheckpoint],
          canUndoMap: true,
          canRedoMap: true,
        );
        final beforeJson = _activeMap.toJson();

        await _pumpCanvas(tester, container);
        final canvas = tester.getRect(find.byType(MapCanvas));
        final gesture = await tester.startGesture(
          canvas.topLeft + const Offset(16, 16),
          kind: ui.PointerDeviceKind.mouse,
        );
        await gesture.moveBy(const Offset(34, 0));
        await tester.pump();
        await gesture.moveBy(const Offset(34, 0));
        await tester.pump();

        final duringStroke = container.read(editorNotifierProvider);
        expect(
          (duringStroke.activeMap!.layers.single as CollisionLayer).collisions,
          const <bool>[
            true,
            true,
            true,
            false,
            false,
            false,
            false,
            false,
          ],
        );
        expect(duringStroke.mapStrokeStart, isNotNull);
        expect(duringStroke.isDirty, isTrue);

        await gesture.cancel();
        await tester.pump();

        final cancelled = container.read(editorNotifierProvider);
        expect(cancelled.activeMap!.toJson(), beforeJson);
        expect(cancelled.mapStrokeStart, isNull);
        expect(
          cancelled.mapUndoStack,
          const <MapHistorySnapshot>[undoCheckpoint],
        );
        expect(
          cancelled.mapRedoStack,
          const <MapHistorySnapshot>[redoCheckpoint],
        );
        expect(cancelled.canUndoMap, isTrue);
        expect(cancelled.canRedoMap, isTrue);
        expect(cancelled.isDirty, isFalse);
      },
    );

    testWidgets(
      'changing buttons during paint rolls the exact transaction back',
      (tester) async {
        const pointer = 41;
        const undoCheckpoint = MapHistorySnapshot(
          map: _historicalUndoMap,
          activeLayerId: 'collision',
        );
        const redoCheckpoint = MapHistorySnapshot(
          map: _historicalRedoMap,
          activeLayerId: 'collision',
        );
        final container = _createContainer();
        container.read(editorNotifierProvider.notifier).state =
            const EditorState(
          project: _project,
          activeMap: _activeMap,
          activeLayerId: 'collision',
          activeTool: EditorToolType.collisionPaint,
          savedMapSnapshot: _activeMap,
          mapUndoStack: <MapHistorySnapshot>[undoCheckpoint],
          mapRedoStack: <MapHistorySnapshot>[redoCheckpoint],
          canUndoMap: true,
          canRedoMap: true,
        );
        final beforeJson = _activeMap.toJson();

        await _pumpCanvas(tester, container);
        final canvas = tester.getRect(find.byType(MapCanvas));
        final downPosition = canvas.topLeft + const Offset(16, 16);
        final gesture = await tester.startGesture(
          downPosition,
          pointer: pointer,
          kind: ui.PointerDeviceKind.mouse,
          buttons: kPrimaryButton,
        );
        await gesture.moveBy(const Offset(34, 0));
        await tester.pump();
        expect(
          container.read(editorNotifierProvider).mapStrokeStart,
          isNotNull,
        );

        await gesture.updateWithCustomEvent(
          PointerMoveEvent(
            pointer: pointer,
            kind: ui.PointerDeviceKind.mouse,
            device: 1,
            position: downPosition + const Offset(68, 0),
            delta: const Offset(34, 0),
            buttons: kPrimaryButton | kSecondaryButton,
          ),
        );
        await tester.pump();
        await gesture.up();
        await tester.pump();

        final rolledBack = container.read(editorNotifierProvider);
        expect(rolledBack.activeMap!.toJson(), beforeJson);
        expect(rolledBack.mapStrokeStart, isNull);
        expect(
          rolledBack.mapUndoStack,
          const <MapHistorySnapshot>[undoCheckpoint],
        );
        expect(
          rolledBack.mapRedoStack,
          const <MapHistorySnapshot>[redoCheckpoint],
        );
        expect(rolledBack.canUndoMap, isTrue);
        expect(rolledBack.canRedoMap, isTrue);
        expect(rolledBack.isDirty, isFalse);
      },
    );

    testWidgets('a multi-sample drag creates exactly one undo entry',
        (tester) async {
      final container = _createContainer();
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: _project,
        activeMap: _activeMap,
        activeLayerId: 'collision',
        activeTool: EditorToolType.collisionPaint,
        savedMapSnapshot: _activeMap,
      );

      await _pumpCanvas(tester, container);
      final canvas = tester.getRect(find.byType(MapCanvas));
      final gesture = await tester.startGesture(
        canvas.topLeft + const Offset(16, 16),
        kind: ui.PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(34, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(34, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      final committed = container.read(editorNotifierProvider);
      expect(
        (committed.activeMap!.layers.single as CollisionLayer).collisions,
        const <bool>[
          true,
          true,
          true,
          false,
          false,
          false,
          false,
          false,
        ],
      );
      expect(committed.mapStrokeStart, isNull);
      expect(committed.mapUndoStack, hasLength(1));
      expect(committed.mapRedoStack, isEmpty);
      expect(committed.canUndoMap, isTrue);
      expect(committed.isDirty, isTrue);

      container.read(editorNotifierProvider.notifier).undoMap();
      final undone = container.read(editorNotifierProvider);
      expect(undone.activeMap, _activeMap);
      expect(undone.isDirty, isFalse);
    });

    testWidgets(
      'middle-button drag pans without mutating the document or its history',
      (tester) async {
        final container = _createContainer();
        const historical = MapHistorySnapshot(
          map: _activeMap,
          activeLayerId: 'collision',
        );
        container.read(editorNotifierProvider.notifier).state =
            const EditorState(
          project: _project,
          activeMap: _activeMap,
          activeLayerId: 'collision',
          activeTool: EditorToolType.collisionPaint,
          savedMapSnapshot: _activeMap,
          mapUndoStack: <MapHistorySnapshot>[historical],
          canUndoMap: true,
          panOffset: Offset(10, 20),
        );
        final beforeJson = _activeMap.toJson();

        await _pumpCanvas(tester, container);
        final canvas = tester.getRect(find.byType(MapCanvas));
        final gesture = await tester.startGesture(
          canvas.center,
          kind: ui.PointerDeviceKind.mouse,
          buttons: kTertiaryButton,
        );
        await gesture.moveBy(const Offset(30, -12));
        await tester.pump();
        await gesture.up();
        await tester.pump();

        final navigated = container.read(editorNotifierProvider);
        expect(navigated.panOffset, const Offset(40, 8));
        expect(navigated.activeMap!.toJson(), beforeJson);
        expect(navigated.mapUndoStack, const <MapHistorySnapshot>[historical]);
        expect(navigated.mapRedoStack, isEmpty);
        expect(navigated.mapStrokeStart, isNull);
        expect(navigated.canUndoMap, isTrue);
        expect(navigated.isDirty, isFalse);
      },
    );

    testWidgets(
      'changing buttons during primary pan ignores the mixed delta and cancels',
      (tester) async {
        const pointer = 42;
        const historical = MapHistorySnapshot(
          map: _activeMap,
          activeLayerId: 'collision',
        );
        final container = _createContainer();
        container.read(editorNotifierProvider.notifier).state =
            const EditorState(
          project: _project,
          activeMap: _activeMap,
          activeLayerId: 'collision',
          activeTool: EditorToolType.collisionPaint,
          savedMapSnapshot: _activeMap,
          mapUndoStack: <MapHistorySnapshot>[historical],
          canUndoMap: true,
          panOffset: Offset(10, 20),
        );
        final beforeJson = _activeMap.toJson();

        await _pumpCanvas(tester, container);
        final canvas = tester.getRect(find.byType(MapCanvas));
        final downPosition = canvas.center;
        await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
        final gesture = await tester.startGesture(
          downPosition,
          pointer: pointer,
          kind: ui.PointerDeviceKind.mouse,
          buttons: kPrimaryButton,
        );
        await gesture.moveBy(const Offset(30, -12));
        await tester.pump();

        await gesture.updateWithCustomEvent(
          PointerMoveEvent(
            pointer: pointer,
            kind: ui.PointerDeviceKind.mouse,
            device: 1,
            position: downPosition + const Offset(48, -6),
            delta: const Offset(18, 6),
            buttons: kPrimaryButton | kSecondaryButton,
          ),
        );
        await tester.pump();
        await gesture.moveBy(const Offset(9, 4));
        await tester.pump();
        await gesture.up();
        await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
        await tester.pump();

        final cancelled = container.read(editorNotifierProvider);
        expect(cancelled.panOffset, const Offset(40, 8));
        expect(cancelled.activeMap!.toJson(), beforeJson);
        expect(cancelled.mapUndoStack, const <MapHistorySnapshot>[historical]);
        expect(cancelled.mapRedoStack, isEmpty);
        expect(cancelled.mapStrokeStart, isNull);
        expect(cancelled.canUndoMap, isTrue);
        expect(cancelled.isDirty, isFalse);
      },
    );

    testWidgets('Escape rolls an active paint gesture back exactly',
        (tester) async {
      final container = _createContainer();
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: _project,
        activeMap: _activeMap,
        activeLayerId: 'collision',
        activeTool: EditorToolType.collisionPaint,
        savedMapSnapshot: _activeMap,
      );
      final beforeJson = _activeMap.toJson();

      await _pumpCanvas(tester, container);
      final canvas = tester.getRect(find.byType(MapCanvas));
      final gesture = await tester.startGesture(
        canvas.topLeft + const Offset(16, 16),
        kind: ui.PointerDeviceKind.mouse,
      );
      await tester.pump();
      await gesture.moveBy(const Offset(34, 0));
      await tester.pump();
      expect(
        container.read(editorNotifierProvider).mapStrokeStart,
        isNotNull,
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await gesture.up();
      await tester.pump();

      final cancelled = container.read(editorNotifierProvider);
      expect(cancelled.activeMap!.toJson(), beforeJson);
      expect(cancelled.mapStrokeStart, isNull);
      expect(cancelled.mapUndoStack, isEmpty);
      expect(cancelled.mapRedoStack, isEmpty);
      expect(cancelled.isDirty, isFalse);
    });

    testWidgets(
      'a child control cannot strand canvas ownership after pointer up',
      (tester) async {
        final container = _createContainer();
        container.read(editorNotifierProvider.notifier).state =
            const EditorState(
          project: _project,
          activeMap: _activeMap,
          activeLayerId: 'collision',
          activeTool: EditorToolType.collisionPaint,
          savedMapSnapshot: _activeMap,
        );

        await _pumpCanvas(tester, container);
        await tester.tap(
          find.byKey(
            const ValueKey<String>('shadow-light-preview-evening-button'),
          ),
        );
        await tester.pump();
        final canvasCenter = tester.getCenter(find.byType(MapCanvas));
        tester.binding.handlePointerEvent(
          PointerScrollEvent(
            position: canvasCenter,
            kind: ui.PointerDeviceKind.mouse,
            scrollDelta: const Offset(12, -8),
          ),
        );
        await tester.pump();

        final state = container.read(editorNotifierProvider);
        expect(state.panOffset, const Offset(-12, 8));
        expect(state.activeMap, _activeMap);
        expect(state.mapUndoStack, isEmpty);
        expect(state.isDirty, isFalse);
      },
    );

    testWidgets('changing tool mid-drag rolls the original transaction back',
        (tester) async {
      final container = _createContainer();
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: _project,
        activeMap: _activeMap,
        activeLayerId: 'collision',
        activeTool: EditorToolType.collisionPaint,
        savedMapSnapshot: _activeMap,
      );
      final beforeJson = _activeMap.toJson();

      await _pumpCanvas(tester, container);
      final canvas = tester.getRect(find.byType(MapCanvas));
      final gesture = await tester.startGesture(
        canvas.topLeft + const Offset(16, 16),
        kind: ui.PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(34, 0));
      await tester.pump();
      expect(
        container.read(editorNotifierProvider).mapStrokeStart,
        isNotNull,
      );

      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = notifier.state.copyWith(
        activeTool: EditorToolType.selection,
      );
      await tester.pump();
      await gesture.moveBy(const Offset(34, 0));
      await tester.pump();

      final rolledBack = container.read(editorNotifierProvider);
      expect(rolledBack.activeTool, EditorToolType.selection);
      expect(rolledBack.activeMap!.toJson(), beforeJson);
      expect(rolledBack.mapStrokeStart, isNull);
      expect(rolledBack.mapUndoStack, isEmpty);
      expect(rolledBack.isDirty, isFalse);

      await gesture.up();
      await tester.pump();
    });

    testWidgets(
        'changing eraser footprint mid-drag rolls the original transaction back',
        (tester) async {
      const filledMap = MapData(
        id: 'map',
        name: 'Map',
        size: GridSize(width: 4, height: 2),
        layers: <MapLayer>[
          CollisionLayer(
            id: 'collision',
            name: 'Collision',
            collisions: <bool>[
              true,
              true,
              true,
              true,
              true,
              true,
              true,
              true,
            ],
          ),
        ],
      );
      final container = _createContainer();
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: _project,
        activeMap: filledMap,
        activeLayerId: 'collision',
        activeTool: EditorToolType.eraser,
        savedMapSnapshot: filledMap,
      );
      final beforeJson = filledMap.toJson();

      await _pumpCanvas(tester, container);
      final canvas = tester.getRect(find.byType(MapCanvas));
      final gesture = await tester.startGesture(
        canvas.topLeft + const Offset(16, 16),
        kind: ui.PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(34, 0));
      await tester.pump();
      expect(
        container.read(editorNotifierProvider).mapStrokeStart,
        isNotNull,
      );

      final notifier = container.read(editorNotifierProvider.notifier);
      expect(
        notifier.setCustomEraserFootprint(width: 2, height: 1),
        isTrue,
      );
      await tester.pump();
      await gesture.moveBy(const Offset(34, 0));
      await tester.pump();

      final rolledBack = container.read(editorNotifierProvider);
      expect(
        rolledBack.eraserFootprint,
        const EditorEraserFootprint.custom(
          size: GridSize(width: 2, height: 1),
        ),
      );
      expect(rolledBack.activeMap!.toJson(), beforeJson);
      expect(rolledBack.mapStrokeStart, isNull);
      expect(rolledBack.mapUndoStack, isEmpty);
      expect(rolledBack.isDirty, isFalse);

      await gesture.up();
      await tester.pump();
    });

    testWidgets('unmounting the canvas rolls an active stroke back',
        (tester) async {
      final container = _createContainer();
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: _project,
        activeMap: _activeMap,
        activeLayerId: 'collision',
        activeTool: EditorToolType.collisionPaint,
        savedMapSnapshot: _activeMap,
      );
      final beforeJson = _activeMap.toJson();

      await _pumpCanvas(tester, container);
      final canvas = tester.getRect(find.byType(MapCanvas));
      final gesture = await tester.startGesture(
        canvas.topLeft + const Offset(16, 16),
        kind: ui.PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(34, 0));
      await tester.pump();
      expect(
        container.read(editorNotifierProvider).mapStrokeStart,
        isNotNull,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SizedBox.shrink(),
        ),
      );
      await tester.pump();

      final rolledBack = container.read(editorNotifierProvider);
      expect(rolledBack.activeMap!.toJson(), beforeJson);
      expect(rolledBack.mapStrokeStart, isNull);
      expect(rolledBack.mapUndoStack, isEmpty);
      expect(rolledBack.isDirty, isFalse);

      await gesture.cancel();
    });

    testWidgets(
      'a cancelled physical pointer quarantines later pointers until release',
      (tester) async {
        final container = _createContainer();
        container.read(editorNotifierProvider.notifier).state =
            const EditorState(
          project: _project,
          activeMap: _activeMap,
          activeLayerId: 'collision',
          activeTool: EditorToolType.collisionPaint,
          savedMapSnapshot: _activeMap,
        );
        final beforeJson = _activeMap.toJson();

        await _pumpCanvas(tester, container);
        final canvas = tester.getRect(find.byType(MapCanvas));
        final first = await tester.startGesture(
          canvas.topLeft + const Offset(16, 16),
          pointer: 1,
          kind: ui.PointerDeviceKind.mouse,
        );
        await first.moveBy(const Offset(34, 0));
        await tester.pump();
        expect(
          container.read(editorNotifierProvider).mapStrokeStart,
          isNotNull,
        );

        await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
        await tester.pump();
        expect(
          container.read(editorNotifierProvider).activeMap!.toJson(),
          beforeJson,
        );

        final second = await tester.startGesture(
          canvas.topLeft + const Offset(16, 48),
          pointer: 2,
          kind: ui.PointerDeviceKind.mouse,
        );
        await second.moveBy(const Offset(34, 0));
        await tester.pump();
        expect(
          container.read(editorNotifierProvider).activeMap!.toJson(),
          beforeJson,
        );
        expect(
          container.read(editorNotifierProvider).mapStrokeStart,
          isNull,
        );

        await first.up();
        await tester.pump();
        await second.up();
        await tester.pump();

        final third = await tester.startGesture(
          canvas.topLeft + const Offset(16, 16),
          pointer: 3,
          kind: ui.PointerDeviceKind.mouse,
        );
        await third.moveBy(const Offset(34, 0));
        await tester.pump();
        await third.up();
        await tester.pump();

        final committed = container.read(editorNotifierProvider);
        expect(committed.activeMap, isNot(_activeMap));
        expect(committed.mapUndoStack, hasLength(1));
      },
    );

    testWidgets(
      'a second physical pointer rolls the owned transaction back',
      (tester) async {
        final container = _createContainer();
        container.read(editorNotifierProvider.notifier).state =
            const EditorState(
          project: _project,
          activeMap: _activeMap,
          activeLayerId: 'collision',
          activeTool: EditorToolType.collisionPaint,
          savedMapSnapshot: _activeMap,
        );
        final beforeJson = _activeMap.toJson();

        await _pumpCanvas(tester, container);
        final canvas = tester.getRect(find.byType(MapCanvas));
        final first = await tester.startGesture(
          canvas.topLeft + const Offset(16, 16),
          pointer: 11,
          kind: ui.PointerDeviceKind.touch,
        );
        await first.moveBy(const Offset(34, 0));
        await tester.pump();
        expect(
          container.read(editorNotifierProvider).mapStrokeStart,
          isNotNull,
        );

        final second = await tester.startGesture(
          canvas.topLeft + const Offset(16, 48),
          pointer: 12,
          kind: ui.PointerDeviceKind.touch,
        );
        await second.moveBy(const Offset(68, 0));
        await tester.pump();

        final rolledBack = container.read(editorNotifierProvider);
        expect(rolledBack.activeMap!.toJson(), beforeJson);
        expect(rolledBack.mapStrokeStart, isNull);
        expect(rolledBack.mapUndoStack, isEmpty);
        expect(rolledBack.isDirty, isFalse);

        await first.up();
        await second.up();
        await tester.pump();
      },
    );
  });
}

ProviderContainer _createContainer() {
  final container = ProviderContainer();
  final subscription = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(() {
    subscription.close();
    container.dispose();
  });
  return container;
}

Future<void> _pumpCanvas(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.binding.setSurfaceSize(const Size(900, 700));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MacosTheme(
        data: MacosThemeData.light(),
        child: const MaterialApp(
          home: CupertinoPageScaffold(
            child: SizedBox.expand(child: MapCanvas()),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

const _project = ProjectManifest(
  name: 'interaction_arbitration_project',
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[],
  surfaceCatalog: ProjectSurfaceCatalog.empty(),
);

const _activeMap = MapData(
  id: 'map',
  name: 'Map',
  size: GridSize(width: 4, height: 2),
  layers: <MapLayer>[
    CollisionLayer(
      id: 'collision',
      name: 'Collision',
      collisions: <bool>[
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
      ],
    ),
  ],
);

const _historicalUndoMap = MapData(
  id: 'undo_map',
  name: 'Undo checkpoint',
  size: GridSize(width: 1, height: 1),
  layers: <MapLayer>[
    CollisionLayer(
      id: 'collision',
      name: 'Collision',
      collisions: <bool>[false],
    ),
  ],
);

const _historicalRedoMap = MapData(
  id: 'redo_map',
  name: 'Redo checkpoint',
  size: GridSize(width: 1, height: 1),
  layers: <MapLayer>[
    CollisionLayer(
      id: 'collision',
      name: 'Collision',
      collisions: <bool>[true],
    ),
  ],
);
