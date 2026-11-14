import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../presentation/story_memory_harness.dart';
import 'storyline_widget_support.dart';

Finder _field(String key) => find.descendant(
  of: find.byKey(ValueKey(key)),
  matching: find.byType(TextField),
);

StudioButton _button(WidgetTester tester, String key) =>
    tester.widget<StudioButton>(find.byKey(ValueKey(key)));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await settleMemory(tester);
  await tester.tap(finder);
  await settleMemory(tester);
}

String _status(WidgetTester tester) => tester
    .widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('studio-save-status')),
        matching: find.byType(Text),
      ),
    )
    .data!;

void main() {
  testWidgets('a milestone journal is written into the draft', (tester) async {
    final reads = await openTrameStudio(tester);
    expect(reads.storylineReads, 0);

    await _tap(tester, find.byKey(const ValueKey('trame-milestone-meet')));
    expect(reads.storylineReads, 1);
    expect(_button(tester, 'trame-journal-apply').label, 'Ajouter au journal');
    expect(_button(tester, 'trame-journal-apply').onPressed, isNull);
    expect(find.byKey(const ValueKey('trame-journal-remove')), findsNothing);

    await tester.ensureVisible(_field('trame-journal-text'));
    await tester.enterText(_field('trame-journal-text'), 'Léo attend au nord.');
    await settleMemory(tester);
    await _tap(tester, find.byKey(const ValueKey('trame-journal-apply')));

    expect(_status(tester), 'Non enregistré');
    expect(
      _button(tester, 'trame-journal-apply').label,
      'Mettre à jour le journal',
    );
    expect(_button(tester, 'trame-journal-apply').onPressed, isNull);
    expect(find.byKey(const ValueKey('trame-journal-remove')), findsOneWidget);
  });

  testWidgets('a clue note is added to the storyline draft', (tester) async {
    await openTrameStudio(tester);

    await _tap(tester, find.byKey(const ValueKey('trame-storyline-main')));
    expect(_button(tester, 'trame-clue-add').onPressed, isNull);
    await tester.ensureVisible(_field('trame-clue-new-text-0'));
    await tester.enterText(_field('trame-clue-new-text-0'), 'Code secret');
    await settleMemory(tester);
    await _tap(tester, find.byKey(const ValueKey('trame-clue-new-fact-0')));
    await tester.tap(find.text('Rencontrer Léo').last);
    await settleMemory(tester);
    await _tap(tester, find.byKey(const ValueKey('trame-clue-add')));

    expect(
      find.byKey(const ValueKey('trame-clue-clue_code_secret')),
      findsOneWidget,
    );
    expect(_status(tester), 'Non enregistré');
    expect(_button(tester, 'trame-clue-add').onPressed, isNull);
  });
}
