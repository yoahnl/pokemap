import 'package:map_core/map_core_domain.dart';

class StoryGraphOutcomeSource {
  const StoryGraphOutcomeSource({
    required this.link,
    required this.outcomeLinkId,
    required this.outcomeId,
    required this.connectable,
    this.pending = false,
  });
  final StorylineSceneLink link;
  final String outcomeLinkId, outcomeId;
  final bool pending, connectable;
}

Map<String, StoryGraphOutcomeSource> storyGraphOutcomeSources(
  ProjectManifest project,
  String storyId,
  Map<String, StorylineProgressionNode> nodes,
) {
  final result = <String, StoryGraphOutcomeSource>{};
  final story = project.storylines.where((s) => s.id == storyId).firstOrNull;
  if (story == null) return result;
  final scenarios = {for (final s in project.scenarios) s.id: s};
  for (final link in story.sceneLinks) {
    final scenario = link.sceneRef?.kind == StorylineSceneRefKind.scenario
        ? scenarios[link.sceneRef?.targetId]
        : null;
    final existing = <String>{};
    final reservedIds = {for (final o in link.outcomeLinks) o.id};
    for (final outcome in link.outcomeLinks) {
      final nodeId = 'outcome:$storyId:${link.id}:${outcome.id}';
      existing.add(outcome.outcomeId);
      nodes[nodeId] = StorylineProgressionNode(
        id: nodeId,
        kind: StorylineProgressionNodeKind.sceneOutcome,
        canonicalId: outcome.id,
        label:
            '${scenario?.name ?? link.label} · ${outcome.label ?? outcome.outcomeId}',
        storylineId: storyId,
        chapterId: link.chapterId,
        stepId: link.stepId,
      );
      result[nodeId] = StoryGraphOutcomeSource(
        link: link,
        outcomeLinkId: outcome.id,
        outcomeId: outcome.outcomeId,
        connectable:
            scenario?.declaredOutcomes.contains(outcome.outcomeId) ?? false,
      );
    }
    for (final outcomeId in link.expectedOutcomeIds) {
      if (existing.contains(outcomeId) ||
          scenario == null ||
          !scenario.declaredOutcomes.contains(outcomeId)) {
        continue;
      }
      final base = 'outcome-$outcomeId';
      var outcomeLinkId = base;
      var suffix = 2;
      while (!reservedIds.add(outcomeLinkId)) {
        outcomeLinkId = '$base-${suffix++}';
      }
      final nodeId = 'outcome:$storyId:${link.id}:$outcomeLinkId';
      nodes[nodeId] = StorylineProgressionNode(
        id: nodeId,
        kind: StorylineProgressionNodeKind.sceneOutcome,
        canonicalId: outcomeLinkId,
        label: '${scenario.name} · $outcomeId',
        storylineId: storyId,
        chapterId: link.chapterId,
        stepId: link.stepId,
      );
      result[nodeId] = StoryGraphOutcomeSource(
        link: link,
        outcomeLinkId: outcomeLinkId,
        outcomeId: outcomeId,
        connectable: true,
        pending: true,
      );
    }
  }
  return result;
}
