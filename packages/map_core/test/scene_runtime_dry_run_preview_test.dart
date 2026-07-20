import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Scene runtime dry-run preview', () {
    test('waits for explicit input then previews the selected dialogue path',
        () {
      final plan = _dialoguePlan();

      final waiting = previewSceneRuntimePath(
        plan,
        input: const SceneDryRunInputState(),
      );
      expect(waiting.status, SceneDryRunPreviewStatus.awaitingInput);
      expect(waiting.awaitingNodeId, 'node_dialogue');
      expect(waiting.acceptedOutputPortIds, ['completed', 'accept', 'leave']);
      expect(waiting.trace.map((entry) => entry.nodeId), [
        'node_start',
        'node_dialogue',
      ]);

      final completed = previewSceneRuntimePath(
        plan,
        input: const SceneDryRunInputState(
          outputPortByNodeId: {'node_dialogue': 'leave'},
        ),
      );
      expect(completed.status, SceneDryRunPreviewStatus.completed);
      expect(completed.sceneOutcomeId, 'left');
      expect(completed.trace.map((entry) => entry.nodeId), [
        'node_start',
        'node_dialogue',
        'node_leave',
      ]);
    });

    test('rejects an explicit output not declared by the node', () {
      final result = previewSceneRuntimePath(
        _dialoguePlan(),
        input: const SceneDryRunInputState(
          outputPortByNodeId: {'node_dialogue': 'unknown'},
        ),
      );

      expect(result.status, SceneDryRunPreviewStatus.failed);
      expect(result.message, contains('unknown'));
    });

    test('routes a recorded dialogue outcome through merge and branch', () {
      final plan = SceneRuntimePlan(
        sceneId: 'scene_branch_preview',
        startNodeId: 'start',
        nodes: [
          SceneRuntimePlanNode(
            id: 'start',
            kind: SceneNodeKind.start,
            intent: SceneRuntimePlanIntent.start(),
          ),
          SceneRuntimePlanNode(
            id: 'dialogue',
            kind: SceneNodeKind.yarnDialogue,
            intent: SceneRuntimePlanIntent.showDialogue(
              dialogueId: 'dialogue_test',
              expectedOutcomes: const ['accept', 'refuse'],
            ),
          ),
          SceneRuntimePlanNode(
            id: 'merge',
            kind: SceneNodeKind.merge,
            intent: SceneRuntimePlanIntent.merge(),
          ),
          SceneRuntimePlanNode(
            id: 'branch',
            kind: SceneNodeKind.branchByOutcome,
            intent: SceneRuntimePlanIntent.branchByOutcome(
              sourceNodeId: 'dialogue',
              fallbackPolicy: SceneBranchOutcomeFallbackPolicy.exact,
              sourceOutcomes: const ['completed', 'accept', 'refuse'],
            ),
          ),
          SceneRuntimePlanNode(
            id: 'end_accept',
            kind: SceneNodeKind.end,
            intent: SceneRuntimePlanIntent.end(sceneOutcomeId: 'accepted'),
          ),
        ],
        edges: const [
          SceneRuntimePlanEdge(
            id: 'start_dialogue',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'dialogue',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneRuntimePlanEdge(
            id: 'dialogue_accept_merge',
            fromNodeId: 'dialogue',
            fromPortId: 'accept',
            toNodeId: 'merge',
            kind: SceneEdgeKind.dialogueOutcome,
          ),
          SceneRuntimePlanEdge(
            id: 'merge_branch',
            fromNodeId: 'merge',
            fromPortId: 'completed',
            toNodeId: 'branch',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneRuntimePlanEdge(
            id: 'branch_accept_end',
            fromNodeId: 'branch',
            fromPortId: 'accept',
            toNodeId: 'end_accept',
            kind: SceneEdgeKind.branchOutcome,
          ),
        ],
        declaredOutcomes: [
          SceneOutcome(id: 'accepted', label: 'Accepted'),
        ],
      );

      final result = previewSceneRuntimePath(
        plan,
        input: const SceneDryRunInputState(
          outputPortByNodeId: {'dialogue': 'accept'},
        ),
      );

      expect(result.status, SceneDryRunPreviewStatus.completed);
      expect(result.sceneOutcomeId, 'accepted');
      expect(result.trace.map((entry) => entry.nodeId),
          ['start', 'dialogue', 'merge', 'branch', 'end_accept']);
      expect(result.context.branchProvenance.single.sourceOutcome, 'accept');
    });
  });
}

SceneRuntimePlan _dialoguePlan() {
  return SceneRuntimePlan(
    sceneId: 'scene_preview',
    startNodeId: 'node_start',
    nodes: [
      SceneRuntimePlanNode(
        id: 'node_start',
        kind: SceneNodeKind.start,
        intent: SceneRuntimePlanIntent.start(),
      ),
      SceneRuntimePlanNode(
        id: 'node_dialogue',
        kind: SceneNodeKind.yarnDialogue,
        intent: SceneRuntimePlanIntent.showDialogue(
          dialogueId: 'dialogue_test',
          expectedOutcomes: const ['accept', 'leave'],
        ),
      ),
      SceneRuntimePlanNode(
        id: 'node_accept',
        kind: SceneNodeKind.end,
        intent: SceneRuntimePlanIntent.end(sceneOutcomeId: 'accepted'),
      ),
      SceneRuntimePlanNode(
        id: 'node_leave',
        kind: SceneNodeKind.end,
        intent: SceneRuntimePlanIntent.end(sceneOutcomeId: 'left'),
      ),
    ],
    edges: const [
      SceneRuntimePlanEdge(
        id: 'edge_start_dialogue',
        fromNodeId: 'node_start',
        fromPortId: 'completed',
        toNodeId: 'node_dialogue',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneRuntimePlanEdge(
        id: 'edge_accept',
        fromNodeId: 'node_dialogue',
        fromPortId: 'accept',
        toNodeId: 'node_accept',
        kind: SceneEdgeKind.dialogueOutcome,
      ),
      SceneRuntimePlanEdge(
        id: 'edge_leave',
        fromNodeId: 'node_dialogue',
        fromPortId: 'leave',
        toNodeId: 'node_leave',
        kind: SceneEdgeKind.dialogueOutcome,
      ),
    ],
    declaredOutcomes: [
      SceneOutcome(id: 'accepted', label: 'Accepted'),
      SceneOutcome(id: 'left', label: 'Left'),
    ],
  );
}
