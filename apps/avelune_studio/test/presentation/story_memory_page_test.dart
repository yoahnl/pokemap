import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'story_memory_harness.dart';

Finder _rows({bool skipOffstage = true}) => find.byWidgetPredicate(
  (widget) =>
      widget is StudioChoice && '${widget.key}'.startsWith("[<'memory-fact-"),
  skipOffstage: skipOffstage,
);

void main() {
  testWidgets('the rail opens Histoire with only the tab that exists', (
    tester,
  ) async {
    final index = memoryIndex();
    await openMemoryStudio(tester, index);
    expect(index.titleRequests, isEmpty);

    await openHistoire(tester);

    expect(find.byKey(const ValueKey('studio-story')), findsOneWidget);
    expect(find.text('Mémoire du jeu'), findsOneWidget);
    expect(find.text('Trame'), findsNothing);
    expect(find.text('Tout le jeu'), findsNothing);
    expect(find.byKey(const ValueKey('map-space-construction')), findsNothing);
    expect(find.text('Rencontre'), findsOneWidget);
    expect(find.text('Nombre · au départ : 3'), findsOneWidget);
    expect(find.text('Oui / non · au départ : faux'), findsOneWidget);
    expect(index.factRequests.expand((ids) => ids).toSet(), {'met', 'coins'});

    await tester.tap(find.byKey(const ValueKey('studio-rail-map')));
    await settleMemory(tester);
    expect(find.byKey(const ValueKey('studio-story')), findsNothing);
    expect(
      find.byKey(const ValueKey('map-space-construction')),
      findsOneWidget,
    );
  });

  testWidgets('only visible fact rows are built and read', (tester) async {
    final index = memoryIndex(unrelated: 300);
    await openMemoryStudio(tester, index);
    await openHistoire(tester);

    final visible = tester.widgetList(_rows()).length;
    final built = tester.widgetList(_rows(skipOffstage: false)).length;
    final read = index.factRequests.expand((ids) => ids).toSet();
    expect(visible, inInclusiveRange(5, 30));
    expect(built, lessThan(visible + 15));
    expect(read.length, inInclusiveRange(built, built + 5));
    expect(read, {
      for (final id in [
        'met',
        'coins',
        for (var i = 0; i < 30; i++) 'unused_$i',
      ])
        if (read.contains(id)) id,
    });

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('memory-fact-search')),
        matching: find.byType(TextField),
      ),
      'inutile 200',
    );
    await settleMemory(tester);
    expect(find.text('Inutile 200'), findsOneWidget);
    expect(tester.widgetList(_rows()), hasLength(1));
    expect(index.factRequests.last, ['unused_200']);
  });

  testWidgets('a fact names who changes and reads it and opens them', (
    tester,
  ) async {
    final index = memoryIndex();
    await openMemoryStudio(tester, index);
    await openHistoire(tester);

    await tester.tap(find.text('Rencontre'));
    await settleMemory(tester);

    expect(find.text('Modifié par'), findsOneWidget);
    expect(find.text('Ouverture de la porte'), findsOneWidget);
    expect(find.text('Lu par'), findsOneWidget);
    expect(find.text('Porte du bourg'), findsOneWidget);
    expect(find.text('Parler au guide'), findsOneWidget);
    expect(find.text('Trame sans nom'), findsOneWidget);
    expect(find.textContaining('main'), findsNothing);
    expect(
      find.textContaining(
        'Non couvert par l’index : les cartes (événements, personnages et '
        'décors posés dessus), les dialogues.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('memory-open-scene-gate')), findsNothing);
    expect(
      find.byKey(const ValueKey('memory-open-storyline-main')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('memory-open-worldRule-world_rule_door')),
    );
    await settleMemory(tester);
    expect(
      find.byKey(const ValueKey('memory-rule-editor-world_rule_door')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('memory-rule-sentence')))
          .data,
      'Tant que « Rencontre » est vrai, alors « Guide » (Clairière) '
      'disparaît.',
    );

    await tester.tap(find.text('États'));
    await settleMemory(tester);
    await tester.tap(find.byKey(ValueKey('memory-open-event-$guideTalk')));
    await settleMemory(tester);
    expect(find.byKey(const ValueKey('studio-story')), findsNothing);
    expect(
      find.byKey(const ValueKey('map-story-inspector-entity:guide')),
      findsOneWidget,
    );
  });

  testWidgets('creating and renaming a fact leaves the project unsaved', (
    tester,
  ) async {
    final index = memoryIndex();
    await openMemoryStudio(tester, index);
    await openHistoire(tester);
    Text status() => tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('studio-save-status')),
        matching: find.byType(Text),
      ),
    );
    expect(status().data, 'Enregistré');

    await tester.tap(find.byKey(const ValueKey('memory-new-fact')));
    await settleMemory(tester);
    await tester.enterText(
      find.byKey(const ValueKey('memory-new-fact-name')),
      'Clé trouvée',
    );
    await tester.tap(find.text('Nombre').last);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('memory-new-fact-create')));
    await settleMemory(tester);

    expect(status().data, 'Non enregistré');
    expect(
      tester
          .widget<StudioChoice>(
            find.ancestor(
              of: find.text('Clé trouvée').first,
              matching: find.byType(StudioChoice),
            ),
          )
          .trailing,
      isA<StudioBadge>(),
    );
    expect(find.text('Nombre · au départ : 0'), findsOneWidget);
    expect(find.byKey(const ValueKey('memory-fact-discard')), findsOneWidget);

    await tester.tap(find.text('Pièces'));
    await settleMemory(tester);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('memory-fact-name-coins')),
        matching: find.byType(TextField),
      ),
      'Or',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settleMemory(tester);
    expect(
      tester
          .widget<StudioChoice>(find.byKey(const ValueKey('memory-fact-coins')))
          .label,
      'Or',
    );

    await tester.tap(find.byKey(const ValueKey('memory-fact-delete')));
    await settleMemory(tester);
    expect(
      find.byKey(const ValueKey('memory-fact-delete-refused')),
      findsOneWidget,
    );
    expect(find.text('Rien ne le modifie d’après l’index.'), findsOneWidget);
  });
}
