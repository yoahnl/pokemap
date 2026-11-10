import 'package:avelune_studio/features/stories/application/story_document_commands.dart';
import 'package:avelune_studio/features/stories/application/story_progression_sources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'support/story_graph_project_fixture.dart';

void main() {
  test('first declared outcome connects without a fabricated effect', () {
    final initial = storyCanvasProject();
    final original = initial.storylines.first;
    final source = StorylineSceneLink.fromJson({
      ...original.sceneLinks.single.toJson(),
      'outcomeLinks': <Object>[],
      'expectedOutcomeIds': ['accepted'],
    });
    final project = initial.copyWith(
      storylines: [
        original.copyWith(sceneLinks: [source]),
        initial.storylines.last,
      ],
    );
    final graph = StoryProgressionSources(project, 'main');
    final sourceNode = graph.nodes['outcome:main:link:outcome-accepted']!;
    final target = graph.nodes['step:step1_1']!;
    expect(project.storylines.first.sceneLinks.single.outcomeLinks, isEmpty);
    expect(graph.canSource(sourceNode), isTrue);
    expect(graph.canTarget(sourceNode, target), isTrue);
    final request = StoryDocumentCommands.connectionRequest(
      source: sourceNode,
      target: target,
      choice: 0,
      outcome: graph.outcomeSources[sourceNode.id],
      relationshipId: () => throw StateError('Unexpected relationship'),
    );
    final result = connectStorylineProgressionEdge(project, request);
    expect(request.outcomeId, 'accepted');
    expect(result.disposition, StorylineProgressionMutationDisposition.applied);
    final outcome =
        result.after.storylines.first.sceneLinks.single.outcomeLinks.single;
    expect(outcome.outcomeId, 'accepted');
    expect(outcome.effects, hasLength(1));
    expect(outcome.effects.single.type, StorylineEffectType.activateStep);
    expect(outcome.effects.single.targetId, 'step1_1');
    expect(project.storylines.first.sceneLinks.single.outcomeLinks, isEmpty);
  });

  test('outcome requests preserve the exact target step and source result', () {
    final project = storyCanvasProject();
    final graph = StoryProgressionSources(project, 'main');
    final source = graph.nodes['outcome:main:link:result']!;
    final request = StoryDocumentCommands.connectionRequest(
      source: source,
      target: graph.nodes['step:step1_1']!,
      choice: 1,
      outcome: graph.outcomeSources[source.id],
      relationshipId: () => throw StateError('Unexpected relationship'),
    );
    expect(request.storylineId, 'main');
    expect(request.sceneLinkId, 'link');
    expect(request.outcomeLinkId, 'result');
    expect(request.targetStepId, 'step1_1');
    final result = connectStorylineProgressionEdge(project, request);
    expect(result.disposition, StorylineProgressionMutationDisposition.applied);
    final edge = buildStorylineProgressionProjection(
      project: result.after,
      storylineId: 'main',
    ).edgesOfKind(StorylineProgressionEdgeKind.outcomeCompletesStep).single;
    expect(edge.toNodeId, 'step:step1_1');
    expect(edge.source.outcomeLinkId, 'result');
  });

  test('fact requests preserve the exact completion slot and false value', () {
    final project = storyCanvasProject();
    final graph = StoryProgressionSources(
      project,
      'main',
      revealedFacts: const ['fact'],
    );
    final request = StoryDocumentCommands.connectionRequest(
      source: graph.nodes['fact:fact']!,
      target: graph.nodes['step:step1_0']!,
      choice: 3,
      relationshipId: () => throw StateError('Unexpected relationship'),
    );
    expect(request.chapterId, 'chapter1');
    expect(request.stepId, 'step1_0');
    expect(request.conditionSlot, StorylineProgressionConditionSlot.completion);
    expect(request.expectedValue, isFalse);
    final result = connectStorylineProgressionEdge(project, request);
    expect(result.disposition, StorylineProgressionMutationDisposition.applied);
    expect(
      result.after.storylines.first.chapters[1].steps[0].completionCondition,
      ScriptConditionFactory.flagIsUnset('fact'),
    );
    expect(
      result.after.storylines.first.chapters[1].steps[1],
      project.storylines.first.chapters[1].steps[1],
    );
  });

  test('secondary relationship keeps its canonical owner outside the displayed story', () {
    final project = storyCanvasProject();
    final graph = StoryProgressionSources(
      project,
      'main',
      revealedStories: const ['side0'],
    );
    final request = StoryDocumentCommands.connectionRequest(
      source: graph.nodes['storyline:side0']!,
      target: graph.nodes['storyline:main']!,
      choice: 0,
      relationshipId: () => 'relation',
    );
    final result = connectStorylineProgressionEdge(project, request);
    expect(result.disposition, StorylineProgressionMutationDisposition.applied);
    expect(request.sourceStorylineId, 'side0');
    expect(request.targetStorylineId, 'main');
    expect(result.after.storylines.first.relationships, isEmpty);
    expect(
      result.after.storylines.last.relationships.single.kind,
      StorylineRelationshipKind.requires,
    );
    final edge = buildStorylineProgressionProjection(
      project: result.after,
      storylineId: 'main',
    ).edgesOfKind(StorylineProgressionEdgeKind.requires).single;
    final removed = disconnectStorylineProgressionEdge(
      result.after,
      storylineId: 'main',
      edgeId: edge.id,
    );
    expect(
      removed.disposition,
      StorylineProgressionMutationDisposition.applied,
    );
    expect(removed.after.storylines, project.storylines);
  });
}
