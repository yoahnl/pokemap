import 'package:avelune_studio/presentation/features/scenes/scene_graph_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'support/scene_canvas_test_harness.dart';

void main() {
  testWidgets('library drop uses graph coordinates after pan and zoom', (
    tester,
  ) async {
    final harness = SceneCanvasTestHarness();
    await harness.mount(
      tester,
      wrap: (canvas) => Column(
        children: [
          const SizedBox(
            height: 40,
            child: Draggable<SceneBlockDragData>(
              data: SceneBlockDragData(
                kind: SceneNodeKind.condition,
                label: 'Condition',
              ),
              dragAnchorStrategy: pointerDragAnchorStrategy,
              feedback: Material(child: Text('Condition')),
              child: Text('Ajouter une condition'),
            ),
          ),
          Expanded(child: canvas),
        ],
      ),
    );
    harness.view.translate(const Offset(35, 20));
    harness.view.zoomAt(.8, const Offset(100, 100));
    await tester.pump();
    const target = Offset(800, 400);
    final topLeft = tester.getTopLeft(
      find.byKey(const ValueKey('scene-graph-pan-surface')),
    );
    final expected = harness.view.localToWorld(target - topLeft);
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Ajouter une condition')),
    );
    await gesture.moveTo(target);
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(harness.additions, hasLength(1));
    expect(harness.additions.single.$1.kind, SceneNodeKind.condition);
    expect((harness.additions.single.$2 - expected).distance, lessThan(.1));
    expect(harness.commits, 0);
  });

  testWidgets(
    'output contextual search retains canonical origin and escape creates nothing',
    (tester) async {
      final harness = SceneCanvasTestHarness();
      await harness.mount(tester);
      final source = find.byKey(
        const ValueKey('scene-graph-output-port-start-completed'),
      );
      final gesture = await tester.startGesture(tester.getCenter(source));
      await gesture.moveTo(const Offset(800, 400));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.enterText(
        find.byKey(const ValueKey('scene-block-search')),
        'cond',
      );
      await tester.pump();
      await tester.tap(find.text('Condition'));
      await tester.pumpAndSettle();
      expect(harness.additions, hasLength(1));
      expect(harness.additions.single.$3, 'start');
      expect(harness.additions.single.$4, 'completed');
      expect(harness.commits, 0);
      await tester.tapAt(const Offset(850, 450));
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(harness.additions, hasLength(1));
    },
  );

  testWidgets('text editing delete does not delete graph selection', (
    tester,
  ) async {
    final harness = SceneCanvasTestHarness();
    harness.scene = addSceneEdgeDraft(
      harness.scene,
      fromNodeId: 'start',
      fromPortId: 'completed',
      toNodeId: 'action',
    ).updatedScene;
    harness.edge = harness.scene.graph.edges.single.id;
    await harness.mount(
      tester,
      wrap: (canvas) => Column(
        children: [
          const TextField(key: ValueKey('external-inspector-field')),
          Expanded(child: canvas),
        ],
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('external-inspector-field')),
      'Un nom',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(harness.scene.graph.edges, hasLength(1));
    expect(harness.commits, 0);
  });
}
