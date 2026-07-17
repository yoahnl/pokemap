import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_registry_persistence_models.dart';
import 'package:map_editor/src/application/ports/narrative_event_registry_persistence_gateway.dart';
import 'package:map_editor/src/application/use_cases/narrative_event_spatial_source_link_use_case.dart';

import 'support/event_registry_persistence_fixtures.dart';

const _eventId = 'evt_019abcde-0000-7000-8000-000000000311';

void main() {
  group('NS-EVENT-V2-24 spatial source link use case', () {
    test('replaces a disabled/draft source and persists exactly once',
        () async {
      final fixture = await createPersistenceFixture(
        map: _map(),
        registry: _registry(
          source: NarrativeEventSourceRef.entityInteract(
            'map_a',
            'entity_a',
          ),
        ),
      );
      addTearDown(fixture.dispose);
      final gateway = _RecordingGateway();

      final result = await NarrativeEventSpatialSourceLinkUseCase(
        persistenceGateway: gateway,
        operationIdFactory: () => 'v2_24_replace',
      )(
        projectPath: fixture.projectPath,
        eventId: _eventId,
        source: NarrativeEventSourceRef.triggerEnter('map_a', 'trigger_a'),
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );

      expect(
        result.status,
        NarrativeEventSpatialSourceLinkStatus.committed,
        reason: '${result.code}: ${result.message}',
      );
      expect(gateway.requests, hasLength(1));
      expect(
        result.nextRegistry!.records.single.draftOrNull!.source,
        NarrativeEventSourceRef.triggerEnter('map_a', 'trigger_a'),
      );
    });

    test('same source is a no-op with zero persistence write', () async {
      final source =
          NarrativeEventSourceRef.entityInteract('map_a', 'entity_a');
      final fixture = await createPersistenceFixture(
        map: _map(),
        registry: _registry(source: source),
      );
      addTearDown(fixture.dispose);
      final gateway = _RecordingGateway();

      final result = await NarrativeEventSpatialSourceLinkUseCase(
        persistenceGateway: gateway,
      )(
        projectPath: fixture.projectPath,
        eventId: _eventId,
        source: source,
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );

      expect(result.status, NarrativeEventSpatialSourceLinkStatus.noOp);
      expect(gateway.requests, isEmpty);
    });

    test('selects a source for a source-less draft exactly once', () async {
      final fixture = await createPersistenceFixture(
        map: _map(),
        registry: _registry(source: null),
      );
      addTearDown(fixture.dispose);
      final gateway = _RecordingGateway();

      final result = await NarrativeEventSpatialSourceLinkUseCase(
        persistenceGateway: gateway,
      )(
        projectPath: fixture.projectPath,
        eventId: _eventId,
        source: NarrativeEventSourceRef.mapEnter('map_a'),
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );

      expect(result.status, NarrativeEventSpatialSourceLinkStatus.committed);
      expect(result.authoringResult?.mutation.name, 'selectSource');
      expect(gateway.requests, hasLength(1));
    });

    test('replaces a configured disabled source and keeps it disabled',
        () async {
      final fixture = await createPersistenceFixture(
        map: _map(),
        registry: _registry(
          source: NarrativeEventSourceRef.entityInteract(
            'map_a',
            'entity_a',
          ),
          configured: true,
        ),
      );
      addTearDown(fixture.dispose);
      final gateway = _RecordingGateway();

      final result = await NarrativeEventSpatialSourceLinkUseCase(
        persistenceGateway: gateway,
      )(
        projectPath: fixture.projectPath,
        eventId: _eventId,
        source: NarrativeEventSourceRef.triggerEnter('map_a', 'trigger_a'),
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );

      expect(
        result.status,
        NarrativeEventSpatialSourceLinkStatus.committed,
        reason: '${result.code}: ${result.message}',
      );
      expect(result.nextRegistry!.records.single.enabledOrNull, isFalse);
      expect(gateway.requests, hasLength(1));
    });

    test('rejects a nonspatial outcome before preparation and writing',
        () async {
      var prepareCalls = 0;
      final gateway = _RecordingGateway();

      final result = await NarrativeEventSpatialSourceLinkUseCase(
        persistenceGateway: gateway,
        prepareSession: (_) async {
          prepareCalls++;
          throw StateError('must not prepare');
        },
      )(
        projectPath: '/unused/project.json',
        eventId: _eventId,
        source: NarrativeEventSourceRef.outcomeReceived(
          NarrativeOutcomeRef(
            producerKind: NarrativeOutcomeProducerKind.scene,
            producerId: 'scene_a',
            outcomeId: 'done',
          ),
        ),
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );

      expect(result.status, NarrativeEventSpatialSourceLinkStatus.rejected);
      expect(result.code, 'nonSpatialSource');
      expect(prepareCalls, 0);
      expect(gateway.requests, isEmpty);
    });

    test('dirty and saving gates run before session preparation', () async {
      for (final flags in <(bool, bool, bool)>[
        (true, false, false),
        (false, true, false),
        (false, false, true),
      ]) {
        var prepareCalls = 0;
        final gateway = _RecordingGateway();
        final useCase = NarrativeEventSpatialSourceLinkUseCase(
          persistenceGateway: gateway,
          prepareSession: (_) async {
            prepareCalls++;
            throw StateError('must not prepare');
          },
        );

        final result = await useCase(
          projectPath: '/unused/project.json',
          eventId: _eventId,
          source: NarrativeEventSourceRef.entityInteract('map_a', 'entity_a'),
          mapDirty: flags.$1,
          projectDirty: flags.$2,
          saving: flags.$3,
        );

        expect(result.status, NarrativeEventSpatialSourceLinkStatus.blocked);
        expect(prepareCalls, 0);
        expect(gateway.requests, isEmpty);
      }
    });

    test('enabled Event rejection and stale persistence never double-write',
        () async {
      final enabledFixture = await createPersistenceFixture(
        map: _map(),
        registry: _registry(
          source: NarrativeEventSourceRef.entityInteract(
            'map_a',
            'entity_a',
          ),
          configuredEnabled: true,
        ),
      );
      addTearDown(enabledFixture.dispose);
      final enabledGateway = _RecordingGateway();
      final enabled = await NarrativeEventSpatialSourceLinkUseCase(
        persistenceGateway: enabledGateway,
      )(
        projectPath: enabledFixture.projectPath,
        eventId: _eventId,
        source: NarrativeEventSourceRef.triggerEnter('map_a', 'trigger_a'),
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );
      expect(enabled.status, NarrativeEventSpatialSourceLinkStatus.rejected);
      expect(enabled.code, 'mustDisableFirst');
      expect(enabledGateway.requests, isEmpty);

      final staleFixture = await createPersistenceFixture(
        map: _map(),
        registry: _registry(
          source: NarrativeEventSourceRef.entityInteract(
            'map_a',
            'entity_a',
          ),
        ),
      );
      addTearDown(staleFixture.dispose);
      final staleGateway = _RecordingGateway(
        result: NarrativeEventRegistryPersistenceResult(
          status: NarrativeEventRegistryPersistenceStatus.staleRevision,
          code: 'staleRevision',
          message: 'Stale.',
        ),
      );
      final stale = await NarrativeEventSpatialSourceLinkUseCase(
        persistenceGateway: staleGateway,
      )(
        projectPath: staleFixture.projectPath,
        eventId: _eventId,
        source: NarrativeEventSourceRef.triggerEnter('map_a', 'trigger_a'),
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );
      expect(stale.status, NarrativeEventSpatialSourceLinkStatus.rejected);
      expect(stale.code, 'staleRevision');
      expect(staleGateway.requests, hasLength(1));
    });
  });
}

NarrativeEventRegistry _registry({
  required NarrativeEventSourceRef? source,
  bool configured = false,
  bool configuredEnabled = false,
}) {
  final record = configured || configuredEnabled
      ? NarrativeEventRecord.configuredStructurallyUnchecked(
          NarrativeEventDefinition(
            id: _eventId,
            name: 'Event',
            source: source!,
            conditions: const [],
            sceneId: 'scene_a',
            reusePolicy: NarrativeEventReusePolicy.oneShot,
            priority: 0,
            order: 0,
          ),
          enabled: configuredEnabled,
        )
      : NarrativeEventRecord.draft(
          NarrativeEventDraft(
            id: _eventId,
            name: 'Event',
            source: source,
            conditions: const [],
            priority: 0,
            order: 0,
          ),
        );
  return NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.dualRead,
    records: [record],
    legacyClaims: const [],
  );
}

MapData _map() => const MapData(
      id: 'map_a',
      name: 'Map A',
      size: GridSize(width: 10, height: 8),
      layers: [ObjectLayer(id: 'objects', name: 'Objects')],
      entities: [
        MapEntity(
          id: 'entity_a',
          name: 'Entity A',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 2, y: 2),
        ),
      ],
      triggers: [
        MapTrigger(
          id: 'trigger_a',
          name: 'Trigger A',
          type: TriggerType.event,
          area: MapRect(
            pos: GridPos(x: 4, y: 3),
            size: GridSize(width: 2, height: 1),
          ),
        ),
      ],
    );

final class _RecordingGateway
    implements NarrativeEventRegistryPersistenceGateway {
  _RecordingGateway({NarrativeEventRegistryPersistenceResult? result})
      : result = result ??
            NarrativeEventRegistryPersistenceResult(
              status: NarrativeEventRegistryPersistenceStatus.committed,
              code: 'committed',
              message: 'Committed.',
            );

  final NarrativeEventRegistryPersistenceResult result;
  final List<NarrativeEventRegistryWriteRequest> requests = [];

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) async {
    requests.add(request);
    return result;
  }

  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) {
    throw UnimplementedError();
  }
}
