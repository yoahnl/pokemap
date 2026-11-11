import 'package:map_core/map_core.dart';
import 'package:map_story/map_story.dart';
import 'package:test/test.dart';

void main() {
  const wire = <String, dynamic>{
    'kind': 'receivePokemonFromCatalog',
    'speciesId': 'clockbird',
    'formId': 'bronze',
    'level': 7,
    'nicknamePolicy': 'offer',
    'nicknameMaxGraphemes': 10,
    'pokedexPresentationPolicy': 'whenNewAndPokedexVisible',
  };

  test('dry run requires a business outcome and routes branchByOutcome', () {
    final gift = SceneInteractiveCommand.fromJson(wire);
    final nodes = [
      SceneRuntimePlanNode(
        id: 'start',
        kind: SceneNodeKind.start,
        intent: SceneRuntimePlanIntent.start(),
      ),
      SceneRuntimePlanNode(
        id: 'gift',
        kind: SceneNodeKind.action,
        intent: SceneRuntimePlanIntent.executeInteractiveCommand(
          command: gift,
          sourceNodeId: 'gift',
        ),
      ),
      SceneRuntimePlanNode(
        id: 'branch',
        kind: SceneNodeKind.branchByOutcome,
        intent: SceneRuntimePlanIntent.branchByOutcome(
          sourceNodeId: 'gift',
          fallbackPolicy: SceneBranchOutcomeFallbackPolicy.exact,
          sourceOutcomes: gift.outputPortIds,
        ),
      ),
      for (final port in gift.outputPortIds)
        SceneRuntimePlanNode(
          id: port,
          kind: SceneNodeKind.end,
          intent: SceneRuntimePlanIntent.end(sceneOutcomeId: port),
        ),
    ];
    final plan = SceneRuntimePlan(
      sceneId: 'gift',
      startNodeId: 'start',
      declaredOutcomes: [
        for (final port in gift.outputPortIds)
          SceneOutcome(id: port, label: port),
      ],
      nodes: nodes,
      edges: [
        SceneRuntimePlanEdge(
          id: 'a',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'gift',
          kind: SceneEdgeKind.defaultFlow,
        ),
        for (final port in gift.outputPortIds) ...[
          SceneRuntimePlanEdge(
            id: 'gift-$port',
            fromNodeId: 'gift',
            fromPortId: port,
            toNodeId: 'branch',
            kind: SceneEdgeKind.actionCompleted,
          ),
          SceneRuntimePlanEdge(
            id: 'branch-$port',
            fromNodeId: 'branch',
            fromPortId: port,
            toNodeId: port,
            kind: SceneEdgeKind.branchOutcome,
          ),
        ],
      ],
    );
    final awaiting = previewSceneRuntimePath(
      plan,
      input: const SceneDryRunInputState(),
    );
    expect(awaiting.status, SceneDryRunPreviewStatus.awaitingInput);
    expect(awaiting.acceptedOutputPortIds, gift.outputPortIds);
    for (final port in gift.outputPortIds) {
      final result = previewSceneRuntimePath(
        plan,
        input: SceneDryRunInputState(outputPortByNodeId: {'gift': port}),
      );
      expect(
        result.status,
        SceneDryRunPreviewStatus.completed,
        reason: result.message,
      );
      expect(result.sceneOutcomeId, port);
      expect(result.context.lastOutcomeByNodeId['gift'], port);
    }
    final invalid = previewSceneRuntimePath(
      plan,
      input: SceneDryRunInputState(outputPortByNodeId: {'gift': 'cancelled'}),
    );
    expect(invalid.status, SceneDryRunPreviewStatus.failed);
  });

}
