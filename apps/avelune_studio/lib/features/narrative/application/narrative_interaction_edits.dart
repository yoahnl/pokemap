import 'package:map_core/map_core_domain.dart';

import '../domain/dialogue_draft.dart';
import 'narrative_editing.dart';
import 'narrative_interaction.dart';

List<NarrativeFactDefinition> narrativeConditionFacts(
  Iterable<NarrativeFactDefinition> facts,
) => facts.where((f) => f.valueKind == NarrativeValueKind.boolean).toList();

({String? factId, bool expected}) narrativeConditionTarget(
  NarrativeEventCondition condition,
) {
  final data = condition.toJson();
  return (
    factId: data['factId'] as String?,
    expected: data['expectedValue'] == true,
  );
}

List<NarrativeEventCondition> withNarrativeCondition(
  List<NarrativeEventCondition> conditions,
  int index,
  String factId,
  bool expected,
) => [...conditions]..[index] = NarrativeEventCondition.fact(factId, expected);

List<NarrativeEventCondition>? toggledNarrativeCondition(
  List<NarrativeEventCondition> conditions,
  int index,
) {
  final target = narrativeConditionTarget(conditions[index]);
  final factId = target.factId;
  if (factId == null) return null;
  return withNarrativeCondition(conditions, index, factId, !target.expected);
}

List<NarrativeEventCondition>? addedNarrativeCondition(
  List<NarrativeEventCondition> conditions,
  Iterable<NarrativeFactDefinition> facts,
) {
  final first = narrativeConditionFacts(facts).firstOrNull;
  if (first == null) return null;
  return [...conditions, NarrativeEventCondition.fact(first.id, true)];
}

List<T> withoutNarrativeItem<T>(List<T> items, int index) =>
    [...items]..removeAt(index);

List<NarrativeSequenceStep> replacedNarrativeStep(
  List<NarrativeSequenceStep> steps,
  int index,
  NarrativeSequenceStep step,
) => [...steps]..[index] = step;

List<NarrativeSequenceStep>? movedNarrativeStep(
  List<NarrativeSequenceStep> steps,
  int index,
  int delta,
) {
  final target = index + delta;
  if (target < 0 || target >= steps.length) return null;
  final next = [...steps];
  next[index] = steps[target];
  next[target] = steps[index];
  return next;
}

List<NarrativeSequenceStep> addedNarrativeStep(
  List<NarrativeSequenceStep> steps,
  NarrativeSequenceKind kind,
  Map<String, String> targets,
) => [
  ...steps,
  NarrativeSequenceStep(kind: kind, targetId: targets.keys.firstOrNull ?? ''),
];

int? narrativeWaitMilliseconds(String input) {
  final ms = int.tryParse(input);
  return ms != null && ms >= 0 ? ms : null;
}

Map<String, String> narrativeOutcomeSections(DialogueDraft dialogue) => {
  for (final branch in dialogue.branches)
    for (final choice in branch.choices)
      if (choice.outcomeId != null) choice.outcomeId!: choice.text,
};

String narrativeOutcomeSectionTitle(String choiceText) =>
    'Après le choix « $choiceText »';

List<NarrativeSequenceStep> narrativeOutcomeSteps(
  NarrativeInteractionDraft interaction,
  String outcomeId,
) => interaction.branches[outcomeId] ?? [];

NarrativeInteractionDraft withNarrativeOutcomeSteps(
  NarrativeInteractionDraft interaction,
  String outcomeId,
  List<NarrativeSequenceStep> steps,
) => interaction.revise(
  branches: {...interaction.branches, outcomeId: steps},
);

int? narrativePriorityFromInput(String input) => int.tryParse(input);

String narrativeInteractionMapName(ProjectManifest project, String mapId) =>
    project.maps.where((map) => map.id == mapId).firstOrNull?.name ??
    'Carte courante';

String narrativeInteractionOriginLabel(NarrativeInteractionDraft interaction) =>
    interaction.source.toJson()['kind'] == 'entityInteract'
    ? 'Interaction avec un personnage'
    : 'Entrée dans une zone';
