import '../dialogue/runtime_dialogue_document.dart';
import '../dialogue/scene_dialogue_choice_policy_validation.dart';
import '../dialogue/scene_dialogue_line_policy_validation.dart';
import '../models/dialogue_line_feedback.dart';
import '../models/scene_asset.dart';

SceneAsset retargetSceneDialogue(
  SceneAsset scene, {
  required String nodeId,
  required String dialogueId,
  String? yarnNodeName,
  required List<String> expectedOutcomes,
  required RuntimeDialogueDocument dialogue,
}) {
  final node = _dialogueNode(scene, nodeId);
  final current = node.payload as SceneYarnDialoguePayload;
  final id = dialogueId.trim();
  final start = yarnNodeName?.trim();
  if (id.isEmpty) throw ArgumentError.value(dialogueId, 'dialogueId');
  if (start != null &&
      (start.isEmpty || !dialogue.nodes.any((node) => node.title == start))) {
    throw ArgumentError.value(
      yarnNodeName,
      'yarnNodeName',
      'The dialogue start must exist in the compiled document.',
    );
  }
  final updated = _payload(
    current,
    dialogueId: id,
    yarnNodeName: start,
    expectedOutcomes: expectedOutcomes,
  );
  _validatePolicies(updated, dialogue);
  return _replacePayload(scene, node, updated);
}

SceneAsset updateSceneDialogueChoicePolicy(
  SceneAsset scene, {
  required String nodeId,
  required RuntimeDialogueDocument dialogue,
  required SceneDialogueChoicePolicy choicePolicy,
}) {
  final node = _dialogueNode(scene, nodeId);
  final current = node.payload as SceneYarnDialoguePayload;
  final policies =
      [
        for (final policy in current.choicePolicies)
          if (policy.nodeName != choicePolicy.nodeName ||
              policy.choiceIndex != choicePolicy.choiceIndex)
            policy,
        choicePolicy,
      ]..sort((left, right) {
        final byName = left.nodeName.compareTo(right.nodeName);
        return byName == 0
            ? left.choiceIndex.compareTo(right.choiceIndex)
            : byName;
      });
  final updated = _payload(
    current,
    yarnNodeName: current.yarnNodeName,
    choicePolicies: policies,
  );
  _validatePolicies(updated, dialogue);
  return _replacePayload(scene, node, updated);
}

SceneAsset updateSceneDialogueLinePolicy(
  SceneAsset scene, {
  required String nodeId,
  required RuntimeDialogueDocument dialogue,
  required SceneDialogueLinePolicy linePolicy,
}) {
  final node = _dialogueNode(scene, nodeId);
  final current = node.payload as SceneYarnDialoguePayload;
  final policies =
      [
        for (final policy in current.linePolicies)
          if (policy.nodeName != linePolicy.nodeName ||
              policy.lineIndex != linePolicy.lineIndex)
            policy,
        linePolicy,
      ]..sort((left, right) {
        final byName = left.nodeName.compareTo(right.nodeName);
        return byName == 0 ? left.lineIndex.compareTo(right.lineIndex) : byName;
      });
  final updated = _payload(
    current,
    yarnNodeName: current.yarnNodeName,
    linePolicies: policies,
  );
  _validatePolicies(updated, dialogue);
  return _replacePayload(scene, node, updated);
}

SceneNode _dialogueNode(SceneAsset scene, String nodeId) {
  final node = scene.graph.nodes.where((node) => node.id == nodeId).firstOrNull;
  if (node == null || node.payload is! SceneYarnDialoguePayload) {
    throw ArgumentError.value(
      nodeId,
      'nodeId',
      'The selected Scene node must contain a dialogue.',
    );
  }
  return node;
}

SceneYarnDialoguePayload _payload(
  SceneYarnDialoguePayload current, {
  String? dialogueId,
  required String? yarnNodeName,
  List<String>? expectedOutcomes,
  List<SceneDialogueChoicePolicy>? choicePolicies,
  List<SceneDialogueLinePolicy>? linePolicies,
}) => SceneYarnDialoguePayload(
  dialogueId: dialogueId ?? current.dialogueId,
  yarnNodeName: yarnNodeName,
  expectedOutcomes: expectedOutcomes ?? current.expectedOutcomes,
  speakerHints: current.speakerHints,
  choicePolicies: choicePolicies ?? current.choicePolicies,
  linePolicies: linePolicies ?? current.linePolicies,
  declaredCancellationOutcomes: current.declaredCancellationOutcomes,
);

void _validatePolicies(
  SceneYarnDialoguePayload payload,
  RuntimeDialogueDocument dialogue,
) {
  validateSceneDialogueChoicePolicies(
    sceneDialogueChoiceScopes(dialogue),
    payload.choicePolicies,
  );
  validateSceneDialogueLinePolicies(
    sceneDialogueLineScopes(dialogue),
    payload.linePolicies,
  );
}

SceneAsset _replacePayload(
  SceneAsset scene,
  SceneNode node,
  SceneYarnDialoguePayload payload,
) => SceneAsset(
  id: scene.id,
  name: scene.name,
  executionProfile: scene.executionProfile,
  description: scene.description,
  storylineId: scene.storylineId,
  chapterId: scene.chapterId,
  tags: scene.tags,
  layout: scene.layout,
  declaredOutcomes: scene.declaredOutcomes,
  metadata: scene.metadata,
  graph: SceneGraph(
    startNodeId: scene.graph.startNodeId,
    edges: scene.graph.edges,
    nodes: [
      for (final candidate in scene.graph.nodes)
        if (candidate.id == node.id)
          SceneNode(
            id: node.id,
            kind: node.kind,
            title: node.title,
            description: node.description,
            payload: payload,
          )
        else
          candidate,
    ],
  ),
);
