
import 'package:map_core/map_core.dart';
import 'package:map_story/map_story.dart';
import 'package:test/test.dart';

void main() {

  test('consequence dry-run names the imposed move order', () {
    final scene = _scene(
      SceneActionPayload.consequence(
        SceneConsequence.fromJson({
          'kind': 'givePokemonFromCatalog',
          'speciesId': 'fixture_species',
          'formId': 'fixture_form',
          'level': 7,
          'moveIds': ['exceptional_move', 'fixture_move'],
        }),
      ),
    );
    final plan = buildSceneRuntimePlan(scene);
    expect(plan.canBuild, isTrue);
    final result = previewSceneRuntimePath(
      plan.plan!,
      input: const SceneDryRunInputState(),
    );
    expect(result.status, SceneDryRunPreviewStatus.completed);
    expect(
      result.consequenceChanges.single.afterSummary,
      contains('exceptional_move, fixture_move'),
    );
  });
}

SceneAsset _scene(SceneActionPayload payload) {
  final ports =
      payload.interactiveCommand?.outputPortIds ?? const ['completed'];
  return SceneAsset(
    id: 'gift',
    name: 'Gift',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(id: 'gift', kind: SceneNodeKind.action, payload: payload),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'start',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'gift',
          kind: SceneEdgeKind.defaultFlow,
        ),
        for (final port in ports)
          SceneEdge(
            id: port,
            fromNodeId: 'gift',
            fromPortId: port,
            toNodeId: 'end',
            kind: SceneEdgeKind.actionCompleted,
          ),
      ],
    ),
  );
}
