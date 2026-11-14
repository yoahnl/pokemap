import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'decor_transform_host_owner_harness.dart';

void main() {
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

  testWidgets('Escape, tool change and source change cancel without history', (
    tester,
  ) async {
    final h = fixture();
    await h.pump(tester);
    final before = h.document.current;
    final count = h.document.undoCount;
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    final gesture = await tester.startGesture(
      point(tester, const Offset(75, 75)),
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveBy(const Offset(4, 4));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(h.document.current, before);
    final toolGesture = await tester.startGesture(
      point(tester, const Offset(75, 75)),
      kind: PointerDeviceKind.mouse,
    );
    await toolGesture.moveBy(const Offset(4, 4));
    await h.use(tester, StudioMapTool.pan);
    await toolGesture.up();
    expect(h.document.current, before);
    await h.use(tester, StudioMapTool.select);
    final staleGesture = await tester.startGesture(
      point(tester, const Offset(75, 75)),
      kind: PointerDeviceKind.mouse,
    );
    await staleGesture.moveBy(const Offset(4, 4));
    h.document.current = before.copyWith(name: 'Concurrent');
    h.redraw();
    await tester.pump();
    await staleGesture.up();
    expect(h.document.selected!.pixelOffset, const PixelOffset(x: 0, y: 0));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(h.document.undoCount, count);
  });

  test(
    'invalid geometry inputs preserve state and snapping preserves custom size',
    () {
      final h = fixture();
      final commands = MapEditingCommands(h.document, h.project);
      final id = h.document.selectedId!;
      commands.setGeometry(
        id,
        x: 73,
        y: 69,
        size: const PixelSize(width: 7, height: 9),
      );
      final before = h.document.current;
      final count = h.document.undoCount;
      for (final text in ['0', '1.5', '1048577']) {
        expect(
          commands.setGeometryText(id, 'width', text, lockProportions: false),
          isFalse,
        );
        expect(h.document.current, before);
        expect(h.document.undoCount, count);
      }
      expect(commands.snapGeometryToGrid(id), isTrue);
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
      MapEditingCommands(h.document, h.project).detach(h.document.selectedId!);
      h.redraw();
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
      expect(find.byKey(const ValueKey('decor-handle-right')), findsNothing);
      final before = h.document.current;
      MapEditingCommands(h.document, h.project).detach(h.document.selectedId!);
      expect(h.document.current, same(before));
      expect(h.document.error, contains('zone d’environnement'));
    },
  );
}
