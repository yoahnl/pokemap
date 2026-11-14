import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../game_behaviours/game_behaviour_fakes.dart';
import '../presentation/story_memory_harness.dart';
import 'storyline_widget_support.dart';

String _subtitle(WidgetTester tester, String key) =>
    tester.widget<StudioChoice>(find.byKey(ValueKey(key))).subtitle!;

Text _status(WidgetTester tester) => tester.widget<Text>(
  find.descendant(
    of: find.byKey(const ValueKey('studio-save-status')),
    matching: find.byType(Text),
  ),
);

void main() {
  testWidgets('the Trame opens first from the outline alone', (tester) async {
    final reads = await openTrameStudio(tester);

    expect(find.byKey(const ValueKey('trame-outline')), findsOneWidget);
    expect((reads.outlines, reads.storylineReads), (1, 0));
    expect(_subtitle(tester, 'trame-milestone-meet'), '1 comportement');
    expect(
      _subtitle(tester, 'trame-milestone-leave'),
      'Aucun comportement · 2 points à vérifier',
    );
    expect(_subtitle(tester, 'trame-outside-outside'), '1 comportement');

    await tester.tap(find.text('Rencontrer Léo'));
    await settleMemory(tester);
    expect(find.text('Cartes : Clairière'), findsOneWidget);
    expect(
      find.text('Se termine quand « Rencontrer Léo » devient vrai'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('trame-milestone-leave')));
    await settleMemory(tester);
    expect(
      find.byKey(const ValueKey('trame-issue-noBehaviour')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('trame-issue-noCompletionFact')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('trame-milestone-meet')));
    await settleMemory(tester);
    await tester.tap(find.text('Parler au guide'));
    await settleMemory(tester);
    expect(find.byKey(const ValueKey('studio-story')), findsNothing);
    expect(
      find.byKey(const ValueKey('map-story-inspector-entity:guide')),
      findsOneWidget,
    );
  });

  testWidgets('a behaviour outside the plot attaches by whole scene', (
    tester,
  ) async {
    final reads = await openTrameStudio(tester);
    expect(_status(tester).data, 'Enregistré');

    await tester.tap(find.byKey(const ValueKey('trame-outside-outside')));
    await settleMemory(tester);
    expect(find.text('Ouvrir la grille'), findsOneWidget);
    await tester.tap(
      find.byKey(ValueKey('trame-outside-attach-${behaviourId(2)}')),
    );
    await settleMemory(tester);
    await tester.tap(find.text('Départ · Partir').last);
    await settleMemory(tester);

    expect(reads.storylineReads, 1);
    expect(_status(tester).data, 'Non enregistré');
    expect(find.byKey(const ValueKey('trame-outside-empty')), findsOneWidget);
    expect(
      _subtitle(tester, 'trame-milestone-leave'),
      contains('1 comportement'),
    );
  });

  testWidgets('chapters are created and renamed into the draft', (
    tester,
  ) async {
    await openTrameStudio(tester);

    await tester.tap(find.byKey(const ValueKey('trame-storyline-main')));
    await settleMemory(tester);
    await tester.tap(find.byKey(const ValueKey('trame-chapter-add')));
    await settleMemory(tester);
    expect(find.text('Nouveau chapitre'), findsOneWidget);

    await tester.tap(find.text('Nouveau chapitre'));
    await settleMemory(tester);
    await tester.enterText(
      find.descendant(
        of: find.byKey(
          const ValueKey('trame-chapter-name-chapter_nouveau_chapitre'),
        ),
        matching: find.byType(TextField),
      ),
      'Retour',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settleMemory(tester);
    expect(find.text('Retour'), findsWidgets);
    expect(_status(tester).data, 'Non enregistré');
  });

  testWidgets('a proposed plot is kept as a draft or discarded', (
    tester,
  ) async {
    final reads = await openTrameStudio(tester, empty: true);

    expect(find.byKey(const ValueKey('trame-empty')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('trame-propose')));
    await settleMemory(tester);
    expect(find.byKey(const ValueKey('trame-proposed-meet')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('trame-proposal-discard')));
    await settleMemory(tester);
    expect(find.byKey(const ValueKey('trame-empty')), findsOneWidget);
    expect(_status(tester).data, 'Enregistré');

    await tester.tap(find.byKey(const ValueKey('trame-propose')));
    await settleMemory(tester);
    await tester.enterText(
      find.byKey(const ValueKey('trame-proposal-title')),
      'Ma trame',
    );
    await tester.tap(find.byKey(const ValueKey('trame-proposal-keep')));
    await settleMemory(tester);

    expect(reads.proposals, 2);
    expect(find.text('Ma trame'), findsOneWidget);
    expect(_status(tester).data, 'Non enregistré');
  });
}
