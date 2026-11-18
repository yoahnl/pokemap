import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/storyline/application/storyline_journal_edits.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_edits.dart';
import 'package:avelune_studio/features/storyline/data/local_storyline_read_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../game_memory/game_memory_catalog_fixture.dart';
import '../pokemon/pokemon_scoped_save_counting_reader.dart';
import 'story_workspace_catalog_fixture.dart';

void main() {
  test('chapter and journal edits keep the same resource scope as the project grows', () async {
    final counts = <({int reads, int unitReads, int writes})>[];
    for (final size in [12, 24]) {
      final session = await openGameMemoryCatalog(
        unrelated: size,
        unrelatedDialogues: true,
        storylines: true,
      );
      final objects = Directory('${session.directoryPath}/catalog/objects');
      Future<Set<String>> objectPaths() async => {
        await for (final entry in objects.list(recursive: true))
          if (entry is File) entry.path,
      };
      final unrelatedStories = await LocalStorylineReadAdapter(session).storylines();
      final initial = await openStoryWorkspaceCatalog(session);
      expect(
        await initial.trame.startStoryline(
          StorylineType.main,
          'Le passage',
          'Le bourg',
        ),
        isTrue,
      );
      final outline = initial.trame.view!.outline.storylines.singleWhere(
        (item) => item.title == 'Le passage',
      );
      final chapter = outline.chapters.single;
      expect(
        await initial.trame.createMilestone(
          outline.id,
          chapter.id,
          'Trouver Léo',
        ),
        isTrue,
      );
      final step = initial.trame.view!.milestones.singleWhere(
        (item) => item.milestone.title == 'Trouver Léo',
      ).milestone;
      expect(await initial.story.save(), isTrue, reason: initial.story.error);

      final reader = CountingReader();
      final promoted = <String>[];
      final (:trame, :story) = await openStoryWorkspaceCatalog(
        session,
        reader: reader,
        observeWrite: (context) {
          if (context.storageKey case final key?
              when context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterResourcePromoted) {
            promoted.add(key);
          }
        },
      );
      expect(await trame.prepare(), isTrue);
      reader.clear();
      final objectsBefore = await objectPaths();
      expect(
        await trame.renameChapter(outline.id, chapter.id, 'Le vieux bourg'),
        isTrue,
      );
      expect(
        await trame.setMilestoneJournal(
          outline.id,
          chapter.id,
          step.id,
          journal: (title: 'Le guide', text: 'Retourner sur la place.'),
        ),
        isTrue,
      );
      expect(reader.paths, isEmpty);
      expect(promoted, isEmpty);
      expect(await objectPaths(), objectsBefore);
      final outside = Zone.current;
      final unrelatedFiles = <String>[];
      await IOOverrides.runZoned(
        () async => expect(await story.save(), isTrue, reason: story.error),
        createFile: (path) {
          if (path.startsWith('${session.directoryPath}/maps/') ||
              path.startsWith('${session.directoryPath}/dialogues/')) {
            unrelatedFiles.add(path);
          }
          return outside.run(() => File(path));
        },
      );
      expect(unrelatedFiles, isEmpty);
      final newObjects = (await objectPaths()).difference(objectsBefore);
      expect(newObjects, isNotEmpty);
      expect(reader.paths, contains('catalog/HEAD.json'));
      expect(
        reader.paths.where(
          (path) => path.startsWith('maps/') || path.startsWith('dialogues/'),
        ),
        isEmpty,
      );
      expect(reader.definitions.where((id) => id.contains('unused_')), isEmpty);
      expect(
        reader.unitKeys.where(
          (key) => key.contains('unused-') ||
              key.contains('unused_') ||
              key.contains('unrelated_story_'),
        ),
        isEmpty,
      );
      expect(promoted, ['catalog/HEAD.json']);
      counts.add((
        reads: reader.paths.length,
        unitReads: reader.unitKeys.length,
        writes: newObjects.length,
      ));

      final reopened = await LocalStorylineReadAdapter(session).storylines();
      final saved = reopened.singleWhere((item) => item.id == outline.id);
      expect(reopened.where((item) => item.id != outline.id), unrelatedStories);
      expect(saved.chapters.single.title, 'Le vieux bourg');
      expect(
        saved.chapters.single.steps.single.journal!.text.fallback,
        'Retourner sur la place.',
      );
      expect(
        saved.chapters.single.steps.single.journal!.title.fallback,
        'Le guide',
      );
    }
    expect(counts.last.reads, counts.first.reads, reason: '$counts');
    expect(counts.last.unitReads, counts.first.unitReads, reason: '$counts');
    expect(counts.last.writes, counts.first.writes, reason: '$counts');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
