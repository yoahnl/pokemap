import 'package:map_core/map_core_domain.dart';

import 'story_graph_sources.dart';

final class StoryProgressionSources {
  StoryProgressionSources(
    this.project,
    this.storyId, {
    Iterable<String> revealedFacts = const [],
    Iterable<String> revealedStories = const [],
  }) {
    projection = buildStorylineProgressionProjection(
      project: project,
      storylineId: storyId,
    );
    nodes = {for (final node in projection.nodes) node.id: node};
    for (final fact in project.facts) {
      if (fact.valueKind == NarrativeValueKind.boolean) {
        _booleanFacts.add(fact.id);
      }
      if (revealedFacts.contains(fact.id)) {
        nodes.putIfAbsent(
          'fact:${fact.id}',
          () => StorylineProgressionNode(
            id: 'fact:${fact.id}',
            kind: StorylineProgressionNodeKind.fact,
            canonicalId: fact.id,
            label: fact.label,
          ),
        );
      }
    }
    for (final story in project.storylines) {
      if (revealedStories.contains(story.id)) {
        nodes.putIfAbsent(
          'storyline:${story.id}',
          () => StorylineProgressionNode(
            id: 'storyline:${story.id}',
            kind: StorylineProgressionNodeKind.storyline,
            canonicalId: story.id,
            storylineId: story.id,
            label: story.title,
          ),
        );
      }
    }
    outcomeSources = storyGraphOutcomeSources(project, storyId, nodes);
  }

  final ProjectManifest project;
  final String storyId;
  late final StorylineProgressionProjection projection;
  late final Map<String, StorylineProgressionNode> nodes;
  late final Map<String, StoryGraphOutcomeSource> outcomeSources;
  final _booleanFacts = <String>{};

  Map<String, String> additionalSources({String query = ''}) {
    final needle = query.toLowerCase();
    final choices = {
      for (final fact in project.facts)
        if (fact.valueKind == NarrativeValueKind.boolean &&
            !nodes.containsKey('fact:${fact.id}'))
          'fact:${fact.id}': 'Fait · ${fact.label}',
      for (final story in project.storylines)
        if (!nodes.containsKey('storyline:${story.id}'))
          'storyline:${story.id}': 'Histoire · ${story.title}',
    };
    return {
      for (final entry in choices.entries)
        if (entry.key.toLowerCase().contains(needle) ||
            entry.value.toLowerCase().contains(needle))
          entry.key: entry.value,
    };
  }

  bool canSource(StorylineProgressionNode node) =>
      !node.isMissing &&
      switch (node.kind) {
        StorylineProgressionNodeKind.sceneOutcome =>
          outcomeSources[node.id]?.connectable ?? false,
        StorylineProgressionNodeKind.storyline => true,
        StorylineProgressionNodeKind.fact => _booleanFacts.contains(
          node.canonicalId,
        ),
        _ => false,
      };

  bool canTarget(
    StorylineProgressionNode source,
    StorylineProgressionNode target,
  ) =>
      !target.isMissing &&
      source.id != target.id &&
      switch (source.kind) {
        StorylineProgressionNodeKind.storyline =>
          target.kind == StorylineProgressionNodeKind.storyline,
        StorylineProgressionNodeKind.fact ||
        StorylineProgressionNodeKind.sceneOutcome =>
          target.kind == StorylineProgressionNodeKind.step &&
              target.storylineId == storyId,
        _ => false,
      };
}
