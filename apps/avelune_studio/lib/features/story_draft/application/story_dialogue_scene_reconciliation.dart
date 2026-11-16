import 'package:map_core/map_core_domain.dart';

import '../../resources/domain/resource_port.dart';
import '../domain/story_draft_entry.dart';
import 'story_draft.dart';
import 'story_publication_plan.dart';

void reconcilePublishedDialogueScenes(
  StoryDraft draft,
  List<StoryPublicationStep> steps,
  int next,
  ResourceMutationReceipt receipt,
) {
  for (final change in receipt.sceneChanges.values) {
    SceneAsset project(SceneAsset scene) =>
        _reconcile(scene, change.before, change.after);
    draft.reconcileSaved(
      StoryDraftKind.scene,
      change.before,
      change.after,
      project,
    );
    for (var index = next; index < steps.length; index++) {
      final step = steps[index];
      if (step.kind != StoryDraftKind.scene) continue;
      steps[index] = StoryPublicationStep(
        kind: step.kind,
        deletion: step.deletion,
        entries: [
          for (final entry in step.entries)
            if (entry.id == change.before.id && entry.base == change.before)
              StoryDraftKind.scene.entry(
                entry.id,
                base: change.after,
                current: entry.current == null
                    ? null
                    : project(entry.current as SceneAsset),
              )
            else
              entry,
        ],
      );
    }
  }
}

SceneAsset _reconcile(SceneAsset scene, SceneAsset before, SceneAsset after) {
  final policies = <String, List<SceneDialogueLinePolicy>>{};
  for (final node in before.graph.nodes) {
    final old = node.payload;
    final updated = after.graph.nodes
        .where((value) => value.id == node.id)
        .firstOrNull
        ?.payload;
    if (old is! SceneYarnDialoguePayload ||
        updated is! SceneYarnDialoguePayload ||
        old.dialogueId != updated.dialogueId ||
        _same(old.linePolicies, updated.linePolicies)) {
      continue;
    }
    final current = scene.graph.nodes
        .where((value) => value.id == node.id)
        .firstOrNull
        ?.payload;
    if (current is SceneYarnDialoguePayload &&
        current.dialogueId == old.dialogueId) {
      final merged = [
        for (final policy in current.linePolicies)
          _mergePolicy(policy, old.linePolicies, updated.linePolicies),
      ];
      if (!_same(merged, current.linePolicies)) policies[node.id] = merged;
    }
  }
  if (policies.isEmpty) return scene;
  return SceneAsset.fromJson({
    ...scene.toJson(),
    'graph': {
      ...scene.graph.toJson(),
      'nodes': [
        for (final node in scene.graph.nodes)
          if (policies[node.id] case final replacement?)
            {
              ...node.toJson(),
              'payload': {
                ...node.payload.toJson(),
                'linePolicies': [
                  for (final policy in replacement) policy.toJson(),
                ],
              },
            }
          else
            node.toJson(),
      ],
    },
  });
}

bool _same(List<SceneDialogueLinePolicy> a, List<SceneDialogueLinePolicy> b) =>
    a.length == b.length && a.indexed.every((entry) => entry.$2 == b[entry.$1]);

SceneDialogueLinePolicy _mergePolicy(
  SceneDialogueLinePolicy current,
  List<SceneDialogueLinePolicy> before,
  List<SceneDialogueLinePolicy> after,
) {
  final old = before
      .where(
        (policy) =>
            policy.nodeName == current.nodeName &&
            policy.lineIndex == current.lineIndex,
      )
      .firstOrNull;
  final saved = after
      .where(
        (policy) =>
            policy.nodeName == current.nodeName &&
            policy.lineIndex == current.lineIndex,
      )
      .firstOrNull;
  final segments = current.feedback.segments;
  if (old == null ||
      saved == null ||
      segments.length != old.feedback.segments.length ||
      !segments.indexed.every(
        (entry) => entry.$2 == old.feedback.segments[entry.$1],
      )) {
    return current;
  }
  return SceneDialogueLinePolicy(
    nodeName: current.nodeName,
    lineIndex: current.lineIndex,
    feedback: DialogueLineFeedback(
      segments: saved.feedback.segments,
      revealIntervalMicros: current.feedback.revealIntervalMicros,
      advance: current.feedback.advance,
      audioCue: current.feedback.audioCue,
    ),
  );
}
