import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'story_view_state.dart';
import 'story_graph_connection.dart';
import 'story_graph_sources.dart';

class StoryGraphGeometry {
  StoryGraphGeometry(
    this.project,
    this.storyId,
    StoryViewState state, {
    this.textScale = 1,
  }) {
    projection = buildStorylineProgressionProjection(
      project: project,
      storylineId: storyId,
    );
    nodes = {for (final node in projection.nodes) node.id: node};
    for (final fact in project.facts) {
      if (fact.valueKind == NarrativeValueKind.boolean) {
        booleanFacts.add(fact.id);
      }
      if (state.revealedFacts.contains(fact.id)) {
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
      if (state.revealedStories.contains(story.id)) {
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
      if (story.id != storyId) continue;
      for (final chapter in story.chapters) {
        for (final step in chapter.steps) {
          conditions['${step.id}:entry'] = step.entryCondition;
          conditions['${step.id}:completion'] = step.completionCondition;
        }
      }
    }
    outcomeSources = storyGraphOutcomeSources(project, storyId, nodes);
    final chapters = nodes.values
        .where((n) => n.kind == StorylineProgressionNodeKind.chapter)
        .toList();
    for (final node in nodes.values) {
      if (node.kind == StorylineProgressionNodeKind.step &&
          node.chapterId != null) {
        final siblings = steps['chapter:${node.chapterId}'] ??= [];
        stepIndices[node.id] = siblings.length;
        siblings.add(node);
      }
    }
    final columns = math.max(1, math.min(3, chapters.length));
    var y = 140.0;
    for (var i = 0; i < chapters.length; i += columns) {
      var height = 0.0;
      for (var j = i; j < math.min(i + columns, chapters.length); j++) {
        final id = chapters[j].id;
        final size = Size(
          230,
          headerHeight +
              18 +
              footerHeight +
              (steps[id]?.length ?? 0) * stepHeight,
        );
        defaults[id] = Offset(60 + (j % columns) * 335, y) & size;
        height = math.max(height, size.height);
      }
      y += height + 64;
    }
    var sourceIndex = 0;
    for (final node in nodes.values) {
      if (defaults.containsKey(node.id) ||
          node.kind == StorylineProgressionNodeKind.step &&
              node.chapterId != null) {
        continue;
      }
      if (node.id == 'storyline:$storyId') {
        defaults[node.id] = Rect.fromLTWH(60, 20, 230, sourceHeight);
      } else {
        defaults[node.id] = Rect.fromLTWH(
          60 + (sourceIndex % columns) * 335,
          y + (sourceIndex ~/ columns) * (sourceHeight + 32),
          230,
          sourceHeight,
        );
        sourceIndex++;
      }
    }
    edges = projection.edges
        .where(
          (e) =>
              e.kind != StorylineProgressionEdgeKind.contains &&
              !(e.kind == StorylineProgressionEdgeKind.authorOrder &&
                  e.source.kind == StorylineProgressionSourceKind.stepOrder),
        )
        .toList();
  }
  final double textScale;
  double get headerHeight => 56 * textScale;
  double get footerHeight => 34 * textScale;
  double get stepHeight => math.max(38, 26 * textScale);
  double get sourceHeight => headerHeight + 32 * textScale;
  final ProjectManifest project;
  final String storyId;
  late final StorylineProgressionProjection projection;
  late final Map<String, StorylineProgressionNode> nodes;
  late final List<StorylineProgressionEdge> edges;
  final defaults = <String, Rect>{};
  final booleanFacts = <String>{};
  final conditions = <String, ScriptCondition?>{};
  String edgeLabel(StorylineProgressionEdge edge) {
    final base = storyGraphEdgeLabel(edge);
    final condition =
        conditions['${edge.source.stepId}:${edge.source.conditionSlot}'];
    final value = switch (condition?.type) {
      ScriptConditionType.flagIsSet => 'vrai',
      ScriptConditionType.flagIsUnset => 'faux',
      ScriptConditionType.factEquals => switch (condition!.params['value']) {
        'true' => 'vrai',
        'false' => 'faux',
        final value => value,
      },
      _ => null,
    };
    return value == null ? base : '$base · $value';
  }

  final stepIndices = <String, int>{};
  final steps = <String, List<StorylineProgressionNode>>{};
  late final Map<String, StoryGraphOutcomeSource> outcomeSources;
  Rect rect(String id, Map<String, Offset> positions) {
    final node = nodes[id]!;
    if (node.kind == StorylineProgressionNodeKind.step &&
        node.chapterId != null) {
      final parent = 'chapter:${node.chapterId}';
      final group = rect(parent, positions);
      final index = stepIndices[id]!;
      return Rect.fromLTWH(
        group.left + 10,
        group.top + headerHeight + 10 + index * stepHeight,
        210,
        stepHeight - 4,
      );
    }
    final base = defaults[id]!;
    return (positions[id] ?? base.topLeft) & base.size;
  }

  Rect bounds(Map<String, Offset> positions) => defaults.isEmpty
      ? const Rect.fromLTWH(0, 0, 700, 450)
      : defaults.keys
            .map((id) => rect(id, positions))
            .reduce((a, b) => a.expandToInclude(b));
  Offset input(String id, Map<String, Offset> positions) =>
      rect(id, positions).centerLeft;
  Offset output(String id, Map<String, Offset> positions) =>
      rect(id, positions).centerRight;
  bool canSource(StorylineProgressionNode node) =>
      !node.isMissing &&
      switch (node.kind) {
        StorylineProgressionNodeKind.sceneOutcome =>
          (outcomeSources[node.id]?.connectable ?? false),
        StorylineProgressionNodeKind.storyline => true,
        StorylineProgressionNodeKind.fact => booleanFacts.contains(
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
