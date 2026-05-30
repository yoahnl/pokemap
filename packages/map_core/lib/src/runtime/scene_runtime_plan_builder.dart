import '../diagnostics/scene_diagnostics.dart';
import '../models/scene_asset.dart';
import 'scene_runtime_plan.dart';

SceneRuntimePlanBuildResult buildSceneRuntimePlan(SceneAsset scene) {
  final diagnostics = <SceneRuntimePlanDiagnostic>[];
  final sceneDiagnostics = diagnoseScene(scene);

  for (final diagnostic in sceneDiagnostics.diagnostics) {
    if (diagnostic.severity != SceneDiagnosticSeverity.error) {
      continue;
    }
    diagnostics.add(
      SceneRuntimePlanDiagnostic(
        code: SceneRuntimePlanDiagnosticCode.planBuildBlockedBySceneDiagnostics,
        severity: SceneRuntimePlanDiagnosticSeverity.error,
        message: 'La scène ne peut pas être compilée: ${diagnostic.message}',
        sceneId: scene.id,
        nodeId: diagnostic.nodeId,
        edgeId: diagnostic.edgeId,
        sourceSceneDiagnosticCode: diagnostic.code,
      ),
    );
  }

  for (final node in scene.graph.nodes) {
    switch (node.kind) {
      case SceneNodeKind.action:
        diagnostics.add(
          SceneRuntimePlanDiagnostic(
            code: SceneRuntimePlanDiagnosticCode.unsupportedAction,
            severity: SceneRuntimePlanDiagnosticSeverity.error,
            message: 'ActionNode n’a pas encore de contrat runtime public V0.',
            sceneId: scene.id,
            nodeId: node.id,
          ),
        );
      case SceneNodeKind.branchByOutcome:
        diagnostics.add(
          SceneRuntimePlanDiagnostic(
            code: SceneRuntimePlanDiagnosticCode.unsupportedBranchByOutcome,
            severity: SceneRuntimePlanDiagnosticSeverity.error,
            message: 'BranchByOutcome attend un mapping outcome -> edge futur.',
            sceneId: scene.id,
            nodeId: node.id,
          ),
        );
      case SceneNodeKind.cinematic:
        diagnostics.add(
          SceneRuntimePlanDiagnostic(
            code: SceneRuntimePlanDiagnosticCode.cinematicBridgeOnly,
            severity: SceneRuntimePlanDiagnosticSeverity.warning,
            message:
                'CinematicNode est compilé comme intent déclaratif bridgeOnly.',
            sceneId: scene.id,
            nodeId: node.id,
          ),
        );
      case SceneNodeKind.start:
      case SceneNodeKind.end:
      case SceneNodeKind.yarnDialogue:
      case SceneNodeKind.condition:
      case SceneNodeKind.battle:
      case SceneNodeKind.merge:
        break;
    }
  }

  final hasBlockingDiagnostic = diagnostics.any(
    (diagnostic) =>
        diagnostic.severity == SceneRuntimePlanDiagnosticSeverity.error,
  );
  if (hasBlockingDiagnostic) {
    return SceneRuntimePlanBuildResult(
      plan: null,
      diagnostics: diagnostics,
    );
  }

  return SceneRuntimePlanBuildResult(
    plan: SceneRuntimePlan(
      sceneId: scene.id,
      startNodeId: scene.graph.startNodeId,
      nodes: [
        for (final node in scene.graph.nodes)
          SceneRuntimePlanNode(
            id: node.id,
            kind: node.kind,
            title: node.title,
            description: node.description,
            intent: _runtimeIntentForNode(node),
          ),
      ],
      edges: [
        for (final edge in scene.graph.edges)
          SceneRuntimePlanEdge(
            id: edge.id,
            fromNodeId: edge.fromNodeId,
            fromPortId: edge.fromPortId,
            toNodeId: edge.toNodeId,
            kind: edge.kind,
            label: edge.label,
          ),
      ],
      declaredOutcomes: scene.declaredOutcomes,
    ),
    diagnostics: diagnostics,
  );
}

SceneRuntimePlanIntent _runtimeIntentForNode(SceneNode node) {
  return switch (node.kind) {
    SceneNodeKind.start => SceneRuntimePlanIntent.start(),
    SceneNodeKind.end => SceneRuntimePlanIntent.end(
        sceneOutcomeId: (node.payload as SceneEndPayload).sceneOutcomeId,
      ),
    SceneNodeKind.condition => SceneRuntimePlanIntent.evaluateCondition(
        source: (node.payload as SceneConditionPayload).conditionSource!,
      ),
    SceneNodeKind.merge => SceneRuntimePlanIntent.merge(),
    SceneNodeKind.yarnDialogue => _dialogueIntent(
        node.payload as SceneYarnDialoguePayload,
      ),
    SceneNodeKind.battle => _battleIntent(
        node.payload as SceneBattlePayload,
      ),
    SceneNodeKind.cinematic => SceneRuntimePlanIntent.playCinematic(
        cinematicId: (node.payload as SceneCinematicPayload).cinematicId,
      ),
    SceneNodeKind.action => throw StateError(
        'ActionNode must be blocked before runtime intent creation.',
      ),
    SceneNodeKind.branchByOutcome => throw StateError(
        'BranchByOutcome must be blocked before runtime intent creation.',
      ),
  };
}

SceneRuntimePlanIntent _dialogueIntent(SceneYarnDialoguePayload payload) {
  return SceneRuntimePlanIntent.showDialogue(
    dialogueId: payload.dialogueId,
    yarnNodeName: payload.yarnNodeName,
    expectedOutcomes: payload.expectedOutcomes,
  );
}

SceneRuntimePlanIntent _battleIntent(SceneBattlePayload payload) {
  return SceneRuntimePlanIntent.startBattle(
    battleKind: payload.battleKind,
    trainerId: payload.trainerId,
    battleTemplateId: payload.battleTemplateId,
    npcEntityId: payload.npcEntityId,
    declaredOutcomes: payload.declaredOutcomes,
  );
}
