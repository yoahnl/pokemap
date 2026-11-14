import 'package:avelune_studio/features/storyline/application/storyline_trame_controller.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_edits.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../game_behaviours/game_behaviour_fakes.dart';
import '../game_memory/game_memory_fakes.dart';
import 'storyline_fakes.dart';

SceneAsset _scene(String id) => SceneAsset(
  id: id,
  name: 'Scène $id',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [SceneNode(id: 'start', kind: SceneNodeKind.start)],
    edges: const [],
  ),
);

void main() {
  late FakeStorylineRead reads;
  late FakeNarrativeIndex index;
  late FakeMemoryStaging staging;
  late StorylineTrameController trame;

  setUp(() {
    final scenes = [_scene('talk'), _scene('gate')];
    reads = FakeStorylineRead(
      stories: [mainStoryline()],
      scenes: scenes,
      facts: [memoryFact('met', 'Rencontrer Léo')],
    );
    index = FakeNarrativeIndex()
      ..addFacts([memoryFact('met', 'Rencontrer Léo')]);
    staging = FakeMemoryStaging();
    final source = FakeBehaviourSource(
      records: [
        behaviour(
          1,
          'Parler',
          source: NarrativeEventSourceRef.mapEnter('town'),
          enabled: true,
          sceneId: 'talk',
        ),
        behaviour(
          2,
          'Ouvrir',
          source: NarrativeEventSourceRef.mapEnter('town'),
          enabled: true,
          sceneId: 'gate',
        ),
        behaviour(
          3,
          'Aussi ouvrir',
          source: NarrativeEventSourceRef.mapEnter('town'),
          enabled: true,
          sceneId: 'gate',
        ),
      ],
      maps: const [
        ProjectMapEntry(
          id: 'town',
          name: 'Bourg',
          relativePath: 'maps/town.json',
        ),
      ],
      scenes: scenes,
    );
    trame = StorylineTrameController(
      port: reads,
      index: index,
      staging: staging,
      source: () => source,
      changed: () {},
    );
  });

  test('opening reads the outline only and indexes behaviours', () async {
    await trame.open();

    expect((reads.outlines, reads.storylineReads), (1, 0));
    expect(index.titleRequests, isEmpty);
    final view = trame.view!;
    final meet = view.milestone('meet')!;
    expect(meet.chapter.title, 'Départ');
    expect(view.behavioursOf(meet.milestone).map((record) => record.id), [
      behaviourId(1),
    ]);
    expect(view.milestoneOfFact('met')?.milestone.id, 'meet');
    expect(view.outsideBehaviours.map((record) => record.id), [
      behaviourId(2),
      behaviourId(3),
    ]);
    expect(
      view.milestone('leave')!.milestone.issues,
      contains(StorylineMilestoneIssue.noBehaviour),
    );
  });

  test(
    'a new chapter and milestone stage the storyline and its fact',
    () async {
      await trame.open();

      expect(await trame.createChapter('main', 'Retour'), isTrue);
      expect(
        await trame.createMilestone('main', 'chapter_retour', 'Rentrer'),
        isTrue,
      );

      expect(
        (reads.storylineReads, staging.stories['main']),
        (1, reads.stories.single),
      );
      final story = staging.draft.entryOf(StoryDraftKind.story, 'main')!;
      expect(story.base, reads.stories.single);
      final chapter = story.current!.chapters.singleWhere(
        (c) => c.id == 'chapter_retour',
      );
      expect(chapter.steps.single.id, 'milestone_rentrer');
      final fact = staging.draft.entryOf(StoryDraftKind.fact, 'fact_rentrer')!;
      expect((fact.creation, fact.current!.label), (true, 'Rentrer'));
      expect(
        trame.view!.milestone('milestone_rentrer')!.milestone.completionFactId,
        'fact_rentrer',
      );
      expect(staging.stages, 2);
    },
  );

  test('renaming a milestone renames its untouched completion fact', () async {
    await trame.open();

    expect(
      await trame.renameMilestone(
        'main',
        'chapter_one',
        'meet',
        'Retrouver Léo',
        completionFactId: 'met',
      ),
      isTrue,
    );

    expect(index.factRequests, [
      ['met'],
    ]);
    final fact = staging.draft.entryOf(StoryDraftKind.fact, 'met')!;
    expect(
      (fact.base, fact.current!.label),
      (index.definitions['met'], 'Retrouver Léo'),
    );
    expect(staging.facts['met'], index.definitions['met']);
  });

  test(
    'attaching a shared scene moves it whole; refusals change nothing',
    () async {
      await trame.open();

      expect(
        await trame.attachScene('main', 'chapter_one', 'leave', 'gate'),
        isTrue,
      );
      var view = trame.view!;
      expect(view.behavioursOf(view.milestone('leave')!.milestone).length, 2);
      expect(view.outsideBehaviours, isEmpty);

      expect(
        await trame.attachScene('main', 'chapter_one', 'meet', 'gate'),
        isTrue,
      );
      view = trame.view!;
      expect(view.milestone('leave')!.milestone.sceneIds, isEmpty);
      expect(view.milestone('meet')!.milestone.sceneIds, ['talk', 'gate']);

      final stages = staging.stages;
      expect(
        await trame.attachScene('main', 'chapter_one', 'meet', 'missing'),
        isFalse,
      );
      expect(trame.refusal, 'sceneNotFound');
      expect(staging.stages, stages);

      expect(
        await trame.detachScene('main', 'chapter_one', 'meet', 'gate'),
        isTrue,
      );
      expect(trame.view!.outsideBehaviours, hasLength(2));
    },
  );

  test('chapters and milestones reorder and archive', () async {
    await trame.open();

    expect(await trame.moveChapter('main', 'chapter_two', -1), isTrue);
    expect(trame.view!.outline.storylines.single.chapters.map((c) => c.id), [
      'chapter_two',
      'chapter_one',
    ]);
    expect(
      await trame.moveMilestone(
        'main',
        'chapter_one',
        'leave',
        targetChapterId: 'chapter_two',
        targetIndex: 0,
      ),
      isTrue,
    );
    expect(trame.view!.milestone('leave')!.chapter.id, 'chapter_two');
    expect(
      await trame.archiveChapter('main', 'chapter_one', archived: true),
      isTrue,
    );
    expect(
      trame.view!.outline.storylines.single.chapters.last.status,
      StorylineStatus.archived,
    );
  });

  test(
    'a proposal is kept into the draft or discarded without writing',
    () async {
      reads
        ..stories = []
        ..proposed = mainStoryline().copyWith(
          id: 'proposed_main',
          title: 'Proposée',
        );
      await trame.open();
      expect(trame.view!.outline.storylines, isEmpty);

      await trame.loadProposal();
      trame.discardProposal();
      expect((trame.proposal.value, staging.stages), (null, 0));

      await trame.loadProposal();
      expect(await trame.keepProposal('Ma trame'), isTrue);
      final kept = staging.draft.entryOf(
        StoryDraftKind.story,
        'proposed_main',
      )!;
      expect((kept.creation, kept.current!.title), (true, 'Ma trame'));
      expect(trame.view!.outline.storylines.single.title, 'Ma trame');
      expect(trame.proposal.value, isNull);

      expect(trame.discardStoryline('proposed_main'), isTrue);
      expect(
        staging.draft.isTouched(StoryDraftKind.story, 'proposed_main'),
        isFalse,
      );
      expect(reads.proposals, 2);
    },
  );

  test('a read only staging edits nothing', () async {
    staging.editable = false;
    await trame.open();

    expect(await trame.createChapter('main', 'Retour'), isFalse);
    expect(staging.stages, 0);
  });
}
