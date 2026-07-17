import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/narrative_event_validation_coordinator.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_builder_v2_providers.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_validation_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../map_core/test/support/narrative_event_authoring_fixtures.dart';
import 'support/event_registry_persistence_fixtures.dart';

void main() {
  group('I3 narrative Event validation coordinator', () {
    test('groups the core report without recomputing diagnostics', () {
      final eventDiagnostic = _diagnostic(
        eventId: eventIdA,
        kind: NarrativeEventValidationDestinationKind.event,
      );
      final globalDiagnostic = NarrativeEventValidationDiagnostic(
        code: 'registryIssue',
        severity: NarrativeEventValidationSeverity.warning,
        path: 'eventRegistry',
        message: 'Registre à vérifier.',
        action: NarrativeEventValidationAction.reviewRegistry,
        destination: NarrativeEventValidationDestination(
          kind: NarrativeEventValidationDestinationKind.registry,
        ),
      );
      final state = NarrativeEventValidationState.fromReport(
        NarrativeEventValidationReport(
          diagnostics: [globalDiagnostic, eventDiagnostic],
        ),
      );

      expect(state.forEvent(eventIdA).single.diagnostic, same(eventDiagnostic));
      expect(state.global.single.diagnostic, same(globalDiagnostic));
    });

    test('resolves exact Event, Map, Scene and claim destinations', () {
      final record = configuredRecord(id: eventIdA, enabled: true);
      final claim = authoringClaim(targetEventIds: [eventIdA]);
      final registry = registryWithRecords(
        [record],
        claims: [claim],
      );
      final catalog = authoringCatalogForRegistry(
        registry,
        scenes: [sceneEntry()],
      );
      const coordinator = NarrativeEventValidationCoordinator();

      final event = coordinator.resolve(
        diagnostic: _diagnostic(
          eventId: eventIdA,
          kind: NarrativeEventValidationDestinationKind.eventSource,
        ),
        registry: registry,
        catalog: catalog,
      );
      expect(event.status, NarrativeEventValidationNavigationStatus.ready);
      expect(event.command!.kind,
          NarrativeEventValidationNavigationKind.selectEvent);
      expect(event.command!.selectedStableKey, 'v2:$eventIdA');
      expect(event.command!.section, NarrativeEventValidationSection.source);

      final eventScene = coordinator.resolve(
        diagnostic: _diagnostic(
          eventId: eventIdA,
          kind: NarrativeEventValidationDestinationKind.eventScene,
        ),
        registry: registry,
        catalog: catalog,
      );
      expect(eventScene.command!.kind,
          NarrativeEventValidationNavigationKind.selectEvent);
      expect(
        eventScene.command!.section,
        NarrativeEventValidationSection.scene,
      );

      final map = coordinator.resolve(
        diagnostic: _diagnostic(
          eventId: eventIdA,
          kind: NarrativeEventValidationDestinationKind.mapSource,
          mapId: 'map_a',
          sourceOwnerId: 'npc_a',
        ),
        registry: registry,
        catalog: catalog,
      );
      expect(map.command!.kind,
          NarrativeEventValidationNavigationKind.openMapSource);
      expect(map.command!.mapId, 'map_a');
      expect(map.command!.sourceOwnerId, 'npc_a');

      final scene = coordinator.resolve(
        diagnostic: _diagnostic(
          eventId: eventIdA,
          kind: NarrativeEventValidationDestinationKind.scene,
          sceneId: 'scene_a',
        ),
        registry: registry,
        catalog: catalog,
      );
      expect(scene.command!.kind,
          NarrativeEventValidationNavigationKind.openScene);
      expect(scene.command!.sceneId, 'scene_a');

      final claimResult = coordinator.resolve(
        diagnostic: NarrativeEventValidationDiagnostic(
          code: 'claimIssue',
          severity: NarrativeEventValidationSeverity.error,
          eventId: eventIdA,
          path: 'eventRegistry.legacyClaims.${claim.cohortId}',
          message: 'Claim invalide.',
          action: NarrativeEventValidationAction.reviewClaim,
          destination: NarrativeEventValidationDestination(
            kind: NarrativeEventValidationDestinationKind.claim,
            claimId: claim.cohortId,
            eventId: eventIdA,
          ),
        ),
        registry: registry,
        catalog: catalog,
      );
      expect(claimResult.command!.kind,
          NarrativeEventValidationNavigationKind.reviewClaim);
    });

    test('returns staleDestination without throwing after deletion', () {
      final registry = registryWithRecords([configuredRecord(id: eventIdA)]);
      const coordinator = NarrativeEventValidationCoordinator();
      final result = coordinator.resolve(
        diagnostic: _diagnostic(
          eventId: eventIdA,
          kind: NarrativeEventValidationDestinationKind.scene,
          sceneId: 'scene_deleted',
        ),
        registry: registry,
        catalog: authoringCatalogForRegistry(registry),
      );

      expect(
        result.status,
        NarrativeEventValidationNavigationStatus.staleDestination,
      );
      expect(result.command, isNull);
      expect(result.message, contains('n’existe plus'));
    });

    test('production snapshot loader reuses its latest project cache',
        () async {
      final fixture = await createPersistenceFixture(
        registry: persistenceRegistry(mode: EventSystemMode.v2Only),
      );
      addTearDown(fixture.dispose);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final request = NarrativeEventBuilderV2SnapshotRequest.fromProject(
        projectRootPath: fixture.root.path,
        project: fixture.session.manifest,
      );
      final loader = container.read(
        narrativeEventValidationSnapshotLoaderProvider,
      );

      final initial = await loader(request);
      final unchanged = await loader(request);

      expect(initial.recalculatedEventIds, {persistenceEventA});
      expect(unchanged.recalculatedEventIds, isEmpty);
      expect(unchanged.report.toDebugJson(), initial.report.toDebugJson());
    });
  });
}

NarrativeEventValidationDiagnostic _diagnostic({
  required String eventId,
  required NarrativeEventValidationDestinationKind kind,
  String? mapId,
  String? sourceOwnerId,
  String? sceneId,
}) {
  return NarrativeEventValidationDiagnostic(
    code: 'testIssue',
    severity: NarrativeEventValidationSeverity.error,
    eventId: eventId,
    path: 'eventRegistry.records.$eventId',
    message: 'Diagnostic de test.',
    action: NarrativeEventValidationAction.openEvent,
    destination: NarrativeEventValidationDestination(
      kind: kind,
      eventId: eventId,
      mapId: mapId,
      sourceOwnerId: sourceOwnerId,
      sceneId: sceneId,
    ),
  );
}
