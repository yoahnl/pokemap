import 'package:map_core/map_core_domain.dart';

import 'narrative_interaction.dart';
import 'interaction_edit_session.dart';

extension NarrativeInteractionEditing on NarrativeInteractionDraft {
  NarrativeInteractionDraft revise({
    String? name,
    List<NarrativeEventCondition>? conditions,
    bool? oneShot,
    List<NarrativeSequenceStep>? steps,
    Map<String, List<NarrativeSequenceStep>>? branches,
    int? priority,
  }) => NarrativeInteractionDraft(
    id: id,
    name: name ?? this.name,
    mapId: mapId,
    source: source,
    dialogueId: dialogueId,
    conditions: conditions ?? this.conditions,
    oneShot: oneShot ?? this.oneShot,
    priority: priority ?? this.priority,
    order: order,
    steps: steps ?? this.steps,
    branches: branches ?? this.branches,
  );
}

({int order, int priority}) nextNarrativeRank(
  ProjectManifest project,
  Iterable<InteractionEditSession> sessions,
  NarrativeEventSourceRef source,
) {
  final ranks = <({int order, int priority})>[
    for (final record
        in project.eventRegistry?.records ?? <NarrativeEventRecord>[])
      if (record.definitionOrNull case final definition?
          when definition.source == source)
        (order: definition.order, priority: definition.priority),
    for (final session in sessions)
      if (session.current.interaction.source == source)
        (
          order: session.current.interaction.order,
          priority: session.current.interaction.priority,
        ),
  ];
  return (
    order:
        ranks.fold(
          -1,
          (value, rank) => rank.order > value ? rank.order : value,
        ) +
        1,
    priority:
        ranks.fold(
          -1,
          (value, rank) => rank.priority > value ? rank.priority : value,
        ) +
        1,
  );
}

const narrativeSequenceLabels = {
  NarrativeSequenceKind.dialogue: 'Afficher un dialogue',
  NarrativeSequenceKind.facing: 'Orienter un personnage',
  NarrativeSequenceKind.wait: 'Attendre',
  NarrativeSequenceKind.setFact: 'Changer un état',
  NarrativeSequenceKind.completeStep: 'Terminer une étape',
};

Map<String, String> narrativeSequenceTargets(
  NarrativeSequenceKind kind, {
  required ProjectManifest project,
  MapData? map,
  List<StorylineAsset>? stories,
  List<NarrativeFactDefinition>? facts,
}) => switch (kind) {
  NarrativeSequenceKind.dialogue => {
    for (final dialogue in project.dialogues) dialogue.id: dialogue.name,
  },
  NarrativeSequenceKind.facing => {
    for (final entity in map?.entities ?? const <MapEntity>[])
      if (entity.npc != null) entity.id: entity.name,
  },
  NarrativeSequenceKind.setFact => {
    for (final fact in facts ?? project.facts)
      if (fact.valueKind == NarrativeValueKind.boolean) fact.id: fact.label,
  },
  NarrativeSequenceKind.completeStep => {
    for (final story in stories ?? project.storylines)
      for (final chapter in story.chapters)
        for (final step in chapter.steps)
          step.id: '${story.title} · ${step.title}',
  },
  NarrativeSequenceKind.wait => {},
};

extension NarrativeSequenceStepEditing on NarrativeSequenceStep {
  NarrativeSequenceStep revise({
    String? target,
    bool? value,
    EntityFacing? facing,
    int? milliseconds,
  }) => NarrativeSequenceStep(
    kind: kind,
    targetId: target ?? targetId,
    value: value ?? this.value,
    facing: facing ?? this.facing,
    milliseconds: milliseconds ?? this.milliseconds,
  );
}
