import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_selection_harness.dart';
import '../support/map_workspace_fixture.dart';
import '../support/map_host_fixture.dart';
import '../support/m2_ui_fixture.dart' show pumpIo;

void main() {
  MapSelectionHarness fixture() {
    final h = MapSelectionHarness.of(workspaceProject);
    final id = MapEditingCommands(
      h.document,
      h.project,
    ).place(workspaceElement, const GridPos(x: 4, y: 4))!;
    h.view.select(h.document, MapSelectionFamily.decor, id);
    addTearDown(h.dispose);
    return h;
  }

  Offset point(WidgetTester tester, Offset pixels) => tester
      .renderObject<RenderBox>(find.byKey(const ValueKey('map-canvas')))
      .localToGlobal(
        pixels * workspaceProject.settings.displayScale.toDouble(),
      );

  testWidgets(
    'pixel selection finds a tiny offset decor and text focus leaves it unchanged',
    (tester) async {
      final h = fixture();
      final id = h.document.selectedId!;
      MapEditingCommands(h.document, h.project).setGeometry(
        id,
        x: 79,
        y: 79,
        size: const PixelSize(width: 1, height: 1),
      );
      h.view.clearSelection(h.document);
      await h.pump(tester);
      await tester.tapAt(point(tester, const Offset(79.5, 79.5)));
      await tester.pumpAndSettle();
      expect(h.document.selectedId, id);
      final field = find.descendant(
        of: find.byKey(const ValueKey('decor-geometry-x')),
        matching: find.byType(EditableText),
      );
      await tester.ensureVisible(field);
      await tester.tap(field);
      await tester.pump();
      final count = h.document.undoCount;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(h.document.undoCount, count);
      expect(h.document.selected!.pixelOffset, const PixelOffset(x: 15, y: 15));
    },
  );

  testWidgets(
    'inspector transform saves and reloads through the real workspace adapter',
    (tester) async {
      final f = await MapHostFixture.open(tester);
      await tester.tap(find.byKey(const ValueKey('decor-arbre')));
      await f.tapCell(8, 7);
      final id = f.document.selectedId!;
      for (final input in [('x', '129'), ('y', '113'), ('width', '37')]) {
        final field = find.descendant(
          of: find.byKey(ValueKey('decor-geometry-${input.$1}')),
          matching: find.byType(EditableText),
        );
        await tester.ensureVisible(field);
        await tester.enterText(field, input.$2);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
      }
      final expected = f.document.selected!;
      expect(expected.pixelOffset, const PixelOffset(x: 1, y: 1));
      expect(expected.pixelSize!.width, 37);
      await tester.tap(find.byKey(const ValueKey('Enregistrer')));
      for (var i = 0; i < 60 && f.document.dirty; i++) {
        await pumpIo(tester, frames: 3);
      }
      expect(f.document.dirty, isFalse, reason: f.document.error);
      final reopened = (await tester.runAsync(() async {
        final adapter = LocalMapWorkspaceAdapter();
        final project = await adapter.loadProject(f.source.session);
        return adapter.loadMap(
          f.source.session,
          project.maps.firstWhere((entry) => entry.id == f.document.current.id),
        );
      }))!;
      expect(
        reopened.map.placedElements.firstWhere((e) => e.id == id),
        expected,
      );
    },
  );

  testWidgets('new decor is authored and Shift drag commits one pixel once', (
    tester,
  ) async {
    final h = fixture();
    expect(isAuthoredMapPlacedElement(h.document.selected!), isTrue);
    await h.pump(tester);
    final before = h.document.current;
    final count = h.document.undoCount;
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    final gesture = await tester.startGesture(
      point(tester, const Offset(75, 75)),
    );
    await gesture.moveTo(point(tester, const Offset(76, 77)));
    await tester.pump();
    expect(identical(h.document.current, before), isTrue);
    await gesture.up();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    expect(h.document.selected!.pixelOffset, const PixelOffset(x: 1, y: 2));
    expect(h.document.undoCount, count + 1);
    h.document.restore(redo: false);
    expect(h.document.current, before);
  });

  testWidgets(
    'right handle stretches only width and Shift repeat is one undo',
    (tester) async {
      final h = fixture();
      await h.pump(tester);
      final right = find.byKey(const ValueKey('decor-handle-right'));
      expect(right, findsOneWidget);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      final gesture = await tester.startGesture(tester.getCenter(right));
      await gesture.moveBy(const Offset(6, 18));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        h.document.selected!.pixelSize,
        const PixelSize(width: 35, height: 32),
      );
      final count = h.document.undoCount;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
      expect(h.document.undoCount, count);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(h.document.selected!.pixelOffset.x, 3);
      expect(h.document.undoCount, count + 1);
    },
  );

  testWidgets(
    'inspector accepts integer instance geometry and resets natural size',
    (tester) async {
      final h = fixture();
      await h.pump(tester);
      final field = find.descendant(
        of: find.byKey(const ValueKey('decor-geometry-width')),
        matching: find.byType(EditableText),
      );
      await tester.ensureVisible(field);
      await tester.enterText(field, '7');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(
        h.document.selected!.pixelSize,
        const PixelSize(width: 7, height: 32),
      );
      final reset = find.byKey(const ValueKey('decor-natural-size'));
      await tester.ensureVisible(reset);
      await tester.tap(reset);
      await tester.pumpAndSettle();
      expect(h.document.selected!.pixelSize, isNull);
    },
  );

  for (final zoom in [.5, 1.0, 1.5, 2.0, 3.0]) {
    testWidgets(
      'Shift rebases without a jump at zoom $zoom and grid keeps residue',
      (tester) async {
        final h = fixture();
        await h.pump(tester);
        h.view.transform.value = Matrix4.identity()
          ..scaleByDouble(zoom, zoom, 1, 1);
        await tester.pump();
        final gesture = await tester.startGesture(
          point(tester, const Offset(75, 75)),
        );
        await gesture.moveTo(point(tester, const Offset(91, 75)));
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await gesture.moveTo(point(tester, const Offset(92, 75)));
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await gesture.moveTo(point(tester, const Offset(108, 75)));
        await gesture.up();
        await tester.pumpAndSettle();
        expect(h.document.selected!.pos, const GridPos(x: 6, y: 4));
        expect(h.document.selected!.pixelOffset, const PixelOffset(x: 1, y: 0));
      },
    );
  }

  testWidgets(
    'corners preserve the initial ratio across Shift changes and sides clamp at one',
    (tester) async {
      final h = fixture();
      h.view.lockDecorProportions = true;
      await h.pump(tester);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      final corner = await tester.startGesture(
        tester.getCenter(
          find.byKey(const ValueKey('decor-handle-bottomRight')),
        ),
      );
      await corner.moveBy(const Offset(6, 12));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await corner.moveBy(const Offset(32, 0));
      await corner.up();
      await tester.pumpAndSettle();
      expect(
        h.document.selected!.pixelSize,
        const PixelSize(width: 54, height: 54),
      );
      final anchor = h.document.selected!.pos;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      final left = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('decor-handle-left'))),
      );
      await left.moveBy(const Offset(200, 18));
      await left.up();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(
        h.document.selected!.pixelSize,
        const PixelSize(width: 1, height: 54),
      );
      expect(h.document.selected!.pos.y, anchor.y);
      expect(
        h.document.selected!.pos.x * 16 + h.document.selected!.pixelOffset.x,
        117,
      );
    },
  );

  testWidgets(
    'Escape, tool change, source change and focus loss cancel without history',
    (tester) async {
      final h = fixture();
      await h.pump(tester);
      final before = h.document.current;
      final count = h.document.undoCount;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      final gesture = await tester.startGesture(
        point(tester, const Offset(75, 75)),
      );
      await gesture.moveBy(const Offset(4, 4));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(h.document.current, before);
      final toolGesture = await tester.startGesture(
        point(tester, const Offset(75, 75)),
      );
      await toolGesture.moveBy(const Offset(4, 4));
      await h.use(tester, StudioMapTool.pan);
      await toolGesture.up();
      expect(h.document.current, before);
      await h.use(tester, StudioMapTool.select);
      final staleGesture = await tester.startGesture(
        point(tester, const Offset(75, 75)),
      );
      await staleGesture.moveBy(const Offset(4, 4));
      h.document.current = before.copyWith(name: 'Concurrent');
      h.redraw();
      await tester.pump();
      await staleGesture.up();
      expect(h.document.selected!.pixelOffset, const PixelOffset(x: 0, y: 0));
      await tester.tapAt(point(tester, const Offset(75, 75)));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      final field = find.descendant(
        of: find.byKey(const ValueKey('decor-geometry-x')),
        matching: find.byType(EditableText),
      );
      await tester.ensureVisible(field);
      await tester.tap(field);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(h.document.selected!.pixelOffset, const PixelOffset(x: 0, y: 0));
      expect(h.document.undoCount, count);
    },
  );

  testWidgets(
    'invalid inspector dimensions preserve state and snap preserves custom size',
    (tester) async {
      final h = fixture();
      final commands = MapEditingCommands(h.document, h.project);
      commands.setGeometry(
        h.document.selectedId!,
        x: 73,
        y: 69,
        size: const PixelSize(width: 7, height: 9),
      );
      await h.pump(tester);
      final before = h.document.current;
      final count = h.document.undoCount;
      final field = find.descendant(
        of: find.byKey(const ValueKey('decor-geometry-width')),
        matching: find.byType(EditableText),
      );
      await tester.ensureVisible(field);
      for (final text in ['0', '1.5', '1048577']) {
        await tester.enterText(field, text);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(h.document.current, before);
        expect(h.document.undoCount, count);
      }
      final snap = find.byKey(const ValueKey('decor-snap-grid'));
      await tester.ensureVisible(snap);
      await tester.tap(snap);
      await tester.pumpAndSettle();
      expect(h.document.selected!.pixelOffset, const PixelOffset(x: 0, y: 0));
      expect(h.document.selected!.pos, const GridPos(x: 5, y: 4));
      expect(
        h.document.selected!.pixelSize,
        const PixelSize(width: 7, height: 9),
      );
    },
  );

  testWidgets(
    'guided detach is undoable and Environment ownership disables transforms',
    (tester) async {
      final h = fixture();
      h.document.current = h.document.current.copyWith(
        placedElements: [h.document.selected!.copyWith(properties: {})],
      );
      await h.pump(tester);
      expect(find.byKey(const ValueKey('decor-handle-right')), findsNothing);
      final detach = find.byKey(const ValueKey('decor-detach'));
      await tester.ensureVisible(detach);
      await tester.pumpAndSettle();
      await tester.tap(detach);
      await tester.pumpAndSettle();
      expect(isAuthoredMapPlacedElement(h.document.selected!), isTrue);
      expect(find.byKey(const ValueKey('decor-handle-right')), findsOneWidget);
      h.document.restore(redo: false);
      expect(isAuthoredMapPlacedElement(h.document.selected!), isFalse);
      h.document.current = h.document.current.copyWith(
        layers: [
          ...h.document.current.layers,
          MapLayer.environment(
            id: 'env',
            name: 'Environment',
            isVisible: false,
            content: EnvironmentLayerContent(
              targetTileLayerId: 'ground',
              areas: [
                EnvironmentArea(
                  id: 'area',
                  name: 'Area',
                  presetId: 'preset',
                  seed: 1,
                  mask: EnvironmentAreaMask(
                    width: 20,
                    height: 16,
                    cells: List.filled(320, false),
                  ),
                  generatedPlacementIds: [h.document.selectedId!],
                ),
              ],
            ),
          ),
        ],
      );
      h.redraw();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('decor-detach')), findsNothing);
      expect(find.byKey(const ValueKey('decor-handle-right')), findsNothing);
      expect(find.textContaining('piloté par une zone'), findsOneWidget);
    },
  );
}
