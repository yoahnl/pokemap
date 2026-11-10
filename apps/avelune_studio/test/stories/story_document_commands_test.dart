import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/stories/application/story_document_commands.dart';
import 'package:avelune_studio/features/stories/application/story_labels.dart';

import '../support/story_backend_fixture.dart';

void main() {
  test(
    'outcome toggles use the current step, remain idempotent and publish',
    () async {
      final fixture = await StoryBackendFixture.create(
        stories: [backendStory('story')],
      );
      addTearDown(fixture.dispose);
      final controller = fixture.attach();
      final commands = StoryDocumentCommands(controller);
      commands.metadata(
        'story',
        'story_chapter',
        'story_step',
        'title',
        'Courante',
      );
      void toggle(bool expected) => commands.expectOutcome(
        storyId: 'story',
        chapterId: 'story_chapter',
        stepId: 'story_step',
        outcomeId: 'unknown-preserved',
        expected: expected,
      );
      toggle(true);
      final once = controller.project;
      toggle(true);
      expect(controller.project, once);
      expect(
        controller.stories.single.chapters.single.steps.single.title,
        'Courante',
      );
      expect(
        controller
            .stories
            .single
            .chapters
            .single
            .steps
            .single
            .expectedOutcomeIds,
        ['unknown-preserved'],
      );
      controller.restore(redo: false);
      expect(
        controller
            .stories
            .single
            .chapters
            .single
            .steps
            .single
            .expectedOutcomeIds,
        isEmpty,
      );
      expect(
        controller.stories.single.chapters.single.steps.single.title,
        'Courante',
      );
      toggle(true);
      toggle(false);
      expect(
        controller
            .stories
            .single
            .chapters
            .single
            .steps
            .single
            .expectedOutcomeIds,
        isEmpty,
      );
      toggle(true);
      expect(await controller.save(), isTrue);
      expect(
        (await fixture.readFresh())
            .storylines
            .single
            .chapters
            .single
            .steps
            .single
            .expectedOutcomeIds,
        ['unknown-preserved'],
      );
      commands.remove('story', 'story_chapter', 'story_step');
      final removed = controller.project;
      toggle(true);
      expect(controller.project, removed);
    },
  );

  test(
    'metadata clears optional text and preserves unrelated fields',
    () async {
      final step = StorylineStep(
        id: 'step',
        title: 'Départ',
        order: 7,
        description: 'Description',
        authorNotes: 'Notes',
        metadata: {'kept': '4'},
        completionCondition: ScriptCondition(
          type: ScriptConditionType.flagIsSet,
          params: {ScriptConditionParams.flagName: 'ready'},
        ),
      );
      final story = StorylineAsset(
        id: 'story',
        title: 'Voyage',
        type: StorylineType.main,
        chapters: [
          StorylineChapter(
            id: 'chapter',
            title: 'Début',
            order: 9,
            steps: [step],
          ),
        ],
      );
      final fixture = await StoryBackendFixture.create(stories: [story]);
      addTearDown(fixture.dispose);
      final controller = fixture.attach();
      final commands = StoryDocumentCommands(controller);
      commands.metadata('story', 'chapter', 'step', 'description', '');
      commands.metadata('story', 'chapter', 'step', 'notes', '');
      final actual = controller.stories.single.chapters.single.steps.single;
      expect(actual.description, isNull);
      expect(actual.authorNotes, isNull);
      expect(actual.order, 7);
      expect(actual.metadata, step.metadata);
      expect(actual.completionCondition, step.completionCondition);
      controller.restore(redo: false);
      expect(
        controller.stories.single.chapters.single.steps.single.authorNotes,
        'Notes',
      );
    },
  );

  test('late text for removed target never edits its parent', () async {
    final fixture = await StoryBackendFixture.create(
      stories: [backendStory('story')],
    );
    addTearDown(fixture.dispose);
    final controller = fixture.attach();
    final commands = StoryDocumentCommands(controller);
    commands.remove('story', 'story_chapter', 'story_step');
    final before = controller.project;
    commands.metadata(
      'story',
      'story_chapter',
      'story_step',
      'title',
      'Texte tardif',
    );
    expect(controller.project, before);
    commands.metadata('story', 'missing', null, 'title', 'Texte tardif');
    expect(controller.project, before);
  });

  test(
    'empty story gains real chapter then step without fake placeholders',
    () async {
      final fixture = await StoryBackendFixture.create();
      addTearDown(fixture.dispose);
      final controller = fixture.attach();
      final story = controller.create(
        'Nouvelle histoire',
        type: StorylineType.epilogue,
      )!;
      expect(story.chapters, isEmpty);
      final commands = StoryDocumentCommands(controller);
      commands.addChapter(story.id, 'Arrivée');
      final chapter = controller.active!.chapters.single;
      commands.addStep(story.id, chapter.id, 'Entrer');
      final current = controller.active!;
      expect(current.type, StorylineType.epilogue);
      expect(current.chapters.single.steps.single.title, 'Entrer');
      expect(current.sceneLinks, isEmpty);
      expect(await controller.save(), isTrue);
      expect((await fixture.readFresh()).storylines.single, current);
    },
  );
  test('author order moves stable chapter and step identities with undo and cold publication', () async {
    final story = StorylineAsset(
      id: 'story',
      title: 'Voyage',
      type: StorylineType.main,
      chapters: [
        StorylineChapter(id: 'later', title: 'Après', order: 20),
        StorylineChapter(
          id: 'first',
          title: 'Avant',
          order: 10,
          steps: [
            StorylineStep(id: 'last', title: 'Dernier', order: 2),
            StorylineStep(id: 'start', title: 'Premier', order: 1),
          ],
        ),
      ],
    );
    final fixture = await StoryBackendFixture.create(stories: [story]);
    addTearDown(fixture.dispose);
    final controller = fixture.attach();
    final commands = StoryDocumentCommands(controller);
    commands.moveChapter('story', 'later', -1);
    expect(
      orderedStoryChapters(controller.stories.single)
          .map((chapter) => chapter.id),
      ['later', 'first'],
    );
    controller.restore(redo: false);
    expect(controller.stories.single, story);
    controller.restore(redo: true);
    commands.moveStep('story', 'first', 'last', -1);
    final changed = controller.stories.single;
    expect(
      orderedStorySteps(
        changed.chapters.singleWhere((chapter) => chapter.id == 'first'),
      ).map((step) => step.id),
      ['last', 'start'],
    );
    for (final delta in [-1, 0, 99]) {
      commands.moveChapter('story', 'later', delta);
      commands.moveStep('story', 'first', 'last', delta);
    }
    commands.moveChapter('missing', 'first', 1);
    commands.moveStep('story', 'missing', 'last', 1);
    commands.moveStep('story', 'first', 'missing', 1);
    expect(controller.stories.single, changed);
    expect(await controller.save(), isTrue, reason: controller.error);
    expect((await fixture.readFresh()).storylines.single, changed);
  });
}
