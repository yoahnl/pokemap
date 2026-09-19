import 'package:map_core/map_core_domain.dart';

import 'narrative_sequence_projection.dart';

enum NarrativeSequenceKind { dialogue, facing, wait, setFact, completeStep }

class NarrativeSequenceStep {
  const NarrativeSequenceStep({
    required this.kind,
    this.targetId = '',
    this.value = true,
    this.facing = EntityFacing.south,
    this.milliseconds = 300,
  });

  final NarrativeSequenceKind kind;
  final String targetId;
  final bool value;
  final EntityFacing facing;
  final int milliseconds;
}

class NarrativeInteractionDraft {
  const NarrativeInteractionDraft({
    required this.id,
    required this.name,
    required this.mapId,
    required this.source,
    required this.dialogueId,
    this.conditions = const [],
    this.oneShot = false,
    this.priority = 0,
    this.order = 0,
    this.steps = const [],
    this.branches = const {},
  });

  final String id;
  final String name;
  final String mapId;
  final NarrativeEventSourceRef source;
  final String dialogueId;
  final List<NarrativeEventCondition> conditions;
  final bool oneShot;
  final int priority;
  final int order;
  final List<NarrativeSequenceStep> steps;
  final Map<String, List<NarrativeSequenceStep>> branches;

  String get sceneId => 'scene_$id';

  NarrativeInteractionProjection project() {
    final projection = NarrativeSequenceProjection(this);
    final scene = projection.build();
    return NarrativeInteractionProjection(
      scene: scene,
      cinematics: projection.cinematics,
      event: NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: id,
          name: name,
          source: source,
          conditions: conditions,
          sceneId: scene.id,
          reusePolicy: oneShot
              ? NarrativeEventReusePolicy.oneShot
              : NarrativeEventReusePolicy.reusable,
          priority: priority,
          order: order,
        ),
        enabled: true,
        activeInLegacyMode: true,
      ),
    );
  }
}

class NarrativeInteractionProjection {
  const NarrativeInteractionProjection({
    required this.scene,
    required this.event,
    required this.cinematics,
  });

  final SceneAsset scene;
  final NarrativeEventRecord event;
  final List<CinematicAsset> cinematics;
}

StorylineAsset createStudioStoryline({
  required String id,
  required String title,
  required Map<String, String> steps,
}) => StorylineAsset(
  id: id,
  title: title,
  type: StorylineType.sideQuest,
  chapters: [
    StorylineChapter(
      id: '${id}_chapter',
      title: title,
      order: 0,
      steps: [
        for (final step in steps.entries.indexed)
          StorylineStep(id: step.$2.key, title: step.$2.value, order: step.$1),
      ],
    ),
  ],
);
