import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'support/event_builder_v2_product_route_fixture.dart';

void main() {
  group('NSC-40 Event lifecycle authoring', () {
    testWidgets('explains draft, published and runtime-enabled separately',
        (tester) async {
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.dualRead,
      );
      await pumpEventBuilderV2ProductRoute(tester, fixture: fixture);

      await _selectAndOpenLifecycle(tester, productRoutePortEventId);
      expect(find.text('Publié · actif'), findsOneWidget);
      expect(find.text('Publié et joué par le runtime.'), findsOneWidget);
      expect(find.text('Renommer'), findsOneWidget);
      expect(find.text('Dupliquer'), findsOneWidget);
      expect(find.text('Désactiver'), findsOneWidget);
      expect(find.text('Dépublier'), findsOneWidget);
      expect(find.text('Supprimer'), findsOneWidget);
      expect(find.text('Archive'), findsNothing);
      await tester.tap(find.byTooltip('Fermer'));
      await tester.pumpAndSettle();

      await _selectAndOpenLifecycle(tester, productRouteForestEventId);
      expect(find.text('Publié · inactif'), findsOneWidget);
      expect(
        find.text(
            'Publié, mais ignoré par le runtime tant qu’il reste inactif.'),
        findsOneWidget,
      );
      expect(find.text('Activer'), findsOneWidget);
      await tester.tap(find.byTooltip('Fermer'));
      await tester.pumpAndSettle();

      await _selectAndOpenLifecycle(tester, productRouteDraftEventId);
      final lifecycleSheet = find.byKey(
        const ValueKey('event-builder-v2-lifecycle-actions'),
      );
      expect(
        find.descendant(
          of: lifecycleSheet,
          matching: find.text('Brouillon'),
        ),
        findsOneWidget,
      );
      expect(find.text('Non publié et jamais joué par le runtime.'),
          findsOneWidget);
      expect(find.text('Publier'), findsOneWidget);
      expect(find.text('Activer'), findsNothing);
      expect(find.text('Dépublier'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _selectAndOpenLifecycle(
  WidgetTester tester,
  String eventId,
) async {
  await tester.tap(
    find.byKey(ValueKey('event-builder-v2-event-v2:$eventId')),
  );
  await tester.pump();
  await tester.tap(
    find.byKey(ValueKey('event-builder-v2-lifecycle-v2:$eventId')),
  );
  await tester.pumpAndSettle();
}
