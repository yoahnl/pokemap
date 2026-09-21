import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/presentation/features/stories/story_document_commands.dart';
import '../support/story_backend_fixture.dart';

void main() {
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
}
