import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../game_behaviours/game_behaviour_fakes.dart';
import '../presentation/story_memory_harness.dart';
import 'storyline_widget_support.dart';

Future<void> _openGuideBehaviour(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('studio-rail-map')));
  await settleMemory(tester);
  await tester.tap(find.byKey(const ValueKey('map-space-story')));
  await settleMemory(tester);
  await tester.tap(find.text('Guide').first);
  await settleMemory(tester);
}

void main() {
  testWidgets('the behaviour inspector shows and changes its milestone', (
    tester,
  ) async {
    final reads = await openTrameStudio(tester);
    await _openGuideBehaviour(tester);

    final field = find.byKey(const ValueKey('map-story-milestone'));
    await tester.ensureVisible(field);
    expect(
      find.descendant(
        of: field,
        matching: find.text('Départ · Rencontrer Léo'),
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(
        of: field,
        matching: find.text('Départ · Rencontrer Léo'),
      ),
    );
    await settleMemory(tester);
    await tester.tap(find.text('Départ · Partir').last);
    await settleMemory(tester);

    expect(reads.storylineReads, 1);
    expect(
      find.descendant(of: field, matching: find.text('Départ · Partir')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('studio-save-status')),
        matching: find.text('Non enregistré'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('"Après le jalon" writes the completion fact condition', (
    tester,
  ) async {
    await openTrameStudio(tester);
    await _openGuideBehaviour(tester);

    final after = find.byKey(const ValueKey('map-story-condition-after'));
    await tester.ensureVisible(after);
    await tester.tap(after);
    await settleMemory(tester);
    await tester.tap(find.byKey(const ValueKey('map-story-after-meet')));
    await settleMemory(tester);

    expect(find.text('Après le jalon « Rencontrer Léo »'), findsOneWidget);
    expect(find.byKey(const ValueKey('map-story-condition-0')), findsOneWidget);
  });

  testWidgets('Tout le jeu filters the behaviours outside the plot', (
    tester,
  ) async {
    await openTrameStudio(tester);
    await tester.tap(find.byKey(const ValueKey('story-tab-world')));
    await settleMemory(tester);

    await tester.tap(
      find.byKey(const ValueKey('behaviours-filter-outsideTrame')),
    );
    await settleMemory(tester);

    expect(
      tester
          .widgetList(find.byType(StudioChoice))
          .where((choice) => '${choice.key}'.contains('behaviour-evt')),
      hasLength(1),
    );
    expect(find.byKey(ValueKey('behaviour-${behaviourId(2)}')), findsOneWidget);
  });
}
