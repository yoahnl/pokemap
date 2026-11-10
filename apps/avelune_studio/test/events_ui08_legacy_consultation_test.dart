import 'support/event_legacy_fixture.dart';

import 'dart:convert';

import 'package:avelune_studio/presentation/features/events/event_library.dart';
import 'package:avelune_studio/presentation/features/events/event_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'historical library opens read-only detail without modern selection',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final view = EventViewState();
      addTearDown(view.dispose);
      final before = jsonEncode([
        historicalProject.toJson(),
        historicalMap.toJson(),
      ]);
      var opened = 0;
      var created = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: SizedBox(
              width: 370,
              height: 720,
              child: EventLibrary(
                project: historicalProject,
                records: [],
                activeId: null,
                dirtyIds: {},
                view: view,
                maps: [historicalMap],
                mapsComplete: true,
                onChanged: () {},
                onOpen: (_) => opened++,
                onCreate: () => created++,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Historique · 2'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('event-legacy:map:old_station:old_greeting')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bienvenue dans la gare historique.'), findsOneWidget);
      expect(
        find.textContaining('Aucune conversion ni activation automatique'),
        findsOneWidget,
      );
      expect(find.text('Enregistrer'), findsNothing);
      await tester.tap(find.text('Fermer la consultation'));
      await tester.pumpAndSettle();
      expect(opened, 0);
      expect(created, 0);
      expect(
        jsonEncode([historicalProject.toJson(), historicalMap.toJson()]),
        before,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'partial historical inventory is explicit and search includes scenario',
    (tester) async {
      final view = EventViewState();
      addTearDown(view.dispose);
      view.search.text = 'Arrivée ancienne';
      var loads = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 560,
              child: EventLibrary(
                project: historicalProject,
                records: [],
                activeId: null,
                dirtyIds: {},
                view: view,
                maps: [],
                mapsComplete: false,
                onLoadHistory: () => loads++,
                onChanged: () {},
                onOpen: (_) {},
                onCreate: () {},
              ),
            ),
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('event-legacy:scenario:old_arrival:entry')),
        findsOneWidget,
      );
      expect(
        find.textContaining('Historique des cartes chargées'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('event-legacy:map:old_station:old_greeting')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      expect(loads, 0);
      await tester.tap(find.text('Charger l’historique des autres cartes'));
      await tester.pump();
      expect(loads, 1);
    },
  );
}
