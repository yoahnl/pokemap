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
  testWidgets('selection drags empty map space to pan without editing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final map = workspaceMap('a').copyWith(
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
      MapWorkspaceDocument(map: map, revision: 'r0', mapId: 'a'),
    );
    final view = MapWorkspaceViewState()..tool = StudioMapTool.select;
    addTearDown(view.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapWorkspaceCanvas(
            document: document,
            project: workspaceProject,
            visuals: WorkspaceTestVisuals(),
            view: view,
            onChanged: () {},
            gestureGeneration: 0,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final before = Matrix4.copy(view.transform.value);
    final box = tester.renderObject<RenderBox>(
      find.byKey(const ValueKey('map-canvas')),
    );
    final start = box.localToGlobal(const Offset(320, 240));
    final gesture = await tester.startGesture(
      start,
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveTo(start + const Offset(60, 40));
    await gesture.up();
    await tester.pump();

    expect(view.transform.value.storage[12], before.storage[12] + 60);
    expect(view.transform.value.storage[13], before.storage[13] + 40);
    expect(document.current.placedElements, map.placedElements);
    expect(document.dirty, isFalse);
  });

  testWidgets('selection still drags a decor without panning the map', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final map = workspaceMap('a').copyWith(
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
      MapWorkspaceDocument(map: map, revision: 'r0', mapId: 'a'),
    );
    final view = MapWorkspaceViewState()..tool = StudioMapTool.select;
    addTearDown(view.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapWorkspaceCanvas(
            document: document,
            project: workspaceProject,
            visuals: WorkspaceTestVisuals(),
            view: view,
            onChanged: () {},
            gestureGeneration: 0,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final before = Matrix4.copy(view.transform.value);
    final box = tester.renderObject<RenderBox>(
      find.byKey(const ValueKey('map-canvas')),
    );
    final start = box.localToGlobal(const Offset(80, 80));
    final gesture = await tester.startGesture(
      start,
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveTo(start + const Offset(32, 0));
    await gesture.up();
    await tester.pump();

    expect(
      document.current.placedElements.single.pos,
      const GridPos(x: 3, y: 2),
    );
    expect(view.transform.value, before);
    expect(document.undoCount, 1);
  });

  testWidgets('the map pans in an editing tool without painting', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: workspaceMap('a'), revision: 'r0', mapId: 'a'),
    );
    final view = MapWorkspaceViewState()..tool = StudioMapTool.terrain;
    addTearDown(view.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapWorkspaceCanvas(
            document: document,
            project: workspaceProject,
            visuals: WorkspaceTestVisuals(),
            view: view,
            onChanged: () {},
            gestureGeneration: 0,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final before = Matrix4.copy(view.transform.value);
    final center = tester.getCenter(find.byKey(const ValueKey('map-canvas')));
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: center,
        kind: PointerDeviceKind.trackpad,
        scrollDelta: const Offset(20, 30),
      ),
    );
    await tester.pump();
    expect(view.transform.value.storage[12], before.storage[12] - 20);
    expect(view.transform.value.storage[13], before.storage[13] - 30);

    final pointer = TestPointer(89, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(
      pointer.down(center, buttons: kMiddleMouseButton),
    );
    await tester.sendEventToBinding(
      pointer.move(center + const Offset(24, 16), buttons: kMiddleMouseButton),
    );
    await tester.sendEventToBinding(pointer.up());
    await tester.pump();
    expect(view.transform.value.storage[12], before.storage[12] + 4);
    expect(view.transform.value.storage[13], before.storage[13] - 14);
    expect(document.dirty, isFalse);
  });

  testWidgets('decor eraser removes the visible instance, not the ground', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final map = workspaceMap('a').copyWith(
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
      MapWorkspaceDocument(map: map, revision: 'r0', mapId: 'a'),
    );
    final view = MapWorkspaceViewState()..tool = StudioMapTool.eraseDecor;
    addTearDown(view.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapWorkspaceCanvas(
            document: document,
            project: workspaceProject,
            visuals: WorkspaceTestVisuals(),
            view: view,
            onChanged: () {},
            gestureGeneration: 0,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final box = tester.renderObject<RenderBox>(
      find.byKey(const ValueKey('map-canvas')),
    );
    await tester.tapAt(box.localToGlobal(const Offset(80, 80)));
    await tester.pump();
    expect(document.current.placedElements, isEmpty);
    expect(document.current.layers, map.layers);
    expect(document.undoCount, 1);
  });

  testWidgets('collision tool paints and clears cells through the canvas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: workspaceMap('a'), revision: 'r0', mapId: 'a'),
    );
    final view = MapWorkspaceViewState()..tool = StudioMapTool.collisionPaint;
    addTearDown(view.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapWorkspaceCanvas(
            document: document,
            project: workspaceProject,
            visuals: WorkspaceTestVisuals(),
            view: view,
            onChanged: () {},
            gestureGeneration: 0,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final box = tester.renderObject<RenderBox>(
      find.byKey(const ValueKey('map-canvas')),
    );
    final position = box.localToGlobal(const Offset(80, 80));
    await tester.tapAt(position);
    await tester.pump();
    var layer = document.current.layers.whereType<CollisionLayer>().single;
    expect(layer.collisions[2 * document.current.size.width + 2], isTrue);
    view.tool = StudioMapTool.collisionErase;
    await tester.tapAt(position);
    await tester.pump();
    layer = document.current.layers.whereType<CollisionLayer>().single;
    expect(layer.collisions[2 * document.current.size.width + 2], isFalse);
    expect(document.undoCount, 2);
  });
}
