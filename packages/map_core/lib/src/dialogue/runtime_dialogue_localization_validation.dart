import '../localization/project_locale_policy.dart';
import '../models/dialogue_line_feedback.dart';
import '../models/scene_asset.dart';
import 'dialogue_fact_references.dart';
import 'dialogue_feedback_text.dart';
import 'dialogue_localization.dart';
import 'runtime_dialogue_document.dart';
import 'runtime_dialogue_localization.dart';
import 'scene_dialogue_line_policy_validation.dart';

void validateRuntimeDialogueLocalizationVariants(
  RuntimeDialogueDocument document,
  DialogueLocalization localization, {
  required ProjectLocalePolicy locales,
  Set<String> factIds = const {},
  Iterable<List<SceneDialogueLinePolicy>> linePolicySets = const [],
}) {
  validateRuntimeDialogueLocalization(document, localization);
  final sourceScopes = sceneDialogueLineScopes(document);
  final sourceByScope = {
    for (final scope in sourceScopes) (scope.nodeName, scope.lineIndex): scope,
  };
  for (final policies in linePolicySets) {
    validateSceneDialogueLinePolicies(sourceScopes, policies);
  }
  for (final locale in locales.supportedLocales) {
    final localized = resolveRuntimeDialogueLocalization(
      document,
      localization,
      preferredLocale: locale,
      locales: locales,
    );
    if (!factIds.containsAll(dialogueDocumentFactIds(localized))) {
      throw const FormatException(
        'Localized dialogue references an unavailable Fact.',
      );
    }
    final targetByScope = {
      for (final scope in sceneDialogueLineScopes(localized))
        (scope.nodeName, scope.lineIndex): scope,
    };
    for (final policies in linePolicySets) {
      for (final policy in policies) {
        final key = (policy.nodeName, policy.lineIndex);
        final feedback = retargetDialogueLineFeedback(
          policy.feedback,
          sourceText: sourceByScope[key]!.text,
          text: targetByScope[key]!.text,
        );
        if (feedback != null) validateDialogueFactFeedback(feedback);
      }
    }
  }
}

Map<String, List<List<SceneDialogueLinePolicy>>> dialogueLinePoliciesByDocument(
  Iterable<SceneAsset> scenes,
) {
  final result = <String, List<List<SceneDialogueLinePolicy>>>{};
  for (final scene in scenes) {
    for (final node in scene.graph.nodes) {
      if (node.payload case SceneYarnDialoguePayload payload) {
        result
            .putIfAbsent(payload.dialogueId, () => [])
            .add(payload.linePolicies);
      }
    }
  }
  return result;
}
