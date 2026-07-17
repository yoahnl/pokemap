import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_registry_persistence_models.dart';
import 'package:map_editor/src/application/ports/narrative_event_registry_persistence_gateway.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

import '../../support/event_builder_v2_product_route_fixture.dart';
import '../../support/event_builder_v2_visual_harness.dart';

void main() {
  group('NS-EVENT-V2 Phase 2 H5 states and accessibility', () {
    testWidgets('shows loading then the complete workspace', (tester) async {
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.v2Only,
      );
      final loading = Completer<NarrativeEventBuilderProjectReadModel>();

      await pumpEventBuilderV2ProductRoute(
        tester,
        fixture: fixture,
        readModelLoader: (_) => loading.future,
      );

      expect(
        find.byKey(const ValueKey('event-builder-v2-product-loading')),
        findsOneWidget,
      );
      loading.complete(fixture.readModel);
      await tester.pump();
      await tester.pump();
      expect(
        find.byKey(const ValueKey('event-builder-v2-new-event')),
        findsOneWidget,
      );
    });

    testWidgets('missing source opens a real repair picker', (tester) async {
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.v2Only,
      );
      await pumpEventBuilderV2ProductRoute(tester, fixture: fixture);

      await tester.tap(
        find.byKey(
          const ValueKey(
            'event-builder-v2-event-v2:$productRouteMissingEventId',
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Rebrancher l’élément').first);
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-source-sheet')),
      );

      expect(find.text('Choisir le déclencheur'), findsOneWidget);
      expect(find.text('Enregistrer le déclencheur'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('event-builder-v2-source-sheet')),
        findsNothing,
      );
    });

    for (final scenario in const [
      (
        NarrativeEventRegistryPersistenceStatus.staleRevision,
        'staleRevision',
        'Le projet a changé.',
        'Une version plus récente existe',
      ),
      (
        NarrativeEventRegistryPersistenceStatus.recoveryRequired,
        'recoveryRequired',
        'Une écriture interrompue doit être récupérée.',
        'Rechargement nécessaire',
      ),
    ]) {
      testWidgets('surfaces ${scenario.$2} with a recovery action',
          (tester) async {
        final fixture = await createEventBuilderV2ProductRouteFixture(
          tester,
          mode: EventSystemMode.v2Only,
        );
        await pumpEventBuilderV2ProductRoute(
          tester,
          fixture: fixture,
          persistenceGateway: _FixedPersistenceGateway(
            NarrativeEventRegistryPersistenceResult(
              status: scenario.$1,
              code: scenario.$2,
              message: scenario.$3,
            ),
          ),
        );
        await tester.tap(
          find.byKey(const ValueKey('event-builder-v2-new-event')),
        );
        await _waitFor(
          tester,
          find.byKey(const ValueKey('event-builder-v2-creation-sheet')),
        );
        await tester.enterText(
          find.descendant(
            of: find.byKey(
              const ValueKey('event-builder-v2-create-name'),
            ),
            matching: find.byType(TextField),
          ),
          'Écriture interrompue',
        );
        await tester.tap(
          find.byKey(const ValueKey('event-builder-v2-save-draft')),
        );
        await _waitFor(tester, find.text(scenario.$4));

        expect(find.text('Enregistrement interrompu'), findsOneWidget);
        expect(find.text('Recharger les événements'), findsOneWidget);
      });
    }

    testWidgets('supports 1280 at 125 percent text scale', (tester) async {
      await pumpEventBuilderV2PhaseK(
        tester,
        viewport: const Size(1280, 941),
        textScaleFactor: 1.25,
      );

      expect(find.text('Rencontre rival au port'), findsWidgets);
      expect(find.text('DÉCLENCHEUR'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps Tab and Shift+Tab inside and restores focus on Escape',
        (tester) async {
      await pumpEventBuilderV2PhaseK(
        tester,
        viewport: const Size(1440, 941),
      );
      await tester.tap(find.text('Ouvrir la bibliothèque'));
      await tester.pumpAndSettle();

      for (var index = 0; index < 5; index++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(_focusIsInsideSideSheet(), isTrue);
      }
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(_focusIsInsideSideSheet(), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      final launcher = tester.widget<PokeMapButton>(
        find.byKey(const ValueKey('event-builder-v2-open-library')),
      );
      expect(launcher.focusNode!.hasFocus, isTrue);
      expect(find.byType(PokeMapDesktopSideSheet), findsNothing);
    });
  });
}

final class _FixedPersistenceGateway
    implements NarrativeEventRegistryPersistenceGateway {
  const _FixedPersistenceGateway(this.result);

  final NarrativeEventRegistryPersistenceResult result;

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) async =>
      result;

  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) async {
    return NarrativeEventRegistryRecoveryInspection(
      status: NarrativeEventRegistryRecoveryGateStatus.clear,
      issues: const [],
    );
  }

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) async =>
      const [];

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) async {
    return NarrativeEventRegistryPersistenceResult(
      status: NarrativeEventRegistryPersistenceStatus.noOp,
      code: 'noOp',
      message: 'Aucune annulation.',
    );
  }
}

bool _focusIsInsideSideSheet() {
  final focusContext = FocusManager.instance.primaryFocus?.context;
  if (focusContext == null) return false;
  if (focusContext.widget is PokeMapDesktopSideSheet) return true;
  var found = false;
  (focusContext as Element).visitAncestorElements((ancestor) {
    found = ancestor.widget is PokeMapDesktopSideSheet;
    return !found;
  });
  return found;
}

Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 400; attempt++) {
    await tester.pump(const Duration(milliseconds: 10));
    if (finder.evaluate().isNotEmpty) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
  throw TestFailure('Expected widget did not appear.');
}
