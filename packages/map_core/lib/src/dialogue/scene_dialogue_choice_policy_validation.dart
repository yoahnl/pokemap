import '../models/scene_asset.dart';
import 'runtime_dialogue_document.dart';

final class SceneDialogueChoiceScope {
  SceneDialogueChoiceScope({required this.nodeName, required this.choiceIndex, required List<String?> outcomeIds})
      : outcomeIds = List.unmodifiable(outcomeIds);

  final String nodeName;
  final int choiceIndex;
  final List<String?> outcomeIds;
}

List<SceneDialogueChoiceScope> sceneDialogueChoiceScopes(RuntimeDialogueDocument document) {
  final scopes = <SceneDialogueChoiceScope>[];
  for (final node in document.nodes) {
    var index = 0;
    void visit(List<RuntimeDialogueStep> steps) {
      for (final step in steps) {
        if (step is! RuntimeDialogueChoiceBlock) continue;
        scopes.add(SceneDialogueChoiceScope(nodeName: node.title, choiceIndex: index++,
          outcomeIds: step.choices.map((choice) => choice.outcomeId).toList(growable: false)));
        for (final choice in step.choices) {
          visit(choice.steps);
        }
      }
    }
    visit(node.steps);
  }
  return List.unmodifiable(scopes);
}

void validateSceneDialogueChoicePolicies(Iterable<SceneDialogueChoiceScope> scopes,
    List<SceneDialogueChoicePolicy> policies) {
  final byScope = {for (final scope in scopes) (scope.nodeName, scope.choiceIndex): scope};
  final seen = <(String, int)>{};
  for (final policy in policies) {
    final key = (policy.nodeName, policy.choiceIndex);
    final scope = byScope[key];
    if (!seen.add(key) || scope == null) {
      throw ArgumentError('Dialogue choice policy scope is duplicate or unknown: $key.');
    }
    void requireVisible(String? outcome) {
      if (outcome == null || outcome.trim().isEmpty ||
          scope.outcomeIds.where((id) => id == outcome).length != 1) {
        throw ArgumentError('Choice policy outcome must identify exactly one visible option: $outcome.');
      }
    }
    if (policy.defaultOutcomeId != null) requireVisible(policy.defaultOutcomeId);
    switch (policy.cancellation.kind) {
      case SceneDialogueChoiceCancellationKind.disabled:
        if (policy.cancellation.outcomeId != null) throw ArgumentError('Disabled cancellation cannot declare an outcome.');
      case SceneDialogueChoiceCancellationKind.choice:
        requireVisible(policy.cancellation.outcomeId);
      case SceneDialogueChoiceCancellationKind.branch:
        final outcome = policy.cancellation.outcomeId;
        if (outcome == null || outcome.trim().isEmpty || scope.outcomeIds.contains(outcome)) {
          throw ArgumentError('Cancellation branch must declare a distinct outcome: $outcome.');
        }
    }
  }
}
