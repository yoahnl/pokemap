import 'package:avelune_studio/features/storyline/application/storyline_journal_edits.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_edits.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/features/scenes/domain/scene_document.dart';
import 'package:avelune_studio/presentation/features/story/story_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../presentation/story_memory_harness.dart';
import 'storyline_widget_support.dart';

Future<void> chooseLinkedScene(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('trame-milestone-leave')));
  await settleMemory(tester);
  final picker = find.byKey(const ValueKey('trame-link-scene'));
  await tester.scrollUntilVisible(
    picker,
    200,
    scrollable: find
        .descendant(
          of: find.byKey(const ValueKey('story-inspector')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  expect(picker, findsOneWidget);
  await tester.ensureVisible(picker);
  await settleMemory(tester);
  await tester.tap(picker);
  await settleMemory(tester);
  await tester.tap(find.text('Scène talk').last);
  await settleMemory(tester);
}

void main() {
  for (final missing in [false, true]) {
    testWidgets(
      'a selected scene absent from the partial source is ${missing ? 'refused without a transaction when unavailable' : 'loaded only on demand before linking'}',
      (tester) async {
        final index = memoryIndex()
          ..titlesByKind[NarrativeTitleKind.scenes] = [
            const NarrativeTitle(id: 'orphan', title: 'Scène orpheline'),
          ]
          ..documents['orphan'] = SceneDocument(
            scene: trameScene('orphan'),
            dialogues: const [],
            missingDialogueIds: const [],
            events: const [],
            maps: const {},
            mapReads: 0,
          );
        if (missing) {
          index.documentLoader = (_) async =>
              throw StateError('Lecture refusée');
        }
        await openTrameStudio(tester, index: index);
        final trame = tester.widget<StoryPage>(find.byType(StoryPage)).trame!;
        expect(index.documentRequests, isEmpty);
        await tester.tap(find.byKey(const ValueKey('trame-milestone-leave')));
        await settleMemory(tester);
        final picker = find.byKey(const ValueKey('trame-link-scene'));
        await tester.scrollUntilVisible(
          picker,
          200,
          scrollable: find
              .descendant(
                of: find.byKey(const ValueKey('story-inspector')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.tap(picker);
        await settleMemory(tester);
        await tester.tap(find.text('Scène orpheline').last);
        await settleMemory(tester);
        expect(index.documentRequests, ['orphan']);
        expect(
          trame.fullMilestone('main', 'chapter_one', 'leave')!.sceneLinkIds,
          missing ? [] : ['orphan'],
        );
        expect(trame.staging.draft.canUndo, !missing);
        if (missing) expect(trame.refusal, 'sceneUnavailable');
      },
    );
  }
  for (final confirm in [false, true]) {
    testWidgets(
      'a scene link move is ${confirm ? 'confirmed atomically and undoable' : 'cancelled without changing either milestone'}',
      (tester) async {
        await openTrameStudio(tester);
        final trame = tester.widget<StoryPage>(find.byType(StoryPage)).trame!;
        await chooseLinkedScene(tester);
        expect(
          find.byKey(const ValueKey('trame-move-scene-review')),
          findsOneWidget,
        );
        expect(find.textContaining('Rencontrer Léo'), findsWidgets);
        expect(find.textContaining('Partir'), findsWidgets);
        expect(
          trame.fullMilestone('main', 'chapter_one', 'meet')!.sceneLinkIds,
          ['talk'],
        );
        if (confirm) {
          await tester.tap(find.byKey(const ValueKey('confirm-reviewed-plan')));
        } else {
          await tester.tap(find.text('Annuler').last);
        }
        await settleMemory(tester);
        expect(
          trame.fullMilestone('main', 'chapter_one', 'meet')!.sceneLinkIds,
          confirm ? [] : ['talk'],
        );
        expect(
          trame.fullMilestone('main', 'chapter_one', 'leave')!.sceneLinkIds,
          confirm ? ['talk'] : [],
        );
        if (confirm) {
          trame.staging.draft.undo();
          expect(
            trame.fullMilestone('main', 'chapter_one', 'meet')!.sceneLinkIds,
            ['talk'],
          );
          expect(
            trame.fullMilestone('main', 'chapter_one', 'leave')!.sceneLinkIds,
            isEmpty,
          );
          trame.staging.draft.redo();
          expect(
            trame.fullMilestone('main', 'chapter_one', 'leave')!.sceneLinkIds,
            ['talk'],
          );
        } else {
          expect(trame.staging.draft.canUndo, isFalse);
          final picker = find.descendant(
            of: find.byKey(const ValueKey('trame-link-scene')),
            matching: find.byType(DropdownButtonFormField<String>),
          );
          expect(tester.state<FormFieldState<String>>(picker).value, isNull);
        }
      },
    );
  }

  testWidgets('a changed plot invalidates a pending link move confirmation', (
    tester,
  ) async {
    await openTrameStudio(tester);
    final trame = tester.widget<StoryPage>(find.byType(StoryPage)).trame!;
    await chooseLinkedScene(tester);
    expect(
      await trame.renameChapter('main', 'chapter_one', 'Autre nom'),
      isTrue,
    );
    await settleMemory(tester);
    await tester.tap(find.byKey(const ValueKey('confirm-reviewed-plan')));
    await settleMemory(tester);
    expect(trame.fullMilestone('main', 'chapter_one', 'meet')!.sceneLinkIds, [
      'talk',
    ]);
    expect(
      trame.fullMilestone('main', 'chapter_one', 'leave')!.sceneLinkIds,
      isEmpty,
    );
    expect(trame.refusal, 'stale');
  });
}
