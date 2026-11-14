import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../game_behaviours/game_behaviour_fakes.dart';
import '../presentation/story_memory_harness.dart';
import '../storyline/storyline_widget_support.dart';

final _project = trameProject.copyWith(
  eventRegistry: NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: [
      behaviour(
        1,
        'Après la rencontre',
        source: NarrativeEventSourceRef.entityInteract('a', 'guide'),
        enabled: true,
        sceneId: 'talk',
        conditions: [NarrativeEventCondition.fact('met', true)],
      ),
      behaviour(
        2,
        'Accueil',
        source: NarrativeEventSourceRef.entityInteract('a', 'guide'),
        enabled: true,
        sceneId: 'gate',
      ),
    ],
    legacyClaims: const [],
  ),
);

String _result(WidgetTester tester) => tester
    .widget<StudioNotice>(
      find.byKey(const ValueKey('map-story-simulation-result')),
    )
    .message;

Text _status(WidgetTester tester) => tester.widget<Text>(
  find.descendant(
    of: find.byKey(const ValueKey('studio-save-status')),
    matching: find.byType(Text),
  ),
);

void main() {
  testWidgets('the simulation explains which case plays, writing nothing', (
    tester,
  ) async {
    await openTrameStudio(tester, project: _project);
    await tester.tap(find.byKey(const ValueKey('studio-rail-map')));
    await settleMemory(tester);
    await tester.tap(find.byKey(const ValueKey('map-space-story')));
    await settleMemory(tester);
    await tester.tap(find.text('Guide').first);
    await settleMemory(tester);
    final simulate = find.byKey(const ValueKey('map-story-simulate'));
    await tester.ensureVisible(simulate);
    await tester.tap(simulate);
    await settleMemory(tester);

    expect(_result(tester), 'C’est « Accueil » qui se déclenche.');
    expect(
      tester
          .widget<StudioChoice>(
            find.byKey(ValueKey('map-story-simulation-case-${behaviourId(1)}')),
          )
          .subtitle,
      'une condition sur un état est fausse',
    );

    final fact = find.byKey(const ValueKey('map-story-simulation-fact-met'));
    await tester.ensureVisible(fact);
    await tester.tap(find.descendant(of: fact, matching: find.byType(Switch)));
    await settleMemory(tester);

    expect(_result(tester), 'C’est « Après la rencontre » qui se déclenche.');
    expect(
      tester
          .widget<StudioChoice>(
            find.byKey(ValueKey('map-story-simulation-case-${behaviourId(2)}')),
          )
          .subtitle,
      'Écarté par un cas prioritaire · priorité 0, ordre 2',
    );
    expect(_status(tester).data, 'Enregistré');
  });

  testWidgets('Tout le jeu opens a behaviour straight into its simulation', (
    tester,
  ) async {
    await openTrameStudio(tester, project: _project);
    await tester.tap(find.byKey(const ValueKey('story-tab-world')));
    await settleMemory(tester);

    await tester.tap(
      find.byKey(ValueKey('behaviour-simulate-${behaviourId(2)}')),
    );
    await settleMemory(tester);

    expect(find.byKey(const ValueKey('studio-story')), findsNothing);
    expect(
      find.byKey(ValueKey('map-story-simulation-${behaviourId(2)}')),
      findsOneWidget,
    );
  });
}
