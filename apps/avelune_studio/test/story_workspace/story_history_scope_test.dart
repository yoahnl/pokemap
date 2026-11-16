import 'package:avelune_studio/features/story_draft/application/story_draft.dart';
import 'package:avelune_studio/features/story_draft/domain/story_dialogue_source.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:avelune_studio/features/story_draft/application/story_draft_fact_identity.dart';
import 'package:avelune_studio/features/story_workspace/application/story_history_scope.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../storyline/storyline_fakes.dart';

SceneAsset scene(String id, {String? dialogueId, String? factId}) => SceneAsset(
  id: id,
  name: id,
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      if (dialogueId != null)
        SceneNode(
          id: 'talk',
          kind: SceneNodeKind.yarnDialogue,
          payload: SceneYarnDialoguePayload(dialogueId: dialogueId),
        ),
      if (factId != null)
        SceneNode(
          id: 'check',
          kind: SceneNodeKind.condition,
          payload: SceneConditionPayload(
            conditionSource: SceneConditionSource(
              sourceKind: SceneConditionSourceKind.fact,
              sourceId: factId,
              operator: SceneConditionOperator.isTrue,
            ),
          ),
        ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: const [],
  ),
);

void main() {
  test(
    'a membership transfer between two stories stays atomic from either story',
    () {
      final draft = StoryDraft();
      StorylineAsset linked(String id, bool linked) {
        final story = mainStoryline().copyWith(id: id);
        final chapter = story.chapters.first;
        return story.copyWith(
          chapters: [
            chapter.copyWith(
              steps: [
                chapter.steps.first.copyWith(
                  sceneLinkIds: linked ? ['gate'] : [],
                ),
              ],
            ),
          ],
        );
      }

      final first = linked('first', true);
      final other = linked('other', false);
      draft.load(StoryDraftKind.story, first.id, first);
      draft.load(StoryDraftKind.story, other.id, other);
      draft.group(() {
        draft.put(StoryDraftKind.story, linked('first', false));
        draft.put(StoryDraftKind.story, linked('other', true));
      });
      final scope = StoryHistoryScope({
        (kind: StoryDraftKind.story, id: first.id),
      });
      expect(scope.decision(draft, redo: false), StoryHistoryDecision.allowed);
      draft.undo();
      expect(draft.currentOf(StoryDraftKind.story, first.id), first);
      expect(draft.currentOf(StoryDraftKind.story, other.id), other);
      expect(scope.decision(draft, redo: true), StoryHistoryDecision.allowed);
    },
  );

  test(
    'a created fact identity change remains undoable under its new identity',
    () {
      final draft = StoryDraft();
      final fact = NarrativeFactDefinition(id: 'fact_old', label: 'Ancien');
      draft.load(StoryDraftKind.fact, fact.id, null);
      draft.put(StoryDraftKind.fact, fact);
      String? renamed;
      draft.group(() {
        draft.put(
          StoryDraftKind.fact,
          NarrativeFactDefinition(id: fact.id, label: 'Nouveau'),
        );
        renamed = followDraftFactName(draft, fact.id, taken: const []);
      });
      expect(renamed, isNotNull);
      final scope = StoryHistoryScope({
        (kind: StoryDraftKind.fact, id: renamed!),
      });
      expect(scope.decision(draft, redo: false), StoryHistoryDecision.allowed);
      draft.undo();
      expect(draft.currentOf(StoryDraftKind.fact, fact.id), fact);
      expect(scope.decision(draft, redo: true), StoryHistoryDecision.allowed);
    },
  );

  test(
    'a foreign next transaction blocks travel without searching older history',
    () {
      final draft = StoryDraft();
      final first = scene('first');
      final other = scene('other');
      draft.load(StoryDraftKind.scene, first.id, first);
      draft.load(StoryDraftKind.scene, other.id, other);
      draft.put(
        StoryDraftKind.scene,
        SceneAsset.fromJson({...first.toJson(), 'name': 'Premier modifié'}),
      );
      draft.put(
        StoryDraftKind.scene,
        SceneAsset.fromJson({...other.toJson(), 'name': 'Autre modifié'}),
      );
      final scope = StoryHistoryScope({
        (kind: StoryDraftKind.scene, id: 'first'),
      });
      expect(
        scope.decision(draft, redo: false),
        StoryHistoryDecision.outsideSelection,
      );
      expect(draft.nextStep(redo: false), {
        (kind: StoryDraftKind.scene, id: 'other'),
      });
    },
  );

  test('a scene and its dialogue travel together in both directions', () {
    final draft = StoryDraft();
    final before = scene('first');
    final dialogue = StoryDialogueSource(
      entry: const ProjectDialogueEntry(
        id: 'greeting',
        name: 'Bonjour',
        relativePath: 'dialogues/bonjour.yarn',
      ),
      source: 'title: Start\n---\nBonjour\n===',
    );
    draft.load(StoryDraftKind.scene, before.id, before);
    draft.load(StoryDraftKind.dialogue, dialogue.id, null);
    draft.group(() {
      draft.put(StoryDraftKind.scene, scene('first', dialogueId: dialogue.id));
      draft.put(StoryDraftKind.dialogue, dialogue);
    });
    final scope = StoryHistoryScope({
      (kind: StoryDraftKind.scene, id: 'first'),
    });
    expect(scope.decision(draft, redo: false), StoryHistoryDecision.allowed);
    draft.undo();
    expect(draft.currentOf(StoryDraftKind.scene, 'first'), before);
    expect(draft.currentOf(StoryDraftKind.dialogue, dialogue.id), isNull);
    expect(scope.decision(draft, redo: true), StoryHistoryDecision.allowed);
    draft.redo();
    expect(draft.currentOf(StoryDraftKind.dialogue, dialogue.id), dialogue);
  });

  test('creating a fact and its condition is one scoped transaction', () {
    final draft = StoryDraft();
    final before = scene('first');
    final fact = NarrativeFactDefinition(id: 'met', label: 'Rencontre');
    draft.load(StoryDraftKind.scene, 'first', before);
    draft.load(StoryDraftKind.fact, fact.id, null);
    draft.group(() {
      draft.put(StoryDraftKind.fact, fact);
      draft.put(StoryDraftKind.scene, scene('first', factId: fact.id));
    });
    final scope = StoryHistoryScope({
      (kind: StoryDraftKind.scene, id: 'first'),
    });
    expect(scope.decision(draft, redo: false), StoryHistoryDecision.allowed);
    draft.undo();
    expect(draft.currentOf(StoryDraftKind.fact, fact.id), isNull);
    expect(scope.decision(draft, redo: true), StoryHistoryDecision.allowed);
  });

  test('an unrelated object in a composite refuses the entire group', () {
    final draft = StoryDraft();
    final before = scene('first');
    final fact = NarrativeFactDefinition(id: 'unrelated', label: 'Autre');
    draft.load(StoryDraftKind.scene, 'first', before);
    draft.load(StoryDraftKind.fact, fact.id, null);
    draft.group(() {
      draft.put(StoryDraftKind.fact, fact);
      draft.put(
        StoryDraftKind.scene,
        SceneAsset.fromJson({...before.toJson(), 'name': 'Modifié'}),
      );
    });
    final scope = StoryHistoryScope({
      (kind: StoryDraftKind.scene, id: 'first'),
    });
    expect(
      scope.decision(draft, redo: false),
      StoryHistoryDecision.outsideSelection,
    );
    expect(draft.currentOf(StoryDraftKind.fact, fact.id), fact);
    expect(
      const StoryHistoryScope.empty().decision(draft, redo: false),
      StoryHistoryDecision.outsideSelection,
    );
  });

  test('a fresh draft never exposes another project history', () {
    final scope = StoryHistoryScope({(kind: StoryDraftKind.fact, id: 'met')});
    expect(
      scope.decision(StoryDraft(), redo: false),
      StoryHistoryDecision.empty,
    );
    expect(
      scope.decision(StoryDraft(), redo: true),
      StoryHistoryDecision.empty,
    );
  });
}
