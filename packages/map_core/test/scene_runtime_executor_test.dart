import 'dart:async';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SceneRuntimeExecutor MVP', () {
    test('executes start to end', () async {
      final plan = _plan(
        nodes: [_startNode(), _endNode()],
        edges: [_edge('edge_start_end', 'node_start', 'completed', 'node_end')],
      );

      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(),
      ).execute(plan);

      expect(result.status, SceneRuntimeExecutionStatus.completed);
      expect(result.sceneId, 'scene_test');
      expect(result.finalNodeId, 'node_end');
      expect(result.sceneOutcomeId, isNull);
      expect(result.errorCode, isNull);
      expect(
        result.trace.map((entry) => (entry.nodeId, entry.outputPortId)),
        [('node_start', 'completed'), ('node_end', null)],
      );
    });

    test('exposes final scene outcome id from end intent', () async {
      final plan = _plan(
        nodes: [
          _startNode(),
          _endNode(sceneOutcomeId: 'scene_done'),
        ],
        edges: [_edge('edge_start_end', 'node_start', 'completed', 'node_end')],
      );

      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(),
      ).execute(plan);

      expect(result.status, SceneRuntimeExecutionStatus.completed);
      expect(result.finalNodeId, 'node_end');
      expect(result.sceneOutcomeId, 'scene_done');
    });

    test('executes a plan built from a SceneAsset without ProjectManifest',
        () async {
      final scene = SceneAsset(
        id: 'scene_test',
        name: 'Runtime Executor Test Scene',
        graph: SceneGraph(
          startNodeId: 'node_start',
          nodes: [
            SceneNode(id: 'node_start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'node_dialogue',
              kind: SceneNodeKind.yarnDialogue,
              payload: SceneYarnDialoguePayload(dialogueId: 'dialogue_test'),
            ),
            SceneNode(
              id: 'node_battle',
              kind: SceneNodeKind.battle,
              payload: SceneBattlePayload(
                battleKind: 'trainer',
                trainerId: 'trainer_test',
                declaredOutcomes: const ['victory', 'defeat'],
              ),
            ),
            SceneNode(id: 'node_end_victory', kind: SceneNodeKind.end),
            SceneNode(id: 'node_end_defeat', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'edge_start_dialogue',
              fromNodeId: 'node_start',
              fromPortId: 'completed',
              toNodeId: 'node_dialogue',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'edge_dialogue_battle',
              fromNodeId: 'node_dialogue',
              fromPortId: 'completed',
              toNodeId: 'node_battle',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'edge_battle_victory',
              fromNodeId: 'node_battle',
              fromPortId: 'victory',
              toNodeId: 'node_end_victory',
              kind: SceneEdgeKind.battleVictory,
            ),
            SceneEdge(
              id: 'edge_battle_defeat',
              fromNodeId: 'node_battle',
              fromPortId: 'defeat',
              toNodeId: 'node_end_defeat',
              kind: SceneEdgeKind.battleDefeat,
            ),
          ],
        ),
        layout: SceneGraphLayout(
          nodeLayouts: [
            SceneNodeLayout(nodeId: 'node_start', x: 1000, y: -80),
            SceneNodeLayout(nodeId: 'node_dialogue', x: -300, y: 440),
            SceneNodeLayout(nodeId: 'node_battle', x: 0, y: 0),
          ],
        ),
      );
      final plan = buildSceneRuntimePlan(scene).plan!;

      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(startBattle: (_) => 'defeat'),
      ).execute(plan);

      expect(result.status, SceneRuntimeExecutionStatus.completed);
      expect(result.finalNodeId, 'node_end_defeat');
      expect(result.trace.map((entry) => entry.nodeId), [
        'node_start',
        'node_dialogue',
        'node_battle',
        'node_end_defeat',
      ]);
    });

    test('executes start to dialogue completed to end', () async {
      final plan = _plan(
        nodes: [_startNode(), _dialogueNode(), _endNode()],
        edges: [
          _edge('edge_start_dialogue', 'node_start', 'completed',
              'node_dialogue'),
          _edge('edge_dialogue_end', 'node_dialogue', 'completed', 'node_end'),
        ],
      );
      var dialogueCalls = 0;

      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(
          showDialogue: (intent) {
            dialogueCalls++;
            expect(intent.dialogueId, 'dialogue_test');
            return 'completed';
          },
        ),
      ).execute(plan);

      expect(result.status, SceneRuntimeExecutionStatus.completed);
      expect(dialogueCalls, 1);
      expect(
        result.trace.map((entry) => entry.nodeId),
        ['node_start', 'node_dialogue', 'node_end'],
      );
    });

    test('executes battle victory branch', () async {
      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(startBattle: (_) => 'victory'),
      ).execute(_battleBranchPlan());

      expect(result.status, SceneRuntimeExecutionStatus.completed);
      expect(result.finalNodeId, 'node_end_victory');
      expect(
        result.trace.map((entry) => (entry.nodeId, entry.outputPortId)),
        [
          ('node_start', 'completed'),
          ('node_battle', 'victory'),
          ('node_end_victory', null),
        ],
      );
    });

    test('executes battle defeat branch', () async {
      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(startBattle: (_) => 'defeat'),
      ).execute(_battleBranchPlan());

      expect(result.status, SceneRuntimeExecutionStatus.completed);
      expect(result.finalNodeId, 'node_end_defeat');
      expect(
        result.trace.map((entry) => (entry.nodeId, entry.outputPortId)),
        [
          ('node_start', 'completed'),
          ('node_battle', 'defeat'),
          ('node_end_defeat', null),
        ],
      );
    });

    test('executes condition true branch', () async {
      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(evaluateCondition: (_) async => 'true'),
      ).execute(_conditionBranchPlan());

      expect(result.status, SceneRuntimeExecutionStatus.completed);
      expect(result.finalNodeId, 'node_end_victory');
      expect(result.trace[1].outputPortId, 'true');
    });

    test('executes condition false branch', () async {
      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(evaluateCondition: (_) => 'false'),
      ).execute(_conditionBranchPlan());

      expect(result.status, SceneRuntimeExecutionStatus.completed);
      expect(result.finalNodeId, 'node_end_defeat');
      expect(result.trace[1].outputPortId, 'false');
    });

    test('executes merge as passthrough', () async {
      final plan = _plan(
        nodes: [_startNode(), _mergeNode(), _endNode()],
        edges: [
          _edge('edge_start_merge', 'node_start', 'completed', 'node_merge'),
          _edge('edge_merge_end', 'node_merge', 'completed', 'node_end'),
        ],
      );

      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(),
      ).execute(plan);

      expect(result.status, SceneRuntimeExecutionStatus.completed);
      expect(
        result.trace.map((entry) => (entry.nodeId, entry.outputPortId)),
        [
          ('node_start', 'completed'),
          ('node_merge', 'completed'),
          ('node_end', null),
        ],
      );
    });

    test('executes cinematic completed via callback', () async {
      final plan = _plan(
        nodes: [_startNode(), _cinematicNode(), _endNode()],
        edges: [
          _edge('edge_start_cinematic', 'node_start', 'completed',
              'node_cinematic'),
          _edge(
            'edge_cinematic_end',
            'node_cinematic',
            'completed',
            'node_end',
            kind: SceneEdgeKind.cinematicCompleted,
          ),
        ],
      );

      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(playCinematic: (_) => Future.value('completed')),
      ).execute(plan);

      expect(result.status, SceneRuntimeExecutionStatus.completed);
      expect(result.finalNodeId, 'node_end');
      expect(result.trace[1].outputPortId, 'completed');
    });

    test('fails when start node is missing from plan', () async {
      final plan = _plan(
        nodes: [_endNode()],
        edges: const [],
      );

      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(),
      ).execute(plan);

      expect(result.status, SceneRuntimeExecutionStatus.failed);
      expect(result.errorCode, SceneRuntimeExecutionErrorCode.missingStartNode);
      expect(result.trace, isEmpty);
    });

    test('fails when returned port has no transition', () async {
      final plan = _plan(
        nodes: [_startNode(), _dialogueNode(), _endNode()],
        edges: [
          _edge('edge_start_dialogue', 'node_start', 'completed',
              'node_dialogue'),
        ],
      );

      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(showDialogue: (_) => 'completed'),
      ).execute(plan);

      expect(result.status, SceneRuntimeExecutionStatus.failed);
      expect(
          result.errorCode, SceneRuntimeExecutionErrorCode.missingTransition);
      expect(result.trace.last.nodeId, 'node_dialogue');
      expect(result.trace.last.outputPortId, 'completed');
    });

    test('fails when returned port is unsupported', () async {
      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(showDialogue: (_) => 'accept'),
      ).execute(_dialoguePlan());

      expect(result.status, SceneRuntimeExecutionStatus.failed);
      expect(
        result.errorCode,
        SceneRuntimeExecutionErrorCode.unsupportedPortResult,
      );
      expect(result.trace.last.nodeId, 'node_dialogue');
      expect(result.trace.last.outputPortId, 'accept');
    });

    test('fails when multiple transitions match same node and port', () async {
      final plan = _plan(
        nodes: [_startNode(), _endNode(), _endNode(id: 'node_end_defeat')],
        edges: [
          _edge('edge_start_end', 'node_start', 'completed', 'node_end'),
          _edge(
              'edge_start_end_2', 'node_start', 'completed', 'node_end_defeat'),
        ],
      );

      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(),
      ).execute(plan);

      expect(result.status, SceneRuntimeExecutionStatus.failed);
      expect(
        result.errorCode,
        SceneRuntimeExecutionErrorCode.ambiguousTransition,
      );
    });

    test('fails when target node is missing', () async {
      final plan = _plan(
        nodes: [_startNode()],
        edges: [
          _edge('edge_start_missing', 'node_start', 'completed', 'node_end'),
        ],
      );

      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(),
      ).execute(plan);

      expect(result.status, SceneRuntimeExecutionStatus.failed);
      expect(
          result.errorCode, SceneRuntimeExecutionErrorCode.targetNodeMissing);
    });

    test('fails when callback throws', () async {
      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(
          showDialogue: (_) => throw StateError('dialogue failed'),
        ),
      ).execute(_dialoguePlan());

      expect(result.status, SceneRuntimeExecutionStatus.failed);
      expect(result.errorCode, SceneRuntimeExecutionErrorCode.callbackFailed);
      expect(result.message, contains('dialogue failed'));
      expect(result.trace.last.nodeId, 'node_dialogue');
      expect(result.trace.last.outputPortId, isNull);
    });

    test('fails when maxSteps is exceeded', () async {
      final plan = _plan(
        nodes: [_startNode(), _mergeNode()],
        edges: [
          _edge('edge_start_merge', 'node_start', 'completed', 'node_merge'),
          _edge('edge_merge_start', 'node_merge', 'completed', 'node_start'),
        ],
      );

      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(),
        maxSteps: 3,
      ).execute(plan);

      expect(result.status, SceneRuntimeExecutionStatus.failed);
      expect(
          result.errorCode, SceneRuntimeExecutionErrorCode.stepLimitExceeded);
      expect(result.trace.map((entry) => entry.nodeId), [
        'node_start',
        'node_merge',
        'node_start',
      ]);
    });

    test('does not mutate SceneRuntimePlan', () async {
      final plan = _dialoguePlan();
      final beforeNodes = List<SceneRuntimePlanNode>.of(plan.nodes);
      final beforeEdges = List<SceneRuntimePlanEdge>.of(plan.edges);

      await SceneRuntimeExecutor(
        callbacks: _callbacks(showDialogue: (_) => 'completed'),
      ).execute(plan);

      expect(plan.nodes, beforeNodes);
      expect(plan.edges, beforeEdges);
      expect(plan.startNodeId, 'node_start');
    });
  });
}

SceneRuntimeExecutionCallbacks _callbacks({
  FutureOr<String> Function(SceneRuntimePlanIntent intent)? evaluateCondition,
  FutureOr<String> Function(SceneRuntimePlanIntent intent)? showDialogue,
  FutureOr<String> Function(SceneRuntimePlanIntent intent)? startBattle,
  FutureOr<String> Function(SceneRuntimePlanIntent intent)? playCinematic,
}) {
  return SceneRuntimeExecutionCallbacks(
    evaluateCondition: evaluateCondition ?? (_) => 'true',
    showDialogue: showDialogue ?? (_) => 'completed',
    startBattle: startBattle ?? (_) => 'victory',
    playCinematic: playCinematic ?? (_) => 'completed',
  );
}

SceneRuntimePlan _dialoguePlan() {
  return _plan(
    nodes: [_startNode(), _dialogueNode(), _endNode()],
    edges: [
      _edge('edge_start_dialogue', 'node_start', 'completed', 'node_dialogue'),
      _edge('edge_dialogue_end', 'node_dialogue', 'completed', 'node_end'),
    ],
  );
}

SceneRuntimePlan _battleBranchPlan() {
  return _plan(
    nodes: [
      _startNode(),
      _battleNode(),
      _endNode(id: 'node_end_victory'),
      _endNode(id: 'node_end_defeat'),
    ],
    edges: [
      _edge('edge_start_battle', 'node_start', 'completed', 'node_battle'),
      _edge(
        'edge_battle_victory',
        'node_battle',
        'victory',
        'node_end_victory',
        kind: SceneEdgeKind.battleVictory,
      ),
      _edge(
        'edge_battle_defeat',
        'node_battle',
        'defeat',
        'node_end_defeat',
        kind: SceneEdgeKind.battleDefeat,
      ),
    ],
  );
}

SceneRuntimePlan _conditionBranchPlan() {
  return _plan(
    nodes: [
      _startNode(),
      _conditionNode(),
      _endNode(id: 'node_end_victory'),
      _endNode(id: 'node_end_defeat'),
    ],
    edges: [
      _edge(
        'edge_start_condition',
        'node_start',
        'completed',
        'node_condition',
      ),
      _edge(
        'edge_condition_true',
        'node_condition',
        'true',
        'node_end_victory',
        kind: SceneEdgeKind.conditionTrue,
      ),
      _edge(
        'edge_condition_false',
        'node_condition',
        'false',
        'node_end_defeat',
        kind: SceneEdgeKind.conditionFalse,
      ),
    ],
  );
}

SceneRuntimePlan _plan({
  required List<SceneRuntimePlanNode> nodes,
  required List<SceneRuntimePlanEdge> edges,
}) {
  return SceneRuntimePlan(
    sceneId: 'scene_test',
    startNodeId: 'node_start',
    nodes: nodes,
    edges: edges,
    declaredOutcomes: const [],
  );
}

SceneRuntimePlanNode _startNode() {
  return SceneRuntimePlanNode(
    id: 'node_start',
    kind: SceneNodeKind.start,
    intent: SceneRuntimePlanIntent.start(),
  );
}

SceneRuntimePlanNode _dialogueNode() {
  return SceneRuntimePlanNode(
    id: 'node_dialogue',
    kind: SceneNodeKind.yarnDialogue,
    intent: SceneRuntimePlanIntent.showDialogue(dialogueId: 'dialogue_test'),
  );
}

SceneRuntimePlanNode _battleNode() {
  return SceneRuntimePlanNode(
    id: 'node_battle',
    kind: SceneNodeKind.battle,
    intent: SceneRuntimePlanIntent.startBattle(
      battleKind: 'trainer',
      trainerId: 'trainer_test',
      declaredOutcomes: const ['victory', 'defeat'],
    ),
  );
}

SceneRuntimePlanNode _conditionNode() {
  return SceneRuntimePlanNode(
    id: 'node_condition',
    kind: SceneNodeKind.condition,
    intent: SceneRuntimePlanIntent.evaluateCondition(
      source: SceneConditionSource(
        sourceKind: SceneConditionSourceKind.factLikeStoryFlag,
        sourceId: 'fact_test',
        operator: SceneConditionOperator.isTrue,
      ),
    ),
  );
}

SceneRuntimePlanNode _mergeNode() {
  return SceneRuntimePlanNode(
    id: 'node_merge',
    kind: SceneNodeKind.merge,
    intent: SceneRuntimePlanIntent.merge(),
  );
}

SceneRuntimePlanNode _cinematicNode() {
  return SceneRuntimePlanNode(
    id: 'node_cinematic',
    kind: SceneNodeKind.cinematic,
    intent: SceneRuntimePlanIntent.playCinematic(
      cinematicId: 'cinematic_test',
    ),
  );
}

SceneRuntimePlanNode _endNode({
  String id = 'node_end',
  String? sceneOutcomeId,
}) {
  return SceneRuntimePlanNode(
    id: id,
    kind: SceneNodeKind.end,
    intent: SceneRuntimePlanIntent.end(sceneOutcomeId: sceneOutcomeId),
  );
}

SceneRuntimePlanEdge _edge(
  String id,
  String fromNodeId,
  String fromPortId,
  String toNodeId, {
  SceneEdgeKind kind = SceneEdgeKind.defaultFlow,
}) {
  return SceneRuntimePlanEdge(
    id: id,
    fromNodeId: fromNodeId,
    fromPortId: fromPortId,
    toNodeId: toNodeId,
    kind: kind,
  );
}
