import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/storyline/application/storyline_journal_edits.dart';
import 'package:avelune_studio/presentation/features/story/story_page.dart';

import '../presentation/story_memory_harness.dart';
import 'storyline_widget_support.dart';

void main() {
  testWidgets(
    'milestone conditions name their facts and edit a simple entry condition',
    (tester) async {
      await openTrameStudio(tester);
      await tester.tap(find.byKey(const ValueKey('trame-milestone-meet')));
      await settleMemory(tester);
      final entry = find.byKey(const ValueKey('trame-condition-entry'));
      await tester.ensureVisible(entry);
      await settleMemory(tester);
      expect(entry, findsOneWidget);
      expect(
        find.byKey(const ValueKey('trame-condition-completion')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('trame-condition-entry-edit')),
      );
      await settleMemory(tester);
      await tester.tap(
        find.byKey(const ValueKey('trame-condition-entry-fact')),
      );
      await settleMemory(tester);
      await tester.tap(find.text('Rencontrer Léo').last);
      await settleMemory(tester);
      expect(
        find.byKey(const ValueKey('trame-condition-entry-remove')),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('trame-condition-entry-remove')),
      );
      await tester.tap(
        find.byKey(const ValueKey('trame-condition-entry-remove')),
      );
      await settleMemory(tester);
      expect(
        find.byKey(const ValueKey('trame-condition-entry-remove')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'a composed condition is displayed faithfully and survives a rename',
    (tester) async {
      final reads = trameReads();
      final story = reads.stories.single;
      final chapter = story.chapters.first;
      final expression = ScriptConditionFactory.allOf([
        ScriptConditionFactory.factEquals(
          'met',
          const NarrativeValue.boolean(true),
        ),
        ScriptConditionFactory.anyOf([
          ScriptConditionFactory.moneyAtLeast(500),
          ScriptConditionFactory.moneyAtLeast(900),
        ]),
      ]);
      reads.stories = [
        story.copyWith(
          chapters: [
            chapter.copyWith(
              steps: [
                chapter.steps.first.copyWith(entryCondition: expression),
                chapter.steps.last,
              ],
            ),
            story.chapters.last,
          ],
        ),
      ];
      await openTrameStudio(tester, reads: reads);
      await tester.tap(find.byKey(const ValueKey('trame-milestone-meet')));
      await settleMemory(tester);
      await tester.ensureVisible(
        find.byKey(const ValueKey('trame-condition-entry')),
      );
      await settleMemory(tester);
      expect(find.text('Toutes ces conditions'), findsOneWidget);
      expect(find.text('Au moins une de ces conditions'), findsOneWidget);
      expect(find.textContaining('500'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('trame-condition-entry-fact')),
        findsNothing,
      );
      final name = find.descendant(
        of: find.byKey(const ValueKey('trame-milestone-name-meet')),
        matching: find.byType(TextField),
      );
      await tester.scrollUntilVisible(
        name,
        -200,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('story-inspector')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.enterText(name, 'Retrouver Léo');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settleMemory(tester);
      await tester.ensureVisible(
        find.byKey(const ValueKey('trame-condition-entry')),
      );
      await settleMemory(tester);
      expect(find.textContaining('500'), findsOneWidget);
      expect(
        tester
            .widget<StoryPage>(find.byType(StoryPage))
            .trame!
            .fullMilestone('main', 'chapter_one', 'meet')!
            .entryCondition,
        expression,
      );
    },
  );
}
