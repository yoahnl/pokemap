import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('gift outcomes are canonical BranchByOutcome sources', () {
    final scene = SceneAsset(
      id: 'gift_branch',
      name: 'Gift branch',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'gift',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.interactive(
              SceneInteractiveCommand.giveItem(itemId: 'tm23', quantity: 1),
            ),
          ),
          SceneNode(
            id: 'branch',
            kind: SceneNodeKind.branchByOutcome,
            payload: SceneBranchByOutcomePayload(
              sourceNodeId: 'gift',
              fallbackPolicy: SceneBranchOutcomeFallbackPolicy.exact,
            ),
          ),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'start_gift',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'gift',
            kind: SceneEdgeKind.defaultFlow,
          ),
          for (final outcome in ['received', 'bagFull']) ...[
            SceneEdge(
              id: 'gift_$outcome',
              fromNodeId: 'gift',
              fromPortId: outcome,
              toNodeId: 'branch',
              kind: SceneEdgeKind.actionCompleted,
            ),
            SceneEdge(
              id: 'branch_$outcome',
              fromNodeId: 'branch',
              fromPortId: outcome,
              toNodeId: 'end',
              kind: SceneEdgeKind.branchOutcome,
            ),
          ],
        ],
      ),
      layout: SceneGraphLayout(nodeLayouts: const []),
      declaredOutcomes: const [],
    );
    final result = buildSceneRuntimePlan(scene);
    expect(
      result.canBuild,
      isTrue,
      reason: result.diagnostics.map((d) => d.code).join(', '),
    );
    expect(
      result.plan!.nodes
          .singleWhere((node) => node.id == 'branch')
          .intent
          .branchSourceOutcomes,
      ['received', 'bagFull'],
    );
  });
  test('bagFull is retryable while received is not delivered twice', () async {
    final plan = SceneRuntimePlan(
      sceneId: 'gift',
      startNodeId: 'gift',
      declaredOutcomes: const [],
      nodes: [
        SceneRuntimePlanNode(
          id: 'gift',
          kind: SceneNodeKind.action,
          intent: SceneRuntimePlanIntent.executeInteractiveCommand(
            command: SceneInteractiveCommand.giveItem(
              itemId: 'tm23',
              quantity: 1,
            ),
          ),
        ),
        SceneRuntimePlanNode(
          id: 'end',
          kind: SceneNodeKind.end,
          intent: SceneRuntimePlanIntent.end(),
        ),
      ],
      edges: [
        for (final outcome in ['received', 'bagFull'])
          SceneRuntimePlanEdge(
            id: outcome,
            fromNodeId: 'gift',
            fromPortId: outcome,
            toNodeId: 'end',
            kind: SceneEdgeKind.actionCompleted,
          ),
      ],
    );
    var attempts = 0;
    final executor = SceneRuntimeExecutor(
      callbacks: SceneRuntimeExecutionCallbacks(
        evaluateCondition: (_) => throw StateError('Unexpected condition'),
        showDialogue: (_) => throw StateError('Unexpected dialogue'),
        startBattle: (_) => throw StateError('Unexpected battle'),
        playCinematic: (_) => throw StateError('Unexpected cinematic'),
        applyConsequence: (_) => throw StateError('Unexpected consequence'),
        executeInteractiveCommand: (_) =>
            ++attempts == 1 ? 'bagFull' : 'received',
      ),
    );
    final blocked = await executor.execute(plan);
    expect(blocked.status, SceneRuntimeExecutionStatus.completed);
    expect(blocked.context.appliedPersistentNodeIds, isNot(contains('gift')));
    final received = await executor.execute(plan, context: blocked.context);
    expect(received.status, SceneRuntimeExecutionStatus.completed);
    expect(received.context.appliedPersistentNodeIds, contains('gift'));
    final replay = await executor.execute(plan, context: received.context);
    expect(replay.status, SceneRuntimeExecutionStatus.completed);
    expect(attempts, 2);
  });
}
