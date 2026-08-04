import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/map_history_snapshot.dart';
import 'package:map_editor/src/application/services/map_viewport_navigation.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';

void main() {
  group('MapCanvas pointer navigation', () {
    for (final kind in <ui.PointerDeviceKind>[
      ui.PointerDeviceKind.mouse,
      ui.PointerDeviceKind.trackpad,
    ]) {
      testWidgets(
        'scroll pans naturally for ${kind.name} without zooming or editing',
        (tester) async {
          final container = _createContainer();
          const map = _activeMap;
          container.read(editorNotifierProvider.notifier).state =
              const EditorState(
            project: _project,
            activeMap: map,
            activeLayerId: 'ground',
            savedMapSnapshot: map,
            panOffset: Offset(10, 20),
            zoom: 1.25,
          );

          await _pumpCanvas(tester, container);

          final canvasCenter = tester.getCenter(find.byType(MapCanvas));
          tester.binding.handlePointerEvent(
            PointerScrollEvent(
              position: canvasCenter,
              kind: kind,
              scrollDelta: const Offset(24, -16),
            ),
          );
          await tester.pump();

          final state = container.read(editorNotifierProvider);
          expect(state.panOffset, const Offset(-14, 36));
          expect(state.zoom, 1.25);
          expect(state.activeMap, same(map));
          expect(state.isDirty, isFalse);
          expect(state.mapUndoStack, isEmpty);
          expect(state.mapRedoStack, isEmpty);
        },
      );
    }

    testWidgets('zero scroll delta is ignored', (tester) async {
      final container = _createContainer();
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: _project,
        activeMap: _activeMap,
        activeLayerId: 'ground',
        activeTool: EditorToolType.tilePaint,
        savedMapSnapshot: _activeMap,
      );

      await _pumpCanvas(tester, container);
      tester.binding.handlePointerEvent(
        PointerScrollEvent(
          position: tester.getCenter(find.byType(MapCanvas)),
          kind: ui.PointerDeviceKind.mouse,
        ),
      );
      await tester.pump();

      final state = container.read(editorNotifierProvider);
      expect(state.panOffset, Offset.zero);
      expect(state.zoom, 1);
      expect(state.activeMap, same(_activeMap));
    });

    testWidgets(
      'tile paint with no brush ignores a primary click without opening a stroke',
      (tester) async {
        final container = _createContainer();
        const undoCheckpoint = MapHistorySnapshot(
          map: _activeMap,
          activeLayerId: 'undo-sentinel',
        );
        const redoCheckpoint = MapHistorySnapshot(
          map: _activeMap,
          activeLayerId: 'redo-sentinel',
        );
        container.read(editorNotifierProvider.notifier).state =
            const EditorState(
          project: _project,
          activeMap: _activeMap,
          activeLayerId: 'ground',
          activeTool: EditorToolType.tilePaint,
          activeBrush: EditorBrush.none(),
          savedMapSnapshot: _activeMap,
          mapUndoStack: <MapHistorySnapshot>[undoCheckpoint],
          mapRedoStack: <MapHistorySnapshot>[redoCheckpoint],
          canUndoMap: true,
          canRedoMap: true,
        );

        await _pumpCanvas(tester, container);
        final before = container.read(editorNotifierProvider);
        final emissions = <EditorState>[];
        final subscription = container.listen<EditorState>(
          editorNotifierProvider,
          (_, next) => emissions.add(next),
        );
        addTearDown(subscription.close);

        await tester.tapAt(
          tester.getRect(find.byType(MapCanvas)).topLeft + const Offset(16, 16),
        );
        await tester.pump();

        final after = container.read(editorNotifierProvider);
        expect(
          emissions.where((snapshot) => snapshot.mapStrokeStart != null),
          isEmpty,
        );
        expect(after.activeMap, same(before.activeMap));
        expect(after.activeMap!.toJson(), before.activeMap!.toJson());
        expect(after.mapStrokeStart, isNull);
        expect(after.mapUndoStack, before.mapUndoStack);
        expect(after.mapRedoStack, before.mapRedoStack);
        expect(after.canUndoMap, isTrue);
        expect(after.canRedoMap, isTrue);
        expect(after.isDirty, isFalse);
      },
    );

    testWidgets('command wheel zooms under the pointer without editing',
        (tester) async {
      final container = _createContainer();
      const initial = MapViewport(
        zoom: 2,
        panOffset: Offset(10, 20),
      );
      const undoCheckpoint = MapHistorySnapshot(
        map: _activeMap,
        activeLayerId: 'undo-sentinel',
      );
      const redoCheckpoint = MapHistorySnapshot(
        map: _activeMap,
        activeLayerId: 'redo-sentinel',
      );
      container.read(editorNotifierProvider.notifier).state = EditorState(
        project: _project,
        activeMap: _activeMap,
        activeLayerId: 'ground',
        activeTool: EditorToolType.tilePaint,
        savedMapSnapshot: _activeMap,
        panOffset: initial.panOffset,
        zoom: initial.zoom,
        mapUndoStack: const <MapHistorySnapshot>[undoCheckpoint],
        mapRedoStack: const <MapHistorySnapshot>[redoCheckpoint],
        canUndoMap: true,
        canRedoMap: true,
        isDirty: true,
        isProjectDirty: true,
      );
      final before = container.read(editorNotifierProvider);

      await _pumpCanvas(
        tester,
        container,
        canvasPadding: const EdgeInsets.only(left: 137, top: 83),
      );
      final canvas = find.byType(MapCanvas);
      final canvasOrigin = tester.getTopLeft(canvas);
      expect(canvasOrigin, const Offset(137, 83));
      const localPointer = Offset(300, 200);
      final expected = MapViewportNavigation.zoomFromScroll(
        viewport: initial,
        focalPoint: localPointer,
        scrollDeltaY: -120,
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      try {
        tester.binding.handlePointerEvent(
          PointerScrollEvent(
            position: canvasOrigin + localPointer,
            kind: ui.PointerDeviceKind.mouse,
            scrollDelta: const Offset(0, -120),
          ),
        );
        await tester.pump();
      } finally {
        await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      }

      final state = container.read(editorNotifierProvider);
      expect(state.zoom, closeTo(expected.zoom, 0.000001));
      expect(state.panOffset.dx, closeTo(expected.panOffset.dx, 0.000001));
      expect(state.panOffset.dy, closeTo(expected.panOffset.dy, 0.000001));
      expect(state.activeMap, same(_activeMap));
      expect(state.savedMapSnapshot, same(before.savedMapSnapshot));
      expect(state.isDirty, isTrue);
      expect(state.isProjectDirty, isTrue);
      expect(state.mapUndoStack, before.mapUndoStack);
      expect(state.mapRedoStack, before.mapRedoStack);
      expect(state.canUndoMap, isTrue);
      expect(state.canRedoMap, isTrue);
    });

    testWidgets('control wheel uses the same anchored zoom contract',
        (tester) async {
      final container = _createContainer();
      const initial = MapViewport(
        zoom: 1.5,
        panOffset: Offset(-25, 35),
      );
      container.read(editorNotifierProvider.notifier).state = EditorState(
        project: _project,
        activeMap: _activeMap,
        activeLayerId: 'ground',
        activeTool: EditorToolType.tilePaint,
        savedMapSnapshot: _activeMap,
        panOffset: initial.panOffset,
        zoom: initial.zoom,
      );

      await _pumpCanvas(tester, container);
      final canvas = find.byType(MapCanvas);
      final canvasOrigin = tester.getTopLeft(canvas);
      const localPointer = Offset(240, 180);
      final expected = MapViewportNavigation.zoomFromScroll(
        viewport: initial,
        focalPoint: localPointer,
        scrollDeltaY: 80,
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      try {
        tester.binding.handlePointerEvent(
          PointerScrollEvent(
            position: canvasOrigin + localPointer,
            kind: ui.PointerDeviceKind.mouse,
            scrollDelta: const Offset(0, 80),
          ),
        );
        await tester.pump();
      } finally {
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      }

      final state = container.read(editorNotifierProvider);
      expect(state.zoom, closeTo(expected.zoom, 0.000001));
      expect(state.panOffset.dx, closeTo(expected.panOffset.dx, 0.000001));
      expect(state.panOffset.dy, closeTo(expected.panOffset.dy, 0.000001));
      expect(state.activeMap, same(_activeMap));
      expect(state.isDirty, isFalse);
    });

    testWidgets('native trackpad pan and pinch use one absolute start snapshot',
        (tester) async {
      final container = _createContainer();
      const initial = MapViewport(
        zoom: 2,
        panOffset: Offset(10, 20),
      );
      const undoCheckpoint = MapHistorySnapshot(
        map: _activeMap,
        activeLayerId: 'undo-sentinel',
      );
      const redoCheckpoint = MapHistorySnapshot(
        map: _activeMap,
        activeLayerId: 'redo-sentinel',
      );
      container.read(editorNotifierProvider.notifier).state = EditorState(
        project: _project,
        activeMap: _activeMap,
        activeLayerId: 'ground',
        activeTool: EditorToolType.tilePaint,
        savedMapSnapshot: _activeMap,
        panOffset: initial.panOffset,
        zoom: initial.zoom,
        mapUndoStack: const <MapHistorySnapshot>[undoCheckpoint],
        mapRedoStack: const <MapHistorySnapshot>[redoCheckpoint],
        canUndoMap: true,
        canRedoMap: true,
        isDirty: true,
        isProjectDirty: true,
      );
      final before = container.read(editorNotifierProvider);

      await _pumpCanvas(
        tester,
        container,
        canvasPadding: const EdgeInsets.only(left: 137, top: 83),
      );
      final canvas = find.byType(MapCanvas);
      final canvasOrigin = tester.getTopLeft(canvas);
      expect(canvasOrigin, const Offset(137, 83));
      const localFocalPoint = Offset(400, 300);
      const cumulativePan = Offset(20, -10);
      final expected = MapViewportNavigation.panZoomFromStart(
        startViewport: initial,
        startFocalPoint: localFocalPoint,
        cumulativePan: cumulativePan,
        scale: 1.5,
      );
      final gesture = await tester.createGesture(
        kind: ui.PointerDeviceKind.trackpad,
        pointer: 41,
      );

      await gesture.panZoomStart(canvasOrigin + localFocalPoint);
      await gesture.panZoomUpdate(
        canvasOrigin + localFocalPoint,
        pan: cumulativePan,
        scale: 1.5,
      );
      await tester.pump();
      final afterFirstUpdate = container.read(editorNotifierProvider);
      await gesture.panZoomUpdate(
        canvasOrigin + localFocalPoint,
        pan: cumulativePan,
        scale: 1.5,
      );
      tester.binding.handlePointerEvent(
        PointerScrollEvent(
          position: canvasOrigin + localFocalPoint,
          kind: ui.PointerDeviceKind.trackpad,
          scrollDelta: const Offset(30, 20),
        ),
      );
      await tester.pump();
      final whileOwned = container.read(editorNotifierProvider);
      expect(whileOwned.zoom, afterFirstUpdate.zoom);
      expect(whileOwned.panOffset, afterFirstUpdate.panOffset);
      await gesture.panZoomEnd();
      await tester.pump();
      tester.binding.handlePointerEvent(
        PointerScrollEvent(
          position: canvasOrigin + localFocalPoint,
          kind: ui.PointerDeviceKind.trackpad,
          scrollDelta: const Offset(4, -6),
        ),
      );
      await tester.pump();

      final state = container.read(editorNotifierProvider);
      expect(state.zoom, closeTo(expected.zoom, 0.000001));
      expect(
        state.panOffset.dx,
        closeTo(expected.panOffset.dx - 4, 0.000001),
      );
      expect(
        state.panOffset.dy,
        closeTo(expected.panOffset.dy + 6, 0.000001),
      );
      expect(state.activeMap, same(_activeMap));
      expect(state.savedMapSnapshot, same(before.savedMapSnapshot));
      expect(state.isDirty, isTrue);
      expect(state.isProjectDirty, isTrue);
      expect(state.mapUndoStack, before.mapUndoStack);
      expect(state.mapRedoStack, before.mapRedoStack);
      expect(state.mapStrokeStart, before.mapStrokeStart);
      expect(state.canUndoMap, isTrue);
      expect(state.canRedoMap, isTrue);
    });

    testWidgets('Escape clears a native pan zoom snapshot and reopens scroll',
        (tester) async {
      final container = _createContainer();
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: _project,
        activeMap: _activeMap,
        activeLayerId: 'ground',
        activeTool: EditorToolType.tilePaint,
        savedMapSnapshot: _activeMap,
        panOffset: Offset(10, 20),
        zoom: 2,
      );

      await _pumpCanvas(tester, container);
      final canvas = find.byType(MapCanvas);
      final focalPoint = tester.getCenter(canvas);
      final gesture = await tester.createGesture(
        kind: ui.PointerDeviceKind.trackpad,
        pointer: 42,
      );
      await gesture.panZoomStart(focalPoint);
      await gesture.panZoomUpdate(
        focalPoint,
        pan: const Offset(20, 10),
        scale: 1.25,
      );
      await tester.pump();
      final beforeEscape = container.read(editorNotifierProvider);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await gesture.panZoomUpdate(
        focalPoint,
        pan: const Offset(100, 80),
        scale: 2,
      );
      await tester.pump();
      final afterLateUpdate = container.read(editorNotifierProvider);
      expect(afterLateUpdate.zoom, beforeEscape.zoom);
      expect(afterLateUpdate.panOffset, beforeEscape.panOffset);

      final replacement = await tester.createGesture(
        kind: ui.PointerDeviceKind.trackpad,
        pointer: 43,
      );
      await replacement.panZoomStart(focalPoint);
      await replacement.panZoomUpdate(
        focalPoint,
        pan: const Offset(10, -5),
        scale: 1.1,
      );
      await tester.pump();
      await gesture.panZoomEnd();
      await replacement.panZoomUpdate(
        focalPoint,
        pan: const Offset(30, -15),
        scale: 0.8,
      );
      await tester.pump();
      final expectedReplacement = MapViewportNavigation.panZoomFromStart(
        startViewport: MapViewport(
          zoom: beforeEscape.zoom,
          panOffset: beforeEscape.panOffset,
        ),
        startFocalPoint: focalPoint,
        cumulativePan: const Offset(30, -15),
        scale: 0.8,
      );
      final afterLateEnd = container.read(editorNotifierProvider);
      expect(
        afterLateEnd.zoom,
        closeTo(expectedReplacement.zoom, 0.000001),
      );
      expect(
        afterLateEnd.panOffset.dx,
        closeTo(expectedReplacement.panOffset.dx, 0.000001),
      );
      expect(
        afterLateEnd.panOffset.dy,
        closeTo(expectedReplacement.panOffset.dy, 0.000001),
      );
      await replacement.panZoomEnd();
      tester.binding.handlePointerEvent(
        PointerScrollEvent(
          position: focalPoint,
          kind: ui.PointerDeviceKind.trackpad,
          scrollDelta: const Offset(5, 7),
        ),
      );
      await tester.pump();

      final state = container.read(editorNotifierProvider);
      expect(
        state.panOffset,
        expectedReplacement.panOffset - const Offset(5, 7),
      );
      expect(state.zoom, expectedReplacement.zoom);
      expect(state.activeMap, same(_activeMap));
      expect(state.isDirty, isFalse);
    });

    testWidgets('an incidental pinch cannot rollback an owned paint stroke',
        (tester) async {
      final container = _createContainer();
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: _project,
        activeMap: _activeMap,
        activeLayerId: 'ground',
        activeTool: EditorToolType.tilePaint,
        activeBrush: EditorBrush.tile(tileId: 7, tilesetId: 'world'),
        savedMapSnapshot: _activeMap,
      );

      await _pumpCanvas(tester, container);
      final canvasOrigin = tester.getTopLeft(find.byType(MapCanvas));
      final paint = await tester.startGesture(
        canvasOrigin + const Offset(8, 8),
        kind: ui.PointerDeviceKind.mouse,
        buttons: kPrimaryButton,
      );
      await paint.moveBy(const Offset(20, 0));
      await tester.pump();
      final duringPaint = container.read(editorNotifierProvider);
      expect(duringPaint.mapStrokeStart, isNotNull);
      expect(duringPaint.activeMap, isNot(same(_activeMap)));

      final pinch = await tester.createGesture(
        kind: ui.PointerDeviceKind.trackpad,
        pointer: 44,
      );
      await pinch.panZoomStart(canvasOrigin + const Offset(20, 20));
      await pinch.panZoomUpdate(
        canvasOrigin + const Offset(20, 20),
        pan: const Offset(30, 10),
        scale: 1.4,
      );
      await tester.pump();
      await pinch.panZoomEnd();
      await tester.pump();

      final afterPinch = container.read(editorNotifierProvider);
      expect(afterPinch.mapStrokeStart, same(duringPaint.mapStrokeStart));
      expect(afterPinch.activeMap, same(duringPaint.activeMap));
      expect(afterPinch.zoom, duringPaint.zoom);
      expect(afterPinch.panOffset, duringPaint.panOffset);

      await paint.up();
      await tester.pump();
      final committed = container.read(editorNotifierProvider);
      expect(committed.mapStrokeStart, isNull);
      expect(committed.isDirty, isTrue);
      expect(committed.mapUndoStack, hasLength(1));
    });

    testWidgets('space plus primary drag pans without painting',
        (tester) async {
      final container = _createContainer();
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: _project,
        activeMap: _activeMap,
        activeLayerId: 'ground',
        savedMapSnapshot: _activeMap,
        panOffset: Offset(10, 20),
      );

      await _pumpCanvas(tester, container);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(MapCanvas)),
        kind: ui.PointerDeviceKind.mouse,
        buttons: kPrimaryButton,
      );
      await gesture.moveBy(const Offset(45, -30));
      await gesture.up();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      await tester.pump();

      final state = container.read(editorNotifierProvider);
      expect(state.panOffset, const Offset(55, -10));
      expect(state.activeMap, same(_activeMap));
      expect(state.isDirty, isFalse);
      expect(state.mapUndoStack, isEmpty);
    });

    testWidgets('focus loss clears a stale physical pan owner', (tester) async {
      final container = _createContainer();
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: _project,
        activeMap: _activeMap,
        activeLayerId: 'ground',
        savedMapSnapshot: _activeMap,
      );

      await _pumpCanvas(tester, container);
      final center = tester.getCenter(find.byType(MapCanvas));
      final abandoned = await tester.startGesture(
        center,
        kind: ui.PointerDeviceKind.mouse,
        buttons: kTertiaryButton,
      );
      await abandoned.moveBy(const Offset(20, 10));
      await tester.pump();
      expect(
        container.read(editorNotifierProvider).panOffset,
        const Offset(20, 10),
      );

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      final replacement = await tester.startGesture(
        center,
        kind: ui.PointerDeviceKind.mouse,
        buttons: kTertiaryButton,
      );
      await replacement.moveBy(const Offset(15, -5));
      await tester.pump();
      expect(
        container.read(editorNotifierProvider).panOffset,
        const Offset(35, 5),
      );
      await replacement.up();
      await abandoned.cancel();
      await tester.pump();

      final state = container.read(editorNotifierProvider);
      expect(state.panOffset, const Offset(35, 5));
      expect(state.activeMap, same(_activeMap));
      expect(state.isDirty, isFalse);
      expect(state.mapUndoStack, isEmpty);
    });

    testWidgets('middle drag pans while right drag remains reserved',
        (tester) async {
      final container = _createContainer();
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: _project,
        activeMap: _activeMap,
        activeLayerId: 'ground',
        savedMapSnapshot: _activeMap,
        panOffset: Offset(10, 20),
      );

      await _pumpCanvas(tester, container);
      final center = tester.getCenter(find.byType(MapCanvas));
      final middle = await tester.startGesture(
        center,
        kind: ui.PointerDeviceKind.mouse,
        buttons: kTertiaryButton,
      );
      await middle.moveBy(const Offset(25, 15));
      await middle.up();
      await tester.pump();
      expect(
        container.read(editorNotifierProvider).panOffset,
        const Offset(35, 35),
      );

      final right = await tester.startGesture(
        center,
        kind: ui.PointerDeviceKind.mouse,
        buttons: kSecondaryButton,
      );
      await right.moveBy(const Offset(60, 50));
      await right.up();
      await tester.pump();

      final state = container.read(editorNotifierProvider);
      expect(state.panOffset, const Offset(35, 35));
      expect(state.activeMap, same(_activeMap));
      expect(state.isDirty, isFalse);
      expect(state.mapUndoStack, isEmpty);
    });

    testWidgets(
      'secondary click emits one typed request after selecting its cell',
      (tester) async {
        final container = _createContainer();
        container.read(editorNotifierProvider.notifier).state =
            const EditorState(
          project: _project,
          activeMap: _activeMap,
          activeLayerId: 'ground',
          savedMapSnapshot: _activeMap,
        );
        final calls = <String>[];
        final requests = <MapCanvasContextMenuRequest>[];

        await _pumpCanvas(
          tester,
          container,
          onCellSelected: (cell) => calls.add('cell:$cell'),
          onContextMenuRequested: (request) {
            calls.add('menu:${request.gridPosition}');
            requests.add(request);
          },
        );
        final canvas = find.byType(MapCanvas);
        final origin = tester.getTopLeft(canvas);
        final gesture = await tester.startGesture(
          origin + const Offset(16, 16),
          kind: ui.PointerDeviceKind.mouse,
          buttons: kSecondaryButton,
        );
        await gesture.moveBy(const Offset(80, 60));
        await gesture.up();
        await tester.pump();

        expect(requests, hasLength(1));
        expect(
          requests.single.invocation,
          MapContextMenuInvocation.pointer,
        );
        expect(requests.single.gridPosition, const GridPos(x: 0, y: 0));
        expect(requests.single.globalPosition, origin + const Offset(16, 16));
        expect(
          calls,
          const <String>[
            'cell:GridPos(x: 0, y: 0)',
            'menu:GridPos(x: 0, y: 0)'
          ],
        );
      },
    );

    testWidgets('Menu and Shift+F10 emit keyboard-equivalent requests once',
        (tester) async {
      final container = _createContainer();
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: _project,
        activeMap: _activeMap,
        activeLayerId: 'ground',
        savedMapSnapshot: _activeMap,
      );
      final requests = <MapCanvasContextMenuRequest>[];

      await _pumpCanvas(
        tester,
        container,
        keyboardContextCell: const GridPos(x: 1, y: 1),
        onContextMenuRequested: requests.add,
      );
      await tester.tap(find.byType(MapCanvas));
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.contextMenu);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.contextMenu);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.contextMenu);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.f10);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.f10);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();

      expect(requests, hasLength(2));
      expect(
        requests.map((request) => request.invocation),
        everyElement(MapContextMenuInvocation.keyboard),
      );
      expect(
        requests.map((request) => request.gridPosition),
        everyElement(const GridPos(x: 1, y: 1)),
      );
      final canvas = tester.getRect(find.byType(MapCanvas));
      expect(
        requests.every((request) => canvas.contains(request.globalPosition)),
        isTrue,
      );
    });

    testWidgets('keyboard context prefers the selected object anchor',
        (tester) async {
      final container = _createContainer();
      final map = _activeMap.copyWith(
        entities: const <MapEntity>[
          MapEntity(
            id: 'selected',
            kind: MapEntityKind.custom,
            pos: GridPos(x: 0, y: 1),
          ),
        ],
      );
      container.read(editorNotifierProvider.notifier).state = EditorState(
        project: _project,
        activeMap: map,
        activeLayerId: 'ground',
        selectedEntityId: 'selected',
        savedMapSnapshot: map,
      );
      final requests = <MapCanvasContextMenuRequest>[];

      await _pumpCanvas(
        tester,
        container,
        keyboardContextCell: const GridPos(x: 1, y: 0),
        onContextMenuRequested: requests.add,
      );
      final focusGesture = await tester.startGesture(
        tester.getCenter(find.byType(MapCanvas)),
        kind: ui.PointerDeviceKind.mouse,
        buttons: kSecondaryButton,
      );
      await focusGesture.up();
      requests.clear();

      await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
      await tester.pump();

      expect(requests.single.gridPosition, const GridPos(x: 0, y: 1));
      expect(
        requests.single.invocation,
        MapContextMenuInvocation.keyboard,
      );
    });

    testWidgets('keyboard context has a deterministic in-map fallback',
        (tester) async {
      final container = _createContainer();
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: _project,
        activeMap: _activeMap,
        activeLayerId: 'ground',
        savedMapSnapshot: _activeMap,
        panOffset: Offset(-500, -400),
      );
      final requests = <MapCanvasContextMenuRequest>[];

      await _pumpCanvas(
        tester,
        container,
        onContextMenuRequested: requests.add,
      );
      final focusGesture = await tester.startGesture(
        tester.getCenter(find.byType(MapCanvas)),
        kind: ui.PointerDeviceKind.mouse,
        buttons: kSecondaryButton,
      );
      await focusGesture.up();
      requests.clear();

      await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
      await tester.pump();

      expect(requests, hasLength(1));
      expect(requests.single.gridPosition.x, inInclusiveRange(0, 1));
      expect(requests.single.gridPosition.y, inInclusiveRange(0, 1));
      expect(
        tester
            .getRect(find.byType(MapCanvas))
            .contains(requests.single.globalPosition),
        isTrue,
      );
    });

    testWidgets('F fits the complete map after the canvas takes focus',
        (tester) async {
      final container = _createContainer();
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: _project,
        activeMap: _activeMap,
        activeLayerId: 'ground',
        savedMapSnapshot: _activeMap,
        panOffset: Offset(180, -90),
        zoom: 3,
      );

      await _pumpCanvas(tester, container);
      final canvas = find.byType(MapCanvas);
      final focusGesture = await tester.startGesture(
        tester.getCenter(canvas),
        kind: ui.PointerDeviceKind.mouse,
        buttons: kSecondaryButton,
      );
      await focusGesture.up();
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      try {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.keyF);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.keyF);
        await tester.pump();
      } finally {
        await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      }
      var state = container.read(editorNotifierProvider);
      expect(state.zoom, 3);
      expect(state.panOffset, const Offset(180, -90));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyF);
      await tester.pump();

      final settings = _project.settings;
      final expected = MapViewportNavigation.fitMap(
        mapPixelSize: Size(
          _activeMap.size.width * settings.tileWidth * settings.displayScale,
          _activeMap.size.height * settings.tileHeight * settings.displayScale,
        ),
        viewportSize: tester.getSize(canvas),
      );
      state = container.read(editorNotifierProvider);
      expect(state.zoom, closeTo(expected.zoom, 0.000001));
      expect(state.panOffset.dx, closeTo(expected.panOffset.dx, 0.000001));
      expect(state.panOffset.dy, closeTo(expected.panOffset.dy, 0.000001));
      expect(state.isDirty, isFalse);
    });

    testWidgets('F is inert until the canvas owns keyboard focus',
        (tester) async {
      final container = _createContainer();
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: _project,
        activeMap: _activeMap,
        activeLayerId: 'ground',
        savedMapSnapshot: _activeMap,
        panOffset: Offset(180, -90),
        zoom: 3,
      );

      await _pumpCanvas(tester, container);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyF);
      await tester.pump();

      final state = container.read(editorNotifierProvider);
      expect(state.zoom, 3);
      expect(state.panOffset, const Offset(180, -90));
    });

    testWidgets('overlay exposes fit, 100 percent, and center controls',
        (tester) async {
      final container = _createContainer();
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: _project,
        activeMap: _activeMap,
        activeLayerId: 'ground',
        savedMapSnapshot: _activeMap,
        panOffset: Offset(-300, -100),
        zoom: 2,
      );

      await _pumpCanvas(tester, container);

      expect(find.byKey(const ValueKey('map-navigation-fit')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('map-navigation-actual-size')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('map-navigation-center')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('map-navigation-zoom-out')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('map-navigation-zoom-in')),
        findsOneWidget,
      );
      expect(find.text('200 %'), findsOneWidget);

      final canvasSize = tester.getSize(find.byType(MapCanvas));
      const initialViewport = MapViewport(
        zoom: 2,
        panOffset: Offset(-300, -100),
      );
      final expectedZoomOut = MapViewportNavigation.zoomAt(
        viewport: initialViewport,
        focalPoint: canvasSize.center(Offset.zero),
        targetZoom: 2 / 1.2,
      );
      await tester.tap(find.byKey(const ValueKey('map-navigation-zoom-out')));
      await tester.pump();
      var state = container.read(editorNotifierProvider);
      expect(state.zoom, closeTo(expectedZoomOut.zoom, 0.000001));
      expect(
        state.panOffset.dx,
        closeTo(expectedZoomOut.panOffset.dx, 0.000001),
      );
      expect(
        state.panOffset.dy,
        closeTo(expectedZoomOut.panOffset.dy, 0.000001),
      );

      await tester.tap(find.byKey(const ValueKey('map-navigation-zoom-in')));
      await tester.pump();
      state = container.read(editorNotifierProvider);
      expect(state.zoom, closeTo(2, 0.000001));

      container.read(editorNotifierProvider.notifier).state =
          state.copyWith(panOffset: const Offset(200, -150), zoom: 3);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('map-navigation-fit')));
      await tester.pump();
      final settings = _project.settings;
      final mapPixelSize = Size(
        _activeMap.size.width * settings.tileWidth * settings.displayScale,
        _activeMap.size.height * settings.tileHeight * settings.displayScale,
      );
      final expectedFit = MapViewportNavigation.fitMap(
        mapPixelSize: mapPixelSize,
        viewportSize: canvasSize,
      );
      state = container.read(editorNotifierProvider);
      expect(state.zoom, closeTo(expectedFit.zoom, 0.000001));
      expect(state.panOffset.dx, closeTo(expectedFit.panOffset.dx, 0.000001));
      expect(state.panOffset.dy, closeTo(expectedFit.panOffset.dy, 0.000001));

      container.read(editorNotifierProvider.notifier).state = state.copyWith(
        panOffset: initialViewport.panOffset,
        zoom: initialViewport.zoom,
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('map-navigation-actual-size')),
      );
      await tester.pump();
      state = container.read(editorNotifierProvider);
      expect(state.zoom, 1);
      expect(state.activeMap, same(_activeMap));
      expect(state.isDirty, isFalse);

      container.read(editorNotifierProvider.notifier).state =
          state.copyWith(panOffset: const Offset(400, -200), zoom: 2);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('map-navigation-center')));
      await tester.pump();

      final expected = MapViewportNavigation.centerMap(
        mapPixelSize: mapPixelSize,
        viewportSize: canvasSize,
        zoom: 2,
      );
      state = container.read(editorNotifierProvider);
      expect(state.panOffset.dx, closeTo(expected.panOffset.dx, 0.000001));
      expect(state.panOffset.dy, closeTo(expected.panOffset.dy, 0.000001));
      expect(state.mapUndoStack, isEmpty);

      tester.binding.handlePointerEvent(
        PointerScrollEvent(
          position: tester.getCenter(find.byType(MapCanvas)),
          kind: ui.PointerDeviceKind.mouse,
          scrollDelta: const Offset(3, 4),
        ),
      );
      await tester.pump();
      state = container.read(editorNotifierProvider);
      expect(
        state.panOffset.dx,
        closeTo(expected.panOffset.dx - 3, 0.000001),
      );
      expect(
        state.panOffset.dy,
        closeTo(expected.panOffset.dy - 4, 0.000001),
      );
    });

    testWidgets(
        'Tab reaches the canvas before showing navigation control focus',
        (tester) async {
      final container = _createContainer();
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: _project,
        activeMap: _activeMap,
        activeLayerId: 'ground',
        savedMapSnapshot: _activeMap,
      );

      await _pumpCanvas(tester, container);

      final canvasFocus = tester.widget<Focus>(
        find.byKey(const ValueKey<String>('map-canvas-focus')),
      );
      expect(canvasFocus.skipTraversal, isFalse);
      expect(canvasFocus.includeSemantics, isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(canvasFocus.focusNode!.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      const zoomOutKey = ValueKey<String>('map-navigation-zoom-out');
      expect(_hasPrimaryFocusWithin(tester, zoomOutKey), isTrue);
      expect(_focusRingFor(tester, zoomOutKey), isNotEmpty);
      expect(canvasFocus.focusNode!.hasFocus, isFalse);
    });

    testWidgets(
        'keyboard navigation actions retain visible focus and Tab advances',
        (tester) async {
      final container = _createContainer();
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: _project,
        activeMap: _activeMap,
        activeLayerId: 'ground',
        savedMapSnapshot: _activeMap,
        panOffset: Offset(-300, -100),
        zoom: 2,
      );

      await _pumpCanvas(tester, container);

      const zoomOutKey = ValueKey<String>('map-navigation-zoom-out');
      const zoomInKey = ValueKey<String>('map-navigation-zoom-in');
      const fitKey = ValueKey<String>('map-navigation-fit');
      const actualSizeKey = ValueKey<String>('map-navigation-actual-size');
      const centerKey = ValueKey<String>('map-navigation-center');

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        tester
            .widget<Focus>(
              find.byKey(const ValueKey<String>('map-canvas-focus')),
            )
            .focusNode!
            .hasFocus,
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_hasPrimaryFocusWithin(tester, zoomOutKey), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(container.read(editorNotifierProvider).zoom, lessThan(2));
      expect(_hasPrimaryFocusWithin(tester, zoomOutKey), isTrue);
      expect(_focusRingFor(tester, zoomOutKey), isNotEmpty);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_hasPrimaryFocusWithin(tester, zoomInKey), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(container.read(editorNotifierProvider).zoom, closeTo(2, 0.000001));
      expect(_hasPrimaryFocusWithin(tester, zoomInKey), isTrue);
      expect(_focusRingFor(tester, zoomInKey), isNotEmpty);

      var state = container.read(editorNotifierProvider);
      container.read(editorNotifierProvider.notifier).state =
          state.copyWith(panOffset: const Offset(200, -150), zoom: 3);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_hasPrimaryFocusWithin(tester, fitKey), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      state = container.read(editorNotifierProvider);
      expect(state.zoom, isNot(3));
      expect(state.panOffset, isNot(const Offset(200, -150)));
      expect(_hasPrimaryFocusWithin(tester, fitKey), isTrue);

      container.read(editorNotifierProvider.notifier).state =
          state.copyWith(panOffset: const Offset(-80, 45), zoom: 2);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_hasPrimaryFocusWithin(tester, actualSizeKey), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      state = container.read(editorNotifierProvider);
      expect(state.zoom, 1);
      expect(_hasPrimaryFocusWithin(tester, actualSizeKey), isTrue);

      container.read(editorNotifierProvider.notifier).state =
          state.copyWith(panOffset: const Offset(400, -200), zoom: 2);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_hasPrimaryFocusWithin(tester, centerKey), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      state = container.read(editorNotifierProvider);
      expect(state.panOffset, isNot(const Offset(400, -200)));
      expect(_hasPrimaryFocusWithin(tester, centerKey), isTrue);
      expect(_focusRingFor(tester, centerKey), isNotEmpty);
    });

    testWidgets('pointer navigation returns focus to the canvas for F',
        (tester) async {
      final container = _createContainer();
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: _project,
        activeMap: _activeMap,
        activeLayerId: 'ground',
        savedMapSnapshot: _activeMap,
        panOffset: Offset(-300, -100),
        zoom: 2,
      );

      await _pumpCanvas(tester, container);

      await tester.tap(
        find.byKey(const ValueKey<String>('map-navigation-zoom-out')),
      );
      await tester.pump();
      final canvasFocus = tester.widget<Focus>(
        find.byKey(const ValueKey<String>('map-canvas-focus')),
      );
      expect(canvasFocus.focusNode!.hasFocus, isTrue);

      final state = container.read(editorNotifierProvider);
      container.read(editorNotifierProvider.notifier).state =
          state.copyWith(panOffset: const Offset(250, -175), zoom: 3);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.pump();

      final settings = _project.settings;
      final expected = MapViewportNavigation.fitMap(
        mapPixelSize: Size(
          _activeMap.size.width * settings.tileWidth * settings.displayScale,
          _activeMap.size.height * settings.tileHeight * settings.displayScale,
        ),
        viewportSize: tester.getSize(find.byType(MapCanvas)),
      );
      final fitted = container.read(editorNotifierProvider);
      expect(fitted.zoom, closeTo(expected.zoom, 0.000001));
      expect(fitted.panOffset.dx, closeTo(expected.panOffset.dx, 0.000001));
      expect(fitted.panOffset.dy, closeTo(expected.panOffset.dy, 0.000001));
    });

    testWidgets('navigation controls are absent without an active map',
        (tester) async {
      final container = _createContainer();
      container.read(editorNotifierProvider.notifier).state =
          const EditorState(project: _project);

      await _pumpCanvas(tester, container);

      expect(
        find.byKey(const ValueKey('map-navigation-zoom-out')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('map-navigation-zoom-in')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('map-navigation-fit')), findsNothing);
    });
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
  ProviderContainer container, {
  EdgeInsets canvasPadding = EdgeInsets.zero,
  MapCanvasContextMenuRequested? onContextMenuRequested,
  ValueChanged<GridPos?>? onCellSelected,
  GridPos? keyboardContextCell,
}) async {
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
        child: MaterialApp(
          home: CupertinoPageScaffold(
            child: Padding(
              padding: canvasPadding,
              child: SizedBox.expand(
                child: MapCanvas(
                  onContextMenuRequested: onContextMenuRequested,
                  onCellSelected: onCellSelected,
                  keyboardContextCell: keyboardContextCell,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

bool _hasPrimaryFocusWithin(WidgetTester tester, Key key) {
  final ancestor = tester.element(find.byKey(key));
  final focusContext = FocusManager.instance.primaryFocus?.context;
  if (focusContext == null) return false;
  if (identical(focusContext, ancestor)) return true;

  var isWithin = false;
  focusContext.visitAncestorElements((element) {
    if (identical(element, ancestor)) {
      isWithin = true;
      return false;
    }
    return true;
  });
  return isWithin;
}

List<BoxShadow> _focusRingFor(WidgetTester tester, Key key) {
  final animatedContainer = find.descendant(
    of: find.byKey(key),
    matching: find.byType(AnimatedContainer),
  );
  expect(animatedContainer, findsOneWidget);
  final widget = tester.widget<AnimatedContainer>(animatedContainer);
  final decoration = widget.decoration! as BoxDecoration;
  return decoration.boxShadow ?? const <BoxShadow>[];
}

const _project = ProjectManifest(
  name: 'pointer_navigation_project',
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[],
);

const _activeMap = MapData(
  id: 'map',
  name: 'Map',
  size: GridSize(width: 2, height: 2),
  layers: <MapLayer>[
    TileLayer(
      id: 'ground',
      name: 'Ground',
      cells: <int>[0, 0, 0, 0],
    ),
  ],
);
