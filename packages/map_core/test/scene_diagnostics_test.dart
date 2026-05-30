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
  List<NarrativeFactDefinition> facts = const [],
}) {
  return ProjectManifest(
    name: 'Scene diagnostics test',
    maps: const [],
    tilesets: const [],
    facts: facts,
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
