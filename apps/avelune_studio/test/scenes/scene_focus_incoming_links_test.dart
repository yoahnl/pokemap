import 'package:avelune_studio/features/scenes/application/graph/scene_graph_view.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_camera.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_canvas.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../presentation/story_interactions_support.dart';
import '../presentation/story_memory_harness.dart';
import '../storyline/storyline_widget_support.dart';
import 'scene_catalog_support.dart';
import 'steps/scene_step_fixtures.dart';

void main() {
  testWidgets('an input menu identifies the branch and undoes one rupture', (
    tester,
  ) async {
    final scene = SceneAsset(
      id: 'gate',
      name: 'Branchements communs',
      graph: graphOf(
        [startNode(), conditionNode('check'), endNode('end')],
        [
          link('start', 'check'),
          link('check', 'end', port: 'true'),
          link('check', 'end', port: 'false'),
        ],
      ),
    );
    final index = memoryIndex()..documents['gate'] = catalogDocument(scene);
    await openTrameStudio(
      tester,
      index: index,
      project: trameProject.copyWith(scenes: [scene]),
    );
    for (final key in [
      'story-section-scenes',
      'story-scene-gate',
      'story-scene-open',
    ]) {
      await tester.tap(interactionKey(key));
      await settleMemory(tester);
    }

    final canvas = find.descendant(
      of: interactionKey('scene-focus-graph-gate'),
      matching: find.byType(SceneGraphCanvas),
    );
    final input = sceneGraphInputAnchor(projectSceneGraph(scene).card('end')!);
    final camera = tester.state<SceneGraphCanvasState>(canvas).camera!;
    final area = tester.getRect(interactionKey('scene-graph-canvas'));
    final click = await tester.startGesture(
      area.topLeft + camera.toScreen(input),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await click.up();
    await settleMemory(tester);

    expect(find.text('Rompre le lien avec Condition · Alors'), findsOneWidget);
    final otherwise = find.text('Rompre le lien avec Condition · Sinon');
    expect(otherwise, findsOneWidget);
    await tester.tap(otherwise);
    await settleMemory(tester);

    SceneGraph current() => tester.widget<SceneGraphCanvas>(canvas).scene.graph;
    expect(current().edges, [
      for (final edge in scene.graph.edges)
        if (edge.id != 'check.false') edge,
    ]);
    expect(current().nodes, scene.graph.nodes);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await settleMemory(tester);
    expect(current(), scene.graph);
  });
}
