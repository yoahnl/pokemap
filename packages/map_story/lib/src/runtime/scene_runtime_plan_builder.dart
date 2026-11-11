import 'package:map_core/map_core.dart';
import 'scene_runtime_plan.dart';

SceneRuntimePlanBuildResult buildSceneRuntimePlan(SceneAsset scene) {
  final check = checkSceneRuntimeCompilation(scene);
  final diagnostics = check.diagnostics;
  if (!check.canCompile) {
    return SceneRuntimePlanBuildResult(plan: null, diagnostics: diagnostics);
  }
  final nodeById = <String, SceneNode>{
    for (final node in scene.graph.nodes) node.id: node,
  };

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
      sourceNodeId: node.id,
    ),
    SceneNodeKind.battle => _battleIntent(node.payload as SceneBattlePayload),
    SceneNodeKind.cinematic => SceneRuntimePlanIntent.playCinematic(
      cinematicId: (node.payload as SceneCinematicPayload).cinematicId,
    ),
    SceneNodeKind.presentationCinematic =>
      SceneRuntimePlanIntent.playPresentationCinematic(
        presentationCinematicId:
            (node.payload as ScenePresentationCinematicPayload)
                .presentationCinematicId,
        sourceNodeId: node.id,
        awaitableNodeIdsByMarkerId: {
          for (final binding
              in (node.payload as ScenePresentationCinematicPayload)
                  .interactionCueBindings)
            binding.markerId: binding.awaitableNodeId,
        },
      ),
    SceneNodeKind.action => _actionIntent(node),
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
    sourceOutcomes: declaredSceneNodeOutcomePorts(sourceNode),
  );
}

SceneRuntimePlanIntent _actionIntent(SceneNode node) {
  final payload = node.payload as SceneActionPayload;
  final preSessionInteraction = payload.preSessionInteraction;
  if (preSessionInteraction != null) {
    return SceneRuntimePlanIntent.requestStructuredInteraction(
      interaction: preSessionInteraction,
      sourceNodeId: node.id,
    );
  }
  final command = payload.interactiveCommand;
  if (command != null) {
    return SceneRuntimePlanIntent.executeInteractiveCommand(command: command, sourceNodeId: node.id);
  }
  final consequence = payload.consequence;
  if (consequence == null) {
    throw StateError(
      'Legacy ActionNode must be blocked before runtime intent creation.',
    );
  }
  return SceneRuntimePlanIntent.applyConsequence(consequence: consequence);
}

SceneRuntimePlanIntent _dialogueIntent(
  SceneYarnDialoguePayload payload, {
  required String sourceNodeId,
}) {
  return SceneRuntimePlanIntent.showDialogue(
    dialogueId: payload.dialogueId,
    yarnNodeName: payload.yarnNodeName,
    sourceNodeId: sourceNodeId,
    expectedOutcomes: payload.expectedOutcomes,
    choicePolicies: payload.choicePolicies,
    linePolicies: payload.linePolicies,
  );
}

SceneRuntimePlanIntent _battleIntent(SceneBattlePayload payload) {
  return SceneRuntimePlanIntent.startBattle(
    battleKind: payload.battleKind,
    trainerId: payload.trainerId,
    battleTemplateId: payload.battleTemplateId,
    npcEntityId: payload.npcEntityId,
    defeatRecovery: payload.defeatRecovery,
    demonstration: payload.demonstration,
    periodicEncounter: payload.periodicEncounter,
    declaredOutcomes: payload.declaredOutcomes,
  );
}
