import 'package:avelune_studio/features/stories/application/story_graph_sources.dart';
import 'package:avelune_studio/features/stories/application/story_document_commands.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/story_graph_project_fixture.dart';

void main() {
  test(
    'connection choices build native requests with exact source identities',
    () {
      final project = storyCanvasProject();
      final nodes = <String, StorylineProgressionNode>{};
      final sources = storyGraphOutcomeSources(project, 'main', nodes);
      final outcome = sources.entries.first;
      const target = StorylineProgressionNode(
        id: 'target',
        kind: StorylineProgressionNodeKind.step,
        canonicalId: 'target',
        label: 'Cible',
        storylineId: 'main',
        chapterId: 'chapter',
        stepId: 'step',
      );
      for (final choice in [0, 1]) {
        final request = StoryDocumentCommands.connectionRequest(
          source: nodes[outcome.key]!,
          target: target,
          choice: choice,
          outcome: outcome.value,
          relationshipId: () => throw StateError('Unexpected relation'),
        );
        expect(request.storylineId, 'main');
        expect(request.sceneLinkId, outcome.value.link.id);
        expect(request.outcomeLinkId, outcome.value.outcomeLinkId);
        expect(
          request.outcomeId,
          outcome.value.pending ? outcome.value.outcomeId : null,
        );
        expect(
          request.effectType,
          choice == 0
              ? StorylineEffectType.activateStep
              : StorylineEffectType.completeStep,
        );
        expect(request.targetStepId, 'step');
      }
      const fact = StorylineProgressionNode(
        id: 'fact',
        kind: StorylineProgressionNodeKind.fact,
        canonicalId: 'ready',
        label: 'Prêt',
      );
      for (var choice = 0; choice < 4; choice++) {
        final request = StoryDocumentCommands.connectionRequest(
          source: fact,
          target: target,
          choice: choice,
          relationshipId: () => throw StateError('Unexpected relation'),
        );
        expect(
          (request.storylineId, request.chapterId, request.stepId),
          ('main', 'chapter', 'step'),
        );
        expect(
          request.conditionSlot,
          choice < 2
              ? StorylineProgressionConditionSlot.entry
              : StorylineProgressionConditionSlot.completion,
        );
        expect(request.factId, 'ready');
        expect(request.expectedValue, choice.isEven);
      }
      const story = StorylineProgressionNode(
        id: 'story',
        kind: StorylineProgressionNodeKind.storyline,
        canonicalId: 'source',
        label: 'Source',
      );
      for (var choice = 0; choice < 3; choice++) {
        final request = StoryDocumentCommands.connectionRequest(
          source: story,
          target: target,
          choice: choice,
          relationshipId: () => 'relation-exact',
        );
        expect(request.relationshipId, 'relation-exact');
        expect(
          request.relationshipKind,
          [
            StorylineRelationshipKind.requires,
            StorylineRelationshipKind.blocks,
            StorylineRelationshipKind.convergesTo,
          ][choice],
        );
        expect(
          (request.sourceStorylineId, request.targetStorylineId),
          ('source', 'target'),
        );
      }
    },
  );
  test(
    'pending outcome identity avoids another result and preserves source names',
    () {
      final initial = storyCanvasProject();
      final story = initial.storylines.first;
      final link = story.sceneLinks.single;
      final conflict = StorylineSceneLink.fromJson({
        ...link.toJson(),
        'expectedOutcomeIds': ['accepted'],
        'outcomeLinks': [
          {
            ...link.outcomeLinks.single.toJson(),
            'id': 'outcome-accepted',
            'outcomeId': 'other',
          },
        ],
      });
      final project = initial.copyWith(
        storylines: [
          story.copyWith(sceneLinks: [conflict]),
          initial.storylines.last,
        ],
      );
      final nodes = <String, StorylineProgressionNode>{};
      final sources = storyGraphOutcomeSources(project, 'main', nodes);
      final source = sources.values.singleWhere((s) => s.pending);
      expect(source.outcomeLinkId, 'outcome-accepted-2');
      expect(
        nodes['outcome:main:link:outcome-accepted-2']!.label,
        'Rencontre · accepted',
      );
      final result = connectStorylineProgressionEdge(
        project,
        StorylineProgressionConnectRequest.outcomeEffect(
          storylineId: 'main',
          sceneLinkId: 'link',
          outcomeLinkId: source.outcomeLinkId,
          outcomeId: source.outcomeId,
          effectType: StorylineEffectType.activateStep,
          targetStepId: 'step1_1',
        ),
      );
      expect(
        result.disposition,
        StorylineProgressionMutationDisposition.applied,
      );
      expect(
        result.after.storylines.first.sceneLinks.single.outcomeLinks
            .singleWhere((o) => o.id == 'outcome-accepted'),
        conflict.outcomeLinks.single,
      );
      expect(
        result.after.storylines.first.sceneLinks.single.outcomeLinks
            .singleWhere((o) => o.outcomeId == 'accepted')
            .id,
        'outcome-accepted-2',
      );
    },
  );
  test(
    'missing stories and unknown expected outcomes do not fabricate links',
    () {
      final project = storyCanvasProject();
      final nodes = <String, StorylineProgressionNode>{};
      expect(storyGraphOutcomeSources(project, 'missing', nodes), isEmpty);
      expect(nodes, isEmpty);
      final story = project.storylines.first;
      final link = story.sceneLinks.single;
      final changed = project.copyWith(
        storylines: [
          story.copyWith(
            sceneLinks: [
              StorylineSceneLink.fromJson({
                ...link.toJson(),
                'outcomeLinks': <Object>[],
                'expectedOutcomeIds': ['unknown'],
              }),
            ],
          ),
        ],
      );
      expect(storyGraphOutcomeSources(changed, story.id, nodes), isEmpty);
      expect(nodes, isEmpty);
    },
  );
}
