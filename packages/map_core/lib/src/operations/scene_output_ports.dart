import '../models/scene_asset.dart';

final class SceneOutputPortSpec {
  const SceneOutputPortSpec({
    required this.id,
    required this.edgeKinds,
    this.required = false,
  });

  final String id;
  final Set<SceneEdgeKind> edgeKinds;
  final bool required;
}

List<SceneOutputPortSpec>? sceneOutputPortSpecsOf(
  SceneNode node,
  Map<String, SceneNode> nodeById,
) {
  return switch (node.kind) {
    SceneNodeKind.start => const [
      SceneOutputPortSpec(
        id: 'completed',
        edgeKinds: {SceneEdgeKind.defaultFlow},
        required: true,
      ),
    ],
    SceneNodeKind.condition => const [
      SceneOutputPortSpec(
        id: 'true',
        edgeKinds: {SceneEdgeKind.conditionTrue},
        required: true,
      ),
      SceneOutputPortSpec(
        id: 'false',
        edgeKinds: {SceneEdgeKind.conditionFalse},
        required: true,
      ),
    ],
    SceneNodeKind.merge => const [
      SceneOutputPortSpec(
        id: 'completed',
        edgeKinds: {SceneEdgeKind.defaultFlow},
        required: true,
      ),
    ],
    SceneNodeKind.yarnDialogue => _yarnDialogueOutputPortSpecs(node),
    SceneNodeKind.battle => _battleOutputPortSpecs(node),
    SceneNodeKind.action => _actionOutputPortSpecs(node),
    SceneNodeKind.cinematic => const [
      SceneOutputPortSpec(
        id: 'completed',
        edgeKinds: {SceneEdgeKind.cinematicCompleted},
        required: true,
      ),
    ],
    SceneNodeKind.presentationCinematic => const [
      SceneOutputPortSpec(
        id: 'completed',
        edgeKinds: {SceneEdgeKind.presentationCompleted},
        required: true,
      ),
    ],
    SceneNodeKind.end => const [],
    SceneNodeKind.branchByOutcome => _branchOutputPortSpecs(node, nodeById),
  };
}

List<SceneOutputPortSpec> _actionOutputPortSpecs(SceneNode node) {
  final payload = node.payload;
  final interactiveCommand = payload is SceneActionPayload
      ? payload.interactiveCommand
      : null;
  final preSessionInteraction = payload is SceneActionPayload
      ? payload.preSessionInteraction
      : null;
  final outputPortIds =
      interactiveCommand?.outputPortIds ??
      preSessionInteraction?.outputPortIds ??
      const <String>['completed'];
  return <SceneOutputPortSpec>[
    for (final outputPortId in outputPortIds)
      SceneOutputPortSpec(
        id: outputPortId,
        edgeKinds: const {
          SceneEdgeKind.defaultFlow,
          SceneEdgeKind.actionCompleted,
        },
        required: true,
      ),
  ];
}

List<SceneOutputPortSpec> _branchOutputPortSpecs(
  SceneNode node,
  Map<String, SceneNode> nodeById,
) {
  final payload = node.payload as SceneBranchByOutcomePayload;
  final sourceNodeId = payload.sourceNodeId;
  final sourceNode = sourceNodeId == null ? null : nodeById[sourceNodeId];
  if (sourceNode == null) return const <SceneOutputPortSpec>[];
  final sourcePorts = sceneBranchSourceOutcomePortIds(sourceNode);
  final exactPortsRequired =
      payload.fallbackPolicy == SceneBranchOutcomeFallbackPolicy.exact;
  return <SceneOutputPortSpec>[
    for (final portId in sourcePorts)
      SceneOutputPortSpec(
        id: portId,
        edgeKinds: const {SceneEdgeKind.branchOutcome},
        required: exactPortsRequired,
      ),
    if (payload.fallbackPolicy ==
            SceneBranchOutcomeFallbackPolicy.defaultRoute &&
        !sourcePorts.contains('default'))
      const SceneOutputPortSpec(
        id: 'default',
        edgeKinds: {SceneEdgeKind.branchOutcome},
        required: true,
      ),
    if (payload.fallbackPolicy == SceneBranchOutcomeFallbackPolicy.errorRoute &&
        !sourcePorts.contains('error'))
      const SceneOutputPortSpec(
        id: 'error',
        edgeKinds: {SceneEdgeKind.error},
        required: true,
      ),
  ];
}

List<String> sceneBranchSourceOutcomePortIds(SceneNode node) {
  return switch (node.payload) {
    SceneYarnDialoguePayload(:final expectedOutcomes) => <String>[
      'completed',
      for (final outcome in expectedOutcomes)
        if (outcome != 'completed') outcome,
    ],
    SceneBattlePayload(:final declaredOutcomes) =>
      declaredOutcomes.isEmpty
          ? const <String>['victory', 'defeat']
          : declaredOutcomes,
    SceneConditionPayload() => const <String>['true', 'false'],
    SceneActionPayload(:final interactiveCommand?) =>
      interactiveCommand.outputPortIds,
    SceneActionPayload(:final preSessionInteraction?) =>
      preSessionInteraction.outputPortIds,
    SceneStartPayload() ||
    SceneActionPayload() ||
    SceneCinematicPayload() ||
    SceneMergePayload() ||
    SceneEndPayload() ||
    SceneBranchByOutcomePayload() => const <String>[],
    _ => const <String>[],
  };
}

List<SceneOutputPortSpec> _yarnDialogueOutputPortSpecs(SceneNode node) {
  final payload = node.payload as SceneYarnDialoguePayload;
  return [
    const SceneOutputPortSpec(
      id: 'completed',
      edgeKinds: {SceneEdgeKind.defaultFlow},
      required: true,
    ),
    for (final outcomeId in payload.expectedOutcomes)
      if (outcomeId != 'completed')
        SceneOutputPortSpec(
          id: outcomeId,
          edgeKinds: const {SceneEdgeKind.dialogueOutcome},
          required: true,
        ),
  ];
}

List<SceneOutputPortSpec> _battleOutputPortSpecs(SceneNode node) {
  final payload = node.payload as SceneBattlePayload;
  final outcomes = payload.declaredOutcomes.isEmpty
      ? const ['victory', 'defeat']
      : payload.declaredOutcomes;
  return [
    for (final outcomeId in outcomes)
      SceneOutputPortSpec(
        id: outcomeId,
        edgeKinds: {
          switch (outcomeId) {
            'victory' => SceneEdgeKind.battleVictory,
            'defeat' => SceneEdgeKind.battleDefeat,
            _ => SceneEdgeKind.branchOutcome,
          },
        },
        required: true,
      ),
  ];
}
