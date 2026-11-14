import 'dart:io';

import 'map_catalog_fixture.dart';

import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'decor_transform_host_owner_harness.dart';

void main() {
  testWidgets('pixel selection finds a tiny offset decor', (tester) async {
    final h = fixture();
    final id = h.document.selectedId!;
    MapEditingCommands(
      h.document,
      h.project,
    ).setGeometry(id, x: 79, y: 79, size: const PixelSize(width: 1, height: 1));
    h.view.clearSelection(h.document);
    await h.pump(tester);
    await tester.tapAt(point(tester, const Offset(79.5, 79.5)));
    await tester.pumpAndSettle();
    expect(h.document.selectedId, id);
    expect(h.document.selected!.pixelOffset, const PixelOffset(x: 15, y: 15));
  });

  test(
    'geometry inputs save and reload through the real workspace adapter',
    () async {
      final parent = Directory.systemTemp;
      await parent.create(recursive: true);
      final fixture = await MapCatalogFixture.create(parent: parent);
      addTearDown(fixture.dispose);
      final document = fixture.controller.active!;
      final project = fixture.controller.project!;
      final commands = MapEditingCommands(document, project);
      final id = commands.place(
        project.elements.first,
        const GridPos(x: 8, y: 7),
      )!;
      for (final input in [('x', '129'), ('y', '113'), ('width', '37')]) {
        expect(
          commands.setGeometryText(
            id,
            input.$1,
            input.$2,
            lockProportions: false,
          ),
          isTrue,
        );
      }
      final expected = document.selected!;
      expect(expected.pixelOffset, const PixelOffset(x: 1, y: 1));
      expect(expected.pixelSize!.width, 37);
      expect(await fixture.controller.save(document), isTrue);
      final adapter = LocalMapWorkspaceAdapter();
      final reopenedProject = await adapter.loadProject(fixture.session);
      final reopened = await adapter.loadMap(
        fixture.session,
        reopenedProject.maps.singleWhere(
          (entry) => entry.id == document.current.id,
        ),
      );
      expect(
        reopened.map.placedElements.firstWhere((entry) => entry.id == id),
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
      kind: PointerDeviceKind.mouse,
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
    'Shift-click with a slight jitter toggles the decor without moving it',
    (tester) async {
      final h = fixture();
      await h.pump(tester);
      final before = h.document.current;
      final count = h.document.undoCount;
      expect(h.document.selectedId, isNotNull);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      final origin = point(tester, const Offset(75, 75));
      final gesture = await tester.startGesture(
        origin,
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveTo(origin + const Offset(1, 0));
      await gesture.up();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(h.document.current, same(before));
      expect(h.document.undoCount, count);
      expect(h.document.selectedId, isNull);
    },
  );

  testWidgets('Escape during a Shift press keeps the selection unchanged', (
    tester,
  ) async {
    final h = fixture();
    await h.pump(tester);
    final before = h.document.current;
    final count = h.document.undoCount;
    final id = h.document.selectedId;
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    final gesture = await tester.startGesture(
      point(tester, const Offset(75, 75)),
      kind: PointerDeviceKind.mouse,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await gesture.up();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    expect(h.document.current, same(before));
    expect(h.document.undoCount, count);
    expect(h.document.selectedId, id);
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

  test('geometry inputs accept integers and natural size can be restored', () {
    final h = fixture();
    final commands = MapEditingCommands(h.document, h.project);
    final id = h.document.selectedId!;
    expect(
      commands.setGeometryText(id, 'width', '7', lockProportions: false),
      isTrue,
    );
    expect(
      h.document.selected!.pixelSize,
      const PixelSize(width: 7, height: 32),
    );
    expect(commands.setGeometry(id, x: 64, y: 64, size: null), isTrue);
    expect(h.document.selected!.pixelSize, isNull);
  });
}
