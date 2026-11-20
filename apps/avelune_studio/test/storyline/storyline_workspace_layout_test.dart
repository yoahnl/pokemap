import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../presentation/story_memory_harness.dart';
import 'storyline_fakes.dart';
import 'storyline_widget_support.dart';

void main() {
  testWidgets('the milestone selection accent follows the selected row', (
    tester,
  ) async {
    await openTrameStudio(tester);
    tester.view.physicalSize = const Size(1280, 720);
    await settleMemory(tester);
    final row = find.byKey(const ValueKey('trame-milestone-meet'));
    final outline = find.byKey(const ValueKey('trame-outline'));
    final chapter = find.byKey(const ValueKey('trame-chapter-chapter_one'));
    expect(tester.getRect(row).left - tester.getRect(outline).left, 22);
    expect(tester.getSize(chapter).width, 260);
    final accent = find.descendant(
      of: row,
      matching: find.byKey(const ValueKey('studio-choice-selection-accent')),
    );
    expect(accent, findsNothing);

    await tester.tap(row);
    await settleMemory(tester);
    expect(accent, findsOneWidget);
    expect(tester.getRect(accent).left, tester.getRect(row).left);
    expect(find.byKey(const ValueKey('trame-milestone-name-meet')), findsOne);
  });

  testWidgets('the milestone warning stays readable at 1280 pixels', (
    tester,
  ) async {
    await openTrameStudio(tester);
    tester.view.physicalSize = const Size(1280, 720);
    await settleMemory(tester);

    const label = 'À vérifier dans la trame';
    final warning = find.descendant(
      of: find.byKey(const ValueKey('trame-milestone-leave')),
      matching: find.text(label),
    );
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: warning, matching: find.byType(RichText)),
    );
    expect(
      paragraph.getBoxesForSelection(
        TextSelection(
          baseOffset: label.length - 'trame'.length,
          extentOffset: label.length,
        ),
      ),
      isNotEmpty,
    );
  });

  for (final milestone in [false, true]) {
    testWidgets(
      'hiding an archived ${milestone ? 'milestone' : 'chapter'} returns its inspector to the visible parent',
      (tester) async {
        await openTrameStudio(tester);
        await tester.tap(
          find.byKey(
            ValueKey(
              milestone ? 'trame-milestone-meet' : 'trame-chapter-chapter_two',
            ),
          ),
        );
        await settleMemory(tester);
        await tester.tap(
          find.byKey(
            ValueKey(
              milestone ? 'trame-milestone-archived' : 'trame-chapter-archived',
            ),
          ),
        );
        await settleMemory(tester);
        final detail = find.byKey(
          ValueKey(
            milestone
                ? 'trame-milestone-detail-meet'
                : 'trame-chapter-detail-chapter_two',
          ),
        );
        expect(detail, findsNothing);
        expect(
          find.byKey(
            ValueKey(
              milestone
                  ? 'trame-chapter-detail-chapter_one'
                  : 'trame-storyline-detail-main',
            ),
          ),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('trame-show-archived')));
        await settleMemory(tester);
        await tester.tap(
          find.byKey(
            ValueKey(
              milestone ? 'trame-milestone-meet' : 'trame-chapter-chapter_two',
            ),
          ),
        );
        await settleMemory(tester);
        expect(detail, findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('trame-show-archived')));
        await settleMemory(tester);
        expect(detail, findsNothing);
      },
    );
  }

  testWidgets(
    'moving a milestone follows its chapter and undo restores the selection',
    (tester) async {
      await openTrameStudio(tester);
      await tester.tap(find.byKey(const ValueKey('trame-milestone-meet')));
      await settleMemory(tester);
      await tester.tap(find.byKey(const ValueKey('trame-milestone-chapter')));
      await settleMemory(tester);
      await tester.tap(find.text('Voyage').last);
      await settleMemory(tester);
      expect(
        tester
            .widget<StudioChoice>(
              find.byKey(const ValueKey('trame-chapter-chapter_two')),
            )
            .selected,
        isTrue,
      );
      expect(
        find.byKey(const ValueKey('trame-milestone-meet')),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithIcon(IconButton, Icons.undo).first);
      await settleMemory(tester);
      expect(
        tester
            .widget<StudioChoice>(
              find.byKey(const ValueKey('trame-chapter-chapter_one')),
            )
            .selected,
        isTrue,
      );
      expect(
        find.byKey(const ValueKey('trame-milestone-meet')),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'chapters show only their milestones and retain a selected story',
    (tester) async {
      final reads = trameReads();
      final story = reads.stories.single;
      reads.stories = [
        story.copyWith(
          chapters: [
            story.chapters.first,
            story.chapters.last.copyWith(
              steps: [milestoneStep('return', 'Rentrer', 0)],
            ),
          ],
        ),
        story.copyWith(
          id: 'side',
          type: StorylineType.sideQuest,
          title: 'Une lettre',
          chapters: [],
        ),
      ];
      await openTrameStudio(tester, reads: reads);
      expect(find.byKey(const ValueKey('trame-chapters')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('trame-milestone-meet')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('trame-milestone-return')),
        findsNothing,
      );
      expect(reads.storylineReads, 0);
      expect(
        find.byKey(const ValueKey('trame-other-story-side')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('trame-chapter-chapter_two')));
      await settleMemory(tester);
      expect(
        find.byKey(const ValueKey('trame-milestone-return')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('trame-milestone-meet')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('trame-story-picker')));
      await settleMemory(tester);
      await tester.tap(find.text('Une lettre').last);
      await settleMemory(tester);
      expect(
        find.byKey(const ValueKey('trame-chapter-chapter_one')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('trame-storyline-side')),
        findsOneWidget,
      );
      expect(reads.stories.map((s) => s.type), [
        StorylineType.main,
        StorylineType.sideQuest,
      ]);
    },
  );

  testWidgets(
    'an empty project asks for the story type and first chapter before creation',
    (tester) async {
      final reads = await openTrameStudio(tester, empty: true);
      await tester.tap(find.byKey(const ValueKey('trame-start-empty')));
      await settleMemory(tester);
      expect(find.byKey(const ValueKey('trame-create-story')), findsOneWidget);
      expect(find.byKey(const ValueKey('trame-outline')), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('trame-create-title')),
        'La lettre',
      );
      await tester.enterText(
        find.byKey(const ValueKey('trame-create-chapter')),
        'Une livraison',
      );
      await tester.tap(find.byKey(const ValueKey('trame-create-type')));
      await settleMemory(tester);
      await tester.tap(find.text('Quête annexe').last);
      await settleMemory(tester);
      await tester.tap(find.byKey(const ValueKey('confirm-reviewed-plan')));
      await settleMemory(tester);
      expect(find.text('La lettre'), findsWidgets);
      expect(find.text('Une livraison'), findsWidgets);
      expect(find.text('Quête annexe'), findsWidgets);
      expect(reads.stories, isEmpty);
    },
  );

  testWidgets('archived chapters remain available through the archive filter', (
    tester,
  ) async {
    final reads = trameReads();
    final story = reads.stories.single;
    reads.stories = [
      story.copyWith(
        chapters: [
          story.chapters.first,
          story.chapters.last.copyWith(status: StorylineStatus.archived),
        ],
      ),
    ];
    await openTrameStudio(tester, reads: reads);
    expect(
      find.byKey(const ValueKey('trame-chapter-chapter_two')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('trame-show-archived')));
    await settleMemory(tester);
    expect(
      find.byKey(const ValueKey('trame-chapter-chapter_two')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<StudioChoice>(
            find.byKey(const ValueKey('trame-chapter-chapter_two')),
          )
          .trailing,
      isNotNull,
    );
    expect(reads.stories.single.chapters.last.status, StorylineStatus.archived);
  });
}
