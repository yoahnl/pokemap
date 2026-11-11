import 'package:avelune_studio/features/scenes/application/scene_edit_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:map_story/map_story.dart';

void main() {
  test(
    '200 canonical nodes and 265 edges retain their identity during preview',
    () {
      final fixture = _volumeScene();
      final session = SceneEditSession(fixture, base: fixture);
      final before = fixture.toJson();
      expect(fixture.graph.nodes, hasLength(200));
      expect(fixture.graph.edges, hasLength(265));
      final build = buildSceneRuntimePlan(fixture);
      expect(build.plan, isNotNull, reason: build.diagnostics.toString());
      final trace = previewSceneRuntimePath(
        build.plan!,
        input: SceneDryRunInputState(
          outputPortByNodeId: {
            for (final node in fixture.graph.nodes.where(
              (node) => node.kind == SceneNodeKind.condition,
            ))
              node.id: 'true',
          },
        ),
        maxSteps: 400,
      );
      expect(trace.status, SceneDryRunPreviewStatus.completed);
      expect(trace.trace, hasLength(200));
      expect(session.current, same(fixture));
      expect(session.undoCount, 0);
      expect(session.dirty, isFalse);
      expect(fixture.toJson(), before);
      expect(fixture.graph.edges, hasLength(265));
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
