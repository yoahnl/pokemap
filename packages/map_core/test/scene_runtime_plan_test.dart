import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Scene runtime plan V0', () {
    test('builds a pure plan for a minimal valid start to end scene', () {
      final scene = _minimalScene();

      final result = buildSceneRuntimePlan(scene);

      expect(result.canBuild, isTrue);
      expect(result.diagnostics, isEmpty);
      final plan = result.plan!;
      expect(plan.sceneId, 'scene_test');
      expect(plan.startNodeId, 'node_start');
      expect(plan.nodes.map((node) => node.id), ['node_start', 'node_end']);
      expect(plan.nodes.first.intent.kind, SceneRuntimePlanIntentKind.start);
      expect(plan.nodes.last.intent.kind, SceneRuntimePlanIntentKind.end);
      expect(plan.edges, hasLength(1));
      expect(plan.edges.single.id, 'edge_start_end');
      expect(plan.edges.single.fromNodeId, 'node_start');
      expect(plan.edges.single.fromPortId, 'completed');
      expect(plan.edges.single.toNodeId, 'node_end');
      expect(plan.edges.single.kind, SceneEdgeKind.defaultFlow);
      expect(plan.declaredOutcomes, isEmpty);
    });

    test('ignores SceneGraphLayout when building the plan', () {
      final scene = _minimalScene(
        layout: SceneGraphLayout(
          nodeLayouts: [
            SceneNodeLayout(nodeId: 'node_start', x: 24, y: 80),
            SceneNodeLayout(nodeId: 'node_end', x: 320, y: 80),
          ],
        ),
      );
      final sameGraphDifferentLayout = _minimalScene(
        layout: SceneGraphLayout(
          nodeLayouts: [
            SceneNodeLayout(nodeId: 'node_start', x: 1000, y: -250),
            SceneNodeLayout(nodeId: 'node_end', x: -80, y: 900),
          ],
        ),
      );

      final plan = buildSceneRuntimePlan(scene).plan!;
      final planWithDifferentLayout =
          buildSceneRuntimePlan(sameGraphDifferentLayout).plan!;

      expect(plan.nodes, planWithDifferentLayout.nodes);
      expect(plan.edges, planWithDifferentLayout.edges);
      expect(plan.startNodeId, planWithDifferentLayout.startNodeId);
    });

    test('preserves deterministic node and edge order from SceneGraph', () {
      final scene = SceneAsset(
        id: 'scene_test',
        name: 'Runtime Plan Test',
        graph: SceneGraph(
          startNodeId: 'node_start',
          nodes: [
            SceneNode(id: 'node_start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'node_condition',
              kind: SceneNodeKind.condition,
              payload: _factConditionPayload(),
            ),
            SceneNode(id: 'node_merge', kind: SceneNodeKind.merge),
            SceneNode(id: 'node_end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'edge_condition_merge',
              fromNodeId: 'node_condition',
              fromPortId: 'true',
              toNodeId: 'node_merge',
              kind: SceneEdgeKind.conditionTrue,
            ),
            SceneEdge(
              id: 'edge_start_condition',
              fromNodeId: 'node_start',
              fromPortId: 'completed',
              toNodeId: 'node_condition',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'edge_merge_end',
              fromNodeId: 'node_merge',
              fromPortId: 'completed',
              toNodeId: 'node_end',
              kind: SceneEdgeKind.defaultFlow,
            ),
          ],
        ),
        layout: SceneGraphLayout(
          nodeLayouts: [
            SceneNodeLayout(nodeId: 'node_merge', x: 640, y: 80),
            SceneNodeLayout(nodeId: 'node_start', x: 40, y: 80),
            SceneNodeLayout(nodeId: 'node_end', x: 940, y: 80),
            SceneNodeLayout(nodeId: 'node_condition', x: 340, y: 80),
          ],
        ),
      );

      final plan = buildSceneRuntimePlan(scene).plan!;

      expect(plan.nodes.map((node) => node.id), [
        'node_start',
        'node_condition',
        'node_merge',
        'node_end',
      ]);
      expect(plan.edges.map((edge) => edge.id), [
        'edge_condition_merge',
        'edge_start_condition',
        'edge_merge_end',
      ]);
    });

    test('scene diagnostics errors block plan building cleanly', () {
      final scene = SceneAsset(
        id: 'scene_test',
        name: 'Runtime Plan Test',
        graph: SceneGraph(
          startNodeId: 'node_start',
          nodes: [
            SceneNode(id: 'node_start', kind: SceneNodeKind.start),
            SceneNode(id: 'node_condition', kind: SceneNodeKind.condition),
            SceneNode(id: 'node_end', kind: SceneNodeKind.end),
          ],
        ),
        layout: SceneGraphLayout(
          nodeLayouts: [
            SceneNodeLayout(nodeId: 'node_start', x: 24, y: 80),
            SceneNodeLayout(nodeId: 'node_condition', x: 324, y: 80),
            SceneNodeLayout(nodeId: 'node_end', x: 624, y: 80),
          ],
        ),
      );

      final result = buildSceneRuntimePlan(scene);

      expect(result.canBuild, isFalse);
      expect(result.plan, isNull);
      expect(
        result.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
            SceneRuntimePlanDiagnosticCode.planBuildBlockedBySceneDiagnostics),
      );
      expect(
        result.diagnostics.map(
          (diagnostic) => diagnostic.sourceSceneDiagnosticCode,
        ),
        contains(SceneDiagnosticCode.conditionSourceMissing),
      );
      expect(
        result.diagnostics.map((diagnostic) => diagnostic.severity),
        everyElement(SceneRuntimePlanDiagnosticSeverity.error),
      );
    });

    test('condition nodes become evaluateCondition intents', () {
      final scene = _sceneWithSingleMiddleNode(
        SceneNode(
          id: 'node_condition',
          kind: SceneNodeKind.condition,
          payload: _factConditionPayload(),
        ),
        incomingEdgeKind: SceneEdgeKind.defaultFlow,
        outgoingPortId: 'true',
        outgoingEdgeKind: SceneEdgeKind.conditionTrue,
      );

      final conditionNode = buildSceneRuntimePlan(scene)
          .plan!
          .nodes
          .singleWhere((node) => node.id == 'node_condition');

      expect(conditionNode.intent.kind,
          SceneRuntimePlanIntentKind.evaluateCondition);
      expect(conditionNode.intent.conditionSource,
          (_factConditionPayload()).conditionSource);
    });

    test('merge nodes become merge intents', () {
      final scene = _sceneWithSingleMiddleNode(
        SceneNode(id: 'node_merge', kind: SceneNodeKind.merge),
      );

      final mergeNode = buildSceneRuntimePlan(scene)
          .plan!
          .nodes
          .singleWhere((node) => node.id == 'node_merge');

      expect(mergeNode.intent.kind, SceneRuntimePlanIntentKind.merge);
    });

    test(
        'yarn dialogue payload becomes showDialogue intent without outcomes invented',
        () {
      final scene = _sceneWithSingleMiddleNode(
        SceneNode(
          id: 'node_dialogue',
          kind: SceneNodeKind.yarnDialogue,
          payload: SceneYarnDialoguePayload(
            dialogueId: 'dialogue_test',
            yarnNodeName: 'Start',
          ),
        ),
      );

      final result = buildSceneRuntimePlan(scene);
      final dialogueNode =
          result.plan!.nodes.singleWhere((node) => node.id == 'node_dialogue');
      final dialogueEdge = result.plan!.edges.singleWhere(
        (edge) => edge.fromNodeId == 'node_dialogue',
      );

      expect(result.canBuild, isTrue);
      expect(dialogueNode.intent.kind, SceneRuntimePlanIntentKind.showDialogue);
      expect(dialogueNode.intent.dialogueId, 'dialogue_test');
      expect(dialogueNode.intent.yarnNodeName, 'Start');
      expect(dialogueNode.intent.expectedOutcomes, isEmpty);
      expect(dialogueEdge.fromPortId, 'completed');
      expect(dialogueEdge.kind, SceneEdgeKind.defaultFlow);
    });

    test(
        'battle payload becomes startBattle intent without importing battle runtime',
        () {
      final scene = _sceneWithSingleMiddleNode(
        SceneNode(
          id: 'node_battle',
          kind: SceneNodeKind.battle,
          payload: SceneBattlePayload(
            battleKind: 'trainer',
            trainerId: 'trainer_test',
            battleTemplateId: 'battle_test',
            declaredOutcomes: const ['victory', 'defeat'],
          ),
        ),
        outgoingPortId: 'victory',
        outgoingEdgeKind: SceneEdgeKind.battleVictory,
      );

      final result = buildSceneRuntimePlan(scene);
      final battleNode =
          result.plan!.nodes.singleWhere((node) => node.id == 'node_battle');
      final battleEdge = result.plan!.edges.singleWhere(
        (edge) => edge.fromNodeId == 'node_battle',
      );

      expect(result.canBuild, isTrue);
      expect(battleNode.intent.kind, SceneRuntimePlanIntentKind.startBattle);
      expect(battleNode.intent.battleKind, 'trainer');
      expect(battleNode.intent.trainerId, 'trainer_test');
      expect(battleNode.intent.battleTemplateId, 'battle_test');
      expect(battleNode.intent.battleDeclaredOutcomes, ['victory', 'defeat']);
      expect(battleEdge.fromPortId, 'victory');
      expect(battleEdge.kind, SceneEdgeKind.battleVictory);
    });

    test('battle plan preserves victory and defeat edges', () {
      final scene = SceneAsset(
        id: 'scene_test',
        name: 'Runtime Plan Battle Branches',
        graph: SceneGraph(
          startNodeId: 'node_start',
          nodes: [
            SceneNode(id: 'node_start', kind: SceneNodeKind.start),
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
              id: 'edge_start_battle',
              fromNodeId: 'node_start',
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
      );

      final result = buildSceneRuntimePlan(scene);

      expect(result.canBuild, isTrue);
      expect(
        result.plan!.edges.map((edge) => (edge.fromPortId, edge.kind)),
        [
          ('completed', SceneEdgeKind.defaultFlow),
          ('victory', SceneEdgeKind.battleVictory),
          ('defeat', SceneEdgeKind.battleDefeat),
        ],
      );
    });

    test('cinematic payload becomes playCinematic intent with bridge warning',
        () {
      final scene = _sceneWithSingleMiddleNode(
        SceneNode(
          id: 'node_cinematic',
          kind: SceneNodeKind.cinematic,
          payload: SceneCinematicPayload(cinematicId: 'cinematic_test'),
        ),
        outgoingEdgeKind: SceneEdgeKind.cinematicCompleted,
      );

      final result = buildSceneRuntimePlan(scene);
      final cinematicNode =
          result.plan!.nodes.singleWhere((node) => node.id == 'node_cinematic');

      expect(result.canBuild, isTrue);
      expect(
        result.diagnostics.single.code,
        SceneRuntimePlanDiagnosticCode.cinematicBridgeOnly,
      );
      expect(
        result.diagnostics.single.severity,
        SceneRuntimePlanDiagnosticSeverity.warning,
      );
      expect(
          cinematicNode.intent.kind, SceneRuntimePlanIntentKind.playCinematic);
      expect(cinematicNode.intent.cinematicId, 'cinematic_test');
    });

    test('action nodes produce unsupported diagnostics and no plan', () {
      final scene = _sceneWithSingleMiddleNode(
        SceneNode(
          id: 'node_action',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload(actionKind: 'action_test'),
        ),
        outgoingEdgeKind: SceneEdgeKind.actionCompleted,
      );

      final result = buildSceneRuntimePlan(scene);

      expect(result.canBuild, isFalse);
      expect(result.plan, isNull);
      expect(
        result.diagnostics.single.code,
        SceneRuntimePlanDiagnosticCode.unsupportedAction,
      );
      expect(result.diagnostics.single.nodeId, 'node_action');
    });

    test('branchByOutcome nodes produce unsupported diagnostics and no plan',
        () {
      final scene = _sceneWithSingleMiddleNode(
        SceneNode(
          id: 'node_branch',
          kind: SceneNodeKind.branchByOutcome,
          payload: SceneBranchByOutcomePayload(sourceNodeId: 'node_dialogue'),
        ),
        outgoingEdgeKind: SceneEdgeKind.branchOutcome,
      );

      final result = buildSceneRuntimePlan(scene);

      expect(result.canBuild, isFalse);
      expect(result.plan, isNull);
      expect(
        result.diagnostics.single.code,
        SceneRuntimePlanDiagnosticCode.unsupportedBranchByOutcome,
      );
      expect(result.diagnostics.single.nodeId, 'node_branch');
    });

    test('does not mutate the original SceneAsset', () {
      final scene = _minimalScene(
        declaredOutcomes: [
          SceneOutcome(id: 'scene_done', label: 'Done'),
        ],
      );
      final beforeJson = scene.toJson();

      buildSceneRuntimePlan(scene);

      expect(scene.toJson(), beforeJson);
    });
  });
}

SceneAsset _minimalScene({
  SceneGraphLayout? layout,
  List<SceneOutcome> declaredOutcomes = const [],
}) {
  return SceneAsset(
    id: 'scene_test',
    name: 'Runtime Plan Test',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_end',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
    layout: layout ??
        SceneGraphLayout(
          nodeLayouts: [
            SceneNodeLayout(nodeId: 'node_start', x: 24, y: 80),
            SceneNodeLayout(nodeId: 'node_end', x: 320, y: 80),
          ],
        ),
    declaredOutcomes: declaredOutcomes,
  );
}

SceneAsset _sceneWithSingleMiddleNode(
  SceneNode middleNode, {
  SceneEdgeKind incomingEdgeKind = SceneEdgeKind.defaultFlow,
  String outgoingPortId = 'completed',
  SceneEdgeKind outgoingEdgeKind = SceneEdgeKind.defaultFlow,
}) {
  return SceneAsset(
    id: 'scene_test',
    name: 'Runtime Plan Test',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        middleNode,
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_middle',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: middleNode.id,
          kind: incomingEdgeKind,
        ),
        SceneEdge(
          id: 'edge_middle_end',
          fromNodeId: middleNode.id,
          fromPortId: outgoingPortId,
          toNodeId: 'node_end',
          kind: outgoingEdgeKind,
        ),
      ],
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [
        SceneNodeLayout(nodeId: 'node_start', x: 24, y: 80),
        SceneNodeLayout(nodeId: middleNode.id, x: 324, y: 80),
        SceneNodeLayout(nodeId: 'node_end', x: 624, y: 80),
      ],
    ),
  );
}

SceneConditionPayload _factConditionPayload() {
  return SceneConditionPayload(
    conditionLabel: 'Fact test',
    conditionRef: 'fact_test',
    conditionSource: SceneConditionSource(
      sourceKind: SceneConditionSourceKind.factLikeStoryFlag,
      sourceId: 'fact_test',
      operator: SceneConditionOperator.isTrue,
      label: 'Fact test',
    ),
  );
}
