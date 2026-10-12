import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_canvas.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  for (final tool in [
    StudioMapTool.select,
    StudioMapTool.place,
    StudioMapTool.terrain,
    StudioMapTool.eraseDecor,
  ]) {
    testWidgets('right drag over a decor pans safely with ${tool.name}', (
      tester,
    ) async {
      final fixture = await mountCanvas(tester, tool);
      final box = tester.renderObject<RenderBox>(
        find.byKey(const ValueKey('map-canvas')),
      );
      final start = box.localToGlobal(const Offset(80, 80));
      final before = Matrix4.copy(fixture.view.transform.value);
      final pointer = TestPointer(91, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(
        pointer.down(start, buttons: kSecondaryMouseButton),
      );
      expect(fixture.contexts, isEmpty);
      await tester.sendEventToBinding(
        pointer.move(
          start + const Offset(48, 32),
          buttons: kSecondaryMouseButton,
        ),
      );
      await tester.sendEventToBinding(pointer.up());
      await tester.pump();
      expect(fixture.view.transform.value.storage[12], before.storage[12] + 48);
      expect(fixture.view.transform.value.storage[13], before.storage[13] + 32);
      expect(fixture.document.current, fixture.original);
      expect(fixture.document.undoCount, 0);
      expect(fixture.document.dirty, isFalse);
      expect(fixture.contexts, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('a stationary right click opens its context on release', (
    tester,
  ) async {
    final fixture = await mountCanvas(tester, StudioMapTool.select);
    final box = tester.renderObject<RenderBox>(
      find.byKey(const ValueKey('map-canvas')),
    );
    final start = box.localToGlobal(const Offset(80, 80));
    final before = Matrix4.copy(fixture.view.transform.value);
    final pointer = TestPointer(92, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(
      pointer.down(start, buttons: kSecondaryMouseButton),
    );
    expect(fixture.contexts, isEmpty);
    await tester.sendEventToBinding(pointer.up());
    expect(fixture.contexts, [const GridPos(x: 2, y: 2)]);
    expect(fixture.view.transform.value, before);
    expect(fixture.document.current, fixture.original);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'right navigation takes over a primary decor drag without saving it',
    (tester) async {
      final fixture = await mountCanvas(tester, StudioMapTool.select);
      final box = tester.renderObject<RenderBox>(
        find.byKey(const ValueKey('map-canvas')),
      );
      final start = box.localToGlobal(const Offset(80, 80));
      final pointer = TestPointer(94, PointerDeviceKind.mouse);
      final before = Matrix4.copy(fixture.view.transform.value);
      await tester.sendEventToBinding(pointer.down(start));
      await tester.sendEventToBinding(
        pointer.move(start + const Offset(16, 0)),
      );
      await tester.sendEventToBinding(
        pointer.move(
          start + const Offset(48, 32),
          buttons: kPrimaryButton | kSecondaryMouseButton,
        ),
      );
      final moved = Matrix4.copy(fixture.view.transform.value);
      await tester.sendEventToBinding(
        pointer.move(start + const Offset(80, 64), buttons: kPrimaryButton),
      );
      await tester.sendEventToBinding(pointer.up());
      await tester.pump();
      expect(moved.storage[12], before.storage[12] + 32);
      expect(moved.storage[13], before.storage[13] + 32);
      expect(fixture.view.transform.value, moved);
      expect(fixture.document.current, fixture.original);
      expect(fixture.document.undoCount, 0);
      expect(fixture.document.dirty, isFalse);
      expect(fixture.contexts, isEmpty);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'cancelling right navigation leaves primary decor editing usable',
    (tester) async {
      final fixture = await mountCanvas(tester, StudioMapTool.select);
      final box = tester.renderObject<RenderBox>(
        find.byKey(const ValueKey('map-canvas')),
      );
      final start = box.localToGlobal(const Offset(80, 80));
      final pointer = TestPointer(93, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(
        pointer.down(start, buttons: kSecondaryMouseButton),
      );
      await tester.sendEventToBinding(pointer.cancel());
      final primary = await tester.startGesture(
        start,
        kind: PointerDeviceKind.mouse,
      );
      await primary.moveBy(const Offset(32, 0));
      await primary.up();
      await tester.pump();
      expect(fixture.contexts, isEmpty);
      expect(
        fixture.document.current.placedElements.single.pos,
        const GridPos(x: 3, y: 2),
      );
      expect(fixture.document.undoCount, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

Future<
  ({
    EditableMapDocument document,
    MapWorkspaceViewState view,
    MapData original,
    List<GridPos> contexts,
  })
>
mountCanvas(WidgetTester tester, StudioMapTool tool) async {
  tester.view.physicalSize = const Size(900, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final original = workspaceMap('a').copyWith(
    placedElements: const [
      MapPlacedElement(
        id: 'tree-1',
        layerId: 'ground',
        elementId: 'tree',
        pos: GridPos(x: 2, y: 2),
      ),
    ],
  );
  final document = EditableMapDocument(
    MapWorkspaceDocument(map: original, revision: 'r0', mapId: 'a'),
  );
  final view = MapWorkspaceViewState()..tool = tool;
  addTearDown(view.dispose);
  final contexts = <GridPos>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MapWorkspaceCanvas(
          document: document,
          project: workspaceProject,
          visuals: WorkspaceTestVisuals(),
          view: view,
          onChanged: () {},
          onContextMenu: (cell, _) => contexts.add(cell),
          gestureGeneration: 0,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (
    document: document,
    view: view,
    original: original,
    contexts: contexts,
  );
}
