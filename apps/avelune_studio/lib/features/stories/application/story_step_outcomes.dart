import 'package:map_core/map_core_domain.dart';

final class StoryStepOutcomeChoice {
  const StoryStepOutcomeChoice({
    required this.id,
    required this.label,
    required this.source,
    required this.expected,
  });

  final String id;
  final String label;
  final String? source;
  final bool expected;

  bool get missing => source == null;
}

List<StoryStepOutcomeChoice> storyScenarioOutcomeChoices(
  List<ScenarioAsset> scenarios,
  StorylineSceneLink link,
) {
  final scenario = scenarios
      .where((candidate) => candidate.id == link.sceneRef?.targetId)
      .firstOrNull;
  if (scenario == null) return const [];
  final labels = {
    for (final outcome in link.outcomeLinks)
      if (outcome.label case final label? when label.trim().isNotEmpty)
        outcome.outcomeId: label,
  };
  return [
    for (final id in {...scenario.declaredOutcomes, ...link.expectedOutcomeIds})
      StoryStepOutcomeChoice(
        id: id,
        label: labels[id] ?? id,
        source: scenario.declaredOutcomes.contains(id)
            ? 'Scénario « ${scenario.name} »'
            : null,
        expected: link.expectedOutcomeIds.contains(id),
      ),
  ];
}

List<StoryStepOutcomeChoice> storyStepOutcomeChoices(
  ProjectManifest project,
  StorylineAsset story,
  String chapterId,
  StorylineStep step,
) {
  final expected = step.expectedOutcomeIds.toSet();
  final found = <String, StoryStepOutcomeChoice>{};
  void offer(String id, String label, String source) {
    found.putIfAbsent(
      id,
      () => StoryStepOutcomeChoice(
        id: id,
        label: label,
        source: source,
        expected: expected.contains(id),
      ),
    );
  }

  final scenes = {for (final scene in project.scenes) scene.id: scene};
  for (final sceneId in step.sceneLinkIds) {
    final scene = scenes[sceneId];
    if (scene == null) continue;
    for (final outcome in scene.declaredOutcomes) {
      offer(outcome.id, outcome.label, 'Scène « ${scene.name} »');
    }
  }
  final scenarios = {
    for (final scenario in project.scenarios) scenario.id: scenario,
  };
  for (final link in story.sceneLinks) {
    if (link.chapterId != chapterId || link.stepId != step.id) continue;
    final scenario = link.sceneRef?.kind == StorylineSceneRefKind.scenario
        ? scenarios[link.sceneRef?.targetId]
        : null;
    if (scenario == null) continue;
    final labels = {
      for (final outcome in link.outcomeLinks)
        if (outcome.label case final label? when label.trim().isNotEmpty)
          outcome.outcomeId: label,
    };
    for (final id in scenario.declaredOutcomes) {
      offer(id, labels[id] ?? id, 'Scénario « ${scenario.name} »');
    }
  }
  return [
    ...found.values,
    for (final id in step.expectedOutcomeIds)
      if (!found.containsKey(id))
        StoryStepOutcomeChoice(id: id, label: id, source: null, expected: true),
  ];
}
