import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Scene diagnostics', () {
    test('V1-08 minimal draft has no blocking error', () {
      final result = createSceneDraftInProject(
        _project(),
        name: 'Minimal draft',
      );

      final report = diagnoseScene(result.createdScene);

      expect(report.hasErrors, isFalse);
      expect(report.byCode(SceneDiagnosticCode.missingEndNode), isEmpty);
      expect(report.byCode(SceneDiagnosticCode.layoutMissingNode), isEmpty);
    });

    test('scene without end node emits missingEndNode error', () {
      final scene = _scene(
        nodes: [
          SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        ],
        edges: const [],
      );

      final report = diagnoseScene(scene);

      expect(report.hasErrors, isTrue);
      final diagnostic =
          report.byCode(SceneDiagnosticCode.missingEndNode).single;
      expect(diagnostic.severity, SceneDiagnosticSeverity.error);
      expect(diagnostic.sceneId, scene.id);
      expect(diagnostic.message, 'La scène n’a pas de fin.');
    });

    test('end outcome absent from declared outcomes emits error', () {
      final scene = _scene(
        nodes: [
          SceneNode(id: 'node_start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'node_end',
            kind: SceneNodeKind.end,
            payload: SceneEndPayload(sceneOutcomeId: 'outcome_done'),
          ),
        ],
      );

      final report = diagnoseScene(scene);

      final diagnostic =
          report.byCode(SceneDiagnosticCode.endOutcomeUndeclared).single;
      expect(diagnostic.severity, SceneDiagnosticSeverity.error);
      expect(diagnostic.sceneId, scene.id);
      expect(diagnostic.nodeId, 'node_end');
      expect(diagnostic.outcomeId, 'outcome_done');
    });

    test('declared outcome never emitted by an end node emits warning', () {
      final scene = _scene(
        declaredOutcomes: [
          SceneOutcome(id: 'outcome_done', label: 'Done'),
        ],
      );

      final report = diagnoseScene(scene);

      final diagnostic =
          report.byCode(SceneDiagnosticCode.declaredOutcomeUnused).single;
      expect(diagnostic.severity, SceneDiagnosticSeverity.warning);
      expect(diagnostic.sceneId, scene.id);
      expect(diagnostic.outcomeId, 'outcome_done');
    });

    test('incomplete layout emits layoutMissingNode warning', () {
      final scene = _scene(
        layout: SceneGraphLayout(
          nodeLayouts: [
            SceneNodeLayout(nodeId: 'node_start', x: 24, y: 80),
          ],
        ),
      );

      final report = diagnoseScene(scene);

      final diagnostic =
          report.byCode(SceneDiagnosticCode.layoutMissingNode).single;
      expect(diagnostic.severity, SceneDiagnosticSeverity.warning);
      expect(diagnostic.sceneId, scene.id);
      expect(diagnostic.nodeId, 'node_end');
    });

    test('complete layout does not emit layoutMissingNode', () {
      final scene = _scene();

      final report = diagnoseScene(scene);

      expect(report.byCode(SceneDiagnosticCode.layoutMissingNode), isEmpty);
    });

    test('condition node without source emits blocking diagnostic', () {
      final scene = _scene(
        nodes: [
          SceneNode(id: 'node_start', kind: SceneNodeKind.start),
          SceneNode(id: 'node_condition', kind: SceneNodeKind.condition),
          SceneNode(id: 'node_end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'edge_start_condition',
            fromNodeId: 'node_start',
            fromPortId: 'completed',
            toNodeId: 'node_condition',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'edge_condition_end',
            fromNodeId: 'node_condition',
            fromPortId: 'true',
            toNodeId: 'node_end',
            kind: SceneEdgeKind.conditionTrue,
          ),
        ],
      );

      final report = diagnoseScene(scene);

      final diagnostic =
          report.byCode(SceneDiagnosticCode.conditionSourceMissing).single;
      expect(diagnostic.severity, SceneDiagnosticSeverity.error);
      expect(diagnostic.nodeId, 'node_condition');
      expect(
        diagnostic.message,
        'La condition doit choisir une source métier V0.',
      );
    });

    test('configured V0 condition source has no condition error', () {
      final scene = _scene(
        nodes: [
          SceneNode(id: 'node_start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'node_condition',
            kind: SceneNodeKind.condition,
            payload: SceneConditionPayload(
              conditionSource: SceneConditionSource(
                sourceKind: SceneConditionSourceKind.factLikeStoryFlag,
                sourceId: 'story_flag.harbor_fog_seen',
                operator: SceneConditionOperator.isTrue,
                label: 'Le joueur a vu la brume',
                debugTechnicalLabel: 'story_flag.harbor_fog_seen',
              ),
            ),
          ),
          SceneNode(id: 'node_end', kind: SceneNodeKind.end),
        ],
      );

      final report = diagnoseScene(scene);

      expect(
          report.byCode(SceneDiagnosticCode.conditionSourceMissing), isEmpty);
      expect(report.byCode(SceneDiagnosticCode.conditionUsesFutureSource),
          isEmpty);
      expect(report.byCode(SceneDiagnosticCode.conditionOperatorUnsupported),
          isEmpty);
    });

    test('incompatible edge port emits blocking diagnostic', () {
      final scene = _scene(
        edges: [
          SceneEdge(
            id: 'edge_start_end',
            fromNodeId: 'node_start',
            fromPortId: 'missing',
            toNodeId: 'node_end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      );

      final report = diagnoseScene(scene);

      final diagnostic =
          report.byCode(SceneDiagnosticCode.edgeFromPortUnsupported).single;
      expect(diagnostic.severity, SceneDiagnosticSeverity.error);
      expect(diagnostic.edgeId, 'edge_start_end');
      expect(diagnostic.nodeId, 'node_start');
    });

    test('edge kind mismatch emits blocking diagnostic', () {
      final scene = _scene(
        nodes: [
          SceneNode(id: 'node_start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'node_condition',
            kind: SceneNodeKind.condition,
            payload: _factConditionPayload(),
          ),
          SceneNode(id: 'node_end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'edge_start_condition',
            fromNodeId: 'node_start',
            fromPortId: 'completed',
            toNodeId: 'node_condition',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'edge_condition_end',
            fromNodeId: 'node_condition',
            fromPortId: 'true',
            toNodeId: 'node_end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      );

      final report = diagnoseScene(scene);

      final diagnostic =
          report.byCode(SceneDiagnosticCode.edgeKindUnsupportedForPort).single;
      expect(diagnostic.severity, SceneDiagnosticSeverity.error);
      expect(diagnostic.edgeId, 'edge_condition_end');
      expect(diagnostic.nodeId, 'node_condition');
    });

    test('duplicate edge from single output port emits blocking diagnostic',
        () {
      final scene = _scene(
        nodes: [
          SceneNode(id: 'node_start', kind: SceneNodeKind.start),
          SceneNode(id: 'node_end', kind: SceneNodeKind.end),
          SceneNode(id: 'node_end_2', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'edge_start_end',
            fromNodeId: 'node_start',
            fromPortId: 'completed',
            toNodeId: 'node_end',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'edge_start_end_2',
            fromNodeId: 'node_start',
            fromPortId: 'completed',
            toNodeId: 'node_end_2',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      );

      final report = diagnoseScene(scene);

      final diagnostic =
          report.byCode(SceneDiagnosticCode.duplicateOutgoingPortEdge).single;
      expect(diagnostic.severity, SceneDiagnosticSeverity.error);
      expect(diagnostic.nodeId, 'node_start');
      expect(diagnostic.edgeId, 'edge_start_end_2');
    });

    test('missing required condition output emits warning', () {
      final scene = _scene(
        nodes: [
          SceneNode(id: 'node_start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'node_condition',
            kind: SceneNodeKind.condition,
            payload: _factConditionPayload(),
          ),
          SceneNode(id: 'node_end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'edge_start_condition',
            fromNodeId: 'node_start',
            fromPortId: 'completed',
            toNodeId: 'node_condition',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'edge_condition_end',
            fromNodeId: 'node_condition',
            fromPortId: 'true',
            toNodeId: 'node_end',
            kind: SceneEdgeKind.conditionTrue,
          ),
        ],
      );

      final report = diagnoseScene(scene);

      final diagnostic =
          report.byCode(SceneDiagnosticCode.requiredOutputPortMissing).single;
      expect(diagnostic.severity, SceneDiagnosticSeverity.warning);
      expect(diagnostic.nodeId, 'node_condition');
      expect(diagnostic.suggestedFixLabel, contains('false'));
    });

    test('dialogue completed output is validated as default flow', () {
      final scene = _scene(
        nodes: [
          SceneNode(id: 'node_start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'node_dialogue',
            kind: SceneNodeKind.yarnDialogue,
            payload: SceneYarnDialoguePayload(dialogueId: 'dialogue_test'),
          ),
          SceneNode(id: 'node_end', kind: SceneNodeKind.end),
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
            id: 'edge_dialogue_end',
            fromNodeId: 'node_dialogue',
            fromPortId: 'completed',
            toNodeId: 'node_end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      );

      final report = diagnoseScene(scene);

      expect(
          report.byCode(SceneDiagnosticCode.edgeFromPortUnsupported), isEmpty);
      expect(
        report.byCode(SceneDiagnosticCode.edgeKindUnsupportedForPort),
        isEmpty,
      );
      expect(
        report
            .byCode(SceneDiagnosticCode.requiredOutputPortMissing)
            .where((diagnostic) => diagnostic.nodeId == 'node_dialogue'),
        isEmpty,
      );
    });

    test('dialogue missing, invalid and duplicate outputs are diagnosed', () {
      final missingScene = _scene(
        nodes: [
          SceneNode(id: 'node_start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'node_dialogue',
            kind: SceneNodeKind.yarnDialogue,
            payload: SceneYarnDialoguePayload(dialogueId: 'dialogue_test'),
          ),
          SceneNode(id: 'node_end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'edge_start_dialogue',
            fromNodeId: 'node_start',
            fromPortId: 'completed',
            toNodeId: 'node_dialogue',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      );
      final invalidKindScene = _scene(
        nodes: missingScene.graph.nodes,
        edges: [
          ...missingScene.graph.edges,
          SceneEdge(
            id: 'edge_dialogue_end',
            fromNodeId: 'node_dialogue',
            fromPortId: 'completed',
            toNodeId: 'node_end',
            kind: SceneEdgeKind.dialogueOutcome,
          ),
        ],
      );
      final invalidPortScene = _scene(
        nodes: missingScene.graph.nodes,
        edges: [
          ...missingScene.graph.edges,
          SceneEdge(
            id: 'edge_dialogue_end',
            fromNodeId: 'node_dialogue',
            fromPortId: 'accept',
            toNodeId: 'node_end',
            kind: SceneEdgeKind.dialogueOutcome,
          ),
        ],
      );
      final duplicateScene = _scene(
        nodes: [
          ...missingScene.graph.nodes,
          SceneNode(id: 'node_end_2', kind: SceneNodeKind.end),
        ],
        edges: [
          ...missingScene.graph.edges,
          SceneEdge(
            id: 'edge_dialogue_end',
            fromNodeId: 'node_dialogue',
            fromPortId: 'completed',
            toNodeId: 'node_end',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'edge_dialogue_end_2',
            fromNodeId: 'node_dialogue',
            fromPortId: 'completed',
            toNodeId: 'node_end_2',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      );

      final missingDiagnostic = diagnoseScene(missingScene)
          .byCode(SceneDiagnosticCode.requiredOutputPortMissing)
          .singleWhere((diagnostic) => diagnostic.nodeId == 'node_dialogue');
      expect(missingDiagnostic.severity, SceneDiagnosticSeverity.warning);
      expect(missingDiagnostic.suggestedFixLabel, contains('completed'));
      expect(
        diagnoseScene(invalidKindScene)
            .byCode(SceneDiagnosticCode.edgeKindUnsupportedForPort)
            .single
            .severity,
        SceneDiagnosticSeverity.error,
      );
      expect(
        diagnoseScene(invalidPortScene)
            .byCode(SceneDiagnosticCode.edgeFromPortUnsupported)
            .single
            .severity,
        SceneDiagnosticSeverity.error,
      );
      expect(
        diagnoseScene(duplicateScene)
            .byCode(SceneDiagnosticCode.duplicateOutgoingPortEdge)
            .single
            .severity,
        SceneDiagnosticSeverity.error,
      );
    });

    test('cinematic completed output is validated as cinematic flow', () {
      final scene = _scene(
        nodes: [
          SceneNode(id: 'node_start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'node_cinematic',
            kind: SceneNodeKind.cinematic,
            payload: SceneCinematicPayload(cinematicId: 'cinematic_test'),
          ),
          SceneNode(id: 'node_end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'edge_start_cinematic',
            fromNodeId: 'node_start',
            fromPortId: 'completed',
            toNodeId: 'node_cinematic',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'edge_cinematic_end',
            fromNodeId: 'node_cinematic',
            fromPortId: 'completed',
            toNodeId: 'node_end',
            kind: SceneEdgeKind.cinematicCompleted,
          ),
        ],
      );

      final report = diagnoseScene(scene);

      expect(
          report.byCode(SceneDiagnosticCode.edgeFromPortUnsupported), isEmpty);
      expect(
        report.byCode(SceneDiagnosticCode.edgeKindUnsupportedForPort),
        isEmpty,
      );
      expect(
        report
            .byCode(SceneDiagnosticCode.requiredOutputPortMissing)
            .where((diagnostic) => diagnostic.nodeId == 'node_cinematic'),
        isEmpty,
      );
    });

    test('cinematic missing, invalid and duplicate outputs are diagnosed', () {
      final missingScene = _scene(
        nodes: [
          SceneNode(id: 'node_start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'node_cinematic',
            kind: SceneNodeKind.cinematic,
            payload: SceneCinematicPayload(cinematicId: 'cinematic_test'),
          ),
          SceneNode(id: 'node_end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'edge_start_cinematic',
            fromNodeId: 'node_start',
            fromPortId: 'completed',
            toNodeId: 'node_cinematic',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      );
      final invalidKindScene = _scene(
        nodes: missingScene.graph.nodes,
        edges: [
          ...missingScene.graph.edges,
          SceneEdge(
            id: 'edge_cinematic_end',
            fromNodeId: 'node_cinematic',
            fromPortId: 'completed',
            toNodeId: 'node_end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      );
      final invalidPortScene = _scene(
        nodes: missingScene.graph.nodes,
        edges: [
          ...missingScene.graph.edges,
          SceneEdge(
            id: 'edge_cinematic_end',
            fromNodeId: 'node_cinematic',
            fromPortId: 'skipped',
            toNodeId: 'node_end',
            kind: SceneEdgeKind.cinematicCompleted,
          ),
        ],
      );
      final duplicateScene = _scene(
        nodes: [
          ...missingScene.graph.nodes,
          SceneNode(id: 'node_end_2', kind: SceneNodeKind.end),
        ],
        edges: [
          ...missingScene.graph.edges,
          SceneEdge(
            id: 'edge_cinematic_end',
            fromNodeId: 'node_cinematic',
            fromPortId: 'completed',
            toNodeId: 'node_end',
            kind: SceneEdgeKind.cinematicCompleted,
          ),
          SceneEdge(
            id: 'edge_cinematic_end_2',
            fromNodeId: 'node_cinematic',
            fromPortId: 'completed',
            toNodeId: 'node_end_2',
            kind: SceneEdgeKind.cinematicCompleted,
          ),
        ],
      );

      final missingDiagnostic = diagnoseScene(missingScene)
          .byCode(SceneDiagnosticCode.requiredOutputPortMissing)
          .singleWhere((diagnostic) => diagnostic.nodeId == 'node_cinematic');
      expect(missingDiagnostic.severity, SceneDiagnosticSeverity.warning);
      expect(missingDiagnostic.suggestedFixLabel, contains('completed'));
      expect(
        diagnoseScene(invalidKindScene)
            .byCode(SceneDiagnosticCode.edgeKindUnsupportedForPort)
            .single
            .severity,
        SceneDiagnosticSeverity.error,
      );
      expect(
        diagnoseScene(invalidPortScene)
            .byCode(SceneDiagnosticCode.edgeFromPortUnsupported)
            .single
            .severity,
        SceneDiagnosticSeverity.error,
      );
      expect(
        diagnoseScene(duplicateScene)
            .byCode(SceneDiagnosticCode.duplicateOutgoingPortEdge)
            .single
            .severity,
        SceneDiagnosticSeverity.error,
      );
    });

    test('battle victory and defeat outputs are validated', () {
      final scene = _battleScene(
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
            toNodeId: 'node_end',
            kind: SceneEdgeKind.battleVictory,
          ),
          SceneEdge(
            id: 'edge_battle_defeat',
            fromNodeId: 'node_battle',
            fromPortId: 'defeat',
            toNodeId: 'node_end_2',
            kind: SceneEdgeKind.battleDefeat,
          ),
        ],
      );

      final report = diagnoseScene(scene);

      expect(
          report.byCode(SceneDiagnosticCode.edgeFromPortUnsupported), isEmpty);
      expect(
        report.byCode(SceneDiagnosticCode.edgeKindUnsupportedForPort),
        isEmpty,
      );
      expect(
        report
            .byCode(SceneDiagnosticCode.requiredOutputPortMissing)
            .where((diagnostic) => diagnostic.nodeId == 'node_battle'),
        isEmpty,
      );
    });

    test('battle missing, invalid and duplicate outputs are diagnosed', () {
      final missingScene = _battleScene(
        edges: [
          SceneEdge(
            id: 'edge_start_battle',
            fromNodeId: 'node_start',
            fromPortId: 'completed',
            toNodeId: 'node_battle',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      );
      final invalidKindScene = _battleScene(
        edges: [
          ...missingScene.graph.edges,
          SceneEdge(
            id: 'edge_battle_victory',
            fromNodeId: 'node_battle',
            fromPortId: 'victory',
            toNodeId: 'node_end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      );
      final invalidPortScene = _battleScene(
        edges: [
          ...missingScene.graph.edges,
          SceneEdge(
            id: 'edge_battle_completed',
            fromNodeId: 'node_battle',
            fromPortId: 'completed',
            toNodeId: 'node_end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      );
      final duplicateScene = _battleScene(
        edges: [
          ...missingScene.graph.edges,
          SceneEdge(
            id: 'edge_battle_victory',
            fromNodeId: 'node_battle',
            fromPortId: 'victory',
            toNodeId: 'node_end',
            kind: SceneEdgeKind.battleVictory,
          ),
          SceneEdge(
            id: 'edge_battle_victory_2',
            fromNodeId: 'node_battle',
            fromPortId: 'victory',
            toNodeId: 'node_end_2',
            kind: SceneEdgeKind.battleVictory,
          ),
        ],
      );

      final missingBattleDiagnostics = diagnoseScene(missingScene)
          .byCode(SceneDiagnosticCode.requiredOutputPortMissing)
          .where((diagnostic) => diagnostic.nodeId == 'node_battle')
          .toList();
      expect(missingBattleDiagnostics, hasLength(2));
      expect(
        missingBattleDiagnostics
            .map((diagnostic) => diagnostic.suggestedFixLabel),
        containsAll([contains('victory'), contains('defeat')]),
      );
      expect(
        diagnoseScene(invalidKindScene)
            .byCode(SceneDiagnosticCode.edgeKindUnsupportedForPort)
            .single
            .severity,
        SceneDiagnosticSeverity.error,
      );
      expect(
        diagnoseScene(invalidPortScene)
            .byCode(SceneDiagnosticCode.edgeFromPortUnsupported)
            .single
            .severity,
        SceneDiagnosticSeverity.error,
      );
      expect(
        diagnoseScene(duplicateScene)
            .byCode(SceneDiagnosticCode.duplicateOutgoingPortEdge)
            .single
            .severity,
        SceneDiagnosticSeverity.error,
      );
    });

    test('unreachable node and unreachable end are diagnosed', () {
      final scene = _scene(
        nodes: [
          SceneNode(id: 'node_start', kind: SceneNodeKind.start),
          SceneNode(id: 'node_end', kind: SceneNodeKind.end),
          SceneNode(id: 'node_merge', kind: SceneNodeKind.merge),
          SceneNode(id: 'node_end_2', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'edge_start_end',
            fromNodeId: 'node_start',
            fromPortId: 'completed',
            toNodeId: 'node_end',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'edge_merge_end_2',
            fromNodeId: 'node_merge',
            fromPortId: 'completed',
            toNodeId: 'node_end_2',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      );

      final report = diagnoseScene(scene);

      expect(
        report
            .byCode(SceneDiagnosticCode.unreachableNode)
            .map((diagnostic) => diagnostic.nodeId),
        containsAll(['node_merge', 'node_end_2']),
      );
      final unreachableEnd =
          report.byCode(SceneDiagnosticCode.unreachableEndNode).single;
      expect(unreachableEnd.severity, SceneDiagnosticSeverity.warning);
      expect(unreachableEnd.nodeId, 'node_end_2');
    });

    test('cycle reachable from start is diagnosed as unsupported warning', () {
      final scene = _scene(
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
            id: 'edge_start_condition',
            fromNodeId: 'node_start',
            fromPortId: 'completed',
            toNodeId: 'node_condition',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'edge_condition_merge',
            fromNodeId: 'node_condition',
            fromPortId: 'true',
            toNodeId: 'node_merge',
            kind: SceneEdgeKind.conditionTrue,
          ),
          SceneEdge(
            id: 'edge_merge_condition',
            fromNodeId: 'node_merge',
            fromPortId: 'completed',
            toNodeId: 'node_condition',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'edge_condition_end',
            fromNodeId: 'node_condition',
            fromPortId: 'false',
            toNodeId: 'node_end',
            kind: SceneEdgeKind.conditionFalse,
          ),
        ],
      );

      final report = diagnoseScene(scene);

      final diagnostic =
          report.byCode(SceneDiagnosticCode.cycleUnsupported).single;
      expect(diagnostic.severity, SceneDiagnosticSeverity.warning);
      expect(diagnostic.nodeId, 'node_condition');
    });

    test('legacy action and branch nodes remain unsupported authoring warnings',
        () {
      final scene = _scene(
        nodes: [
          SceneNode(id: 'node_start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'node_action',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload(actionKind: 'action_test'),
          ),
          SceneNode(
            id: 'node_branch',
            kind: SceneNodeKind.branchByOutcome,
          ),
          SceneNode(id: 'node_end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'edge_start_action',
            fromNodeId: 'node_start',
            fromPortId: 'completed',
            toNodeId: 'node_action',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'edge_action_branch',
            fromNodeId: 'node_action',
            fromPortId: 'completed',
            toNodeId: 'node_branch',
            kind: SceneEdgeKind.actionCompleted,
          ),
          SceneEdge(
            id: 'edge_branch_end',
            fromNodeId: 'node_branch',
            fromPortId: 'fallback',
            toNodeId: 'node_end',
            kind: SceneEdgeKind.branchOutcome,
          ),
        ],
      );

      final report = diagnoseScene(scene);

      expect(
        report
            .byCode(SceneDiagnosticCode.actionPayloadLegacyUnsupported)
            .single
            .severity,
        SceneDiagnosticSeverity.warning,
      );
      expect(
        report
            .byCode(SceneDiagnosticCode.branchByOutcomeUnsupported)
            .single
            .severity,
        SceneDiagnosticSeverity.warning,
      );
    });

    test('typed consequence action does not emit raw action warning', () {
      final scene = _scene(
        nodes: [
          SceneNode(id: 'node_start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'node_action_set_fact',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(
              SceneConsequence.setFact(
                factId: 'fact_test_gate_unlocked',
                value: true,
              ),
            ),
          ),
          SceneNode(id: 'node_end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'edge_start_action',
            fromNodeId: 'node_start',
            fromPortId: 'completed',
            toNodeId: 'node_action_set_fact',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'edge_action_end',
            fromNodeId: 'node_action_set_fact',
            fromPortId: 'completed',
            toNodeId: 'node_end',
            kind: SceneEdgeKind.actionCompleted,
          ),
        ],
      );

      final report = diagnoseScene(scene);

      expect(
        report.byCode(SceneDiagnosticCode.actionPayloadLegacyUnsupported),
        isEmpty,
      );
    });

    test('fact source references must resolve against ProjectManifest facts',
        () {
      final scene = _scene(
        nodes: [
          SceneNode(id: 'node_start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'node_condition',
            kind: SceneNodeKind.condition,
            payload: SceneConditionPayload(
              conditionSource: SceneConditionSource(
                sourceKind: SceneConditionSourceKind.fact,
                sourceId: 'fact_harbor_fog_seen',
                operator: SceneConditionOperator.isTrue,
                label: 'Brume vue au port',
              ),
            ),
          ),
          SceneNode(id: 'node_end', kind: SceneNodeKind.end),
        ],
      );

      final missingReport = diagnoseSceneAgainstProject(scene, _project());

      final diagnostic = missingReport
          .byCode(SceneDiagnosticCode.conditionFactRefUnknown)
          .single;
      expect(diagnostic.severity, SceneDiagnosticSeverity.error);
      expect(diagnostic.nodeId, 'node_condition');

      final validReport = diagnoseSceneAgainstProject(
        scene,
        _project(
          facts: [
            NarrativeFactDefinition(
              id: 'fact_harbor_fog_seen',
              label: 'Brume vue au port',
            ),
          ],
        ),
      );

      expect(validReport.byCode(SceneDiagnosticCode.conditionFactRefUnknown),
          isEmpty);
      expect(validReport.byCode(SceneDiagnosticCode.conditionSourceMissing),
          isEmpty);
    });

    test('setFact consequence references must resolve against facts', () {
      final scene = _scene(
        nodes: [
          SceneNode(id: 'node_start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'node_action_set_fact',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(
              SceneConsequence.setFact(
                factId: 'fact_test_gate_unlocked',
                value: true,
              ),
            ),
          ),
          SceneNode(id: 'node_end', kind: SceneNodeKind.end),
        ],
      );

      final missingReport = diagnoseSceneAgainstProject(scene, _project());

      final diagnostic = missingReport
          .byCode(SceneDiagnosticCode.consequenceUnknownFact)
          .single;
      expect(diagnostic.severity, SceneDiagnosticSeverity.error);
      expect(diagnostic.nodeId, 'node_action_set_fact');

      final validReport = diagnoseSceneAgainstProject(
        scene,
        _project(
          facts: [
            NarrativeFactDefinition(
              id: 'fact_test_gate_unlocked',
              label: 'Test gate unlocked',
            ),
          ],
        ),
      );

      expect(
        validReport.byCode(SceneDiagnosticCode.consequenceUnknownFact),
        isEmpty,
      );
    });

    test('markEventConsumed consequence references must resolve against maps',
        () {
      final scene = _scene(
        nodes: [
          SceneNode(id: 'node_start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'node_action_mark_event',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(
              SceneConsequence.markEventConsumed(
                mapId: 'map_test',
                eventId: 'event_gate',
              ),
            ),
          ),
          SceneNode(id: 'node_end', kind: SceneNodeKind.end),
        ],
      );

      final missingMapReport = diagnoseSceneAgainstProject(
        scene,
        _project(),
      );
      expect(
        missingMapReport
            .byCode(SceneDiagnosticCode.consequenceUnknownEvent)
            .single
            .severity,
        SceneDiagnosticSeverity.error,
      );

      final missingEventReport = diagnoseSceneAgainstProject(
        scene,
        _project(
          maps: const [
            ProjectMapEntry(
              id: 'map_test',
              name: 'Map Test',
              relativePath: 'maps/map_test.json',
            ),
          ],
        ),
        mapsById: {
          'map_test': _map(events: const []),
        },
      );
      expect(
        missingEventReport
            .byCode(SceneDiagnosticCode.consequenceUnknownEvent)
            .single
            .message,
        contains('event'),
      );

      final validReport = diagnoseSceneAgainstProject(
        scene,
        _project(
          maps: const [
            ProjectMapEntry(
              id: 'map_test',
              name: 'Map Test',
              relativePath: 'maps/map_test.json',
            ),
          ],
        ),
        mapsById: {
          'map_test': _map(
            events: [
              _event(id: 'event_gate'),
            ],
          ),
        },
      );

      expect(
        validReport.byCode(SceneDiagnosticCode.consequenceUnknownEvent),
        isEmpty,
      );
    });

    test('future and incomplete condition sources are diagnosed', () {
      final futureScene = _scene(
        nodes: [
          SceneNode(id: 'node_start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'node_condition',
            kind: SceneNodeKind.condition,
            payload: SceneConditionPayload(
              conditionSource: SceneConditionSource(
                sourceKind: SceneConditionSourceKind.inventoryItem,
                sourceId: 'item_potion',
                operator: SceneConditionOperator.isTrue,
                label: 'Potion possédée',
              ),
            ),
          ),
          SceneNode(id: 'node_end', kind: SceneNodeKind.end),
        ],
      );
      final missingValueScene = _scene(
        nodes: [
          SceneNode(id: 'node_start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'node_condition',
            kind: SceneNodeKind.condition,
            payload: SceneConditionPayload(
              conditionSource: SceneConditionSource(
                sourceKind: SceneConditionSourceKind.storyStepCompletion,
                sourceId: 'step_intro_completed',
                operator: SceneConditionOperator.equals,
                label: 'Introduction terminée',
              ),
            ),
          ),
          SceneNode(id: 'node_end', kind: SceneNodeKind.end),
        ],
      );

      expect(
        diagnoseScene(futureScene)
            .byCode(SceneDiagnosticCode.conditionUsesFutureSource)
            .single
            .severity,
        SceneDiagnosticSeverity.error,
      );
      expect(
        diagnoseScene(missingValueScene)
            .byCode(SceneDiagnosticCode.conditionValueMissing)
            .single
            .severity,
        SceneDiagnosticSeverity.error,
      );
    });
  });
}

ProjectManifest _project({
  List<ProjectMapEntry> maps = const [],
  List<NarrativeFactDefinition> facts = const [],
  List<ProjectDialogueEntry> dialogues = const [],
  List<ProjectTrainerEntry> trainers = const [],
  List<ScenarioAsset> scenarios = const [],
  List<WorldRuleDefinition> worldRules = const [],
}) {
  return ProjectManifest(
    name: 'Scene diagnostics test',
    maps: maps,
    tilesets: const [],
    facts: facts,
    dialogues: dialogues,
    trainers: trainers,
    scenarios: scenarios,
    worldRules: worldRules,
  );
}

MapData _map({
  List<MapEventDefinition> events = const [],
}) {
  return MapData(
    id: 'map_test',
    name: 'Map Test',
    size: const GridSize(width: 10, height: 10),
    events: events,
  );
}

MapEventDefinition _event({required String id}) {
  return MapEventDefinition(
    id: id,
    pages: const [
      MapEventPage(pageNumber: 0),
    ],
    position: const EventPosition(
      layerId: 'layer_test',
      x: 1,
      y: 1,
    ),
  );
}

SceneAsset _scene({
  List<SceneNode>? nodes,
  List<SceneEdge>? edges,
  SceneGraphLayout? layout,
  List<SceneOutcome> declaredOutcomes = const [],
}) {
  final graphNodes = nodes ??
      [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ];
  return SceneAsset(
    id: 'scene_diagnostic_test',
    name: 'Diagnostic Test Scene',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: graphNodes,
      edges: edges ??
          [
            if (graphNodes.any((node) => node.id == 'node_end'))
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
            if (graphNodes.any((node) => node.id == 'node_end'))
              SceneNodeLayout(nodeId: 'node_end', x: 320, y: 80),
          ],
        ),
    declaredOutcomes: declaredOutcomes,
  );
}

SceneConditionPayload _factConditionPayload() {
  return SceneConditionPayload(
    conditionSource: SceneConditionSource(
      sourceKind: SceneConditionSourceKind.factLikeStoryFlag,
      sourceId: 'flag_test',
      operator: SceneConditionOperator.isTrue,
      label: 'Flag test',
    ),
  );
}

SceneAsset _battleScene({
  required List<SceneEdge> edges,
}) {
  return _scene(
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
      SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      SceneNode(id: 'node_end_2', kind: SceneNodeKind.end),
    ],
    edges: edges,
  );
}
