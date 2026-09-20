import 'package:avelune_studio/presentation/features/scenes/scene_graph_canvas.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_canvas_painter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'support/scene_canvas_test_harness.dart';

void main() {
  testWidgets('wires use canonical action input after pan and zoom', (
    tester,
  ) async {
    final harness = SceneCanvasTestHarness();
    await harness.mount(tester);
    await tester.drag(
      find.byKey(const ValueKey('scene-graph-pan-surface')),
      const Offset(30, 45),
    );
    await tester.tap(find.byKey(const ValueKey('scene-graph-zoom-in')));
    await tester.pump();
    final wire = await tester.startGesture(
      tester.getCenter(
        find.byKey(const ValueKey('scene-graph-output-port-start-completed')),
      ),
    );
    await wire.moveTo(
      tester.getCenter(
        find.byKey(const ValueKey('scene-graph-input-port-action-in')),
      ),
    );
    await tester.pump();
    expect(find.text('Reliez une entrée · Échap pour annuler'), findsOneWidget);
    await wire.up();
    await tester.pump();
    expect(harness.commits, 1);
    expect(harness.scene.graph.edges.single.fromNodeId, 'start');
    expect(harness.scene.graph.edges.single.toNodeId, 'action');
    expect(harness.scene.graph.edges.single.fromPortId, 'completed');
    expect(harness.scene.graph.edges.single.kind, SceneEdgeKind.defaultFlow);
    harness.undo();
    await tester.pump();
    expect(harness.scene.graph.edges, isEmpty);
  });

  testWidgets('cancel, escape and drop into void never connect', (
    tester,
  ) async {
    final harness = SceneCanvasTestHarness();
    await harness.mount(tester);
    final source = find.byKey(
      const ValueKey('scene-graph-output-port-start-completed'),
    );
    final target = find.byKey(
      const ValueKey('scene-graph-input-port-action-in'),
    );
    var gesture = await tester.startGesture(tester.getCenter(source));
    await gesture.moveTo(tester.getCenter(target));
    await tester.pump();
    await gesture.cancel();
    await tester.pump();
    expect(harness.commits, 0);
    gesture = await tester.startGesture(tester.getCenter(source));
    await gesture.moveTo(tester.getCenter(target));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await gesture.up();
    await tester.pump();
    expect(harness.commits, 0);
    gesture = await tester.startGesture(tester.getCenter(source));
    await gesture.moveTo(const Offset(900, 400));
    await gesture.up();
    await tester.pump();
    expect(harness.scene.graph.edges, isEmpty);
  });

  testWidgets('node drag commits once and undo restores displayed position', (
    tester,
  ) async {
    final harness = SceneCanvasTestHarness();
    await harness.mount(tester);
    harness.view.zoomAt(.75, const Offset(0, 0));
    await tester.pump();
    final node = find.byKey(
      const ValueKey('scene-graph-node-drag-target-action'),
    );
    final before = tester.getTopLeft(node);
    var gesture = await tester.startGesture(tester.getCenter(node));
    await gesture.moveBy(const Offset(20, 0));
    await gesture.moveBy(const Offset(30, 15));
    await tester.pump();
    final preview = tester.getTopLeft(node);
    expect(harness.commits, 0);
    await gesture.up();
    await tester.pump();
    expect(harness.commits, 1);
    expect((tester.getTopLeft(node) - preview).distance, lessThan(.1));
    expect(tester.getTopLeft(node).dx, greaterThan(before.dx));
    harness.undo();
    await tester.pump();
    expect(tester.getTopLeft(node), before);
    gesture = await tester.startGesture(tester.getCenter(node));
    await gesture.moveBy(const Offset(30, 20));
    await tester.pump();
    await gesture.cancel();
    await tester.pump();
    expect(harness.commits, 1);
    expect(tester.getTopLeft(node), before);
  });

  testWidgets('select actual wire at two zooms and delete via focused canvas', (
    tester,
  ) async {
    final harness = SceneCanvasTestHarness();
    harness.scene = addSceneEdgeDraft(
      harness.scene,
      fromNodeId: 'start',
      fromPortId: 'completed',
      toNodeId: 'action',
    ).updatedScene;
    await harness.mount(tester);
    for (final zoom in [.75, 1.3]) {
      harness.view.zoomAt(zoom, Offset.zero);
      await tester.pump();
      final geometry = SceneCanvasGeometry(harness.scene);
      final path = sceneWirePath(
        harness.view.worldToLocal(geometry.output('start', 'completed', {})),
        harness.view.worldToLocal(geometry.input('action', {})),
      );
      final metric = path.computeMetrics().single;
      await tester.tapAt(
        metric.getTangentForOffset(metric.length * .5)!.position,
      );
      await tester.pump();
      expect(harness.edge, harness.scene.graph.edges.single.id);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pump();
    expect(harness.scene.graph.edges, isEmpty);
    harness.undo();
    await tester.pump();
    expect(harness.scene.graph.edges, hasLength(1));
  });

  testWidgets(
    'trackpad focal zoom changes viewport without document mutation',
    (tester) async {
      final harness = SceneCanvasTestHarness();
      await harness.mount(tester);
      const focal = Offset(820, 350);
      final before = harness.view.localToWorld(focal);
      final trackpad = await tester.createGesture(
        kind: PointerDeviceKind.trackpad,
      );
      await trackpad.panZoomStart(focal);
      await trackpad.panZoomUpdate(focal, scale: 1.4);
      await trackpad.panZoomEnd();
      await tester.pump();
      expect(harness.view.zoom, closeTo(1.4, .001));
      expect(
        (harness.view.localToWorld(focal) - before).distance,
        lessThan(.001),
      );
      expect(harness.commits, 0);
    },
  );
}
