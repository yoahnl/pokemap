import 'package:avelune_studio/presentation/features/events/event_options_panel.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  final outcome = NarrativeOutcomeRef(
    producerKind: NarrativeOutcomeProducerKind.scene,
    producerId: 'bg-labo',
    outcomeId: 'oeuf-recu',
  );

  NarrativeEventRecord record({
    NarrativeEventReusePolicy reuse = NarrativeEventReusePolicy.oneShot,
    NarrativeEventResetPolicy reset = const NarrativeEventResetPolicy.never(),
  }) => NarrativeEventRecord.draft(
    NarrativeEventDraft(
      id: 'evt_00000000-0000-7000-8000-000000000001',
      name: 'Arrivée',
      source: NarrativeEventSourceRef.mapEnter('map'),
      conditions: const [],
      reusePolicy: reuse,
      resetPolicy: reset,
      priority: 100,
      order: 0,
    ),
  );

  Future<List<String>> pump(
    WidgetTester tester,
    NarrativeEventRecord value, {
    EventSystemMode? mode = EventSystemMode.v2Only,
    String? priorityInput,
  }) async {
    final calls = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: KeyedSubtree(
            key: const PageStorageKey('event-page-test'),
            child: EventOptionsPanel(
              record: value,
              mode: mode,
              outcomes: NarrativeOutcomeEventSourceCatalog(
                options: const [],
                diagnostics: const [],
              ),
              priorityInput: priorityInput,
              onReuse: (_) => calls.add('reuse'),
              onReset: (_) => calls.add('reset'),
              onPriority: (_) => calls.add('priority'),
              onOrder: (_) => calls.add('order'),
              onConfigure: () => calls.add('configure'),
              onEnabled: () => calls.add('enabled'),
              onMode: () => calls.add('mode'),
              onParallel: (_) => calls.add('parallel'),
            ),
          ),
        ),
      ),
    );
    return calls;
  }

  testWidgets('the in-game effect is stated before the controls', (
    tester,
  ) async {
    await pump(tester, record());
    expect(find.text('Effet en jeu'), findsOneWidget);
    expect(find.text('Une seule fois dans la partie.'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Effet en jeu')).dy,
      lessThan(tester.getTopLeft(find.text('Après avoir joué')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Après avoir joué')).dy,
      lessThan(tester.getTopLeft(find.text('Exécution')).dy),
    );
  });

  testWidgets('each verified replay rule has its own sentence', (tester) async {
    await pump(
      tester,
      record(reset: const NarrativeEventResetPolicy.onMapReentry()),
    );
    expect(
      find.text(
        'Une fois par visite : se rejoue après avoir quitté puis retrouvé sa carte.',
      ),
      findsOneWidget,
    );
    await pump(
      tester,
      record(reset: NarrativeEventResetPolicy.onOutcomeReceived(outcome)),
    );
    expect(
      find.text('Une fois, puis à nouveau après le résultat « oeuf-recu ».'),
      findsOneWidget,
    );
    await pump(tester, record(reuse: NarrativeEventReusePolicy.reusable));
    expect(
      find.text(
        'À chaque déclenchement, tant que ses conditions sont remplies.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Sans effet : l’événement peut déjà se rejouer.'),
      findsOneWidget,
    );
  });

  testWidgets('priority, order and project mode are advanced and inert', (
    tester,
  ) async {
    final calls = await pump(tester, record());
    expect(find.text('Options avancées'), findsOneWidget);
    expect(find.text('Priorité'), findsNothing);
    expect(find.text('Ordre de distribution'), findsNothing);
    expect(find.text('Examiner le mode du projet'), findsNothing);
    final advanced = find.text('Options avancées');
    await tester.ensureVisible(advanced);
    await tester.tap(advanced);
    await tester.pumpAndSettle();
    expect(find.text('Priorité'), findsOneWidget);
    expect(find.text('Ordre de distribution'), findsOneWidget);
    expect(
      find.text('Mode des événements du projet : moderne'),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Propres à cet événement, enregistrés avec Enregistrer',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('concerne tout le projet'), findsOneWidget);
    expect(find.text('Examiner le mode du projet'), findsOneWidget);
    expect(calls, isEmpty);
  });

  testWidgets('a historical mode warning stays visible without expanding', (
    tester,
  ) async {
    final calls = await pump(
      tester,
      record(),
      mode: EventSystemMode.legacyOnly,
    );
    expect(
      find.textContaining('Le mode historique peut empêcher la distribution'),
      findsOneWidget,
    );
    expect(find.text('Priorité'), findsNothing);
    expect(calls, isEmpty);
  });

  testWidgets('an invalid priority keeps the advanced options open', (
    tester,
  ) async {
    await pump(tester, record(), priorityInput: 'pas un nombre');
    expect(find.text('Priorité'), findsOneWidget);
    expect(find.text('pas un nombre'), findsOneWidget);
  });
}
