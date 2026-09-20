import 'package:avelune_studio/presentation/features/scenes/scene_graph_canvas.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'support/scene_canvas_test_harness.dart';

void main() {
  testWidgets(
    '200 canonical nodes retain document identity during eight viewport updates',
    (tester) async {
      final fixture = _volumeScene();
      expect(fixture.graph.nodes, hasLength(200));
      final build = buildSceneRuntimePlan(fixture);
      expect(build.plan, isNotNull, reason: build.diagnostics.toString());
      final trace = previewSceneRuntimePath(
        build.plan!,
        input: SceneDryRunInputState(
          outputPortByNodeId: {
            for (final node in fixture.graph.nodes.where(
              (n) => n.kind == SceneNodeKind.condition,
            ))
              node.id: 'true',
          },
        ),
        maxSteps: 400,
      );
      expect(trace.status, SceneDryRunPreviewStatus.completed);
      expect(trace.trace, hasLength(200));
      final harness = SceneCanvasTestHarness()..scene = fixture;
      final watch = Stopwatch()..start();
      await harness.mount(tester);
      final firstFrameMicros = watch.elapsedMicroseconds;
      expect(find.byType(SceneGraphCanvas), findsOneWidget);
      final original = harness.scene;
      final trackpad = await tester.createGesture(
        kind: PointerDeviceKind.trackpad,
      );
      await trackpad.panZoomStart(const Offset(900, 500));
      watch.reset();
      for (var i = 1; i <= 8; i++) {
        await trackpad.panZoomUpdate(
          const Offset(900, 500),
          pan: Offset(i * 20, -i * 10),
          scale: 1 + i * .05,
        );
        await tester.pump();
      }
      await trackpad.panZoomEnd();
      final gestureMicros = watch.elapsedMicroseconds;
      expect(harness.scene, same(original));
      expect(harness.commits, 0);
      expect(harness.view.zoom, closeTo(1.4, .001));
      expect(
        (harness.view.pan - const Offset(-200, -280)).distance,
        lessThan(.001),
      );
      expect(harness.scene.graph.edges, hasLength(265));
      expect(tester.takeException(), isNull);
      debugPrint(
        'UI06 volume: nodes=200 edges=265 viewportUpdates=8 documentMutations=0 firstFrameUs=$firstFrameMicros gesturesUs=$gestureMicros; no I/O adapter instantiated',
      );
    },
  );
}

SceneAsset _volumeScene() {
  var scene = createSceneDraftInProject(
    ProjectManifest(name: 'Volume', maps: [], tilesets: []),
    name: '200 blocs',
  ).createdScene;
  scene = removeSceneEdgeDraft(scene, scene.graph.edges.single.id).updatedScene;
  var previous = scene.graph.startNodeId;
  for (var i = 0; i < 66; i++) {
    final condition = addSceneNodeDraft(
      scene,
      kind: SceneNodeKind.condition,
      title: 'Décision $i',
    );
    scene = updateSceneConditionSource(
      condition.updatedScene,
      nodeId: condition.createdNode.id,
      source: SceneConditionSource(
        sourceKind: SceneConditionSourceKind.fact,
        sourceId: 'pass',
        operator: SceneConditionOperator.isTrue,
      ),
    ).updatedScene;
    final action = addSceneConsequenceActionNodeDraft(
      scene,
      consequence: SceneConsequence.setFact(factId: 'departure', value: true),
      title: 'Autorisation $i',
    );
    final merge = addSceneNodeDraft(
      action.updatedScene,
      kind: SceneNodeKind.merge,
      title: 'Suite $i',
    );
    scene = merge.updatedScene;
    for (final edge in [
      (previous, 'completed', condition.createdNode.id),
      (condition.createdNode.id, 'true', action.createdNode.id),
      (condition.createdNode.id, 'false', merge.createdNode.id),
      (action.createdNode.id, 'completed', merge.createdNode.id),
    ]) {
      scene = addSceneEdgeDraft(
        scene,
        fromNodeId: edge.$1,
        fromPortId: edge.$2,
        toNodeId: edge.$3,
      ).updatedScene;
    }
    final x = (i % 11) * 760.0;
    final y = (i ~/ 11) * 400.0;
    for (final layout in [
      (condition.createdNode.id, x, y),
      (action.createdNode.id, x + 260, y),
      (merge.createdNode.id, x + 500, y + 200),
    ]) {
      scene = updateSceneNodeLayout(
        scene,
        nodeId: layout.$1,
        x: layout.$2,
        y: layout.$3,
      ).updatedScene;
    }
    previous = merge.createdNode.id;
  }
  return addSceneEdgeDraft(
    scene,
    fromNodeId: previous,
    fromPortId: 'completed',
    toNodeId: 'node_end',
  ).updatedScene;
}
