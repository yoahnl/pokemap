import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/stories/data/local_story_adapter.dart';
import 'package:avelune_studio/features/stories/domain/story_port.dart';
import 'package:avelune_studio/features/storyline/application/storyline_journal_edits.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_edits.dart';
import 'package:avelune_studio/features/storyline/data/local_storyline_read_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../game_memory/game_memory_catalog_fixture.dart';
import 'story_workspace_catalog_fixture.dart';

void main() {
  test('conflicting chapter drafts preserve the local title and the published revision', () async {
    final session = await openGameMemoryCatalog();
    final initial = await openStoryWorkspaceCatalog(session);
    expect(
      await initial.trame.startStoryline(StorylineType.main, 'Voyage', 'Bourg'),
      isTrue,
    );
    expect(await initial.story.save(), isTrue, reason: initial.story.error);
    final first = await openStoryWorkspaceCatalog(session);
    final second = await openStoryWorkspaceCatalog(session);
    final outline = first.trame.view!.outline.storylines.single;
    final chapter = outline.chapters.single;
    expect(
      await first.trame.renameChapter(
        outline.id,
        chapter.id,
        'Version publiée',
      ),
      isTrue,
    );
    expect(
      await second.trame.renameChapter(
        outline.id,
        chapter.id,
        'Brouillon local',
      ),
      isTrue,
    );
    expect(await first.story.save(), isTrue, reason: first.story.error);
    final head = File('${session.directoryPath}/catalog/HEAD.json');
    final revision = await head.readAsBytes();

    expect(await second.story.save(), isFalse);
    expect(second.story.error, startsWith('publish-refused:story:'));
    expect(second.story.dirty, isTrue);
    expect(
      second.trame.view!.outline.storylines.single.chapters.single.title,
      'Brouillon local',
    );
    expect(await head.readAsBytes(), revision);
    final reader = LocalStorylineReadAdapter(session);
    expect(
      (await reader.storylines()).single.chapters.single.title,
      'Version publiée',
    );
  });

  test(
    'H10 counter: targeted publication keeps checks on related documents',
    () async {
      final session = await openGameMemoryCatalog();
      final (:story, :trame) = await openStoryWorkspaceCatalog(session);
      expect(
        await trame.startStoryline(StorylineType.main, 'Voyage', 'Bourg'),
        isTrue,
      );
      expect(await story.save(), isTrue, reason: story.error);
      final reader = LocalStorylineReadAdapter(session);
      final before = (await reader.storylines()).single;
      final mapAdapter = LocalMapWorkspaceAdapter();
      final maps = MapWorkspaceController(session, mapAdapter);
      addTearDown(maps.dispose);
      await maps.initialize();
      final adapter = LocalStoryAdapter(
        session: session,
        mapAdapter: mapAdapter,
      );
      final updated = before.copyWith(title: 'Retour au bourg');
      await adapter.publishStory(
        id: before.id,
        base: before,
        current: updated,
        requiredSceneIds: {'gate'},
        requiredStoryIds: {before.id},
        requiredFactIds: {'fact_met'},
      );
      final head = File('${session.directoryPath}/catalog/HEAD.json');
      final revision = await head.readAsString();
      for (final kind in ['scene', 'story', 'fact']) {
        await expectLater(
          adapter.publishStory(
            id: updated.id,
            base: updated,
            current: updated.copyWith(title: 'Écriture refusée'),
            requiredSceneIds: {kind == 'scene' ? 'missing_scene' : 'gate'},
            requiredStoryIds: {kind == 'story' ? 'missing_story' : updated.id},
            requiredFactIds: {kind == 'fact' ? 'missing_fact' : 'fact_met'},
          ),
          throwsA(isA<StoryFailure>()),
          reason: 'missing $kind',
        );
        expect(await head.readAsString(), revision);
      }
      expect((await reader.storylines()).single.title, updated.title);
    },
  );

  test(
    'a trame, its scene link and its journal survive closing and reopening',
    () async {
      final session = await openGameMemoryCatalog();
      final head = File('${session.directoryPath}/catalog/HEAD.json');
      final map = File('${session.directoryPath}/maps/town.json');
      final savedHead = await head.readAsBytes();
      final savedMap = await map.readAsBytes();
      final reader = LocalStorylineReadAdapter(session);
      final (:story, :trame) = await openStoryWorkspaceCatalog(session);
      expect(trame.view!.outline.storylines, isEmpty);

      expect(
        await trame.startStoryline(
          StorylineType.main,
          'Le passage',
          'Le bourg',
        ),
        isTrue,
      );
      final storyId = trame.view!.outline.storylines.single.id;
      expect(await trame.createChapter(storyId, 'La sortie'), isTrue);
      final [firstChapter, secondChapter] =
          trame.view!.outline.storylines.single.chapters;
      expect(
        await trame.createMilestone(storyId, firstChapter.id, 'Trouver Léo'),
        isTrue,
      );
      expect(
        await trame.createMilestone(
          storyId,
          secondChapter.id,
          'Ouvrir la porte',
        ),
        isTrue,
      );
      final [firstStep, secondStep] = trame.view!.milestones
          .map((item) => item.milestone)
          .toList();
      expect(
        await trame.attachScene(
          storyId,
          secondChapter.id,
          secondStep.id,
          'gate',
        ),
        isTrue,
      );
      expect(
        await trame.attachScene(
          storyId,
          firstChapter.id,
          firstStep.id,
          'missing',
        ),
        isFalse,
      );
      expect(
        await trame.setMilestoneJournal(
          storyId,
          firstChapter.id,
          firstStep.id,
          journal: (
            title: 'Retrouver Léo',
            text: 'Chercher le guide dans le bourg.',
          ),
        ),
        isTrue,
      );
      expect(
        await trame.setMilestoneJournal(
          storyId,
          secondChapter.id,
          secondStep.id,
          journal: (
            title: 'La porte',
            text: 'Ouvrir le passage vers la sortie.',
          ),
        ),
        isTrue,
      );
      expect(
        await trame.addJournalClue(
          storyId,
          text: 'Léo connaît le chemin.',
          factId: 'fact_met',
        ),
        isTrue,
      );

      expect(story.dirty, isTrue);
      expect(await head.readAsBytes(), savedHead);
      expect(await reader.storylines(), isEmpty);
      expect(await story.save(), isTrue, reason: story.error);
      expect(story.dirty, isFalse);
      expect(await head.readAsBytes(), isNot(savedHead));
      expect(await map.readAsBytes(), savedMap);

      final reopened = await LocalProjectSessionAdapter().open(
        session.directoryPath,
      );
      final reopenedReader = LocalStorylineReadAdapter(reopened);
      final outline = await reopenedReader.outline();
      final saved = (await reopenedReader.storylines()).single;
      expect(saved.id, storyId);
      expect(saved.title, 'Le passage');
      expect(saved.chapters.map((chapter) => (chapter.id, chapter.title)), [
        (firstChapter.id, 'Le bourg'),
        (secondChapter.id, 'La sortie'),
      ]);
      final [firstSaved, secondSaved] = saved.chapters
          .map((chapter) => chapter.steps.single)
          .toList();
      expect((firstSaved.id, secondSaved.id), (firstStep.id, secondStep.id));
      expect(firstSaved.sceneLinkIds, isEmpty);
      expect(secondSaved.sceneLinkIds, ['gate']);
      expect(
        outline.storylines.single.chapters.last.milestones.single.sceneIds,
        ['gate'],
      );
      expect(
        firstSaved.journal?.text.fallback,
        'Chercher le guide dans le bourg.',
      );
      expect(
        secondSaved.journal?.text.fallback,
        'Ouvrir le passage vers la sortie.',
      );
      expect(saved.journalClues.single.factId, 'fact_met');
      expect(saved.journalClues.single.text.fallback, 'Léo connaît le chemin.');
      expect(
        outline.scenesOutsideStorylines.map((scene) => scene.id),
        isNot(contains('gate')),
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
