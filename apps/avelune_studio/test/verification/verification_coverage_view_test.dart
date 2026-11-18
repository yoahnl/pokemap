import 'package:avelune_studio/features/verification/domain/verification_port.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../presentation/story_memory_harness.dart';
import '../presentation/story_interactions_support.dart';
import '../support/map_workspace_fixture.dart';
import '../storyline/storyline_widget_support.dart';
import 'verification_fakes.dart';

void main() {
  testWidgets('an unreadable saved map does not open its cached view', (
    tester,
  ) async {
    final map = workspaceEntries.first;
    final port = FakeVerificationPort(
      diagnostics: [
        verificationDiagnostic(
          verificationUnreadableMap,
          NarrativeProjectDiagnosticDestination.map,
          mapId: map.id,
        ),
      ],
    );
    final maps = await openMemoryStudio(
      tester,
      memoryIndex(),
      verification: port,
      world: (maps) => MapOnlyWorld(maps, readSaved: true),
    );
    await openTrame(tester);
    await tester.tap(interactionKey('story-section-verification'));
    await settleMemory(tester);
    await tester.tap(interactionKey('verification-start'));
    await settleMemory(tester);
    expect(interactionMaps(tester).active!.base.mapId, map.id);
    maps.failedMap = map.id;

    await tester.tap(interactionKey('verification-open-0'));
    await settleMemory(tester);

    expect(
      interactionKey('verification-destination-unavailable'),
      findsOneWidget,
    );
    expect(interactionKey('verification-summary'), findsOneWidget);
    expect(interactionMaps(tester).active!.base.mapId, map.id);
  });

  testWidgets(
    'an excluded map leaves visible partial coverage and a French diagnostic',
    (tester) async {
      final map = trameProject.maps.first;
      final port = FakeVerificationPort(
        diagnostics: [
          for (final code in [
            verificationUnreadableMap,
            verificationRuntimeMissingMap,
          ])
            verificationDiagnostic(
              code,
              NarrativeProjectDiagnosticDestination.map,
              mapId: map.id,
            ),
        ],
      );
      await openTrameStudio(tester, verification: port);
      await tester.tap(
        find.byKey(const ValueKey('story-section-verification')),
      );
      await settleMemory(tester);
      expect(port.analyses, 0);
      await tester.tap(find.byKey(const ValueKey('verification-start')));
      await settleMemory(tester);

      expect(
        find.text('Accessibilité sur les cartes · Partielle'),
        findsOneWidget,
      );
      expect(find.text('1 carte exclue du contrôle.'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('verification-problem-1')),
        findsNothing,
      );
      expect(
        find.text(
          'Les données de la carte « ${map.name} » sont indisponibles pour la vérification.',
        ),
        findsOneWidget,
      );
    },
  );
}
