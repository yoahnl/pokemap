import 'dart:async';

import 'package:avelune_studio/features/dialogues/domain/dialogue_catalog_port.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/presentation/features/story/trame_milestone_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../dialogues/dialogue_catalog_support.dart';
import '../game_memory/game_memory_dialogue_usages_test.dart'
    show localizedFactDialogue;
import '../scenes/scene_catalog_support.dart';
import '../storyline/storyline_fakes.dart';
import 'story_memory_harness.dart';

Future<void> _openUsage(WidgetTester tester, String kind, String id) async {
  final usage = find.byKey(ValueKey('memory-open-$kind-$id'));
  await tester.ensureVisible(usage);
  await settleMemory(tester);
  await tester.tap(usage);
  await settleMemory(tester);
}

StorylineAsset _story({bool multiple = false, String secondId = 'main'}) =>
    StorylineAsset(
      id: 'main',
      type: StorylineType.main,
      title: 'Voyage',
      status: StorylineStatus.active,
      chapters: [
        StorylineChapter(
          id: 'chapter',
          title: 'Départ',
          order: 0,
          steps: [
            milestoneStep(
              'first',
              'Premier jalon',
              0,
              factId: multiple ? 'met' : null,
            ),
            milestoneStep(secondId, 'Deuxième jalon', 1, factId: 'met'),
          ],
        ),
      ],
    );

void main() {
  testWidgets(
    'a usage stays with its owning story when another story has the same milestone id',
    (tester) async {
      final story = _story();
      final other = story.copyWith(id: 'other', title: 'Autre voyage');
      final index = memoryIndex()..usageStories['main'] = story;
      index.users['met'] = NarrativeUsages(
        owners: const [
          NarrativeOwner(
            kind: NarrativeOwnerKind.storyline,
            id: 'main',
            role: NarrativeFactRole.read,
          ),
        ],
        notCovered: const [],
      );
      await openMemoryStudio(
        tester,
        index,
        storylines: FakeStorylineRead(stories: [story, other]),
      );
      await openHistoire(tester);
      await tester.tap(find.text('Rencontre'));
      await settleMemory(tester);
      await _openUsage(tester, 'storyline', 'main');
      expect(
        tester
            .widget<TrameMilestoneDetail>(find.byType(TrameMilestoneDetail))
            .at
            .storyline
            .id,
        'main',
      );
    },
  );

  testWidgets(
    'a usage opens the precise scene and shared localized dialogue document',
    (tester) async {
      final index = memoryIndex();
      final dialogue = localizedFactDialogue('met');
      final scene = catalogScene('gate', 'Porte');
      index.documents['gate'] = catalogDocument(scene);
      index.titlesByKind[NarrativeTitleKind.dialogues] = [
        NarrativeTitle(id: dialogue.id, title: dialogue.entry.name),
      ];
      index.users['met'] = NarrativeUsages(
        owners: [
          const NarrativeOwner(
            kind: NarrativeOwnerKind.scene,
            id: 'gate',
            role: NarrativeFactRole.read,
          ),
          NarrativeOwner(
            kind: NarrativeOwnerKind.dialogue,
            id: dialogue.id,
            role: NarrativeFactRole.read,
          ),
        ],
        notCovered: const ['dialogueDefinitions'],
      );
      final port = FakeDialogueCatalog()
        ..documents[dialogue.id] = DialogueCatalogDocument(
          dialogue: dialogue,
          sceneIds: const ['gate', 'other_scene'],
          notCovered: const [],
        );
      await openMemoryStudio(
        tester,
        index,
        dialogueCatalog: port,
        project: memoryProject.copyWith(
          scenes: [scene],
          dialogues: [dialogue.entry],
        ),
      );
      await openHistoire(tester);
      final directoriesBefore = [...index.directoryRequests];
      await tester.tap(find.text('Rencontre'));
      await settleMemory(tester);
      expect(index.directoryRequests, directoriesBefore);
      await _openUsage(tester, 'scene', 'gate');
      expect(
        find.byKey(const ValueKey('scene-focus-graph-gate')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('scene-focus-close')));
      await settleMemory(tester);
      await _openUsage(tester, 'dialogue', dialogue.id);
      expect(
        find.byKey(ValueKey('dialogue-document-${dialogue.id}')),
        findsOneWidget,
      );
      expect(port.requests, [dialogue.id]);
    },
  );

  testWidgets(
    'a storyline usage opens the second milestone instead of the first',
    (tester) async {
      final story = _story();
      final index = memoryIndex()..usageStories['main'] = story;
      index.users['met'] = NarrativeUsages(
        owners: const [
          NarrativeOwner(
            kind: NarrativeOwnerKind.storyline,
            id: 'main',
            role: NarrativeFactRole.read,
          ),
        ],
        notCovered: const [],
      );
      await openMemoryStudio(
        tester,
        index,
        storylines: FakeStorylineRead(stories: [story]),
      );
      await openHistoire(tester);
      await tester.tap(find.text('Rencontre'));
      await settleMemory(tester);
      await _openUsage(tester, 'storyline', 'main');
      expect(
        find.byKey(const ValueKey('trame-milestone-detail-main')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('trame-milestone-detail-first')),
        findsNothing,
      );
      expect(index.usageStoryRequests, ['main']);
    },
  );

  testWidgets(
    'multiple usage targets keep story and milestone namespaces distinct',
    (tester) async {
      final story = _story(multiple: true, secondId: 'storyline').copyWith(
        journalClues: [
          StorylineJournalClue(
            id: 'clue',
            factId: 'met',
            text: SceneLocalizedText(fallback: 'Indice'),
          ),
        ],
      );
      final index = memoryIndex()..usageStories['main'] = story;
      index.users['met'] = NarrativeUsages(
        owners: const [
          NarrativeOwner(
            kind: NarrativeOwnerKind.storyline,
            id: 'main',
            role: NarrativeFactRole.read,
          ),
        ],
        notCovered: const [],
      );
      await openMemoryStudio(
        tester,
        index,
        storylines: FakeStorylineRead(stories: [story]),
      );
      await openHistoire(tester);
      await tester.tap(find.text('Rencontre'));
      await settleMemory(tester);
      await _openUsage(tester, 'storyline', 'main');
      expect(
        find.byKey(const ValueKey('memory-usage-targets')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('memory-usage-target-root')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('confirm-reviewed-plan')));
      await settleMemory(tester);
      expect(
        find.byKey(const ValueKey('trame-storyline-detail-main')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('trame-milestone-detail-main')),
        findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey('story-section-facts')));
      await settleMemory(tester);
      await _openUsage(tester, 'storyline', 'main');
      await tester.tap(
        find.byKey(const ValueKey('memory-usage-target-step-storyline')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('confirm-reviewed-plan')));
      await settleMemory(tester);
      expect(
        find.byKey(const ValueKey('trame-milestone-detail-storyline')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'a late usage target cannot reopen a context after a map round trip',
    (tester) async {
      final story = _story();
      final pending = Completer<StorylineAsset?>();
      final index = memoryIndex()..usageStoryLoader = (_) => pending.future;
      index.users['met'] = NarrativeUsages(
        owners: const [
          NarrativeOwner(
            kind: NarrativeOwnerKind.storyline,
            id: 'main',
            role: NarrativeFactRole.read,
          ),
        ],
        notCovered: const [],
      );
      await openMemoryStudio(
        tester,
        index,
        storylines: FakeStorylineRead(stories: [story]),
      );
      await openHistoire(tester);
      await tester.tap(find.text('Rencontre'));
      await settleMemory(tester);
      await _openUsage(tester, 'storyline', 'main');
      await tester.tap(find.byKey(const ValueKey('studio-rail-map')));
      await settleMemory(tester);
      await tester.tap(find.byKey(const ValueKey('studio-rail-story')));
      await settleMemory(tester);
      pending.complete(story);
      await settleMemory(tester);
      expect(find.byKey(const ValueKey('memory-fact-list')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('trame-milestone-detail-main')),
        findsNothing,
      );
    },
  );

  testWidgets('a late usage target cannot override a newer section selection', (
    tester,
  ) async {
    final story = _story();
    final pending = Completer<StorylineAsset?>();
    final index = memoryIndex()..usageStoryLoader = (_) => pending.future;
    index.users['met'] = NarrativeUsages(
      owners: const [
        NarrativeOwner(
          kind: NarrativeOwnerKind.storyline,
          id: 'main',
          role: NarrativeFactRole.read,
        ),
      ],
      notCovered: const [],
    );
    await openMemoryStudio(
      tester,
      index,
      storylines: FakeStorylineRead(stories: [story]),
    );
    await openHistoire(tester);
    await tester.tap(find.text('Rencontre'));
    await settleMemory(tester);
    await _openUsage(tester, 'storyline', 'main');
    await tester.tap(find.byKey(const ValueKey('story-section-scenes')));
    await settleMemory(tester);
    pending.complete(story);
    await settleMemory(tester);
    expect(find.byKey(const ValueKey('scene-catalog-search')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('trame-milestone-detail-main')),
      findsNothing,
    );
  });
}
