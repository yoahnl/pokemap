import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_map_bridge_models.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_builder_v2_providers.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_map_bridge_state.dart';

import '../../support/event_builder_v2_product_route_fixture.dart';

void main() {
  group('NS-EVENT-V2 H2 product project list', () {
    testWidgets(
      'shows every project group independently from the active map',
      (tester) async {
        final fixture = await createEventBuilderV2ProductRouteFixture(
          tester,
          mode: EventSystemMode.dualRead,
        );
        final container = await pumpEventBuilderV2ProductRoute(
          tester,
          fixture: fixture,
          activeMap: fixture.forestMap,
        );

        expect(fixture.readModel.events, hasLength(6));
        for (final event in fixture.readModel.events) {
          expect(
            find.byKey(
              ValueKey('event-builder-v2-event-${event.stableKey}'),
            ),
            findsOneWidget,
          );
        }
        expect(find.text('Port Selbrume'), findsWidgets);
        expect(find.text('Forêt Brumeuse'), findsWidgets);
        expect(find.text('Événements globaux'), findsOneWidget);
        expect(find.text('Brouillons à terminer'), findsOneWidget);
        expect(find.text('Références à réparer'), findsOneWidget);
        expect(find.text('Ancien format à convertir'), findsOneWidget);
        final list = find.byKey(const ValueKey('event-builder-v2-list'));
        expect(
          find.descendant(of: list, matching: find.text('Actif')),
          findsNWidgets(2),
        );
        expect(
          find.descendant(of: list, matching: find.text('Inactif')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: list, matching: find.text('Brouillon')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: list, matching: find.text('Manquant')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: list, matching: find.text('Ancien')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(
            const ValueKey(
              'event-builder-v2-event-v2:$productRoutePortEventId',
            ),
          ),
        );
        await pumpEventBuilderV2ProductRouteFrames(
          tester,
          container: container,
        );

        final bridge =
            container.read(narrativeEventMapBridgeControllerProvider);
        expect(
          bridge.selectedGroupContext,
          const NarrativeEventGroupContext.map('map_port'),
        );
        final sourceInspector = find.byKey(
          const ValueKey('event-builder-v2-inspector-source'),
        );
        expect(
          find.descendant(
            of: sourceInspector,
            matching: find.text('PORTÉE DÉRIVÉE · LECTURE SEULE'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: sourceInspector,
            matching: find.text('Port Selbrume'),
          ),
          findsOneWidget,
        );
        expect(find.textContaining('map_port'), findsNothing);
        expect(find.textContaining('npc_rival'), findsNothing);
        expect(find.text('Choisir une map'), findsNothing);
      },
    );

    testWidgets(
      'keeps bridge selection across search, filter and snapshot refresh',
      (tester) async {
        final fixture = await createEventBuilderV2ProductRouteFixture(
          tester,
          mode: EventSystemMode.dualRead,
        );
        final container = await pumpEventBuilderV2ProductRoute(
          tester,
          fixture: fixture,
        );
        const portKey = ValueKey(
          'event-builder-v2-event-v2:$productRoutePortEventId',
        );

        await tester.tap(find.byKey(portKey));
        await pumpEventBuilderV2ProductRouteFrames(
          tester,
          container: container,
        );
        await tester.enterText(
          find.byKey(const ValueKey('event-builder-v2-search')),
          'esprit',
        );
        await tester.pump();

        expect(find.byKey(portKey), findsNothing);
        expect(find.text('Écho dans la brume'), findsOneWidget);
        expect(
          container
              .read(narrativeEventMapBridgeControllerProvider)
              .selectedNarrativeEventV2Id,
          productRoutePortEventId,
        );

        await tester.enterText(
          find.byKey(const ValueKey('event-builder-v2-search')),
          '',
        );
        await tester.pump();
        await tester.tap(
          find.byKey(const ValueKey('event-builder-v2-filter-button')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Actifs'));
        await tester.pumpAndSettle();

        expect(find.byKey(portKey), findsOneWidget);
        expect(find.text('Après la victoire'), findsOneWidget);
        expect(find.text('Écho dans la brume'), findsNothing);
        expect(find.text('Événement à préparer'), findsNothing);
        expect(find.text('Objet disparu'), findsNothing);
        expect(find.text('Ancienne rumeur au port'), findsNothing);
        expect(
          container
              .read(narrativeEventMapBridgeControllerProvider)
              .selectedNarrativeEventV2Id,
          productRoutePortEventId,
        );

        final request = NarrativeEventBuilderV2SnapshotRequest.fromProject(
          projectRootPath: fixture.root.path,
          project: fixture.project,
        );
        container.invalidate(
          narrativeEventBuilderV2ReadModelProvider(request),
        );
        await pumpEventBuilderV2ProductRouteFrames(
          tester,
          container: container,
        );

        expect(find.byKey(portKey), findsOneWidget);
        expect(
          container
              .read(narrativeEventMapBridgeControllerProvider)
              .selectedNarrativeEventV2Id,
          productRoutePortEventId,
        );
      },
    );

    test('loads the complete list through the production disk snapshot',
        () async {
      final fixture = await EventBuilderV2ProductRouteFixture.create(
        mode: EventSystemMode.dualRead,
      );
      addTearDown(fixture.dispose);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final request = NarrativeEventBuilderV2SnapshotRequest.fromProject(
        projectRootPath: fixture.root.path,
        project: fixture.project,
      );

      final readModel = await container.read(
        narrativeEventBuilderV2ReadModelProvider(request).future,
      );

      expect(readModel.events, hasLength(6));
      expect(
        readModel.events.map((event) => event.title),
        containsAll(<String>[
          'Rencontre rival au port',
          'Écho dans la brume',
          'Après la victoire',
          'Événement à préparer',
          'Objet disparu',
          'Ancienne rumeur au port',
        ]),
      );
      expect(
        readModel.groups
            .where((group) => group.kind == NarrativeEventProjectGroupKind.map)
            .map((group) => group.label),
        containsAll(<String>['Port Selbrume', 'Forêt Brumeuse']),
      );
    });

    test('rejects a disk snapshot that drifted from the editor manifest',
        () async {
      final fixture = await EventBuilderV2ProductRouteFixture.create(
        mode: EventSystemMode.dualRead,
      );
      addTearDown(fixture.dispose);
      final request = NarrativeEventBuilderV2SnapshotRequest.fromProject(
        projectRootPath: fixture.root.path,
        project: fixture.project,
      );
      final projectFile = File(fixture.projectPath);
      final json =
          jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>;
      json['name'] = 'Selbrume changé sur disque';
      await projectFile.writeAsString(jsonEncode(json), flush: true);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await expectLater(
        container.read(
          narrativeEventBuilderV2ReadModelProvider(request).future,
        ),
        throwsA(isA<NarrativeEventBuilderV2SnapshotMismatch>()),
      );
    });
  });
}
