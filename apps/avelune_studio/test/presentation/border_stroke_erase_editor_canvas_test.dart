import 'package:avelune_studio/platform/rendering/viewports/map_editing_viewport_2d.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import 'border_stroke_erase_editor_support.dart';

void main() {
  testWidgets(
    '2D selected local eraser previews fragments then release commits and Escape cancels',
    (tester) async {
      final host = await pumpEraseHost(tester, false);
      armErase(host);
      await tester.pump();
      final initial = host.document.current;
      final point = _at(tester, host.view, 5, 5);
      final gesture = await tester.startGesture(
        point,
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      expectSplit(host.visuals.renderedMap!);
      expect(host.document.current, same(initial));
      expect(host.document.undoCount, 0);
      await gesture.up();
      await tester.pump();
      expectSplit(host.document.current);
      expect(host.document.undoCount, 1);
      host.document.restore(redo: false);
      host.refresh();
      await tester.pump();
      final cancelled = await tester.startGesture(
        point,
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await cancelled.up();
      await tester.pump();
      expect(host.document.current, initial);
      expect(host.document.undoCount, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    '2D drag erases sampled cells and rejects changed zoom or selection',
    (tester) async {
      final host = await pumpEraseHost(tester, false);
      armErase(host);
      await tester.pump();
      Offset at(int x) => _at(tester, host.view, x, 5);
      final drag = await tester.startGesture(
        at(4),
        kind: PointerDeviceKind.mouse,
      );
      await drag.moveTo(at(6));
      await tester.pump();
      await drag.up();
      await tester.pump();
      final strokes =
          (traceFeature(host.document.current).geometry as BorderStrokeGeometry)
              .strokes;
      expect(strokes.map((stroke) => stroke.points), [
        [const GridPos(x: 2, y: 5), const GridPos(x: 3, y: 5)],
        [const GridPos(x: 7, y: 5), const GridPos(x: 8, y: 5)],
      ]);
      expect(host.document.undoCount, 1);
      host.document.restore(redo: false);
      host.refresh();
      await tester.pump();
      final before = host.document.current;
      final zoom = await tester.startGesture(
        at(5),
        kind: PointerDeviceKind.mouse,
      );
      host.view.transform.value = host.view.transform.value.clone()
        ..scaleByDouble(1.1, 1.1, 1, 1);
      await zoom.up();
      await tester.pump();
      expect(host.document.current, same(before));
      expect(host.document.undoCount, 0);
      final selection = await tester.startGesture(
        at(5),
        kind: PointerDeviceKind.mouse,
      );
      host.view.borderFeature = null;
      await selection.up();
      await tester.pump();
      expect(host.document.current, same(before));
      expect(host.document.undoCount, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    '3D local erase shows native preview and preserves foreign models with one undo',
    (tester) async {
      final host = await pumpEraseHost(tester, true);
      armErase(host);
      await tester.pump();
      SpatialSceneView scene() => tester.widget(find.byType(SpatialSceneView));
      final before = host.document.current;
      expect(scene().onDragStart!(5, 5, null), true);
      await tester.pump();
      expect(scene().scene.instances, hasLength(7));
      expect(host.document.current, same(before));
      expect(host.document.undoCount, 0);
      scene().onDragEnd!();
      await tester.pump();
      expectSplit(host.document.current);
      expect(
        host.document.current.spatialScene!.instances.lastWhere(
          (instance) => instance.id == 'foreign',
        ),
        before.spatialScene!.instances.singleWhere(
          (instance) => instance.id == 'foreign',
        ),
      );
      expect(host.document.undoCount, 1);
      host.document.restore(redo: false);
      host.refresh();
      await tester.pump();
      expect(host.document.current, before);
      expect(scene().onDragStart!(5, 5, null), true);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      scene().onDragEnd!();
      expect(host.document.current, before);
      expect(host.document.undoCount, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('3D erase rejects camera and tool changes', (tester) async {
    final host = await pumpEraseHost(tester, true);
    armErase(host);
    await tester.pump();
    SpatialSceneView scene() => tester.widget(find.byType(SpatialSceneView));
    final before = host.document.current;
    for (final cameraChange in [
      (SpatialSceneController camera) => camera.dolly(100),
      (SpatialSceneController camera) => camera.orbit(12, 0),
      (SpatialSceneController camera) => camera.panBy(1, 0),
    ]) {
      expect(scene().onDragStart!(5, 5, null), true);
      cameraChange(scene().controller);
      scene().onDragEnd!();
      await tester.pump();
      expect(host.document.current, same(before));
      expect(host.document.undoCount, 0);
    }
    expect(scene().onDragStart!(5, 5, null), true);
    host.view.tool = StudioMapTool.select;
    host.refresh();
    await tester.pump();
    scene().onDragEnd!();
    expect(host.document.current, same(before));
    expect(host.document.undoCount, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'complete erasure returns to draw mode and never silently selects another trace',
    (tester) async {
      final host = await pumpEraseHost(tester, true);
      armErase(host);
      await tester.pump();
      SpatialSceneView scene() => tester.widget(find.byType(SpatialSceneView));
      expect(scene().onDragStart!(2, 5, null), true);
      scene().onDragUpdate!((8, 5));
      scene().onDragEnd!();
      await tester.pump();
      expect(
        host.document.current.layers
            .whereType<BorderLayer>()
            .single
            .content
            .features,
        isEmpty,
      );
      expect(
        host.document.current.spatialScene!.instances.map(
          (instance) => instance.id,
        ),
        ['foreign'],
      );
      expect(host.view.borderFeature, isNull);
      expect(host.view.borderEditingMode, BorderStrokeEditingMode.draw);
      expect(host.document.undoCount, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'native eraser converts world cells back to the offset authored trace',
    (tester) async {
      final host = await pumpEraseHost(
        tester,
        true,
        offset: Model3dVector3(x: .5, y: .25, z: .5),
      );
      armErase(host);
      await tester.pump();
      final scene = tester.widget<SpatialSceneView>(
        find.byType(SpatialSceneView),
      );
      expect(scene.onDragStart!(6, 6, null), true);
      scene.onDragEnd!();
      await tester.pump();
      expectSplit(host.document.current);
      expect(
        traceFeature(host.document.current).spatialOffsetWorld,
        Model3dVector3(x: .5, y: .25, z: .5),
      );
      expect(host.document.undoCount, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

Offset _at(WidgetTester tester, MapEditingViewportSession view, int x, int y) {
  final canvas = tester.widget<MapEditingViewport2D>(
    find.byType(MapEditingViewport2D),
  );
  final box = tester.renderObject<RenderBox>(
    find.byKey(const ValueKey('map-canvas')),
  );
  return box.localToGlobal(
    Offset(
      (x + .5) *
          canvas.project.settings.tileWidth *
          canvas.project.settings.displayScale,
      (y + .5) *
          canvas.project.settings.tileHeight *
          canvas.project.settings.displayScale,
    ),
  );
}
