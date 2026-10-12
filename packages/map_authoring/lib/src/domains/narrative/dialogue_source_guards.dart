import 'package:map_core/map_core.dart';

import 'dialogue_authoring_service.dart';
import 'narrative_authoring_exception.dart';

void validateDialogueSceneStarts({
  required ProjectManifest project,
  required String dialogueId,
  required DialogueAuthoringCompileResult compiled,
}) {
  final titles = {for (final node in compiled.document!.nodes) node.title};
  final references = <String>[];
  final choiceReferences = <String>[];
  final lineReferences = <String>[];
  for (final scene in project.scenes) {
    for (final node in scene.graph.nodes) {
      final payload = node.payload;
      if (payload is! SceneYarnDialoguePayload ||
          payload.dialogueId != dialogueId) {
        continue;
      }
      final start = payload.yarnNodeName;
      if (start != null && start.isNotEmpty && !titles.contains(start)) {
        references.add('scenes[${scene.id}].nodes[${node.id}]: $start');
      }
      try {
        validateSceneDialogueChoicePolicies(sceneDialogueChoiceScopes(compiled.document!), payload.choicePolicies);
      } on ArgumentError {
        choiceReferences.add('scenes[${scene.id}].nodes[${node.id}].choicePolicies');
      }
      try {
        validateDialogueLineFeedbackAgainstProject(
          project: project,
          document: compiled.document!,
          policies: payload.linePolicies,
        );
      } on ArgumentError {
        lineReferences.add('scenes[${scene.id}].nodes[${node.id}].linePolicies');
      } on FormatException {
        lineReferences.add('scenes[${scene.id}].nodes[${node.id}].linePolicies');
      }
    }
  }
  if (references.isNotEmpty) {
    throw NarrativeAuthoringException(
      'dialogue.scene_start_references_blocking',
      'A Scene still starts this dialogue at a missing Yarn node.',
      details: {'references': references},
    );
  }
  if (choiceReferences.isNotEmpty) {
    throw NarrativeAuthoringException('dialogue.scene_choice_policy_references_blocking',
      'A Scene still references a missing or incompatible dialogue choice.',
      details: {'references': choiceReferences});
  }
  if (lineReferences.isNotEmpty) {
    throw NarrativeAuthoringException(
      'dialogue.scene_line_policy_references_blocking',
      'A Scene still references a missing or incompatible dialogue line.',
      details: {'references': lineReferences},
    );
  }
}

void validateDialogueLineFeedbackAgainstProject({
  required ProjectManifest project,
  required RuntimeDialogueDocument document,
  required List<SceneDialogueLinePolicy> policies,
}) {
  final scopes = sceneDialogueLineScopes(document);
  validateSceneDialogueLinePolicies(scopes, policies);
  final byScope = {
    for (final policy in policies) (policy.nodeName, policy.lineIndex): policy,
  };
  final feedback = <DialogueLineFeedback>[
    for (final scope in scopes)
      if (byScope[(scope.nodeName, scope.lineIndex)]?.feedback ?? scope.feedback
          case final DialogueLineFeedback value)
        value,
  ];
  validateDialogueFeedbackReferences(
    feedback,
    iconAssetIds: {
      for (final entry in project.tilesets) entry.id,
      for (final character in project.characters) ...{
        for (final animation in character.animations)
          if (animation.sourceAssetId case final String id)
            'character-animation:$id',
        for (final animation in character.customAnimations)
          'character-animation:${animation.sourceAssetId}',
      },
    },
    mediaAssets: project.cinematicMediaAssets,
  );
}
