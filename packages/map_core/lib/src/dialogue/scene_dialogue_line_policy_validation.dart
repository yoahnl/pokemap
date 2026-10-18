import '../models/cinematic_media_asset.dart';
import '../models/dialogue_line_feedback.dart';
import 'runtime_dialogue_document.dart';
import 'dialogue_fact_references.dart';

final class SceneDialogueLineScope {
  const SceneDialogueLineScope({
    required this.nodeName,
    required this.lineIndex,
    required this.text,
    this.feedback,
  });

  final String nodeName;
  final int lineIndex;
  final String text;
  final DialogueLineFeedback? feedback;
}

List<SceneDialogueLineScope> sceneDialogueLineScopes(
  RuntimeDialogueDocument document,
) {
  final result = <SceneDialogueLineScope>[];
  for (final node in document.nodes) {
    var index = 0;
    void visit(List<RuntimeDialogueStep> steps) {
      for (final step in steps) {
        if (step is RuntimeDialogueLine) {
          result.add(
            SceneDialogueLineScope(
              nodeName: node.title,
              lineIndex: index++,
              text: step.text,
              feedback: step.feedback,
            ),
          );
        } else if (step is RuntimeDialogueChoiceBlock) {
          for (final choice in step.choices) {
            visit(choice.steps);
          }
        }
      }
    }

    visit(node.steps);
  }
  return List.unmodifiable(result);
}

void validateSceneDialogueLinePolicies(
  Iterable<SceneDialogueLineScope> scopes,
  List<SceneDialogueLinePolicy> policies,
) {
  final byScope = {
    for (final scope in scopes) (scope.nodeName, scope.lineIndex): scope,
  };
  final seen = <(String, int)>{};
  for (final policy in policies) {
    final key = (policy.nodeName, policy.lineIndex);
    final scope = byScope[key];
    if (!seen.add(key) || scope == null) {
      throw ArgumentError(
        'Dialogue line policy scope is duplicate or unknown: $key.',
      );
    }
    if (scope.feedback != null && scope.feedback != policy.feedback) {
      throw ArgumentError(
        'Dialogue line has conflicting embedded and Scene feedback: $key.',
      );
    }
    policy.feedback.validateText(scope.text);
    validateDialogueFactFeedback(policy.feedback);
  }
}

void validateDialogueFeedbackReferences(
  Iterable<DialogueLineFeedback> feedback, {
  required Set<String> iconAssetIds,
  required Iterable<CinematicMediaAsset> mediaAssets,
}) {
  final byId = <String, CinematicMediaAsset>{};
  for (final asset in mediaAssets) {
    if (byId.containsKey(asset.id)) {
      throw ArgumentError('Duplicate dialogue media identity: ${asset.id}.');
    }
    byId[asset.id] = asset;
  }
  final cues = <String>{};
  for (final line in feedback) {
    for (final segment in line.segments.whereType<DialogueIconSegment>()) {
      if (!iconAssetIds.contains(segment.assetId)) {
        throw ArgumentError('Unknown dialogue icon asset: ${segment.assetId}.');
      }
    }
    final cue = line.audioCue;
    if (cue == null) continue;
    if (!cues.add(cue.cueId)) {
      throw ArgumentError('Duplicate dialogue audio cue: ${cue.cueId}.');
    }
    final asset = byId[cue.mediaAssetId];
    if (asset == null ||
        asset.kind != CinematicMediaAssetKind.sound ||
        asset.loopByDefault) {
      throw ArgumentError(
        'Dialogue cue requires a known non-looping sound: ${cue.mediaAssetId}.',
      );
    }
  }
}
