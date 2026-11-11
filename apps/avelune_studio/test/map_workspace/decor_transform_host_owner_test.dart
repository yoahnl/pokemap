import 'dart:io';

import 'map_catalog_fixture.dart';

import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_selection_owner_fixture.dart';
import '../support/map_workspace_fixture.dart';

void main() {
  MapSelectionOwnerHarness fixture() {
    final h = MapSelectionOwnerHarness.of(workspaceProject);
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
