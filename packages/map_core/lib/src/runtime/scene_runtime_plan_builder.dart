import '../diagnostics/scene_diagnostics.dart';
import '../models/scene_asset.dart';
import '../models/scene_execution_capabilities.dart';
import 'scene_runtime_plan.dart';

SceneRuntimePlanBuildResult buildSceneRuntimePlan(SceneAsset scene) {
  final diagnostics = <SceneRuntimePlanDiagnostic>[];
  final sceneDiagnostics = diagnoseScene(scene);
  final nodeById = <String, SceneNode>{
    for (final node in scene.graph.nodes) node.id: node,
  };

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
        capabilityIssueCode: diagnostic.capabilityIssueCode,
      ),
    );
  }

  for (final node in scene.graph.nodes) {
    switch (node.kind) {
      case SceneNodeKind.action:
        final payload = node.payload;
        if (payload is! SceneActionPayload ||
            (payload.consequence == null &&
                payload.interactiveCommand == null &&
                payload.preSessionInteraction == null)) {
          diagnostics.add(
            SceneRuntimePlanDiagnostic(
              code: SceneRuntimePlanDiagnosticCode.unsupportedAction,
              severity: SceneRuntimePlanDiagnosticSeverity.error,
              message:
                  'ActionNode legacy sans conséquence ou commande typée reste non exécutable.',
              sceneId: scene.id,
              nodeId: node.id,
            ),
          );
        }
      case SceneNodeKind.branchByOutcome:
        final payload = node.payload as SceneBranchByOutcomePayload;
        final sourceNodeId = payload.sourceNodeId;
        if (sourceNodeId == null) {
          diagnostics.add(
            SceneRuntimePlanDiagnostic(
              code: SceneRuntimePlanDiagnosticCode.branchSourceMissing,
              severity: SceneRuntimePlanDiagnosticSeverity.error,
              message: 'BranchByOutcome doit choisir un nœud source.',
              sceneId: scene.id,
              nodeId: node.id,
            ),
          );
          break;
        }
        final sourceNode = nodeById[sourceNodeId];
        if (sourceNode == null) {
          diagnostics.add(
            SceneRuntimePlanDiagnostic(
              code: SceneRuntimePlanDiagnosticCode.branchSourceUnknown,
              severity: SceneRuntimePlanDiagnosticSeverity.error,
              message: 'BranchByOutcome référence un nœud source introuvable.',
              sceneId: scene.id,
              nodeId: node.id,
            ),
          );
          break;
        }
        if (_declaredOutcomePortsForNode(sourceNode).isEmpty) {
          diagnostics.add(
            SceneRuntimePlanDiagnostic(
              code: SceneRuntimePlanDiagnosticCode.branchSourceHasNoOutcomes,
              severity: SceneRuntimePlanDiagnosticSeverity.error,
              message:
                  'Le nœud source de BranchByOutcome ne produit aucun outcome.',
              sceneId: scene.id,
              nodeId: node.id,
            ),
          );
        }
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
      case SceneNodeKind.presentationCinematic:
        break;
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
      executionProfile: scene.executionProfile,
      startNodeId: scene.graph.startNodeId,
      nodes: [
        for (final node in scene.graph.nodes)
          SceneRuntimePlanNode(
            id: node.id,
            kind: node.kind,
            title: node.title,
            description: node.description,
            capabilityId: sceneExecutionCapabilityForNode(
              scene.executionProfile,
              node,
            ),
            intent: _runtimeIntentForNode(node, nodeById),
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

SceneRuntimePlanIntent _runtimeIntentForNode(
  SceneNode node,
  Map<String, SceneNode> nodeById,
) {
  return switch (node.kind) {
    SceneNodeKind.start => SceneRuntimePlanIntent.start(),
    SceneNodeKind.end => SceneRuntimePlanIntent.end(
        sceneOutcomeId: (node.payload as SceneEndPayload).sceneOutcomeId,
        outcomePolicy: (node.payload as SceneEndPayload).outcomePolicy,
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
    SceneNodeKind.presentationCinematic =>
      SceneRuntimePlanIntent.playPresentationCinematic(
        presentationCinematicId:
            (node.payload as ScenePresentationCinematicPayload)
                .presentationCinematicId,
      ),
    SceneNodeKind.action => _actionIntent(
        node.payload as SceneActionPayload,
      ),
    SceneNodeKind.branchByOutcome => _branchIntent(
        node.payload as SceneBranchByOutcomePayload,
        nodeById,
      ),
  };
}

SceneRuntimePlanIntent _branchIntent(
  SceneBranchByOutcomePayload payload,
  Map<String, SceneNode> nodeById,
) {
  final sourceNodeId = payload.sourceNodeId;
  final sourceNode = sourceNodeId == null ? null : nodeById[sourceNodeId];
  if (sourceNodeId == null || sourceNode == null) {
    throw StateError(
      'Invalid BranchByOutcome must be blocked before intent creation.',
    );
  }
  return SceneRuntimePlanIntent.branchByOutcome(
    sourceNodeId: sourceNodeId,
    fallbackPolicy: payload.fallbackPolicy,
    sourceOutcomes: _declaredOutcomePortsForNode(sourceNode),
  );
}

List<String> _declaredOutcomePortsForNode(SceneNode node) {
  return switch (node.payload) {
    SceneYarnDialoguePayload(:final expectedOutcomes) => <String>[
        'completed',
        for (final outcome in expectedOutcomes)
          if (outcome != 'completed') outcome,
      ],
    SceneBattlePayload(:final declaredOutcomes) => declaredOutcomes.isEmpty
        ? const <String>['victory', 'defeat']
        : declaredOutcomes,
    SceneConditionPayload() => const <String>['true', 'false'],
    SceneStartPayload() ||
    SceneActionPayload() ||
    SceneCinematicPayload() ||
    ScenePresentationCinematicPayload() ||
    SceneMergePayload() ||
    SceneEndPayload() ||
    SceneBranchByOutcomePayload() =>
      const <String>[],
    _ => const <String>[],
  };
}

SceneRuntimePlanIntent _actionIntent(SceneActionPayload payload) {
  final preSessionInteraction = payload.preSessionInteraction;
  if (preSessionInteraction != null) {
    return SceneRuntimePlanIntent.requestStructuredInteraction(
      interaction: preSessionInteraction,
    );
  }
  final command = payload.interactiveCommand;
  if (command != null) {
    return SceneRuntimePlanIntent.executeInteractiveCommand(command: command);
  }
  final consequence = payload.consequence;
  if (consequence == null) {
    throw StateError(
      'Legacy ActionNode must be blocked before runtime intent creation.',
    );
  }
  return SceneRuntimePlanIntent.applyConsequence(
    consequence: consequence,
  );
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
