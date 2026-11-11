import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

({List<SceneRuntimePlanDiagnostic> diagnostics, bool canCompile}) _check(
  SceneAsset scene,
) {
  final result = checkSceneRuntimeCompilation(scene);
  return (diagnostics: result.diagnostics, canCompile: result.canCompile);
}

SceneAsset _scene(List<SceneNode> middle, List<SceneEdge> edges) => SceneAsset(
      id: 'scene_check',
      name: 'Check',
      graph: SceneGraph(
        startNodeId: 'node_start',
        nodes: [
          SceneNode(id: 'node_start', kind: SceneNodeKind.start),
          ...middle,
          SceneNode(id: 'node_end', kind: SceneNodeKind.end),
        ],
        edges: edges,
      ),
      layout: SceneGraphLayout(
        nodeLayouts: [
          SceneNodeLayout(nodeId: 'node_start', x: 0, y: 0),
          for (final node in middle)
            SceneNodeLayout(nodeId: node.id, x: 100, y: 0),
          SceneNodeLayout(nodeId: 'node_end', x: 200, y: 0),
        ],
      ),
    );

SceneEdge _edge(
  String id,
  String from,
  String to, {
  String port = 'completed',
  SceneEdgeKind kind = SceneEdgeKind.defaultFlow,
}) =>
    SceneEdge(
      id: id,
      fromNodeId: from,
      fromPortId: port,
      toNodeId: to,
      kind: kind,
    );

SceneAsset _branch(String? sourceNodeId) => _scene(
      [
        SceneNode(
          id: 'node_branch',
          kind: SceneNodeKind.branchByOutcome,
          payload: SceneBranchByOutcomePayload(sourceNodeId: sourceNodeId),
        ),
      ],
      [
        _edge('e1', 'node_start', 'node_branch'),
        _edge('e2', 'node_branch', 'node_end'),
      ],
    );

String _describe(SceneRuntimePlanDiagnostic d) => [
      d.code.name,
      d.severity.name,
      d.sceneId,
      d.nodeId,
      d.edgeId,
      d.sourceSceneDiagnosticCode?.name,
      d.capabilityIssueCode?.name,
      d.message,
    ].join('|');

const _blockedPort =
    'planBuildBlockedBySceneDiagnostics|error|scene_check|node_branch|e2|edgeFromPortUnsupported|null|La scène ne peut pas être compilée: Un lien part d’un port non supporté pour ce nœud.';

void main() {
  test('a minimal scene compiles without diagnostics', () {
    final check = _check(_scene([], [_edge('e1', 'node_start', 'node_end')]));

    expect(check.canCompile, isTrue);
    expect(check.diagnostics, isEmpty);
  });

  test('legacy actions without typed behavior block compilation', () {
    final check = _check(_scene(
      [
        SceneNode(
          id: 'node_action',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload(actionKind: 'legacy'),
        ),
      ],
      [
        _edge('e1', 'node_start', 'node_action'),
        _edge('e2', 'node_action', 'node_end',
            kind: SceneEdgeKind.actionCompleted),
      ],
    ));

    expect(check.canCompile, isFalse);
    expect(check.diagnostics.map(_describe), [
      'unsupportedAction|error|scene_check|node_action|null|null|null|ActionNode legacy sans conséquence ou commande typée reste non exécutable.',
    ]);
  });

  test('invalid branch sources keep scene diagnostics before plan diagnostics',
      () {
    expect(_check(_branch(null)).canCompile, isFalse);
    expect(_check(_branch(null)).diagnostics.map(_describe), [
      _blockedPort,
      'planBuildBlockedBySceneDiagnostics|error|scene_check|node_branch|null|branchSourceMissing|null|La scène ne peut pas être compilée: La branche doit choisir un nœud producteur d’outcome.',
      'branchSourceMissing|error|scene_check|node_branch|null|null|null|BranchByOutcome doit choisir un nœud source.',
    ]);
    expect(_check(_branch('ghost')).diagnostics.map(_describe), [
      _blockedPort,
      'planBuildBlockedBySceneDiagnostics|error|scene_check|node_branch|null|branchSourceUnknown|null|La scène ne peut pas être compilée: Le nœud producteur d’outcome n’existe plus.',
      'branchSourceUnknown|error|scene_check|node_branch|null|null|null|BranchByOutcome référence un nœud source introuvable.',
    ]);
    expect(_check(_branch('node_start')).diagnostics.map(_describe), [
      _blockedPort,
      'planBuildBlockedBySceneDiagnostics|error|scene_check|node_branch|null|branchSourceHasNoOutcomes|null|La scène ne peut pas être compilée: Le nœud choisi ne produit aucun outcome routable.',
      'branchSourceHasNoOutcomes|error|scene_check|node_branch|null|null|null|Le nœud source de BranchByOutcome ne produit aucun outcome.',
    ]);
  });

  test('cinematic bridge warnings do not block compilation', () {
    final check = _check(_scene(
      [
        SceneNode(
          id: 'node_cinematic',
          kind: SceneNodeKind.cinematic,
          payload: SceneCinematicPayload(cinematicId: 'c1'),
        ),
      ],
      [
        _edge('e1', 'node_start', 'node_cinematic'),
        _edge('e2', 'node_cinematic', 'node_end',
            kind: SceneEdgeKind.cinematicCompleted),
      ],
    ));

    expect(check.canCompile, isTrue);
    expect(check.diagnostics.map(_describe), [
      'cinematicBridgeOnly|warning|scene_check|node_cinematic|null|null|null|CinematicNode est compilé comme intent déclaratif bridgeOnly.',
    ]);
  });

  test('scene diagnostics errors are converted with their source code', () {
    final check = _check(_scene(
      [
        SceneNode(
          id: 'node_condition',
          kind: SceneNodeKind.condition,
          payload: SceneConditionPayload(conditionLabel: 'x'),
        ),
      ],
      [
        _edge('e1', 'node_start', 'node_condition'),
        _edge('e2', 'node_condition', 'node_end',
            port: 'true', kind: SceneEdgeKind.conditionTrue),
      ],
    ));

    expect(check.canCompile, isFalse);
    expect(check.diagnostics.map(_describe), [
      'planBuildBlockedBySceneDiagnostics|error|scene_check|node_condition|null|conditionSourceMissing|null|La scène ne peut pas être compilée: La condition doit choisir une source métier V0.',
    ]);
  });

  test('declared outcome ports keep order and defaults', () {
    expect(
      declaredSceneNodeOutcomePorts(SceneNode(
        id: 'dialogue',
        kind: SceneNodeKind.yarnDialogue,
        payload: SceneYarnDialoguePayload(
          dialogueId: 'd',
          yarnNodeName: 'n',
          expectedOutcomes: ['accepted', 'completed', 'refused'],
        ),
      )),
      ['completed', 'accepted', 'refused'],
    );
    expect(
      declaredSceneNodeOutcomePorts(SceneNode(
        id: 'battle',
        kind: SceneNodeKind.battle,
        payload: SceneBattlePayload(battleKind: 'trainer'),
      )),
      ['victory', 'defeat'],
    );
    expect(
      declaredSceneNodeOutcomePorts(SceneNode(
        id: 'condition',
        kind: SceneNodeKind.condition,
        payload: SceneConditionPayload(conditionLabel: 'x'),
      )),
      ['true', 'false'],
    );
    expect(
      declaredSceneNodeOutcomePorts(
          SceneNode(id: 'start', kind: SceneNodeKind.start)),
      isEmpty,
    );
  });
}
