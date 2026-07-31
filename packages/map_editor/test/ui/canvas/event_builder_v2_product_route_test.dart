import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_map_bridge_models.dart';
import 'package:map_editor/src/application/models/narrative_event_spatial_source_creation_models.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_target_editor_navigation.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_builder_v2_providers.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_map_bridge_state.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_validation_state.dart';
import 'package:map_editor/src/features/narrative/state/scene_consequence_catalog_providers.dart';
import 'package:map_editor/src/ui/canvas/events/event_builder_workspace.dart';
import 'package:map_editor/src/ui/canvas/events_v2/event_builder_v2_product_route.dart';
import 'package:map_editor/src/ui/canvas/events_v2/event_builder_v2_workspace.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_destination.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_navigation.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_workspace_page.dart';
import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_editor/src/ui/editor_shell_page.dart';

import '../../support/event_builder_v2_product_route_fixture.dart';
import '../../support/event_builder_v2_visual_harness.dart';

void main() {
  group('NS-EVENT-V2 H1 product route', () {
    test('projects canonical gameplay authoring pickers', () {
      const project = ProjectManifest(
        name: 'Authoring pickers',
        maps: [],
        tilesets: [],
        shops: [
          ShopDefinition(id: 'shop_port', label: 'Boutique du port'),
        ],
        badges: [
          BadgeDefinition(id: 'badge_tide', label: 'Badge Marée'),
        ],
        trainers: [
          ProjectTrainerEntry(
            id: 'trainer_route',
            name: 'Dresseur de route',
            trainerClass: 'Guide',
          ),
          ProjectTrainerEntry(
            id: 'trainer_static_guardian',
            name: 'Gardien immobile',
            trainerClass: 'Rencontre',
            tags: ['static-encounter'],
          ),
        ],
      );

      final options = buildEventBuilderV2TemplateActionPickerOptions(
        project: project,
        maps: const [],
        catalogs: const SceneConsequenceCatalogs.unavailable(),
      );

      expect(
        options[NarrativeCommandParameterKind.shop]!.single.label,
        'Boutique du port',
      );
      expect(
        options[NarrativeCommandParameterKind.badge]!.single.id,
        'badge_tide',
      );
      expect(
        options[NarrativeCommandParameterKind.fieldAbility]!
            .map((option) => option.id),
        contains('surf'),
      );
      expect(
        options[NarrativeCommandParameterKind.staticEncounter]!.single.id,
        'static:trainer_static_guardian',
      );
      expect(
        options[NarrativeCommandParameterKind.staticEncounter]!.single.label,
        'Rencontre Gardien immobile',
      );
    });

    for (final mode in EventSystemMode.values) {
      testWidgets(
          'mounts the shared Event product shell on the real ${mode.name} route',
          (tester) async {
        final fixture = await createEventBuilderV2ProductRouteFixture(
          tester,
          mode: mode,
        );
        var validationLoads = 0;

        final container = await pumpEventBuilderV2FullProductRoute(
          tester,
          fixture: fixture,
          validationLoader: (_) async {
            validationLoads++;
            return buildEventBuilderV2ProductRouteValidationSnapshot(fixture);
          },
        );

        final usesLegacy = mode == EventSystemMode.legacyOnly;
        expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
        expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
        expect(
          find.byKey(const ValueKey('project-explorer-region')),
          findsNothing,
        );
        expect(find.text('Selbrume Route Test'), findsOneWidget);
        expect(
          find.byType(EventBuilderWorkspace),
          usesLegacy ? findsOneWidget : findsNothing,
        );
        expect(
          find.byType(EventBuilderV2Workspace),
          usesLegacy ? findsNothing : findsOneWidget,
        );

        final validate = find.byKey(
          const ValueKey('event-builder-v2-validate-project'),
        );
        expect(validate, usesLegacy ? findsNothing : findsOneWidget);
        if (usesLegacy) {
          expect(
            find.byKey(const ValueKey('event-builder-new-event-button')),
            findsOneWidget,
          );
          expect(validationLoads, 0);
        } else {
          final initialLoads = validationLoads;
          expect(initialLoads, greaterThanOrEqualTo(1));
          await tester.tap(validate);
          await pumpEventBuilderV2ProductRouteFrames(
            tester,
            container: container,
          );
          expect(validationLoads, greaterThan(initialLoads));
        }

        for (final key in const <ValueKey<String>>[
          ValueKey('event-builder-v2-new-storyline'),
          ValueKey('event-builder-v2-preview-project'),
          ValueKey('event-builder-v2-search-project'),
          ValueKey('event-builder-v2-project-notifications'),
          ValueKey('event-builder-v2-project-settings'),
          ValueKey('event-builder-v2-product-nav-validator'),
        ]) {
          expect(find.byKey(key), findsNothing);
        }
        expect(find.text('Project Health'), findsNothing);
        expect(find.text('Bon'), findsNothing);
      });
    }

    testWidgets(
        'consumes one pre-mount Map compatibility key and focuses its exact row',
        (tester) async {
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.dualRead,
      );
      final compatibility = fixture.readModel.events.singleWhere(
        (event) => event.readOnly && event.stableKey.startsWith('legacy:'),
      );

      final container = await pumpEventBuilderV2ProductRoute(
        tester,
        fixture: fixture,
        pendingCompatibilityStableKey: compatibility.stableKey,
      );

      final workspace = tester.widget<EventBuilderV2Workspace>(
        find.byType(EventBuilderV2Workspace),
      );
      expect(workspace.selectedStableKey, compatibility.stableKey);
      expect(
        container.read(worldMapTargetEditorNavigationProvider).pending,
        isNull,
      );
      final row = tester.widget<PokeMapSidebarItem>(
        find.byKey(
          ValueKey('event-builder-v2-event-${compatibility.stableKey}'),
        ),
      );
      expect(row.focusNode?.hasFocus, isTrue);
      expect(
        container
            .read(narrativeEventMapBridgeControllerProvider)
            .selectedNarrativeEventV2Id,
        isNull,
        reason: 'A compatibility key must never be guessed as a V2 Event id.',
      );

      container
          .read(worldMapTargetEditorNavigationProvider.notifier)
          .enqueue('legacy:missing:stale');
      await pumpEventBuilderV2ProductRouteFrames(
        tester,
        container: container,
      );
      expect(
        tester
            .widget<EventBuilderV2Workspace>(
              find.byType(EventBuilderV2Workspace),
            )
            .selectedStableKey,
        compatibility.stableKey,
      );
      expect(
        container.read(worldMapTargetEditorNavigationProvider).pending,
        isNull,
      );
    });

    testWidgets('derives the Event save status from map or project dirtiness',
        (tester) async {
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.legacyOnly,
      );
      final container = await pumpEventBuilderV2FullProductRoute(
        tester,
        fixture: fixture,
      );
      final notifier = container.read(editorNotifierProvider.notifier);

      expect(find.text('Tous les changements enregistrés'), findsOneWidget);

      notifier.state = notifier.state.copyWith(isProjectDirty: true);
      await tester.pump();
      expect(find.text('Modifications non enregistrées'), findsOneWidget);

      notifier.state = notifier.state.copyWith(
        isProjectDirty: false,
        isDirty: true,
      );
      await tester.pump();
      expect(find.text('Modifications non enregistrées'), findsOneWidget);
    });

    for (final mode in const [
      EventSystemMode.dualRead,
      EventSystemMode.v2Only,
    ]) {
      testWidgets(
          'disables validation on the real ${mode.name} route without a project root',
          (tester) async {
        final semantics = tester.ensureSemantics();
        final fixture = await createEventBuilderV2ProductRouteFixture(
          tester,
          mode: mode,
        );

        await pumpEventBuilderV2FullProductRoute(
          tester,
          fixture: fixture,
          includeProjectRootPath: false,
        );

        final validate = find.byKey(
          const ValueKey('event-builder-v2-validate-project'),
        );
        expect(validate, findsOneWidget);
        expect(tester.widget<PokeMapButton>(validate).onPressed, isNull);
        expect(
          find.descendant(
            of: validate,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Semantics && widget.properties.enabled == false,
            ),
          ),
          findsOneWidget,
        );
        semantics.dispose();
      });
    }

    testWidgets(
        'deduplicates and collapses global diagnostics without hiding errors',
        (tester) async {
      final semantics = tester.ensureSemantics();
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.v2Only,
      );
      final warning = NarrativeEventValidationDiagnostic(
        code: 'registry.readableLabel',
        severity: NarrativeEventValidationSeverity.warning,
        path: r'$.eventRegistry.records',
        message: 'Libellé lisible identique à l’identifiant technique.',
        action: NarrativeEventValidationAction.reviewRegistry,
        destination: NarrativeEventValidationDestination(
          kind: NarrativeEventValidationDestinationKind.registry,
        ),
      );
      final error = NarrativeEventValidationDiagnostic(
        code: 'registry.schema',
        severity: NarrativeEventValidationSeverity.error,
        path: r'$.eventRegistry.schemaVersion',
        message: 'Version du registre Event incompatible.',
        action: NarrativeEventValidationAction.none,
        destination: NarrativeEventValidationDestination(
          kind: NarrativeEventValidationDestinationKind.unavailable,
        ),
      );

      await pumpEventBuilderV2ProductRoute(
        tester,
        fixture: fixture,
        validationLoader: (_) async => _validationWithDiagnostics(
          fixture,
          [warning, warning, error],
        ),
      );

      expect(
        find.byKey(const ValueKey('event-builder-v2-global-diagnostics')),
        findsOneWidget,
      );
      expect(find.text('1 erreur'), findsOneWidget);
      expect(find.text('2 avertissements'), findsOneWidget);
      expect(find.text(error.message), findsOneWidget);
      expect(find.text(warning.message), findsNothing);
      expect(
        tester.getSemantics(find.text(error.message)).label,
        contains(error.message),
      );

      await tester.tap(
        find.byKey(
          const ValueKey('event-builder-v2-global-diagnostics-toggle'),
        ),
      );
      await tester.pump();

      expect(find.text(error.message), findsOneWidget);
      expect(find.text(warning.message), findsOneWidget);
      expect(find.text('2 occurrences'), findsOneWidget);
      expect(find.text('Replier les détails'), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });

    testWidgets('keeps one primary empty state and a neutral inspector',
        (tester) async {
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.v2Only,
      );

      await pumpEventBuilderV2ProductRoute(tester, fixture: fixture);

      expect(find.text('Sélectionnez un événement'), findsOneWidget);
      final neutralInspector = find.byKey(
        const ValueKey('event-builder-v2-inspector-neutral'),
      );
      expect(neutralInspector, findsOneWidget);
      expect(
        find.descendant(
          of: neutralInspector,
          matching: find.byType(PokeMapEmptyState),
        ),
        findsNothing,
      );
      expect(
        find.text('Choisissez un événement dans la liste du projet.'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses an informational tone for info-only diagnostics',
        (tester) async {
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.v2Only,
      );
      final info = NarrativeEventValidationDiagnostic(
        code: 'registry.info',
        severity: NarrativeEventValidationSeverity.info,
        path: r'$.eventRegistry',
        message: 'Information du registre Event.',
        action: NarrativeEventValidationAction.none,
        destination: NarrativeEventValidationDestination(
          kind: NarrativeEventValidationDestinationKind.unavailable,
        ),
      );

      await pumpEventBuilderV2ProductRoute(
        tester,
        fixture: fixture,
        validationLoader: (_) async => _validationWithDiagnostics(
          fixture,
          [info],
        ),
      );

      final tile = tester.widget<PokeMapIconTile>(
        find.byKey(
          const ValueKey('event-builder-v2-global-diagnostics-icon'),
        ),
      );
      expect(tile.tone, PokeMapTone.info);
      expect(tile.icon, CupertinoIcons.info_circle_fill);
      expect(find.text('1 information'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

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
      final navigationAway =
          container.read(narrativeStudioNavigationControllerProvider);
      expect(
        navigationAway.pendingReturn?.location.destination,
        NarrativeStudioDestination.events,
      );
      expect(
        navigationAway.pendingReturn?.location.selection?.assetId,
        productRoutePortEventId,
      );
      expect(
        navigationAway.pendingReturn?.focusAnchorId,
        'v2:$productRoutePortEventId',
      );
      expect(navigationAway.pendingReturn?.scrollOffset, isNonNegative);

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
      final navigationReturned =
          container.read(narrativeStudioNavigationControllerProvider);
      expect(
        navigationReturned.location.selection?.assetId,
        productRoutePortEventId,
      );
      expect(navigationReturned.pendingReturn, isNull);
      expect(navigationReturned.restorationRequest, isNull);
      final returnedItem = find.byKey(
        const ValueKey(
          'event-builder-v2-event-v2:$productRoutePortEventId',
        ),
      );
      final returnedSidebarItem = tester.widget<PokeMapSidebarItem>(
        returnedItem,
      );
      expect(returnedSidebarItem.focusNode?.hasFocus, isTrue);
    });

    testWidgets('consumes an exact Event route selection from Map Events',
        (tester) async {
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.dualRead,
      );
      final container = await pumpEventBuilderV2ProductRoute(
        tester,
        fixture: fixture,
      );

      container
          .read(narrativeStudioNavigationControllerProvider.notifier)
          .replace(
            NarrativeStudioRouteLocation.events(
              selection: NarrativeStudioAssetSelection(
                kind: NarrativeStudioAssetKind.event,
                assetId: productRoutePortEventId,
              ),
            ),
          );
      await pumpEventBuilderV2ProductRouteFrames(
        tester,
        container: container,
      );

      expect(
        container
            .read(narrativeEventMapBridgeControllerProvider)
            .selectedNarrativeEventV2Id,
        productRoutePortEventId,
      );
      expect(find.text('Rencontre rival au port'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'restores a lazy Event row with its non-zero scroll offset and focus',
        (tester) async {
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.dualRead,
      );
      final longReadModel = _withLazyEventGroups(fixture.readModel);
      final container = await pumpEventBuilderV2ProductRoute(
        tester,
        fixture: fixture,
        readModelLoader: (_) => Future.value(longReadModel),
      );
      const listKey = ValueKey('event-builder-v2-event-list-scroll');
      const eventKey = ValueKey(
        'event-builder-v2-event-v2:$productRoutePortEventId',
      );
      final listFinder = find.byKey(listKey);
      final scrollableFinder = find.descendant(
        of: listFinder,
        matching: find.byType(Scrollable),
      );
      final eventFinder = find.byKey(eventKey);

      expect(eventFinder, findsNothing);
      await tester.scrollUntilVisible(
        eventFinder,
        360,
        scrollable: scrollableFinder,
      );
      await tester.pump();
      final offsetBeforeMap =
          tester.widget<ListView>(listFinder).controller!.offset;
      expect(offsetBeforeMap, greaterThan(0));

      await tester.tap(eventFinder);
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

      final navigationAway =
          container.read(narrativeStudioNavigationControllerProvider);
      expect(navigationAway.pendingReturn?.scrollOffset, offsetBeforeMap);
      expect(
        navigationAway.pendingReturn?.focusAnchorId,
        'v2:$productRoutePortEventId',
      );

      await tester.tap(
        find.byKey(const ValueKey('narrative-event-map-return')),
      );
      expect(
        container
            .read(narrativeStudioNavigationControllerProvider)
            .restorationRequest,
        isNotNull,
      );
      await _waitForWidget(tester, eventFinder);
      expect(
        container
            .read(narrativeStudioNavigationControllerProvider)
            .restorationRequest,
        isNotNull,
        reason: 'La restauration ne doit être consommée qu’après le focus.',
      );
      await pumpEventBuilderV2ProductRouteFrames(
        tester,
        container: container,
        count: 6,
      );

      final restoredList = tester.widget<ListView>(listFinder);
      expect(restoredList.controller!.offset, offsetBeforeMap);
      expect(eventFinder, findsOneWidget);
      final restoredSidebarItem = tester.widget<PokeMapSidebarItem>(
        eventFinder,
      );
      expect(restoredSidebarItem.focusNode?.hasFocus, isTrue);
      expect(
        container
            .read(narrativeStudioNavigationControllerProvider)
            .restorationRequest,
        isNull,
      );
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

      // NS-UI-CVG-03 guards the production route, not an isolated visual
      // harness. Event now consumes the same shell and context page as every
      // Narrative Studio destination while retaining its four business
      // columns below that shared chrome.
      expect(
        tester.getRect(
          find.byKey(narrativeStudioProductShellHeaderKey),
        ),
        const Rect.fromLTWH(0, 0, 1672, 50),
      );
      expect(
        tester.getRect(
          find.byKey(narrativeStudioWorkspaceContextKey),
        ),
        const Rect.fromLTWH(199, 50, 1465, 52),
      );
      for (final key in const <ValueKey<String>>[
        ValueKey('event-builder-v2-new-storyline'),
        ValueKey('event-builder-v2-preview-project'),
        ValueKey('event-builder-v2-search-project'),
        ValueKey('event-builder-v2-project-notifications'),
        ValueKey('event-builder-v2-project-settings'),
      ]) {
        expect(find.byKey(key), findsNothing);
      }
      expect(
        tester.getRect(
          find.byKey(narrativeStudioProductShellProjectKey),
        ),
        const Rect.fromLTWH(0, 50, 191, 52),
      );
      expect(
        tester.getRect(
          find.byKey(narrativeStudioProductShellNavigationKey),
        ),
        const Rect.fromLTWH(8, 110, 183, 823),
      );
      expect(
        tester.getRect(
          find.byKey(narrativeStudioProductShellWorkspaceKey),
        ),
        const Rect.fromLTWH(199, 50, 1465, 883),
      );
      expect(
        tester.getRect(
          find.byKey(const ValueKey('event-builder-v2-list')),
        ),
        const Rect.fromLTWH(199, 102, 266, 831),
      );
      expect(
        tester.getRect(
          find.byKey(const ValueKey('event-builder-v2-library')),
        ),
        const Rect.fromLTWH(473, 102, 213, 831),
      );
      expect(
        tester.getRect(
          find.byKey(const ValueKey('event-builder-v2-editor')),
        ),
        const Rect.fromLTWH(694, 102, 574, 831),
      );
      expect(
        tester.getRect(
          find.byKey(const ValueKey('event-builder-v2-inspector')),
        ),
        const Rect.fromLTWH(1276, 102, 388, 831),
      );
      expect(
        find.byKey(const ValueKey('project-explorer-region')),
        findsNothing,
      );

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

    testWidgets('captures the full legacy product shell at the north-star size',
        (tester) async {
      await loadEventBuilderV2PhaseKCaptureFonts();
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.legacyOnly,
      );
      await pumpEventBuilderV2FullProductRoute(
        tester,
        fixture: fixture,
        fontFamily: eventBuilderV2PhaseKCaptureFontFamily,
      );

      expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
      expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
      expect(find.byType(EventBuilderWorkspace), findsOneWidget);
      expect(find.byType(EventBuilderV2Workspace), findsNothing);
      expect(
        find.byKey(const ValueKey('event-builder-v2-validate-project')),
        findsNothing,
      );

      final output = File(
        'test/goldens/narrative_studio/events/'
        'event_builder_legacy_full_product_route_1672x941.png',
      );
      output.parent.createSync(recursive: true);
      await expectLater(
        find.byType(EditorShellPage),
        matchesGoldenFile(output.absolute.path),
      );
    });
  });
}

NarrativeEventBuilderProjectReadModel _withLazyEventGroups(
  NarrativeEventBuilderProjectReadModel source,
) {
  final template = source.events.singleWhere(
    (event) => event.eventId == productRouteForestEventId,
  );
  return NarrativeEventBuilderProjectReadModel(
    groups: [
      for (var index = 0; index < 40; index++)
        NarrativeEventProjectGroup(
          stableKey: 'map:lazy_$index',
          label: 'Map de test ${index.toString().padLeft(2, '0')}',
          kind: NarrativeEventProjectGroupKind.map,
          events: [
            NarrativeEventProjectSummary(
              stableKey: 'v2:lazy_event_$index',
              eventId: 'lazy_event_$index',
              title: 'Événement de remplissage $index',
              origin: template.origin,
              readOnly: template.readOnly,
              enabled: template.enabled,
              group: NarrativeEventProjectGroupKind.map,
              groupKey: 'map:lazy_$index',
              groupLabel: 'Map de test ${index.toString().padLeft(2, '0')}',
              status: template.status,
              severity: template.severity,
              source: template.source,
              scene: template.scene,
              conditions: template.conditions,
              lifecycle: template.lifecycle,
              migration: template.migration,
              projection: template.projection,
              compatibilityOrigins: template.compatibilityOrigins,
              diagnostics: template.diagnostics,
              debug: template.debug,
            ),
          ],
        ),
      ...source.groups,
    ],
    diagnostics: source.diagnostics,
  );
}

NarrativeEventValidationSnapshot _validationWithDiagnostics(
  EventBuilderV2ProductRouteFixture fixture,
  List<NarrativeEventValidationDiagnostic> diagnostics,
) {
  final base = buildEventBuilderV2ProductRouteValidationSnapshot(fixture);
  final report = NarrativeEventValidationReport(diagnostics: diagnostics);
  return NarrativeEventValidationSnapshot(
    registry: base.registry,
    catalog: base.catalog,
    report: report,
    state: NarrativeEventValidationState.fromReport(report),
    recalculatedEventIds: base.recalculatedEventIds,
  );
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
