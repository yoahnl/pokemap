import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_map_bridge_models.dart';
import 'package:map_editor/src/application/models/narrative_event_spatial_source_creation_models.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_builder_v2_providers.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_map_bridge_state.dart';
import 'package:map_editor/src/ui/canvas/events/event_builder_workspace.dart';
import 'package:map_editor/src/ui/canvas/events_v2/event_builder_v2_product_route.dart';
import 'package:map_editor/src/ui/canvas/events_v2/event_builder_v2_workspace.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_editor/src/ui/editor_shell_page.dart';

import '../../support/event_builder_v2_product_route_fixture.dart';
import '../../support/event_builder_v2_visual_harness.dart';

void main() {
  group('NS-EVENT-V2 H1 product route', () {
    for (final mode in EventSystemMode.values) {
      testWidgets('routes ${mode.name} to its single authorized workspace',
          (tester) async {
        final fixture = await createEventBuilderV2ProductRouteFixture(
          tester,
          mode: mode,
        );

        await pumpEventBuilderV2ProductRoute(tester, fixture: fixture);

        final usesV1 = mode == EventSystemMode.legacyOnly;
        expect(
          find.byType(EventBuilderWorkspace),
          usesV1 ? findsOne : findsNothing,
        );
        expect(
          find.byType(EventBuilderV2Workspace),
          usesV1 ? findsNothing : findsOne,
        );
        if (usesV1) {
          expect(
            find.byKey(
              const ValueKey('event-builder-v2-legacy-migration-entry'),
            ),
            findsOneWidget,
          );
          expect(find.text('Prévisualiser la conversion'), findsOneWidget);
        }
        if (!usesV1) {
          // V2 modes must not leave a hidden legacy write path mounted.
          expect(
            find.byKey(const ValueKey('event-builder-create-event-button')),
            findsNothing,
          );
          expect(
            find.byKey(const ValueKey('event-builder-new-event-button')),
            findsNothing,
          );
        }
      });
    }

    testWidgets('fails closed on snapshot drift and retries without V1',
        (tester) async {
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.dualRead,
      );
      var attempts = 0;
      await pumpEventBuilderV2ProductRoute(
        tester,
        fixture: fixture,
        readModelLoader: (_) {
          attempts++;
          if (attempts == 1) {
            return Future.error(
              const NarrativeEventBuilderV2SnapshotMismatch(),
            );
          }
          return Future.value(fixture.readModel);
        },
      );

      expect(
        find.byKey(const ValueKey('event-builder-v2-product-error')),
        findsOneWidget,
      );
      expect(find.byType(EventBuilderWorkspace), findsNothing);
      await tester.tap(find.text('Réessayer'));
      await pumpEventBuilderV2ProductRouteFrames(tester);

      expect(attempts, 2);
      expect(find.byType(EventBuilderV2Workspace), findsOneWidget);
      expect(find.byType(EventBuilderWorkspace), findsNothing);
    });

    testWidgets('fails closed when validation cannot be guaranteed',
        (tester) async {
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.dualRead,
      );
      await pumpEventBuilderV2ProductRoute(
        tester,
        fixture: fixture,
        validationLoader: (_) => Future.error(StateError('validator down')),
      );

      expect(
        find.byKey(const ValueKey('event-builder-v2-validation-error')),
        findsOneWidget,
      );
      expect(find.byType(EventBuilderV2Workspace), findsNothing);
      expect(find.textContaining('éviter de masquer'), findsOneWidget);
    });

    testWidgets(
        'gates a narrow V2 route before diagnostics or snapshot loading',
        (tester) async {
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.dualRead,
      );
      var readModelLoads = 0;
      var validationLoads = 0;

      await pumpEventBuilderV2ProductRoute(
        tester,
        fixture: fixture,
        viewport: const Size(800, 632),
        readModelLoader: (_) {
          readModelLoads++;
          return Future.value(fixture.readModel);
        },
        validationLoader: (_) {
          validationLoads++;
          return Future.value(
            buildEventBuilderV2ProductRouteValidationSnapshot(fixture),
          );
        },
      );

      expect(find.byType(EventBuilderV2NarrowViewportGate), findsOneWidget);
      expect(find.text('Zone de travail trop étroite'), findsOneWidget);
      expect(find.textContaining('1280 px dans la zone Event'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('event-builder-v2-migration-available')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('event-builder-v2-global-diagnostic')),
        findsNothing,
      );
      expect(readModelLoads, 0);
      expect(validationLoads, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'gates the full shell from the actual Event workspace width at 1280',
        (tester) async {
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.dualRead,
      );
      var readModelLoads = 0;
      var validationLoads = 0;

      await pumpEventBuilderV2FullProductRoute(
        tester,
        fixture: fixture,
        viewport: const Size(1280, 800),
        readModelLoader: (_) {
          readModelLoads++;
          return Future.value(fixture.readModel);
        },
        validationLoader: (_) {
          validationLoads++;
          return Future.value(
            buildEventBuilderV2ProductRouteValidationSnapshot(fixture),
          );
        },
      );

      expect(find.byType(EventBuilderV2NarrowViewportGate), findsOneWidget);
      expect(find.text('Zone de travail trop étroite'), findsOneWidget);
      expect(find.byType(EventBuilderV2Workspace), findsNothing);
      expect(readModelLoads, 0);
      expect(validationLoads, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reloads validation evidence when a repair action is clicked',
        (tester) async {
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.dualRead,
      );
      var validationLoads = 0;
      await pumpEventBuilderV2ProductRoute(
        tester,
        fixture: fixture,
        validationLoader: (_) async {
          validationLoads++;
          return buildEventBuilderV2ProductRouteValidationSnapshot(fixture);
        },
      );
      expect(validationLoads, 1);
      await tester.tap(
        find.byKey(
          const ValueKey(
            'event-builder-v2-event-v2:$productRouteDraftEventId',
          ),
        ),
      );
      await tester.pump();
      final validationSection = find.byKey(
        const ValueKey('event-builder-v2-inspector-validation-diagnostics'),
      );
      expect(validationSection, findsOneWidget);

      await tester.tap(
        find.descendant(
          of: validationSection,
          matching: find.text('Ouvrir'),
        ),
      );
      await _waitForWidget(
        tester,
        find.byKey(const ValueKey('event-builder-v2-source-sheet')),
      );

      expect(validationLoads, 2);
      expect(find.text('Choisir le déclencheur'), findsOneWidget);
    });

    testWidgets('reloads its disk snapshot after an unsaved map gate',
        (tester) async {
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.dualRead,
      );
      var loads = 0;
      final container = await pumpEventBuilderV2ProductRoute(
        tester,
        fixture: fixture,
        readModelLoader: (_) {
          loads++;
          return Future.value(fixture.readModel);
        },
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      expect(loads, 1);

      notifier.state = notifier.state.copyWith(isDirty: true);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('event-builder-v2-unsaved-map-gate')),
        findsOneWidget,
      );
      expect(find.byType(EventBuilderV2Workspace), findsNothing);

      notifier.state = notifier.state.copyWith(isDirty: false);
      await pumpEventBuilderV2ProductRouteFrames(
        tester,
        container: container,
      );
      expect(loads, 2);
      expect(find.byType(EventBuilderV2Workspace), findsOneWidget);
    });

    testWidgets('does not leak a source-less map context across projects',
        (tester) async {
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.dualRead,
      );
      final container = await pumpEventBuilderV2ProductRoute(
        tester,
        fixture: fixture,
      );
      final bridge = container.read(
        narrativeEventMapBridgeControllerProvider.notifier,
      );
      expect(
        bridge.selectNarrativeEventV2(
          fixture.project,
          productRouteDraftEventId,
          groupContext: const NarrativeEventGroupContext.map('map_port'),
        ),
        isTrue,
      );
      await tester.pump();
      await tester.tap(
        find.byKey(
          const ValueKey(
            'event-builder-v2-event-v2:$productRoutePortEventId',
          ),
        ),
      );
      await tester.pump();

      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = notifier.state.copyWith(
        projectRootPath: '${fixture.root.path}/second_project',
      );
      await pumpEventBuilderV2ProductRouteFrames(
        tester,
        container: container,
      );
      await tester.tap(
        find.byKey(
          const ValueKey(
            'event-builder-v2-event-v2:$productRouteDraftEventId',
          ),
        ),
      );
      await tester.pump();

      expect(
        container
            .read(narrativeEventMapBridgeControllerProvider)
            .selectedGroupContext,
        const NarrativeEventGroupContext.global(),
      );
    });

    testWidgets('round-trips a spatial Event through the Map bridge exactly',
        (tester) async {
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.dualRead,
      );
      final container = await pumpEventBuilderV2ProductRoute(
        tester,
        fixture: fixture,
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
      await tester.tap(find.text('Voir sur la carte').first);
      await pumpEventBuilderV2ProductRouteFrames(
        tester,
        container: container,
      );
      await waitForEventBuilderV2BridgeIdle(tester, container);

      final bridge = container.read(narrativeEventMapBridgeControllerProvider);
      expect(bridge.selectedNarrativeEventV2Id, productRoutePortEventId);
      expect(
        bridge.selectedGroupContext,
        const NarrativeEventGroupContext.map('map_port'),
      );
      expect(bridge.pendingReturn?.eventId, productRoutePortEventId);
      expect(
        container.read(editorNotifierProvider).workspaceMode,
        EditorWorkspaceMode.map,
      );
      expect(find.byType(MapCanvas), findsOneWidget);
      expect(
        find.byKey(const ValueKey('narrative-event-map-banner')),
        findsOneWidget,
      );
      expect(bridge.focusRequest?.focusTarget.kind,
          NarrativeEditorFocusTargetKind.entity);
      expect(bridge.focusRequest?.focusTarget.mapId, 'map_port');
      expect(bridge.focusRequest?.focusTarget.ownerId, 'npc_rival');
      expect(bridge.focusRequest?.cameraApplied, isTrue);

      await tester.tap(
        find.byKey(const ValueKey('narrative-event-map-return')),
      );
      await pumpEventBuilderV2ProductRouteFrames(tester);

      expect(find.byType(EventBuilderV2Workspace), findsOneWidget);
      expect(
        container
            .read(narrativeEventMapBridgeControllerProvider)
            .selectedNarrativeEventV2Id,
        productRoutePortEventId,
      );
      expect(find.text('Rencontre rival au port'), findsWidgets);
    });

    testWidgets(
        'creates a missing physical source and returns to the same draft',
        (tester) async {
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.dualRead,
      );
      final container = await pumpEventBuilderV2ProductRoute(
        tester,
        fixture: fixture,
      );
      final bridgeController = container.read(
        narrativeEventMapBridgeControllerProvider.notifier,
      );
      final notifier = container.read(editorNotifierProvider.notifier);

      expect(
        bridgeController.selectNarrativeEventV2(
          fixture.project,
          productRouteDraftEventId,
          groupContext: const NarrativeEventGroupContext.map('map_port'),
        ),
        isTrue,
      );
      await pumpEventBuilderV2ProductRouteFrames(tester);
      await tester.tap(
        find.byKey(
          const ValueKey(
            'event-builder-v2-event-v2:$productRoutePortEventId',
          ),
        ),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(
          const ValueKey(
            'event-builder-v2-event-v2:$productRouteDraftEventId',
          ),
        ),
      );
      await tester.pump();
      expect(
        container
            .read(narrativeEventMapBridgeControllerProvider)
            .selectedGroupContext,
        const NarrativeEventGroupContext.map('map_port'),
      );
      await tester.tap(find.text('Choisir un élément').first);
      await pumpEventBuilderV2ProductRouteFrames(
        tester,
        container: container,
      );
      await waitForEventBuilderV2BridgeIdle(tester, container);

      expect(
        container.read(editorNotifierProvider).workspaceMode,
        EditorWorkspaceMode.map,
      );
      expect(find.byType(MapCanvas), findsOneWidget);
      expect(
        find.byKey(const ValueKey('narrative-event-map-banner')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('narrative-event-create-kind-npc')),
      );
      await tester.pump();
      final proposal = notifier.proposeNarrativeEventSourceAt(
        position: const GridPos(x: 3, y: 3),
        kind: NarrativeEventPhysicalSourceKind.npc,
      );
      expect(proposal, isNotNull);
      expect(
        bridgeController.previewSourceCreationProposal(proposal!),
        isTrue,
      );
      await tester.pump();
      expect(
        container
            .read(narrativeEventMapBridgeControllerProvider)
            .sourceCreationProposal,
        isNotNull,
      );
      final confirm = tester.widget<PokeMapButton>(
        find.byKey(const ValueKey('narrative-event-create-confirm')),
      );
      expect(confirm.onPressed, isNotNull);
      await tester.runAsync(() async {
        confirm.onPressed!();
        for (var attempt = 0; attempt < 400; attempt++) {
          final bridge =
              container.read(narrativeEventMapBridgeControllerProvider);
          if (!bridge.isSourceCreationBusy &&
              bridge.lastSourceCreationResult != null) {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
        fail('The product source-creation flow did not complete.');
      });
      await pumpEventBuilderV2ProductRouteFrames(tester);

      final afterReturn = container.read(
        narrativeEventMapBridgeControllerProvider,
      );
      expect(afterReturn.lastSourceCreationResult?.status.name, 'committed');
      expect(afterReturn.selectedNarrativeEventV2Id, productRouteDraftEventId);
      expect(
        afterReturn.selectedGroupContext,
        const NarrativeEventGroupContext.map('map_port'),
      );
      expect(find.byType(EventBuilderV2Workspace), findsOneWidget);
      expect(find.text('Événement à préparer'), findsWidgets);

      final refreshed = await tester.runAsync(() async {
        final freshContainer = ProviderContainer();
        try {
          final editor = container.read(editorNotifierProvider);
          final request = NarrativeEventBuilderV2SnapshotRequest.fromProject(
            projectRootPath: fixture.root.path,
            project: editor.project!,
          );
          return await freshContainer.read(
            narrativeEventBuilderV2ReadModelProvider(request).future,
          );
        } finally {
          freshContainer.dispose();
        }
      });
      final persistedDraft = refreshed!.events.singleWhere(
        (event) => event.eventId == productRouteDraftEventId,
      );
      expect(persistedDraft.source.available, isTrue);
      expect(persistedDraft.source.mapId, 'map_port');
    });

    testWidgets('matches the actual V2 product route golden', (tester) async {
      await loadEventBuilderV2PhaseKCaptureFonts();
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.dualRead,
      );
      final container = await pumpEventBuilderV2ProductRoute(
        tester,
        fixture: fixture,
        fontFamily: eventBuilderV2PhaseKCaptureFontFamily,
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

      final route = find.byType(NarrativeWorkspaceCanvas);
      expect(tester.getSize(route), const Size(1672, 941));
      final output = File(
        'test/goldens/event_builder_v2/phase_1/'
        'event_builder_v2_product_route_1672x941.png',
      );
      output.parent.createSync(recursive: true);
      await expectLater(
        route,
        matchesGoldenFile(output.absolute.path),
      );
    });

    testWidgets('projects the rich Selbrume event through the real read model',
        (tester) async {
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.v2Only,
      );

      final selected = fixture.readModel.events.singleWhere(
        (event) => event.eventId == productRoutePortEventId,
      );
      expect(selected.conditions.count, 2);
      expect(
        selected.conditions.unresolvedCount,
        0,
        reason: selected.conditions.humanLabel,
      );
      expect(selected.projection.outcomeLabels, hasLength(3));
      expect(
          selected.projection.outcomeLabels,
          containsAll(<String>[
            'Victoire',
            'Défaite',
            'Échec',
          ]));
      expect(selected.projection.consequences, hasLength(2));
      expect(selected.projection.worldRules, hasLength(1));
      expect(selected.lifecycle.reusePolicy, NarrativeEventReusePolicy.oneShot);
      expect(selected.lifecycle.priority, 10);
      expect(selected.lifecycle.order, 0);
      expect(selected.lifecycle.activeCandidateCount, 2);
      expect(selected.lifecycle.hasActiveCompetition, isTrue);
      expect(selected.source.mapLabel, 'Port Selbrume');

      final validation =
          buildEventBuilderV2ProductRouteValidationSnapshot(fixture);
      expect(
        validation.state.global,
        isEmpty,
        reason: validation.state.global
            .map(
                (item) => '${item.diagnostic.code}: ${item.diagnostic.message}')
            .join('\n'),
      );
    });

    testWidgets(
        'captures the full V2-only product shell at the north-star size',
        (tester) async {
      await loadEventBuilderV2PhaseKCaptureFonts();
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.v2Only,
      );
      final container = await pumpEventBuilderV2FullProductRoute(
        tester,
        fixture: fixture,
        fontFamily: eventBuilderV2PhaseKCaptureFontFamily,
      );

      expect(
        container.read(editorNotifierProvider).workspaceMode,
        EditorWorkspaceMode.events,
      );
      expect(find.byType(EditorShellPage), findsOneWidget);
      expect(find.byType(NarrativeWorkspaceCanvas), findsOneWidget);
      expect(find.byType(EventBuilderV2ProductRoute), findsOneWidget);
      expect(find.byType(EventBuilderV2Workspace), findsOneWidget);
      expect(find.byType(EventBuilderWorkspace), findsNothing);
      expect(
        tester
            .widget<EventBuilderV2Workspace>(
              find.byType(EventBuilderV2Workspace),
            )
            .viewportWidth,
        greaterThanOrEqualTo(1280),
      );
      expect(find.text('Zone de travail trop étroite'), findsNothing);

      await _waitForWidget(
        tester,
        find.byKey(
          const ValueKey(
            'event-builder-v2-event-v2:$productRoutePortEventId',
          ),
        ),
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

      final shell = find.byType(EditorShellPage);
      expect(shell, findsOneWidget);
      expect(tester.getSize(shell), const Size(1672, 941));

      final output = File(
        'test/goldens/event_builder_v2/phase_1/'
        'event_builder_v2_full_product_route_1672x941.png',
      );
      output.parent.createSync(recursive: true);
      await expectLater(
        shell,
        matchesGoldenFile(output.absolute.path),
      );
    });
  });
}

Future<void> _waitForWidget(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 400; attempt++) {
    await tester.pump(const Duration(milliseconds: 10));
    if (finder.evaluate().isNotEmpty) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
  throw TestFailure('Expected widget did not appear.');
}
