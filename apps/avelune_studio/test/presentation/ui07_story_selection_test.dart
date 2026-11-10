import 'package:avelune_studio/features/stories/application/story_document_commands.dart';
import 'package:avelune_studio/features/stories/application/story_labels.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/story_backend_fixture.dart';

void main() {
  test('rapid document changes retain original metadata targets and a removed target never edits its parent', () async {
    final fixture = await StoryBackendFixture.create(
      stories: [backendStory('main')],
    );
    addTearDown(fixture.dispose);
    final controller = fixture.attach()..open('main');
    final commands = StoryDocumentCommands(controller);
    commands.addStep('main', 'main_chapter', 'Autre étape');
    final other = controller.active!.chapters.single.steps.last;
    commands.metadata(
      'main',
      'main_chapter',
      'main_step',
      'title',
      'Trouver la gare après la pluie',
    );
    final parentTitle = controller.active!.title;
    commands.remove('main', 'main_chapter', other.id);
    final beforeLateEdit = controller.project;
    commands.metadata(
      'main',
      'main_chapter',
      other.id,
      'title',
      'Texte tardif',
    );
    expect(controller.project, beforeLateEdit);
    expect(controller.active!.title, parentTitle);
    expect(
      controller.active!.chapters.single.steps.single.title,
      'Trouver la gare après la pluie',
    );
    expect(controller.error, isNull);
    expect((await fixture.readFresh()).storylines.single, backendStory('main'));
  });

  test(
    'homonym story IDs and filtering retain the exact active dirty document',
    () async {
      final original = backendStory('main', title: 'Préparer le départ');
      final fixture = await StoryBackendFixture.create(stories: [original]);
      addTearDown(fixture.dispose);
      final controller = fixture.attach()..open('main');
      final created = controller.create('Préparer le départ')!;
      expect(created.id, isNot(original.id));
      final commands = StoryDocumentCommands(controller);
      commands.metadata(
        created.id,
        null,
        null,
        'title',
        'Préparer le départ — autre histoire',
      );
      final draft = controller.active!;
      controller.open('main');
      expect(controller.active, original);
      expect(
        controller.stories.singleWhere((story) => story.id == created.id),
        draft,
      );
      controller.open(created.id);
      expect(
        filterStoryLibrary(controller.stories, 'sans résultat').stories,
        isEmpty,
      );
      expect(controller.active, same(draft));
      expect(controller.dirty, isTrue);
      controller.open('main');
      controller.open(created.id);
      expect(controller.active, same(draft));
      expect((await fixture.readFresh()).storylines, [original]);
    },
  );

  test(
    'metadata commits publish the exact story without another selection',
    () async {
      final fixture = await StoryBackendFixture.create(
        stories: [backendStory('main')],
      );
      addTearDown(fixture.dispose);
      final controller = fixture.attach()..open('main');
      StoryDocumentCommands(controller).metadata(
        'main',
        null,
        null,
        'title',
        'Préparer le départ après la pluie',
      );
      expect(await controller.save(), isTrue, reason: controller.error);
      expect(controller.dirty, isFalse);
      expect(
        (await fixture.readFresh()).storylines.single.title,
        'Préparer le départ après la pluie',
      );
    },
  );
}
