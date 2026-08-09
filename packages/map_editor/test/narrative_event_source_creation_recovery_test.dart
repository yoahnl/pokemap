import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import './support/riverpod_notifier_harness.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:map_editor/src/application/models/narrative_event_map_bridge_models.dart';
import 'package:map_editor/src/application/models/narrative_event_registry_persistence_models.dart';
import 'package:map_editor/src/application/models/narrative_event_spatial_link_journal_models.dart';
import 'package:map_editor/src/application/models/narrative_event_spatial_source_creation_models.dart';
import 'package:map_editor/src/application/ports/narrative_event_registry_persistence_gateway.dart';
import 'package:map_editor/src/application/ports/narrative_event_spatial_source_creation_gateway.dart';
import 'package:map_editor/src/application/use_cases/create_narrative_event_from_map_source_use_case.dart';
import 'package:map_editor/src/application/use_cases/narrative_event_explicit_source_creation_use_case.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_event_registry_persistence.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_event_spatial_link_journal_repository.dart';
import 'package:path/path.dart' as p;

import 'support/event_registry_persistence_fixtures.dart';

const _eventId = 'evt_019abcde-0000-7000-8000-000000000351';
const _eventBId = 'evt_019abcde-0000-7000-8000-000000000352';

void main() {
  group('NS-EVENT-V2-25 explicit source orchestration', () {
    test('dirty and saving gates run before every durable gateway', () async {
      for (final gates in [
        (mapDirty: true, projectDirty: false, saving: false, code: 'mapDirty'),
        (
          mapDirty: false,
          projectDirty: true,
          saving: false,
          code: 'projectDirty',
        ),
        (
          mapDirty: false,
          projectDirty: false,
          saving: true,
          code: 'saveInProgress',
        ),
      ]) {
        final sourceGateway = _RecordingSourceGateway();
        final registryGateway = _NeverRegistryGateway();
        final useCase = NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: sourceGateway,
          registryGateway: registryGateway,
        );

        final result = await useCase.createAndLink(
          projectPath: '/project/project.json',
          eventId: _eventId,
          proposal: _proposal(),
          mapDirty: gates.mapDirty,
          projectDirty: gates.projectDirty,
          saving: gates.saving,
        );

        expect(
          result.status,
          NarrativeEventExplicitSourceCreationStatus.blocked,
        );
        expect(result.code, gates.code);
        expect(sourceGateway.commitRequests, isEmpty);
        expect(registryGateway.calls, 0);
      }
    });

    test(
      'rejects a forged proposal before any gateway or project read',
      () async {
        final valid = _proposal();
        final forged = NarrativeEventCreatedSourceProposal(
          physicalKind: valid.physicalKind,
          source: valid.source,
          beforeMap: valid.beforeMap,
          afterMap: valid.afterMap,
          bounds: valid.bounds,
          ownerJson: {...valid.ownerJson, 'sourceId': 'another_owner'},
        );
        final sourceGateway = _RecordingSourceGateway();
        final registryGateway = _NeverRegistryGateway();
        final useCase = NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: sourceGateway,
          registryGateway: registryGateway,
        );

        final result = await useCase.createAndLink(
          projectPath: '/project/does-not-exist.json',
          eventId: _eventId,
          proposal: forged,
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );

        expect(
          result.status,
          NarrativeEventExplicitSourceCreationStatus.rejected,
        );
        expect(result.code, 'invalidProposal');
        expect(sourceGateway.commitRequests, isEmpty);
        expect(registryGateway.calls, 0);
      },
    );

    test(
      'accepts an exact proposal when the map has an existing trigger',
      () async {
        const existingTrigger = MapTrigger(
          id: 'existing_trigger',
          name: 'Existing trigger',
          type: TriggerType.custom,
          area: MapRect(
            pos: GridPos(x: 0, y: 0),
            size: GridSize(width: 2, height: 1),
          ),
        );
        final proposal = _proposal(
          beforeMap: const MapData(
            id: 'map_a',
            name: 'Map A',
            size: GridSize(width: 8, height: 6),
            triggers: [existingTrigger],
          ),
        );
        final fixture = await createPersistenceFixture(
          registry: persistenceRegistry(
            records: [persistenceDraft(id: _eventId)],
          ),
          map: proposal.beforeMap,
        );
        addTearDown(fixture.dispose);
        final sourceGateway = _RecordingSourceGateway(
          delegate: NarrativeEventSpatialLinkJournalRepository(),
        );
        final useCase = NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: sourceGateway,
          registryGateway: _RecordingRegistryGateway(
            delegate: FileProjectRepository(),
            steps: <String>[],
          ),
          operationIdFactory: () => 'existing_trigger_source',
        );

        final result = await useCase.createAndLink(
          projectPath: fixture.projectPath,
          eventId: _eventId,
          proposal: proposal,
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );

        expect(
          result.status,
          NarrativeEventExplicitSourceCreationStatus.committed,
        );
        final diskMap = MapData.fromJson(
          Map<String, dynamic>.from(
            decodeNarrativeEventJsonStrict(
                  await File(fixture.session.mapPaths['map_a']!).readAsString(),
                )
                as Map,
          ),
        );
        expect(diskMap.triggers, [existingTrigger]);
        expect(diskMap.entities.single.id, 'sign');
      },
    );

    test(
      'commits map then one fresh Event write and finalizes the journal',
      () async {
        final proposal = _proposal();
        final fixture = await createPersistenceFixture(
          registry: persistenceRegistry(
            records: [persistenceDraft(id: _eventId)],
          ),
          map: proposal.beforeMap,
        );
        addTearDown(fixture.dispose);
        final steps = <String>[];
        final sourceGateway = _RecordingSourceGateway(
          delegate: NarrativeEventSpatialLinkJournalRepository(),
          steps: steps,
        );
        final registryGateway = _RecordingRegistryGateway(
          delegate: FileProjectRepository(),
          steps: steps,
        );
        final useCase = NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: sourceGateway,
          registryGateway: registryGateway,
          operationIdFactory: () => 'explicit_source_test',
        );

        final result = await useCase.createAndLink(
          projectPath: fixture.projectPath,
          eventId: _eventId,
          proposal: proposal,
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );

        expect(
          result.status,
          NarrativeEventExplicitSourceCreationStatus.committed,
        );
        expect(steps, ['map', 'registry', 'finalize']);
        expect(sourceGateway.commitRequests, hasLength(1));
        expect(
          sourceGateway.commitRequests.single.eventRecordFingerprintBefore,
          narrativeEventRecordCanonicalFingerprint(
            persistenceDraft(id: _eventId),
          ),
        );
        expect(registryGateway.persistRequests, hasLength(1));
        expect(result.previousRegistry, isNotNull);
        expect(result.nextRegistry, isNotNull);
        expect(
          result.nextRegistry!.records.single.draftOrNull!.source,
          proposal.source,
        );
        final diskMap = MapData.fromJson(
          Map<String, dynamic>.from(
            decodeNarrativeEventJsonStrict(
                  await File(fixture.session.mapPaths['map_a']!).readAsString(),
                )
                as Map,
          ),
        );
        expect(diskMap.entities.single.id, 'sign');
        expect(
          (await sourceGateway.inspectProject(fixture.projectPath)).status,
          NarrativeEventSpatialLinkInspectionStatus.eventAlreadyLinked,
        );
        expect(await File(result.journal!.journalPath).exists(), isTrue);

        final acknowledged = await useCase.acknowledge(
          projectPath: fixture.projectPath,
          operationId: result.journal!.operationId,
          expectedEventId: _eventId,
          expectedMapId: 'map_a',
        );

        expect(
          acknowledged.status,
          NarrativeEventExplicitSourceCreationStatus.committed,
        );
        expect(acknowledged.code, 'eventCommitAcknowledged');
        expect(
          (await sourceGateway.inspectProject(fixture.projectPath)).status,
          NarrativeEventSpatialLinkInspectionStatus.clear,
        );
      },
    );

    test(
      'registry failure after map commit is explicit and retry never rewrites the map',
      () async {
        final proposal = _proposal();
        final fixture = await createPersistenceFixture(
          registry: persistenceRegistry(
            records: [persistenceDraft(id: _eventId)],
          ),
          map: proposal.beforeMap,
        );
        addTearDown(fixture.dispose);
        final mapFile = File(fixture.session.mapPaths['map_a']!);
        final beforeMapHash = narrativeEventBytesFingerprint(
          await mapFile.readAsBytes(),
        );
        final beforeManifestHash = narrativeEventBytesFingerprint(
          await fixture.readBytes(),
        );
        final firstSource = _RecordingSourceGateway(
          delegate: NarrativeEventSpatialLinkJournalRepository(),
        );
        final crashingRegistry = _RecordingRegistryGateway(
          delegate: FileProjectRepository(
            eventRegistryPersistence: NarrativeEventRegistryPersistence(
              faultInjector: (checkpoint) async {
                if (checkpoint ==
                    NarrativeEventRegistryWriteCheckpoint
                        .afterJournalPrepared) {
                  throw const FileSystemException('simulated registry crash');
                }
              },
            ),
          ),
          steps: <String>[],
        );
        final first = NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: firstSource,
          registryGateway: crashingRegistry,
          operationIdFactory: () => 'explicit_source_retry',
        );

        final interrupted = await first.createAndLink(
          projectPath: fixture.projectPath,
          eventId: _eventId,
          proposal: proposal,
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );

        expect(
          interrupted.status,
          NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
        );
        expect(
          interrupted.journal?.state,
          NarrativeEventSpatialLinkJournalState.mapCommitted,
        );
        expect(firstSource.commitRequests, hasLength(1));
        expect(
          (await firstSource.inspectProject(fixture.projectPath)).status,
          NarrativeEventSpatialLinkInspectionStatus.blocked,
        );
        final sourceBytesAfterFirst = await mapFile.readAsBytes();
        final afterMapCommitHash = narrativeEventBytesFingerprint(
          sourceBytesAfterFirst,
        );
        final afterMapCommitManifestHash = narrativeEventBytesFingerprint(
          await fixture.readBytes(),
        );
        expect(afterMapCommitHash, isNot(beforeMapHash));
        expect(afterMapCommitManifestHash, beforeManifestHash);

        final retrySource = _RecordingSourceGateway(
          delegate: NarrativeEventSpatialLinkJournalRepository(),
        );
        final retryRegistry = _RecordingRegistryGateway(
          delegate: FileProjectRepository(),
          steps: <String>[],
        );
        final restarted = NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: retrySource,
          registryGateway: retryRegistry,
        );
        final retried = await restarted.retry(
          projectPath: fixture.projectPath,
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );

        expect(
          retried.status,
          NarrativeEventExplicitSourceCreationStatus.committed,
        );
        expect(
          retried.journal?.state,
          NarrativeEventSpatialLinkJournalState.eventCommitted,
        );
        expect(retrySource.commitRequests, isEmpty);
        expect(retryRegistry.recoverCalls, 1);
        expect(retryRegistry.persistRequests, hasLength(1));
        expect(await mapFile.readAsBytes(), sourceBytesAfterFirst);
        final afterRetryMapHash = narrativeEventBytesFingerprint(
          await mapFile.readAsBytes(),
        );
        final afterRetryManifestHash = narrativeEventBytesFingerprint(
          await fixture.readBytes(),
        );
        expect(afterRetryMapHash, afterMapCommitHash);
        expect(afterRetryManifestHash, isNot(beforeManifestHash));
        expect(
          retried.nextRegistry!.records.single.draftOrNull!.source,
          proposal.source,
        );
        expect(
          (await retrySource.inspectProject(fixture.projectPath)).status,
          NarrativeEventSpatialLinkInspectionStatus.eventAlreadyLinked,
        );
        final acknowledged = await restarted.acknowledge(
          projectPath: fixture.projectPath,
          operationId: retried.journal!.operationId,
          expectedEventId: _eventId,
          expectedMapId: 'map_a',
        );
        expect(
          acknowledged.status,
          NarrativeEventExplicitSourceCreationStatus.committed,
        );
        expect(
          (await retrySource.inspectProject(fixture.projectPath)).status,
          NarrativeEventSpatialLinkInspectionStatus.clear,
        );
        // Machine-readable closure evidence for the V2-25 two-commit trace.
        // The hashes prove map-first persistence and a retry that never rewrites
        // the already committed physical source.
        // ignore: avoid_print
        print(
          'PHASE_G_RETRY_HASH_TRACE ${jsonEncode({
            'before': {'map': beforeMapHash, 'manifest': beforeManifestHash, 'journal': 'absent'},
            'afterMapCommit': {'map': afterMapCommitHash, 'manifest': afterMapCommitManifestHash, 'journal': interrupted.journal!.state.name},
            'afterRetry': {'map': afterRetryMapHash, 'manifest': afterRetryManifestHash, 'journal': retried.journal!.state.name},
            'afterAcknowledge': {'journal': 'clear'},
          })}',
        );
      },
    );

    test(
      'retry contains an exception while finalizing an already linked Event',
      () async {
        final proposal = _proposal();
        final fixture = await createPersistenceFixture(
          registry: persistenceRegistry(
            records: [persistenceDraft(id: _eventId)],
          ),
          map: proposal.beforeMap,
        );
        addTearDown(fixture.dispose);
        final firstSource = _RecordingSourceGateway(
          delegate: NarrativeEventSpatialLinkJournalRepository(),
          finalizeError: const FileSystemException('simulated finalize outage'),
        );
        final first = NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: firstSource,
          registryGateway: _RecordingRegistryGateway(
            delegate: FileProjectRepository(),
            steps: <String>[],
          ),
          operationIdFactory: () => 'already_linked_finalize_exception',
        );
        final interrupted = await first.createAndLink(
          projectPath: fixture.projectPath,
          eventId: _eventId,
          proposal: proposal,
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );
        expect(interrupted.code, 'journalFinalizeException');

        final restarted = NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: _RecordingSourceGateway(
            delegate: NarrativeEventSpatialLinkJournalRepository(),
            finalizeError: const FileSystemException(
              'simulated retry finalize outage',
            ),
          ),
          registryGateway: _RecordingRegistryGateway(
            delegate: FileProjectRepository(),
            steps: <String>[],
          ),
        );

        final retried = await restarted.retry(
          projectPath: fixture.projectPath,
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );

        expect(
          retried.status,
          NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
        );
        expect(retried.code, 'journalFinalizeException');
        expect(retried.journal?.eventId, _eventId);
      },
    );

    test(
      'retry contains an exception during post-recovery reinspection',
      () async {
        final proposal = _proposal();
        final fixture = await createPersistenceFixture(
          registry: persistenceRegistry(
            records: [persistenceDraft(id: _eventId)],
          ),
          map: proposal.beforeMap,
        );
        addTearDown(fixture.dispose);
        final crashingSource = _RecordingSourceGateway(
          delegate: NarrativeEventSpatialLinkJournalRepository(
            faultInjector: (checkpoint) async {
              if (checkpoint ==
                  NarrativeEventSpatialLinkCheckpoint.afterMapRename) {
                throw const FileSystemException('simulated map commit crash');
              }
            },
          ),
        );
        final first = NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: crashingSource,
          registryGateway: _NeverRegistryGateway(),
          operationIdFactory: () => 'post_recovery_reinspection',
        );
        final interrupted = await first.createAndLink(
          projectPath: fixture.projectPath,
          eventId: _eventId,
          proposal: proposal,
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );
        expect(
          interrupted.inspection?.status,
          NarrativeEventSpatialLinkInspectionStatus.preparedSourcePresent,
        );

        final restarted = NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: _RecordingSourceGateway(
            delegate: NarrativeEventSpatialLinkJournalRepository(),
            throwOnInspectCall: 2,
            inspectError: const FileSystemException(
              'simulated reinspection outage',
            ),
          ),
          registryGateway: _RecordingRegistryGateway(
            delegate: FileProjectRepository(),
            steps: <String>[],
          ),
        );

        final retried = await restarted.retry(
          projectPath: fixture.projectPath,
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );

        expect(
          retried.status,
          NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
        );
        expect(retried.code, 'sourceReinspectionException');
        expect(retried.journal?.eventId, _eventId);
      },
    );

    test(
      'refuses retry linkage when the Event changed after map commit',
      () async {
        final proposal = _proposal();
        final fixture = await createPersistenceFixture(
          registry: persistenceRegistry(
            records: [persistenceDraft(id: _eventId)],
          ),
          map: proposal.beforeMap,
        );
        addTearDown(fixture.dispose);
        final sourceGateway = _RecordingSourceGateway(
          delegate: NarrativeEventSpatialLinkJournalRepository(),
          afterCommit: (_) async {
            final root = await fixture.readRoot();
            root['eventRegistry'] = persistenceRegistry(
              records: [
                persistenceDraft(id: _eventId, name: 'Changed elsewhere'),
              ],
            ).toJson();
            await File(fixture.projectPath).writeAsBytes(
              canonicalizeNarrativeEventJsonUtf8(root),
              flush: true,
            );
          },
        );
        final registryGateway = _NeverRegistryGateway();
        final useCase = NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: sourceGateway,
          registryGateway: registryGateway,
          operationIdFactory: () => 'explicit_source_event_changed',
        );

        final result = await useCase.createAndLink(
          projectPath: fixture.projectPath,
          eventId: _eventId,
          proposal: proposal,
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );

        expect(
          result.status,
          NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
        );
        expect(result.code, 'eventModified');
        expect(registryGateway.calls, 0);
        expect(
          (await sourceGateway.inspectProject(
            fixture.projectPath,
          )).issues.single.code,
          'eventRecordChanged',
        );
      },
    );

    test(
      'map mutation immediately before registry persist is attested and writes no Event link',
      () async {
        final proposal = _proposal();
        final registry = persistenceRegistry(
          records: [persistenceDraft(id: _eventId)],
        );
        final fixture = await createPersistenceFixture(
          registry: registry,
          map: proposal.beforeMap,
        );
        addTearDown(fixture.dispose);
        final sourceGateway = _RecordingSourceGateway(
          delegate: NarrativeEventSpatialLinkJournalRepository(),
        );
        final mapPath = fixture.session.mapPaths['map_a']!;
        final registryGateway = _RecordingRegistryGateway(
          delegate: FileProjectRepository(),
          steps: <String>[],
          beforePersist: (_) async {
            await File(mapPath).writeAsBytes(
              canonicalizeNarrativeEventJsonUtf8(proposal.beforeMap.toJson()),
              flush: true,
            );
          },
        );
        final useCase = NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: sourceGateway,
          registryGateway: registryGateway,
          operationIdFactory: () => 'explicit_source_stale_map_attestation',
        );

        final result = await useCase.createAndLink(
          projectPath: fixture.projectPath,
          eventId: _eventId,
          proposal: proposal,
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );

        expect(
          result.status,
          NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
        );
        expect(result.code, 'staleMapRevision');
        expect(
          result.persistenceResult?.status,
          NarrativeEventRegistryPersistenceStatus.staleAuthoringSnapshot,
        );
        expect(result.persistenceResult?.code, 'staleMapRevision');
        expect(registryGateway.persistRequests, hasLength(1));
        expect(sourceGateway.steps, ['map']);
        final diskProject = decodeValidatedNarrativeEventAuthoringProject(
          await fixture.readBytes(),
        ).manifest;
        final diskRecord = diskProject.eventRegistry!.records.singleWhere(
          (candidate) => candidate.id == _eventId,
        );
        expect(diskRecord.draftOrNull?.source, isNull);
      },
    );

    test(
      'cleanup requires a second confirmation and removes only pending owner',
      () async {
        final proposal = _proposal();
        final fixture = await createPersistenceFixture(
          registry: persistenceRegistry(
            records: [persistenceDraft(id: _eventId)],
          ),
          map: proposal.beforeMap,
        );
        addTearDown(fixture.dispose);
        final mapFile = File(fixture.session.mapPaths['map_a']!);
        final beforeMapHash = narrativeEventBytesFingerprint(
          await mapFile.readAsBytes(),
        );
        final beforeManifestHash = narrativeEventBytesFingerprint(
          await fixture.readBytes(),
        );
        final sourceGateway = _RecordingSourceGateway(
          delegate: NarrativeEventSpatialLinkJournalRepository(),
        );
        final useCase = NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: sourceGateway,
          registryGateway: _NeverRegistryGateway(),
          operationIdFactory: () => 'explicit_source_cleanup',
        );
        final interrupted = await useCase.createAndLink(
          projectPath: fixture.projectPath,
          eventId: _eventId,
          proposal: proposal,
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );
        expect(
          interrupted.status,
          NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
        );
        expect(
          interrupted.journal?.state,
          NarrativeEventSpatialLinkJournalState.mapCommitted,
        );
        final afterMapCommitHash = narrativeEventBytesFingerprint(
          await mapFile.readAsBytes(),
        );
        final afterMapCommitManifestHash = narrativeEventBytesFingerprint(
          await fixture.readBytes(),
        );
        expect(afterMapCommitHash, isNot(beforeMapHash));
        expect(afterMapCommitManifestHash, beforeManifestHash);
        expect(
          (await sourceGateway.inspectProject(fixture.projectPath)).status,
          NarrativeEventSpatialLinkInspectionStatus.awaitingEventCommit,
        );

        final notConfirmed = await useCase.cleanup(
          projectPath: fixture.projectPath,
          operationId: 'explicit_source_cleanup',
          confirmed: false,
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );
        expect(notConfirmed.code, 'confirmationRequired');
        expect(sourceGateway.cleanupCalls, 0);

        final cleaned = await useCase.cleanup(
          projectPath: fixture.projectPath,
          operationId: 'explicit_source_cleanup',
          confirmed: true,
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );
        expect(
          cleaned.status,
          NarrativeEventExplicitSourceCreationStatus.cleaned,
        );
        expect(sourceGateway.cleanupCalls, 1);
        final afterCleanupMapHash = narrativeEventBytesFingerprint(
          await mapFile.readAsBytes(),
        );
        final afterCleanupManifestHash = narrativeEventBytesFingerprint(
          await fixture.readBytes(),
        );
        expect(afterCleanupMapHash, isNot(afterMapCommitHash));
        expect(afterCleanupManifestHash, beforeManifestHash);
        final diskMap = MapData.fromJson(
          Map<String, dynamic>.from(
            decodeNarrativeEventJsonStrict(await mapFile.readAsString()) as Map,
          ),
        );
        expect(diskMap, proposal.beforeMap);
        expect(diskMap.entities, isEmpty);
        expect(
          (await sourceGateway.inspectProject(fixture.projectPath)).status,
          NarrativeEventSpatialLinkInspectionStatus.clear,
        );
        // Machine-readable closure evidence for the confirmed cleanup rollback
        // of the exact physical owner. The map is reserialized by cleanup, so
        // semantic restoration is asserted above instead of byte identity.
        // ignore: avoid_print
        print(
          'PHASE_G_CLEANUP_HASH_TRACE ${jsonEncode({
            'before': {'map': beforeMapHash, 'manifest': beforeManifestHash, 'journal': 'absent'},
            'afterMapCommit': {'map': afterMapCommitHash, 'manifest': afterMapCommitManifestHash, 'journal': interrupted.journal!.state.name},
            'afterCleanup': {'map': afterCleanupMapHash, 'manifest': afterCleanupManifestHash, 'journal': 'clear', 'entities': diskMap.entities.length},
          })}',
        );
      },
    );

    test(
      'successful disk cleanup remains blocking when the cleaned map cannot be adopted in memory',
      () async {
        final proposal = _proposal();
        final registry = persistenceRegistry(
          records: [persistenceDraft(id: _eventId)],
        );
        final fixture = await createPersistenceFixture(
          registry: registry,
          map: proposal.beforeMap,
        );
        addTearDown(fixture.dispose);
        final repository = NarrativeEventSpatialLinkJournalRepository();
        final sourceGateway = _RecordingSourceGateway(delegate: repository);
        final interrupted =
            await NarrativeEventExplicitSourceCreationUseCase(
              sourceGateway: sourceGateway,
              registryGateway: _NeverRegistryGateway(),
              operationIdFactory: () => 'cleanup_adoption_failure',
            ).createAndLink(
              projectPath: fixture.projectPath,
              eventId: _eventId,
              proposal: proposal,
              mapDirty: false,
              projectDirty: false,
              saving: false,
            );
        expect(
          interrupted.status,
          NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
        );
        final registryGateway = _CountingClearRegistryGateway();
        final project = ProjectManifest(
          name: 'Cleanup adoption failure project',
          maps: const [
            ProjectMapEntry(
              id: 'map_a',
              name: 'Map A',
              relativePath: 'maps/map_a.json',
            ),
          ],
          tilesets: const [],
          scenes: const [],
          eventRegistry: registry,
        );
        final controller = mountNarrativeEventMapBridgeController(
          useCase: CreateNarrativeEventFromMapSourceUseCase(
            persistenceGateway: registryGateway,
          ),
          explicitSourceCreationUseCase:
              NarrativeEventExplicitSourceCreationUseCase(
                sourceGateway: sourceGateway,
                registryGateway: registryGateway,
              ),
        );
        final projectRoot = p.dirname(fixture.projectPath);
        controller.bindProjectRootPath(projectRoot);
        await controller.openMapForMissingSource(
          eventId: _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
          project: project,
          activeMap: proposal.afterMap,
          mapDirty: false,
          loadMapSnapshot: (_) async => null,
          activateMapSnapshot: (_) => true,
        );
        await controller.inspectPendingSourceCreation(
          projectRootPath: projectRoot,
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );
        expect(controller.requestSourceCleanupConfirmation(), isTrue);
        var adoptionAttempts = 0;

        final result = await controller.cleanupCreatedSource(
          projectRootPath: projectRoot,
          activeMap: proposal.afterMap,
          mapDirty: false,
          projectDirty: false,
          saving: false,
          beginCleanupInterlock:
              ({
                required expectedProjectRootPath,
                required expectedActiveMap,
                required journal,
              }) => true,
          releaseCleanupInterlock:
              ({required expectedProjectRootPath, required journal}) {},
          adoptPersistedCleanup:
              ({
                required expectedProjectRootPath,
                required expectedActiveMap,
                required journal,
              }) async {
                adoptionAttempts++;
                return false;
              },
        );

        expect(
          result?.status,
          NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
        );
        expect(result?.code, 'cleanedMapOutOfSync');
        expect(result?.journal?.source, proposal.source);
        expect(
          controller.state.lastSourceCreationResult?.code,
          'cleanedMapOutOfSync',
        );
        expect(adoptionAttempts, 1);
        expect(controller.state.isSourceCreationBusy, isFalse);
        final pendingReturn = controller.state.pendingReturn;
        controller.cancelMapNavigation();
        expect(controller.state.pendingReturn, same(pendingReturn));
        final diskMap = MapData.fromJson(
          Map<String, dynamic>.from(
            decodeNarrativeEventJsonStrict(
                  await File(fixture.session.mapPaths['map_a']!).readAsString(),
                )
                as Map,
          ),
        );
        expect(diskMap.entities, isEmpty);
        expect(
          controller.completeSourceCleanupReload(
            projectRootPath: projectRoot,
            activeMap: diskMap,
          ),
          isTrue,
        );
        expect(
          controller.state.lastSourceCreationResult?.status,
          NarrativeEventExplicitSourceCreationStatus.cleaned,
        );
        controller.cancelMapNavigation();
        expect(controller.state.pendingReturn, isNull);
      },
    );

    test('bridge rejects a pending journal for another Event or map', () async {
      final project = _recoveryProject();
      const mapA = MapData(
        id: 'map_a',
        name: 'Map A',
        size: GridSize(width: 8, height: 6),
      );
      for (final journal in [
        _pendingJournal(eventId: _eventBId, mapId: 'map_a'),
        _pendingJournal(eventId: _eventId, mapId: 'map_b'),
      ]) {
        final sourceGateway = _PendingJournalSourceGateway(journal);
        final registryGateway = _CountingClearRegistryGateway();
        final controller = mountNarrativeEventMapBridgeController(
          useCase: CreateNarrativeEventFromMapSourceUseCase(
            persistenceGateway: registryGateway,
          ),
          explicitSourceCreationUseCase:
              NarrativeEventExplicitSourceCreationUseCase(
                sourceGateway: sourceGateway,
                registryGateway: registryGateway,
              ),
        );
        controller.bindProjectRootPath('/project');
        expect(
          controller.selectNarrativeEventV2(
            project,
            _eventId,
            groupContext: const NarrativeEventGroupContext.map('map_a'),
          ),
          isTrue,
        );
        final opened = await controller.openMapForMissingSource(
          eventId: _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
          project: project,
          activeMap: mapA,
          mapDirty: false,
          loadMapSnapshot: (_) async => null,
          activateMapSnapshot: (_) => true,
        );
        expect(opened.succeeded, isTrue);

        final inspected = await controller.inspectPendingSourceCreation(
          projectRootPath: '/project',
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );

        expect(
          inspected?.status,
          NarrativeEventExplicitSourceCreationStatus.rejected,
        );
        expect(inspected?.code, 'pendingJournalMismatch');
        expect(controller.state.lastSourceCreationResult?.journal, isNull);
        expect(controller.requestSourceCleanupConfirmation(), isFalse);
        expect(
          await controller.retrySourceCreation(
            projectRootPath: '/project',
            project: project,
            activeMap: mapA,
            mapDirty: false,
            projectDirty: false,
            saving: false,
            adoptPersistedMap: (_) {
              fail('A mismatched journal must never adopt a map.');
            },
            applyPersistedRegistry:
                ({
                  required expectedProjectRootPath,
                  required expectedPreviousRegistry,
                  required nextRegistry,
                }) {
                  fail('A mismatched journal must never adopt a registry.');
                },
          ),
          isNull,
        );
        expect(
          await controller.cleanupCreatedSource(
            projectRootPath: '/project',
            activeMap: mapA,
            mapDirty: false,
            projectDirty: false,
            saving: false,
            beginCleanupInterlock:
                ({
                  required expectedProjectRootPath,
                  required expectedActiveMap,
                  required journal,
                }) => true,
            releaseCleanupInterlock:
                ({required expectedProjectRootPath, required journal}) {},
            adoptPersistedCleanup:
                ({
                  required expectedProjectRootPath,
                  required expectedActiveMap,
                  required journal,
                }) {
                  fail('A mismatched journal must never adopt a cleanup.');
                },
          ),
          isNull,
        );
        expect(sourceGateway.inspectCalls, 1);
        expect(sourceGateway.recoverCalls, 0);
        expect(sourceGateway.cleanupCalls, 0);
        expect(registryGateway.inspectCalls, 0);
        expect(registryGateway.persistCalls, 0);
      }
    });

    test(
      'bridge exposes recovery only for the exact Event and map token',
      () async {
        final project = _recoveryProject();
        const mapB = MapData(
          id: 'map_b',
          name: 'Map B',
          size: GridSize(width: 8, height: 6),
        );
        final journal = _pendingJournal(eventId: _eventBId, mapId: 'map_b');
        final sourceGateway = _PendingJournalSourceGateway(journal);
        final registryGateway = _CountingClearRegistryGateway();
        final controller = mountNarrativeEventMapBridgeController(
          useCase: CreateNarrativeEventFromMapSourceUseCase(
            persistenceGateway: registryGateway,
          ),
          explicitSourceCreationUseCase:
              NarrativeEventExplicitSourceCreationUseCase(
                sourceGateway: sourceGateway,
                registryGateway: registryGateway,
              ),
        );
        controller.bindProjectRootPath('/project');
        expect(
          controller.selectNarrativeEventV2(
            project,
            _eventBId,
            groupContext: const NarrativeEventGroupContext.map('map_b'),
          ),
          isTrue,
        );
        await controller.openMapForMissingSource(
          eventId: _eventBId,
          groupContext: const NarrativeEventGroupContext.map('map_b'),
          project: project,
          activeMap: mapB,
          mapDirty: false,
          loadMapSnapshot: (_) async => null,
          activateMapSnapshot: (_) => true,
        );

        final inspected = await controller.inspectPendingSourceCreation(
          projectRootPath: '/project',
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );

        expect(
          inspected?.status,
          NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
        );
        expect(inspected?.journal, same(journal));
        expect(controller.state.pendingReturn?.eventId, _eventBId);
        expect(
          controller.state.pendingReturn?.groupContext,
          const NarrativeEventGroupContext.map('map_b'),
        );
        expect(controller.requestSourceCleanupConfirmation(), isTrue);
        expect(controller.cancelSourceCleanupConfirmation(), isTrue);
      },
    );

    test(
      'delayed inspection A never applies to navigation B and B starts its own inspection',
      () async {
        final project = _recoveryProject();
        const mapA = MapData(
          id: 'map_a',
          name: 'Map A',
          size: GridSize(width: 8, height: 6),
        );
        const mapB = MapData(
          id: 'map_b',
          name: 'Map B',
          size: GridSize(width: 8, height: 6),
        );
        final sourceGateway = _DelayedInspectionSourceGateway();
        final registryGateway = _CountingClearRegistryGateway();
        final controller = mountNarrativeEventMapBridgeController(
          useCase: CreateNarrativeEventFromMapSourceUseCase(
            persistenceGateway: registryGateway,
          ),
          explicitSourceCreationUseCase:
              NarrativeEventExplicitSourceCreationUseCase(
                sourceGateway: sourceGateway,
                registryGateway: registryGateway,
              ),
        );
        controller.bindProjectRootPath('/project');
        await controller.openMapForMissingSource(
          eventId: _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
          project: project,
          activeMap: mapA,
          mapDirty: false,
          loadMapSnapshot: (_) async => null,
          activateMapSnapshot: (_) => true,
        );
        final inspectionA = controller.inspectPendingSourceCreation(
          projectRootPath: '/project',
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );
        expect(sourceGateway.inspectCalls, 1);

        await controller.openMapForMissingSource(
          eventId: _eventBId,
          groupContext: const NarrativeEventGroupContext.map('map_b'),
          project: project,
          activeMap: mapA,
          mapDirty: false,
          loadMapSnapshot: (_) async => mapB,
          activateMapSnapshot: (_) => true,
        );
        final inspectionB = controller.inspectPendingSourceCreation(
          projectRootPath: '/project',
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );

        expect(sourceGateway.inspectCalls, 2);
        sourceGateway.complete(
          0,
          _pendingJournal(eventId: _eventId, mapId: 'map_a'),
        );
        await inspectionA;
        expect(controller.state.pendingReturn?.eventId, _eventBId);
        expect(controller.state.pendingReturn?.groupContext.mapId, 'map_b');
        expect(controller.state.lastSourceCreationResult?.journal, isNull);
        expect(controller.state.isSourceCreationBusy, isTrue);

        final journalB = _pendingJournal(eventId: _eventBId, mapId: 'map_b');
        sourceGateway.complete(1, journalB);
        final resultB = await inspectionB;

        expect(resultB?.journal, same(journalB));
        expect(
          controller.state.lastSourceCreationResult?.journal,
          same(journalB),
        );
        expect(controller.state.isSourceCreationBusy, isFalse);
      },
    );

    test(
      'stale inspection after a same-root session rebind releases busy without applying its result',
      () async {
        final project = _recoveryProject();
        const mapA = MapData(
          id: 'map_a',
          name: 'Map A',
          size: GridSize(width: 8, height: 6),
        );
        final sourceGateway = _DelayedInspectionSourceGateway();
        final registryGateway = _CountingClearRegistryGateway();
        final controller = mountNarrativeEventMapBridgeController(
          useCase: CreateNarrativeEventFromMapSourceUseCase(
            persistenceGateway: registryGateway,
          ),
          explicitSourceCreationUseCase:
              NarrativeEventExplicitSourceCreationUseCase(
                sourceGateway: sourceGateway,
                registryGateway: registryGateway,
              ),
        );
        controller.bindProjectSession(
          projectRootPath: '/project',
          project: project,
        );
        await controller.openMapForMissingSource(
          eventId: _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
          project: project,
          activeMap: mapA,
          mapDirty: false,
          loadMapSnapshot: (_) async => null,
          activateMapSnapshot: (_) => true,
        );
        final staleInspection = controller.inspectPendingSourceCreation(
          projectRootPath: '/project',
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );
        expect(sourceGateway.inspectCalls, 1);
        expect(controller.state.isSourceCreationBusy, isTrue);

        controller.bindProjectSession(
          projectRootPath: '/project',
          project: _recoveryProject(),
        );
        final staleJournal = _pendingJournal(eventId: _eventId, mapId: 'map_a');
        sourceGateway.complete(0, staleJournal);
        final staleResult = await staleInspection;

        expect(staleResult?.journal, same(staleJournal));
        expect(controller.state.lastSourceCreationResult, isNull);
        expect(controller.state.isSourceCreationBusy, isFalse);

        final freshInspection = controller.inspectPendingSourceCreation(
          projectRootPath: '/project',
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );
        expect(sourceGateway.inspectCalls, 2);
        sourceGateway.completeClear(1);
        expect(
          (await freshInspection)?.status,
          NarrativeEventExplicitSourceCreationStatus.clear,
        );
        expect(controller.state.isSourceCreationBusy, isFalse);

        controller.cancelMapNavigation();
        expect(controller.state.pendingReturn, isNull);
        expect(controller.state.navigationMode, isNull);
      },
    );

    test(
      'stale inspection cannot release busy owned by a later source mutation',
      () async {
        final proposal = _proposal();
        final registry = persistenceRegistry(
          records: [persistenceDraft(id: _eventId)],
        );
        final fixture = await createPersistenceFixture(
          registry: registry,
          map: proposal.beforeMap,
        );
        addTearDown(fixture.dispose);
        final repository = NarrativeEventSpatialLinkJournalRepository();
        final delayedInspection =
            Completer<NarrativeEventSpatialLinkInspection>();
        final commitStarted = Completer<void>();
        final releaseCommit = Completer<void>();
        final sourceGateway = _RecordingSourceGateway(
          delegate: repository,
          inspectOverride: (projectPath, call) {
            if (call == 1) return delayedInspection.future;
            return repository.inspectProject(projectPath);
          },
          beforeCommit: (_) async {
            commitStarted.complete();
            await releaseCommit.future;
          },
        );
        final registryGateway = _RecordingRegistryGateway(
          delegate: FileProjectRepository(),
          steps: <String>[],
        );
        final project = ProjectManifest(
          name: 'Busy ownership project',
          maps: const [
            ProjectMapEntry(
              id: 'map_a',
              name: 'Map A',
              relativePath: 'maps/map_a.json',
            ),
          ],
          tilesets: const [],
          scenes: const [],
          eventRegistry: registry,
        );
        final controller = mountNarrativeEventMapBridgeController(
          useCase: CreateNarrativeEventFromMapSourceUseCase(
            persistenceGateway: registryGateway,
          ),
          explicitSourceCreationUseCase:
              NarrativeEventExplicitSourceCreationUseCase(
                sourceGateway: sourceGateway,
                registryGateway: registryGateway,
                operationIdFactory: () => 'busy_owner_mutation',
              ),
        );
        final projectRoot = p.dirname(fixture.projectPath);
        controller.bindProjectSession(
          projectRootPath: projectRoot,
          project: project,
        );
        await controller.openMapForMissingSource(
          eventId: _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
          project: project,
          activeMap: proposal.beforeMap,
          mapDirty: false,
          loadMapSnapshot: (_) async => null,
          activateMapSnapshot: (_) => true,
        );
        expect(
          controller.selectPhysicalSourceKind(proposal.physicalKind),
          isTrue,
        );
        expect(controller.previewSourceCreationProposal(proposal), isTrue);
        final staleInspection = controller.inspectPendingSourceCreation(
          projectRootPath: projectRoot,
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );
        expect(controller.state.isSourceCreationBusy, isTrue);

        controller.bindProjectSession(
          projectRootPath: projectRoot,
          project: ProjectManifest.fromJson(project.toJson()),
        );
        final freshInspection = controller.inspectPendingSourceCreation(
          projectRootPath: projectRoot,
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );
        expect(
          (await freshInspection)?.status,
          NarrativeEventExplicitSourceCreationStatus.clear,
        );
        expect(controller.state.isSourceCreationBusy, isFalse);

        final confirmation = controller.confirmSourceCreation(
          projectRootPath: projectRoot,
          project: project,
          mapDirty: false,
          projectDirty: false,
          saving: false,
          adoptPersistedMap: (_) => true,
          applyPersistedRegistry:
              ({
                required expectedProjectRootPath,
                required expectedPreviousRegistry,
                required nextRegistry,
              }) => true,
        );
        await commitStarted.future;
        expect(controller.state.isSourceCreationBusy, isTrue);

        delayedInspection.complete(
          NarrativeEventSpatialLinkInspection(
            status: NarrativeEventSpatialLinkInspectionStatus.clear,
          ),
        );
        await staleInspection;
        expect(controller.state.lastSourceCreationResult, isNull);
        expect(controller.state.isSourceCreationBusy, isTrue);

        releaseCommit.complete();
        expect(
          (await confirmation)?.status,
          NarrativeEventExplicitSourceCreationStatus.committed,
        );
        expect(controller.state.isSourceCreationBusy, isFalse);
      },
    );

    test(
      'delayed acknowledgement never injects Event A state after navigation switched to Event B',
      () async {
        final proposal = _proposal();
        final recordA = persistenceDraft(id: _eventId);
        final registryA = persistenceRegistry(records: [recordA]);
        final fixture = await createPersistenceFixture(
          registry: registryA,
          map: proposal.beforeMap,
        );
        addTearDown(fixture.dispose);
        final repository = NarrativeEventSpatialLinkJournalRepository();
        final acknowledgementStarted = Completer<void>();
        final releaseAcknowledgement = Completer<void>();
        final sourceGateway = _RecordingSourceGateway(
          delegate: repository,
          beforeAcknowledge: () async {
            acknowledgementStarted.complete();
            await releaseAcknowledgement.future;
          },
        );
        final registryGateway = _RecordingRegistryGateway(
          delegate: FileProjectRepository(),
          steps: <String>[],
        );
        final projectA = ProjectManifest(
          name: 'Acknowledgement project A',
          maps: const [
            ProjectMapEntry(
              id: 'map_a',
              name: 'Map A',
              relativePath: 'maps/map_a.json',
            ),
          ],
          tilesets: const [],
          scenes: const [],
          eventRegistry: registryA,
        );
        final projectB = ProjectManifest(
          name: 'Acknowledgement project B',
          maps: projectA.maps,
          tilesets: const [],
          scenes: const [],
          eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.dualRead,
            records: [
              recordA,
              NarrativeEventRecord.draft(
                NarrativeEventDraft(
                  id: _eventBId,
                  name: 'Event B',
                  conditions: const [],
                  priority: 0,
                  order: 1,
                ),
              ),
            ],
            legacyClaims: const [],
          ),
        );
        final controller = mountNarrativeEventMapBridgeController(
          useCase: CreateNarrativeEventFromMapSourceUseCase(
            persistenceGateway: registryGateway,
          ),
          explicitSourceCreationUseCase:
              NarrativeEventExplicitSourceCreationUseCase(
                sourceGateway: sourceGateway,
                registryGateway: registryGateway,
                operationIdFactory: () => 'delayed_ack_operation_a',
              ),
        );
        final projectRoot = p.dirname(fixture.projectPath);
        controller.bindProjectSession(
          projectRootPath: projectRoot,
          project: projectA,
        );
        await controller.openMapForMissingSource(
          eventId: _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
          project: projectA,
          activeMap: proposal.beforeMap,
          mapDirty: false,
          loadMapSnapshot: (_) async => null,
          activateMapSnapshot: (_) => true,
        );
        expect(
          controller.selectPhysicalSourceKind(proposal.physicalKind),
          isTrue,
        );
        expect(controller.previewSourceCreationProposal(proposal), isTrue);

        final confirmation = controller.confirmSourceCreation(
          projectRootPath: projectRoot,
          project: projectA,
          mapDirty: false,
          projectDirty: false,
          saving: false,
          adoptPersistedMap: (_) => true,
          applyPersistedRegistry:
              ({
                required expectedProjectRootPath,
                required expectedPreviousRegistry,
                required nextRegistry,
              }) => true,
        );
        await acknowledgementStarted.future;
        expect(controller.state.isSourceCreationBusy, isTrue);

        controller.bindProjectSession(
          projectRootPath: projectRoot,
          project: projectB,
        );
        await controller.openMapForMissingSource(
          eventId: _eventBId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
          project: projectB,
          activeMap: proposal.afterMap,
          mapDirty: false,
          loadMapSnapshot: (_) async => null,
          activateMapSnapshot: (_) => true,
        );
        final tokenB = controller.state.pendingReturn;
        expect(tokenB?.eventId, _eventBId);

        releaseAcknowledgement.complete();
        final result = await confirmation;

        expect(
          result?.status,
          NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
        );
        expect(result?.code, 'projectChangedAfterAcknowledgement');
        expect(controller.state.pendingReturn, same(tokenB));
        expect(controller.state.pendingReturn?.eventId, _eventBId);
        expect(controller.state.focusRequest, isNull);
        expect(controller.state.lastSourceCreationResult, isNull);
        expect(controller.state.isSourceCreationBusy, isFalse);
        expect(sourceGateway.acknowledgeCalls, 1);
        expect(
          (await repository.inspectProject(fixture.projectPath)).status,
          NarrativeEventSpatialLinkInspectionStatus.clear,
        );
      },
    );

    test(
      'journal B appearing between preview A and confirm becomes the only recovery and retry identity',
      () async {
        final previewA = _proposal();
        final durableB = _alternateProposal();
        final record = persistenceDraft(id: _eventId);
        final registry = persistenceRegistry(records: [record]);
        final fixture = await createPersistenceFixture(
          registry: registry,
          map: previewA.beforeMap,
        );
        addTearDown(fixture.dispose);
        final repository = NarrativeEventSpatialLinkJournalRepository();
        final sourceGateway = _RecordingSourceGateway(
          delegate: repository,
          beforeCommit: (request) async {
            final injected = await repository.commitMap(
              NarrativeEventSpatialLinkMapCommitRequest(
                projectPath: request.projectPath,
                projectRevision: request.projectRevision,
                operationId: 'durable_operation_b_between_preview_and_confirm',
                eventId: request.eventId,
                eventRecordFingerprintBefore:
                    request.eventRecordFingerprintBefore,
                beforeMap: durableB.beforeMap,
                afterMap: durableB.afterMap,
                source: durableB.source,
                sourceOwnerJson: durableB.ownerJson,
                sourceOwnerFingerprint: durableB.ownerFingerprint,
              ),
            );
            expect(
              injected.status,
              NarrativeEventSpatialLinkOperationStatus.mapCommitted,
            );
          },
        );
        final registryGateway = _RecordingRegistryGateway(
          delegate: FileProjectRepository(),
          steps: <String>[],
        );
        final project = ProjectManifest(
          name: 'Concurrent source project',
          maps: const [
            ProjectMapEntry(
              id: 'map_a',
              name: 'Map A',
              relativePath: 'maps/map_a.json',
            ),
          ],
          tilesets: const [],
          scenes: const [],
          eventRegistry: registry,
        );
        final controller = mountNarrativeEventMapBridgeController(
          useCase: CreateNarrativeEventFromMapSourceUseCase(
            persistenceGateway: registryGateway,
          ),
          explicitSourceCreationUseCase:
              NarrativeEventExplicitSourceCreationUseCase(
                sourceGateway: sourceGateway,
                registryGateway: registryGateway,
                operationIdFactory: () => 'preview_operation_a',
              ),
        );
        final projectRoot = p.dirname(fixture.projectPath);
        controller.bindProjectRootPath(projectRoot);
        await controller.openMapForMissingSource(
          eventId: _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
          project: project,
          activeMap: previewA.beforeMap,
          mapDirty: false,
          loadMapSnapshot: (_) async => null,
          activateMapSnapshot: (_) => true,
        );
        expect(
          controller.selectPhysicalSourceKind(previewA.physicalKind),
          isTrue,
        );
        expect(controller.previewSourceCreationProposal(previewA), isTrue);
        var adoptedPreviewA = 0;
        var appliedRegistry = 0;

        final confirmation = await controller.confirmSourceCreation(
          projectRootPath: projectRoot,
          project: project,
          mapDirty: false,
          projectDirty: false,
          saving: false,
          adoptPersistedMap: (_) {
            adoptedPreviewA++;
            return true;
          },
          applyPersistedRegistry:
              ({
                required expectedProjectRootPath,
                required expectedPreviousRegistry,
                required nextRegistry,
              }) {
                appliedRegistry++;
                return true;
              },
        );

        expect(
          confirmation?.status,
          NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
        );
        expect(confirmation?.code, 'pendingSpatialLinkJournal');
        expect(
          confirmation?.journal?.operationId,
          'durable_operation_b_between_preview_and_confirm',
        );
        expect(confirmation?.journal?.source, durableB.source);
        expect(confirmation?.inspection?.journal?.source, durableB.source);
        expect(controller.state.sourceCreationProposal, isNull);
        expect(
          controller.state.lastSourceCreationResult?.journal?.source,
          durableB.source,
        );
        expect(adoptedPreviewA, 0);
        expect(appliedRegistry, 0);
        expect(sourceGateway.acknowledgeCalls, 0);

        final mapPath = fixture.session.mapPaths['map_a']!;
        final durableMap = MapData.fromJson(
          Map<String, dynamic>.from(
            decodeNarrativeEventJsonStrict(await File(mapPath).readAsString())
                as Map,
          ),
        );
        expect(durableMap, durableB.afterMap);

        final retried = await controller.retrySourceCreation(
          projectRootPath: projectRoot,
          project: project,
          activeMap: durableMap,
          mapDirty: false,
          projectDirty: false,
          saving: false,
          adoptPersistedMap: (_) {
            adoptedPreviewA++;
            return true;
          },
          applyPersistedRegistry:
              ({
                required expectedProjectRootPath,
                required expectedPreviousRegistry,
                required nextRegistry,
              }) {
                appliedRegistry++;
                final linked = nextRegistry.records.singleWhere(
                  (candidate) => candidate.id == _eventId,
                );
                expect(linked.draftOrNull?.source, durableB.source);
                return true;
              },
        );

        expect(
          retried?.status,
          NarrativeEventExplicitSourceCreationStatus.committed,
        );
        expect(retried?.journal?.source, durableB.source);
        expect(controller.state.focusRequest?.source, durableB.source);
        expect(controller.state.pendingReturn?.expectedSource, durableB.source);
        expect(controller.state.sourceCreationProposal, isNull);
        expect(adoptedPreviewA, 0);
        expect(appliedRegistry, 1);
        expect(sourceGateway.acknowledgeCalls, 1);
        expect(
          (await repository.inspectProject(fixture.projectPath)).status,
          NarrativeEventSpatialLinkInspectionStatus.clear,
        );
      },
    );

    test(
      'retry derives map source and adoption from journal B discovered after preview A',
      () async {
        final previewA = _proposal();
        final durableB = _alternateProposal();
        final record = persistenceDraft(id: _eventId);
        final registry = persistenceRegistry(records: [record]);
        final fixture = await createPersistenceFixture(
          registry: registry,
          map: previewA.beforeMap,
        );
        addTearDown(fixture.dispose);
        final repository = NarrativeEventSpatialLinkJournalRepository();
        final committedB = await repository.commitMap(
          NarrativeEventSpatialLinkMapCommitRequest(
            projectPath: fixture.projectPath,
            projectRevision: fixture.revision,
            operationId: 'durable_operation_b_discovered_by_retry',
            eventId: _eventId,
            eventRecordFingerprintBefore:
                narrativeEventRecordCanonicalFingerprint(record),
            beforeMap: durableB.beforeMap,
            afterMap: durableB.afterMap,
            source: durableB.source,
            sourceOwnerJson: durableB.ownerJson,
            sourceOwnerFingerprint: durableB.ownerFingerprint,
          ),
        );
        expect(
          committedB.status,
          NarrativeEventSpatialLinkOperationStatus.mapCommitted,
        );
        final sourceGateway = _RecordingSourceGateway(delegate: repository);
        final registryGateway = _RecordingRegistryGateway(
          delegate: FileProjectRepository(),
          steps: <String>[],
        );
        final project = ProjectManifest(
          name: 'Retry race project',
          maps: const [
            ProjectMapEntry(
              id: 'map_a',
              name: 'Map A',
              relativePath: 'maps/map_a.json',
            ),
          ],
          tilesets: const [],
          scenes: const [],
          eventRegistry: registry,
        );
        final controller = mountNarrativeEventMapBridgeController(
          useCase: CreateNarrativeEventFromMapSourceUseCase(
            persistenceGateway: registryGateway,
          ),
          explicitSourceCreationUseCase:
              NarrativeEventExplicitSourceCreationUseCase(
                sourceGateway: sourceGateway,
                registryGateway: registryGateway,
              ),
        );
        final projectRoot = p.dirname(fixture.projectPath);
        controller.bindProjectRootPath(projectRoot);
        await controller.openMapForMissingSource(
          eventId: _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
          project: project,
          activeMap: previewA.beforeMap,
          mapDirty: false,
          loadMapSnapshot: (_) async => null,
          activateMapSnapshot: (_) => true,
        );
        expect(
          controller.selectPhysicalSourceKind(previewA.physicalKind),
          isTrue,
        );
        expect(controller.previewSourceCreationProposal(previewA), isTrue);
        final mapPath = fixture.session.mapPaths['map_a']!;
        final durableMap = MapData.fromJson(
          Map<String, dynamic>.from(
            decodeNarrativeEventJsonStrict(await File(mapPath).readAsString())
                as Map,
          ),
        );
        var adoptedPreviewA = 0;
        var appliedRegistryB = 0;

        final retried = await controller.retrySourceCreation(
          projectRootPath: projectRoot,
          project: project,
          activeMap: durableMap,
          mapDirty: false,
          projectDirty: false,
          saving: false,
          adoptPersistedMap: (_) {
            adoptedPreviewA++;
            return true;
          },
          applyPersistedRegistry:
              ({
                required expectedProjectRootPath,
                required expectedPreviousRegistry,
                required nextRegistry,
              }) {
                appliedRegistryB++;
                final linked = nextRegistry.records.singleWhere(
                  (candidate) => candidate.id == _eventId,
                );
                expect(linked.draftOrNull?.source, durableB.source);
                return true;
              },
        );

        expect(
          retried?.status,
          NarrativeEventExplicitSourceCreationStatus.committed,
        );
        expect(retried?.journal?.source, durableB.source);
        expect(controller.state.focusRequest?.source, durableB.source);
        expect(controller.state.sourceCreationProposal, isNull);
        expect(adoptedPreviewA, 0);
        expect(appliedRegistryB, 1);
        expect(sourceGateway.acknowledgeCalls, 1);
      },
    );

    test(
      'durable journal B clears preview A and never adopts or acknowledges the mixed operation',
      () async {
        final previewA = _proposal();
        final durableB = _alternateProposal();
        final record = persistenceDraft(id: _eventId);
        final registry = persistenceRegistry(records: [record]);
        final fixture = await createPersistenceFixture(
          registry: registry,
          map: previewA.beforeMap,
        );
        addTearDown(fixture.dispose);
        final repository = NarrativeEventSpatialLinkJournalRepository();
        final mapCommit = await repository.commitMap(
          NarrativeEventSpatialLinkMapCommitRequest(
            projectPath: fixture.projectPath,
            projectRevision: fixture.revision,
            operationId: 'durable_operation_b',
            eventId: _eventId,
            eventRecordFingerprintBefore:
                narrativeEventRecordCanonicalFingerprint(record),
            beforeMap: durableB.beforeMap,
            afterMap: durableB.afterMap,
            source: durableB.source,
            sourceOwnerJson: durableB.ownerJson,
            sourceOwnerFingerprint: durableB.ownerFingerprint,
          ),
        );
        expect(
          mapCommit.status,
          NarrativeEventSpatialLinkOperationStatus.mapCommitted,
        );
        final sourceGateway = _RecordingSourceGateway(delegate: repository);
        final registryGateway = _RecordingRegistryGateway(
          delegate: FileProjectRepository(),
          steps: <String>[],
        );
        final project = ProjectManifest(
          name: 'Mixed operation project',
          maps: const [
            ProjectMapEntry(
              id: 'map_a',
              name: 'Map A',
              relativePath: 'maps/map_a.json',
            ),
          ],
          tilesets: const [],
          scenes: const [],
          eventRegistry: registry,
        );
        final controller = mountNarrativeEventMapBridgeController(
          useCase: CreateNarrativeEventFromMapSourceUseCase(
            persistenceGateway: registryGateway,
          ),
          explicitSourceCreationUseCase:
              NarrativeEventExplicitSourceCreationUseCase(
                sourceGateway: sourceGateway,
                registryGateway: registryGateway,
              ),
        );
        controller.bindProjectRootPath(p.dirname(fixture.projectPath));
        await controller.openMapForMissingSource(
          eventId: _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
          project: project,
          activeMap: previewA.beforeMap,
          mapDirty: false,
          loadMapSnapshot: (_) async => null,
          activateMapSnapshot: (_) => true,
        );
        expect(
          controller.selectPhysicalSourceKind(previewA.physicalKind),
          isTrue,
        );
        expect(controller.previewSourceCreationProposal(previewA), isTrue);

        final inspected = await controller.inspectPendingSourceCreation(
          projectRootPath: p.dirname(fixture.projectPath),
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );

        expect(inspected?.journal?.operationId, 'durable_operation_b');
        expect(controller.state.sourceCreationProposal, isNull);
        var adoptedPreviewA = 0;
        var appliedRegistryB = 0;
        final retried = await controller.retrySourceCreation(
          projectRootPath: p.dirname(fixture.projectPath),
          project: project,
          activeMap: previewA.beforeMap,
          mapDirty: false,
          projectDirty: false,
          saving: false,
          adoptPersistedMap: (_) {
            adoptedPreviewA++;
            return true;
          },
          applyPersistedRegistry:
              ({
                required expectedProjectRootPath,
                required expectedPreviousRegistry,
                required nextRegistry,
              }) {
                appliedRegistryB++;
                return true;
              },
        );

        expect(
          retried?.status,
          NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
        );
        expect(retried?.code, 'committedMapOutOfSync');
        expect(controller.state.sourceCreationProposal, isNull);
        expect(
          controller.state.lastSourceCreationResult?.journal?.source,
          durableB.source,
        );
        expect(adoptedPreviewA, 0);
        expect(appliedRegistryB, 0);
        expect(sourceGateway.acknowledgeCalls, 0);
      },
    );

    test(
      'transient inspection exception preserves the previous journal and retry action',
      () async {
        final project = _recoveryProject();
        const mapA = MapData(
          id: 'map_a',
          name: 'Map A',
          size: GridSize(width: 8, height: 6),
        );
        final journal = _pendingJournal(eventId: _eventId, mapId: 'map_a');
        final sourceGateway = _RecordingSourceGateway(
          delegate: _PendingJournalSourceGateway(journal),
          throwOnInspectCall: 2,
          inspectError: const FileSystemException(
            'transient inspection outage',
          ),
        );
        final registryGateway = _CountingClearRegistryGateway();
        final controller = mountNarrativeEventMapBridgeController(
          useCase: CreateNarrativeEventFromMapSourceUseCase(
            persistenceGateway: registryGateway,
          ),
          explicitSourceCreationUseCase:
              NarrativeEventExplicitSourceCreationUseCase(
                sourceGateway: sourceGateway,
                registryGateway: registryGateway,
              ),
        );
        controller.bindProjectRootPath('/project');
        await controller.openMapForMissingSource(
          eventId: _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
          project: project,
          activeMap: mapA,
          mapDirty: false,
          loadMapSnapshot: (_) async => null,
          activateMapSnapshot: (_) => true,
        );
        final recovered = await controller.inspectPendingSourceCreation(
          projectRootPath: '/project',
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );
        expect(recovered?.journal, same(journal));

        final transient = await controller.inspectPendingSourceCreation(
          projectRootPath: '/project',
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );

        expect(transient?.code, 'inspectionException');
        expect(
          controller.state.lastSourceCreationResult?.status,
          NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
        );
        expect(
          controller.state.lastSourceCreationResult?.journal,
          same(journal),
        );
        expect(controller.requestSourceCleanupConfirmation(), isTrue);
        expect(controller.cancelSourceCleanupConfirmation(), isTrue);

        final retried = await controller.retrySourceCreation(
          projectRootPath: '/project',
          project: project,
          activeMap: mapA,
          mapDirty: false,
          projectDirty: false,
          saving: false,
          adoptPersistedMap: (_) {
            fail(
              'A transient inspection failure must not adopt a new preview.',
            );
          },
          applyPersistedRegistry:
              ({
                required expectedProjectRootPath,
                required expectedPreviousRegistry,
                required nextRegistry,
              }) {
                fail('A failed fresh session must not apply a registry.');
              },
        );

        expect(retried, isNotNull);
        expect(retried?.code, 'freshSessionRejected');
        expect(retried?.journal, same(journal));
        expect(sourceGateway.inspectCalls, 3);
      },
    );

    test(
      'retry dirty gates preserve the exact durable recovery without IO or navigation escape',
      () async {
        final project = _recoveryProject();
        const mapA = MapData(
          id: 'map_a',
          name: 'Map A',
          size: GridSize(width: 8, height: 6),
        );
        for (final gates in [
          (
            mapDirty: true,
            projectDirty: false,
            saving: false,
            code: 'mapDirty',
          ),
          (
            mapDirty: false,
            projectDirty: true,
            saving: false,
            code: 'projectDirty',
          ),
          (
            mapDirty: false,
            projectDirty: false,
            saving: true,
            code: 'saveInProgress',
          ),
        ]) {
          final journal = _pendingJournal(eventId: _eventId, mapId: 'map_a');
          final sourceGateway = _PendingJournalSourceGateway(journal);
          final registryGateway = _CountingClearRegistryGateway();
          final controller = mountNarrativeEventMapBridgeController(
            useCase: CreateNarrativeEventFromMapSourceUseCase(
              persistenceGateway: registryGateway,
            ),
            explicitSourceCreationUseCase:
                NarrativeEventExplicitSourceCreationUseCase(
                  sourceGateway: sourceGateway,
                  registryGateway: registryGateway,
                ),
          );
          controller.bindProjectRootPath('/project');
          await controller.openMapForMissingSource(
            eventId: _eventId,
            groupContext: const NarrativeEventGroupContext.map('map_a'),
            project: project,
            activeMap: mapA,
            mapDirty: false,
            loadMapSnapshot: (_) async => null,
            activateMapSnapshot: (_) => true,
          );
          final recovered = await controller.inspectPendingSourceCreation(
            projectRootPath: '/project',
            mapDirty: false,
            projectDirty: false,
            saving: false,
          );
          final exactInspection = recovered?.inspection;
          final recoveryToken = controller.state.pendingReturn;
          final sourceInspectionsBefore = sourceGateway.inspectCalls;
          final registryInspectionsBefore = registryGateway.inspectCalls;

          final retried = await controller.retrySourceCreation(
            projectRootPath: '/project',
            project: project,
            activeMap: mapA,
            mapDirty: gates.mapDirty,
            projectDirty: gates.projectDirty,
            saving: gates.saving,
            adoptPersistedMap: (_) {
              fail('A dirty-gated retry must not adopt a map.');
            },
            applyPersistedRegistry:
                ({
                  required expectedProjectRootPath,
                  required expectedPreviousRegistry,
                  required nextRegistry,
                }) {
                  fail('A dirty-gated retry must not apply a registry.');
                },
          );

          expect(retried?.code, gates.code, reason: gates.code);
          expect(
            retried?.status,
            NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
            reason: gates.code,
          );
          expect(retried?.journal, same(journal), reason: gates.code);
          expect(
            retried?.inspection,
            same(exactInspection),
            reason: gates.code,
          );
          expect(
            controller.state.lastSourceCreationResult?.status,
            NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
            reason: gates.code,
          );
          expect(
            controller.state.lastSourceCreationResult?.journal,
            same(journal),
            reason: gates.code,
          );
          expect(sourceGateway.inspectCalls, sourceInspectionsBefore);
          expect(sourceGateway.recoverCalls, 0);
          expect(sourceGateway.cleanupCalls, 0);
          expect(registryGateway.inspectCalls, registryInspectionsBefore);
          expect(registryGateway.persistCalls, 0);

          controller.cancelMapNavigation();
          expect(controller.state.pendingReturn, same(recoveryToken));
          var openedDuringRecovery = false;
          expect(
            controller.returnToEvent(
              project: project,
              openExactEvent: ({required eventId, required groupContext}) {
                openedDuringRecovery = true;
              },
            ),
            isFalse,
            reason: gates.code,
          );
          expect(openedDuringRecovery, isFalse);
          expect(controller.state.pendingReturn, same(recoveryToken));
          expect(
            controller.selectPhysicalSourceKind(
              NarrativeEventPhysicalSourceKind.zone1x1,
            ),
            isFalse,
            reason: gates.code,
          );
        }
      },
    );

    test(
      'cleanup dirty gates preserve the exact durable recovery without IO or navigation escape',
      () async {
        final project = _recoveryProject();
        const mapA = MapData(
          id: 'map_a',
          name: 'Map A',
          size: GridSize(width: 8, height: 6),
        );
        for (final gates in [
          (
            mapDirty: true,
            projectDirty: false,
            saving: false,
            code: 'mapDirty',
          ),
          (
            mapDirty: false,
            projectDirty: true,
            saving: false,
            code: 'projectDirty',
          ),
          (
            mapDirty: false,
            projectDirty: false,
            saving: true,
            code: 'saveInProgress',
          ),
        ]) {
          final journal = _pendingJournal(eventId: _eventId, mapId: 'map_a');
          final sourceGateway = _PendingJournalSourceGateway(journal);
          final registryGateway = _CountingClearRegistryGateway();
          final controller = mountNarrativeEventMapBridgeController(
            useCase: CreateNarrativeEventFromMapSourceUseCase(
              persistenceGateway: registryGateway,
            ),
            explicitSourceCreationUseCase:
                NarrativeEventExplicitSourceCreationUseCase(
                  sourceGateway: sourceGateway,
                  registryGateway: registryGateway,
                ),
          );
          controller.bindProjectRootPath('/project');
          await controller.openMapForMissingSource(
            eventId: _eventId,
            groupContext: const NarrativeEventGroupContext.map('map_a'),
            project: project,
            activeMap: mapA,
            mapDirty: false,
            loadMapSnapshot: (_) async => null,
            activateMapSnapshot: (_) => true,
          );
          final recovered = await controller.inspectPendingSourceCreation(
            projectRootPath: '/project',
            mapDirty: false,
            projectDirty: false,
            saving: false,
          );
          final exactInspection = recovered?.inspection;
          final recoveryToken = controller.state.pendingReturn;
          expect(controller.requestSourceCleanupConfirmation(), isTrue);
          final sourceInspectionsBefore = sourceGateway.inspectCalls;
          final registryInspectionsBefore = registryGateway.inspectCalls;
          var cleanupInterlockBegins = 0;
          var cleanupInterlockReleases = 0;
          var cleanupAdoptions = 0;

          final cleaned = await controller.cleanupCreatedSource(
            projectRootPath: '/project',
            activeMap: mapA,
            mapDirty: gates.mapDirty,
            projectDirty: gates.projectDirty,
            saving: gates.saving,
            beginCleanupInterlock:
                ({
                  required expectedProjectRootPath,
                  required expectedActiveMap,
                  required journal,
                }) {
                  cleanupInterlockBegins++;
                  return true;
                },
            releaseCleanupInterlock:
                ({required expectedProjectRootPath, required journal}) {
                  cleanupInterlockReleases++;
                },
            adoptPersistedCleanup:
                ({
                  required expectedProjectRootPath,
                  required expectedActiveMap,
                  required journal,
                }) async {
                  cleanupAdoptions++;
                  return true;
                },
          );

          expect(cleaned?.code, gates.code, reason: gates.code);
          expect(
            cleaned?.status,
            NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
            reason: gates.code,
          );
          expect(cleaned?.journal, same(journal), reason: gates.code);
          expect(
            cleaned?.inspection,
            same(exactInspection),
            reason: gates.code,
          );
          expect(
            controller.state.lastSourceCreationResult?.status,
            NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
            reason: gates.code,
          );
          expect(
            controller.state.lastSourceCreationResult?.journal,
            same(journal),
            reason: gates.code,
          );
          expect(sourceGateway.inspectCalls, sourceInspectionsBefore);
          expect(sourceGateway.recoverCalls, 0);
          expect(sourceGateway.cleanupCalls, 0);
          expect(registryGateway.inspectCalls, registryInspectionsBefore);
          expect(registryGateway.persistCalls, 0);
          expect(cleanupInterlockBegins, 1);
          expect(cleanupInterlockReleases, 1);
          expect(cleanupAdoptions, 0);

          controller.cancelMapNavigation();
          expect(controller.state.pendingReturn, same(recoveryToken));
          var openedDuringRecovery = false;
          expect(
            controller.returnToEvent(
              project: project,
              openExactEvent: ({required eventId, required groupContext}) {
                openedDuringRecovery = true;
              },
            ),
            isFalse,
            reason: gates.code,
          );
          expect(openedDuringRecovery, isFalse);
          expect(controller.state.pendingReturn, same(recoveryToken));
          expect(
            controller.selectPhysicalSourceKind(
              NarrativeEventPhysicalSourceKind.zone1x1,
            ),
            isFalse,
            reason: gates.code,
          );
          expect(controller.requestSourceCleanupConfirmation(), isTrue);
        }
      },
    );

    test(
      'retry releasing a journal that became clear returns cleanly and releases busy',
      () async {
        final project = _recoveryProject();
        const mapA = MapData(
          id: 'map_a',
          name: 'Map A',
          size: GridSize(width: 8, height: 6),
        );
        final journal = _pendingJournal(eventId: _eventId, mapId: 'map_a');
        final sourceGateway = _RecordingSourceGateway(
          inspectOverride: (_, call) async {
            if (call == 1) {
              return NarrativeEventSpatialLinkInspection(
                status: NarrativeEventSpatialLinkInspectionStatus
                    .awaitingEventCommit,
                journal: journal,
              );
            }
            return NarrativeEventSpatialLinkInspection(
              status: NarrativeEventSpatialLinkInspectionStatus.clear,
            );
          },
        );
        final registryGateway = _CountingClearRegistryGateway();
        final controller = mountNarrativeEventMapBridgeController(
          useCase: CreateNarrativeEventFromMapSourceUseCase(
            persistenceGateway: registryGateway,
          ),
          explicitSourceCreationUseCase:
              NarrativeEventExplicitSourceCreationUseCase(
                sourceGateway: sourceGateway,
                registryGateway: registryGateway,
              ),
        );
        controller.bindProjectRootPath('/project');
        await controller.openMapForMissingSource(
          eventId: _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
          project: project,
          activeMap: mapA,
          mapDirty: false,
          loadMapSnapshot: (_) async => null,
          activateMapSnapshot: (_) => true,
        );
        final inspected = await controller.inspectPendingSourceCreation(
          projectRootPath: '/project',
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );
        expect(inspected?.journal, same(journal));

        final retried = await controller.retrySourceCreation(
          projectRootPath: '/project',
          project: project,
          activeMap: mapA,
          mapDirty: false,
          projectDirty: false,
          saving: false,
          adoptPersistedMap: (_) {
            fail('A clear retry must never adopt a proposal.');
          },
          applyPersistedRegistry:
              ({
                required expectedProjectRootPath,
                required expectedPreviousRegistry,
                required nextRegistry,
              }) {
                fail('A clear retry must never adopt a registry.');
              },
        );

        expect(
          retried?.status,
          NarrativeEventExplicitSourceCreationStatus.clear,
        );
        expect(retried?.journal, isNull);
        expect(controller.state.isSourceCreationBusy, isFalse);
        expect(controller.state.sourceCreationProposal, isNull);
      },
    );

    test(
      'transient cleanup exception preserves the exact recovery and allows another cleanup attempt',
      () async {
        final project = _recoveryProject();
        const mapA = MapData(
          id: 'map_a',
          name: 'Map A',
          size: GridSize(width: 8, height: 6),
        );
        final journal = _pendingJournal(eventId: _eventId, mapId: 'map_a');
        final sourceGateway = _PendingJournalSourceGateway(journal);
        final registryGateway = _CountingClearRegistryGateway();
        final controller = mountNarrativeEventMapBridgeController(
          useCase: CreateNarrativeEventFromMapSourceUseCase(
            persistenceGateway: registryGateway,
          ),
          explicitSourceCreationUseCase:
              NarrativeEventExplicitSourceCreationUseCase(
                sourceGateway: sourceGateway,
                registryGateway: registryGateway,
              ),
        );
        controller.bindProjectRootPath('/project');
        await controller.openMapForMissingSource(
          eventId: _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
          project: project,
          activeMap: mapA,
          mapDirty: false,
          loadMapSnapshot: (_) async => null,
          activateMapSnapshot: (_) => true,
        );
        final inspected = await controller.inspectPendingSourceCreation(
          projectRootPath: '/project',
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );
        final exactInspection = inspected?.inspection;
        expect(inspected?.journal, same(journal));
        expect(exactInspection?.journal, same(journal));
        expect(controller.requestSourceCleanupConfirmation(), isTrue);

        final firstFailure = await controller.cleanupCreatedSource(
          projectRootPath: '/project',
          activeMap: mapA,
          mapDirty: false,
          projectDirty: false,
          saving: false,
          beginCleanupInterlock:
              ({
                required expectedProjectRootPath,
                required expectedActiveMap,
                required journal,
              }) => true,
          releaseCleanupInterlock:
              ({required expectedProjectRootPath, required journal}) {},
          adoptPersistedCleanup:
              ({
                required expectedProjectRootPath,
                required expectedActiveMap,
                required journal,
              }) {
                fail('A failed cleanup must never adopt a map.');
              },
        );

        expect(firstFailure?.code, 'cleanupException');
        expect(firstFailure?.journal, same(journal));
        expect(firstFailure?.inspection, same(exactInspection));
        expect(
          controller.state.lastSourceCreationResult?.journal,
          same(journal),
        );
        expect(
          controller.state.lastSourceCreationResult?.inspection,
          same(exactInspection),
        );
        expect(sourceGateway.cleanupCalls, 1);
        expect(controller.requestSourceCleanupConfirmation(), isTrue);

        final secondFailure = await controller.cleanupCreatedSource(
          projectRootPath: '/project',
          activeMap: mapA,
          mapDirty: false,
          projectDirty: false,
          saving: false,
          beginCleanupInterlock:
              ({
                required expectedProjectRootPath,
                required expectedActiveMap,
                required journal,
              }) => true,
          releaseCleanupInterlock:
              ({required expectedProjectRootPath, required journal}) {},
          adoptPersistedCleanup:
              ({
                required expectedProjectRootPath,
                required expectedActiveMap,
                required journal,
              }) {
                fail('A failed cleanup must never adopt a map.');
              },
        );

        expect(secondFailure?.code, 'cleanupException');
        expect(secondFailure?.journal, same(journal));
        expect(secondFailure?.inspection, same(exactInspection));
        expect(sourceGateway.cleanupCalls, 2);
        expect(controller.state.isSourceCreationBusy, isFalse);
        expect(controller.requestSourceCleanupConfirmation(), isTrue);
      },
    );

    test(
      'registry inspection exception keeps the exact source journal context',
      () async {
        final journal = _pendingJournal(eventId: _eventId, mapId: 'map_a');
        final useCase = NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: _PendingJournalSourceGateway(journal),
          registryGateway: _ThrowingRegistryInspectionGateway(),
        );

        final result = await useCase.retry(
          projectPath: '/project/project.json',
          expectedEventId: _eventId,
          expectedMapId: 'map_a',
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );

        expect(
          result.status,
          NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
        );
        expect(result.code, 'registryInspectionException');
        expect(result.journal, same(journal));
        expect(result.inspection?.journal, same(journal));
      },
    );

    test(
      'retry rejects a swapped journal before registry recovery or writing',
      () async {
        final sourceGateway = _PendingJournalSourceGateway(
          _pendingJournal(eventId: _eventBId, mapId: 'map_a'),
        );
        final registryGateway = _CountingClearRegistryGateway();
        var prepareCalls = 0;
        final useCase = NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: sourceGateway,
          registryGateway: registryGateway,
          prepareSession: (_) async {
            prepareCalls++;
            throw StateError(
              'A mismatched journal must not prepare a session.',
            );
          },
        );

        final result = await useCase.retry(
          projectPath: '/project/project.json',
          expectedEventId: _eventId,
          expectedMapId: 'map_a',
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );

        expect(
          result.status,
          NarrativeEventExplicitSourceCreationStatus.rejected,
        );
        expect(result.code, 'pendingJournalMismatch');
        expect(result.journal, isNull);
        expect(sourceGateway.inspectCalls, 1);
        expect(sourceGateway.recoverCalls, 0);
        expect(registryGateway.inspectCalls, 0);
        expect(registryGateway.persistCalls, 0);
        expect(prepareCalls, 0);
      },
    );

    test(
      'cleanup rejects a swapped journal before deleting its owner',
      () async {
        final sourceGateway = _PendingJournalSourceGateway(
          _pendingJournal(eventId: _eventBId, mapId: 'map_a'),
        );
        final useCase = NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: sourceGateway,
          registryGateway: _CountingClearRegistryGateway(),
        );

        final result = await useCase.cleanup(
          projectPath: '/project/project.json',
          operationId: sourceGateway.journal.operationId,
          expectedEventId: _eventId,
          expectedMapId: 'map_a',
          confirmed: true,
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );

        expect(
          result.status,
          NarrativeEventExplicitSourceCreationStatus.rejected,
        );
        expect(result.code, 'pendingJournalMismatch');
        expect(result.journal, isNull);
        expect(sourceGateway.inspectCalls, 1);
        expect(sourceGateway.cleanupCalls, 0);
      },
    );
  });
}

NarrativeEventCreatedSourceProposal _proposal({MapData? beforeMap}) {
  final before =
      beforeMap ??
      const MapData(
        id: 'map_a',
        name: 'Map A',
        size: GridSize(width: 8, height: 6),
      );
  const owner = MapEntity(
    id: 'sign',
    name: 'Sign',
    kind: MapEntityKind.sign,
    pos: GridPos(x: 2, y: 2),
    sign: MapEntitySignData(),
  );
  final after = before.copyWith(entities: const [owner]);
  return NarrativeEventCreatedSourceProposal(
    physicalKind: NarrativeEventPhysicalSourceKind.sign,
    source: NarrativeEventSourceRef.entityInteract('map_a', 'sign'),
    beforeMap: before,
    afterMap: after,
    bounds: const MapRect(
      pos: GridPos(x: 2, y: 2),
      size: GridSize(width: 1, height: 1),
    ),
    ownerJson: {
      'schemaVersion': 1,
      'ownerKind': 'mapEntity',
      'mapId': 'map_a',
      'sourceId': 'sign',
      'owner': owner.toJson(),
    },
  );
}

NarrativeEventCreatedSourceProposal _alternateProposal() {
  const before = MapData(
    id: 'map_a',
    name: 'Map A',
    size: GridSize(width: 8, height: 6),
  );
  const owner = MapEntity(
    id: 'sign_b',
    name: 'Durable sign B',
    kind: MapEntityKind.sign,
    pos: GridPos(x: 5, y: 3),
    sign: MapEntitySignData(),
  );
  return NarrativeEventCreatedSourceProposal(
    physicalKind: NarrativeEventPhysicalSourceKind.sign,
    source: NarrativeEventSourceRef.entityInteract('map_a', owner.id),
    beforeMap: before,
    afterMap: before.copyWith(entities: const [owner]),
    bounds: const MapRect(
      pos: GridPos(x: 5, y: 3),
      size: GridSize(width: 1, height: 1),
    ),
    ownerJson: {
      'schemaVersion': 1,
      'ownerKind': 'mapEntity',
      'mapId': 'map_a',
      'sourceId': owner.id,
      'owner': owner.toJson(),
    },
  );
}

ProjectManifest _recoveryProject() {
  return ProjectManifest(
    name: 'Recovery binding project',
    maps: const [
      ProjectMapEntry(
        id: 'map_a',
        name: 'Map A',
        relativePath: 'maps/map_a.json',
      ),
      ProjectMapEntry(
        id: 'map_b',
        name: 'Map B',
        relativePath: 'maps/map_b.json',
      ),
    ],
    tilesets: const [],
    scenes: const [],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.dualRead,
      records: [
        NarrativeEventRecord.draft(
          NarrativeEventDraft(
            id: _eventId,
            name: 'Event A',
            conditions: const [],
            priority: 0,
            order: 0,
          ),
        ),
        NarrativeEventRecord.draft(
          NarrativeEventDraft(
            id: _eventBId,
            name: 'Event B',
            conditions: const [],
            priority: 0,
            order: 1,
          ),
        ),
      ],
      legacyClaims: const [],
    ),
  );
}

NarrativeEventSpatialLinkJournal _pendingJournal({
  required String eventId,
  required String mapId,
}) {
  const owner = MapEntity(
    id: 'pending_owner',
    name: 'Pending owner',
    kind: MapEntityKind.custom,
    pos: GridPos(x: 2, y: 2),
  );
  final ownerJson = Map<String, Object?>.from(
    (jsonDecode(
              jsonEncode(<String, Object?>{
                'schemaVersion': 1,
                'ownerKind': 'mapEntity',
                'mapId': mapId,
                'sourceId': owner.id,
                'owner': owner.toJson(),
              }),
            )
            as Map)
        .cast<String, Object?>(),
  );
  final ownerFingerprint = narrativeEventBytesFingerprint(
    canonicalizeNarrativeEventJsonUtf8(ownerJson),
  );
  final projectFingerprint = narrativeEventBytesFingerprint(
    canonicalizeNarrativeEventJsonUtf8({'project': mapId}),
  );
  final eventFingerprint = narrativeEventBytesFingerprint(
    canonicalizeNarrativeEventJsonUtf8({'event': eventId}),
  );
  final mapFingerprint = narrativeEventBytesFingerprint(
    canonicalizeNarrativeEventJsonUtf8({'map': mapId}),
  );
  return NarrativeEventSpatialLinkJournal(
    schemaVersion: 1,
    operationId: 'pending_${eventId.hashCode.abs()}_${mapId.hashCode.abs()}',
    projectPath: '/project/project.json',
    projectRevision: projectFingerprint,
    journalPath: '/project/pending.journal.json',
    mapPath: '/project/maps/$mapId.json',
    mapTempPath: '/project/maps/$mapId.tmp',
    mapId: mapId,
    eventId: eventId,
    eventRecordFingerprintBefore: eventFingerprint,
    source: NarrativeEventSourceRef.entityInteract(mapId, owner.id),
    sourceOwnerJson: ownerJson,
    sourceOwnerFingerprint: ownerFingerprint,
    beforeMapHash: mapFingerprint,
    afterMapHash: mapFingerprint,
    state: NarrativeEventSpatialLinkJournalState.mapCommitted,
    preparedAt: DateTime.utc(2026, 7, 15, 12),
    mapCommittedAt: DateTime.utc(2026, 7, 15, 12, 0, 1),
    cleanupMarker: NarrativeEventSpatialLinkCleanupMarker.none,
  );
}

final class _DelayedInspectionSourceGateway
    implements NarrativeEventSpatialSourceCreationGateway {
  final _inspections = <Completer<NarrativeEventSpatialLinkInspection>>[];

  int get inspectCalls => _inspections.length;

  void complete(int index, NarrativeEventSpatialLinkJournal journal) {
    _inspections[index].complete(
      NarrativeEventSpatialLinkInspection(
        status: NarrativeEventSpatialLinkInspectionStatus.awaitingEventCommit,
        journal: journal,
      ),
    );
  }

  void completeClear(int index) {
    _inspections[index].complete(
      NarrativeEventSpatialLinkInspection(
        status: NarrativeEventSpatialLinkInspectionStatus.clear,
      ),
    );
  }

  @override
  Future<NarrativeEventSpatialLinkInspection> inspectProject(
    String projectPath,
  ) {
    final inspection = Completer<NarrativeEventSpatialLinkInspection>();
    _inspections.add(inspection);
    return inspection.future;
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> acknowledgeEventCommitted({
    required String projectPath,
    required String operationId,
  }) {
    throw StateError('A delayed inspection must never acknowledge an Event.');
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> cleanupSource({
    required String projectPath,
    required String operationId,
    required bool confirmed,
  }) {
    throw StateError('A delayed inspection must never clean a source.');
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> commitMap(
    NarrativeEventSpatialLinkMapCommitRequest request,
  ) {
    throw StateError('A delayed inspection must never commit a map.');
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> markEventCommitted({
    required String projectPath,
    required String operationId,
  }) {
    throw StateError('A delayed inspection must never finalize an Event.');
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> recoverProject({
    required String projectPath,
    required String expectedOperationId,
    required String expectedEventId,
    required String expectedMapId,
    required NarrativeEventSourceRef expectedSource,
  }) {
    throw StateError('A delayed inspection must never recover a source.');
  }
}

final class _PendingJournalSourceGateway
    implements NarrativeEventSpatialSourceCreationGateway {
  _PendingJournalSourceGateway(this.journal);

  final NarrativeEventSpatialLinkJournal journal;
  int inspectCalls = 0;
  int recoverCalls = 0;
  int cleanupCalls = 0;

  @override
  Future<NarrativeEventSpatialLinkOperationResult> acknowledgeEventCommitted({
    required String projectPath,
    required String operationId,
  }) {
    throw StateError('A recovery inspection must never acknowledge an Event.');
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> cleanupSource({
    required String projectPath,
    required String operationId,
    required bool confirmed,
  }) async {
    cleanupCalls++;
    throw StateError('A mismatched journal must never be cleaned.');
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> commitMap(
    NarrativeEventSpatialLinkMapCommitRequest request,
  ) {
    throw StateError('A recovery inspection must never commit a map.');
  }

  @override
  Future<NarrativeEventSpatialLinkInspection> inspectProject(
    String projectPath,
  ) async {
    inspectCalls++;
    return NarrativeEventSpatialLinkInspection(
      status: NarrativeEventSpatialLinkInspectionStatus.awaitingEventCommit,
      journal: journal,
    );
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> markEventCommitted({
    required String projectPath,
    required String operationId,
  }) {
    throw StateError('A recovery inspection must never finalize an Event.');
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> recoverProject({
    required String projectPath,
    required String expectedOperationId,
    required String expectedEventId,
    required String expectedMapId,
    required NarrativeEventSourceRef expectedSource,
  }) async {
    recoverCalls++;
    throw StateError('A mismatched journal must never be recovered.');
  }
}

final class _CountingClearRegistryGateway
    implements NarrativeEventRegistryPersistenceGateway {
  int inspectCalls = 0;
  int persistCalls = 0;

  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) async {
    inspectCalls++;
    return NarrativeEventRegistryRecoveryInspection(
      status: NarrativeEventRegistryRecoveryGateStatus.clear,
      issues: const [],
    );
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) async {
    persistCalls++;
    throw StateError('A mismatched journal must never persist an Event.');
  }

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) {
    throw StateError('A mismatched journal must never recover a registry.');
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) {
    throw StateError('A mismatched journal must never undo a registry.');
  }
}

final class _ThrowingRegistryInspectionGateway
    implements NarrativeEventRegistryPersistenceGateway {
  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) {
    throw const FileSystemException('transient registry inspection outage');
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) {
    throw StateError('A failed registry inspection must not persist.');
  }

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) {
    throw StateError('A failed registry inspection must not recover.');
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) {
    throw StateError('A failed registry inspection must not undo.');
  }
}

final class _RecordingSourceGateway
    implements NarrativeEventSpatialSourceCreationGateway {
  _RecordingSourceGateway({
    this.delegate,
    List<String>? steps,
    this.beforeAcknowledge,
    this.beforeCommit,
    this.afterCommit,
    this.finalizeError,
    this.throwOnInspectCall,
    this.inspectError,
    this.inspectOverride,
  }) : steps = steps ?? <String>[];

  final NarrativeEventSpatialSourceCreationGateway? delegate;
  final List<String> steps;
  final Future<void> Function()? beforeAcknowledge;
  final Future<void> Function(
    NarrativeEventSpatialLinkMapCommitRequest request,
  )?
  beforeCommit;
  final Future<void> Function(NarrativeEventSpatialLinkOperationResult result)?
  afterCommit;
  final Object? finalizeError;
  final int? throwOnInspectCall;
  final Object? inspectError;
  final Future<NarrativeEventSpatialLinkInspection> Function(
    String projectPath,
    int call,
  )?
  inspectOverride;
  final commitRequests = <NarrativeEventSpatialLinkMapCommitRequest>[];
  int acknowledgeCalls = 0;
  int cleanupCalls = 0;
  int inspectCalls = 0;

  @override
  Future<NarrativeEventSpatialLinkOperationResult> acknowledgeEventCommitted({
    required String projectPath,
    required String operationId,
  }) async {
    acknowledgeCalls++;
    await beforeAcknowledge?.call();
    final target = delegate;
    if (target == null) {
      throw StateError('acknowledgeEventCommitted must be gated in this test.');
    }
    return target.acknowledgeEventCommitted(
      projectPath: projectPath,
      operationId: operationId,
    );
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> commitMap(
    NarrativeEventSpatialLinkMapCommitRequest request,
  ) async {
    commitRequests.add(request);
    steps.add('map');
    final target = delegate;
    if (target == null) {
      throw StateError('commitMap must be gated in this test.');
    }
    await beforeCommit?.call(request);
    final result = await target.commitMap(request);
    await afterCommit?.call(result);
    return result;
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> cleanupSource({
    required String projectPath,
    required String operationId,
    required bool confirmed,
  }) async {
    cleanupCalls++;
    final target = delegate;
    if (target == null) {
      throw StateError('cleanupSource must be gated in this test.');
    }
    return target.cleanupSource(
      projectPath: projectPath,
      operationId: operationId,
      confirmed: confirmed,
    );
  }

  @override
  Future<NarrativeEventSpatialLinkInspection> inspectProject(
    String projectPath,
  ) async {
    inspectCalls++;
    if (inspectCalls == throwOnInspectCall) {
      throw inspectError ?? StateError('Simulated inspection failure.');
    }
    final override = inspectOverride;
    if (override != null) return override(projectPath, inspectCalls);
    final target = delegate;
    if (target == null) {
      throw StateError('inspectProject must be gated in this test.');
    }
    return target.inspectProject(projectPath);
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> markEventCommitted({
    required String projectPath,
    required String operationId,
  }) async {
    steps.add('finalize');
    if (finalizeError case final error?) throw error;
    final target = delegate;
    if (target == null) {
      throw StateError('markEventCommitted must be gated in this test.');
    }
    return target.markEventCommitted(
      projectPath: projectPath,
      operationId: operationId,
    );
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> recoverProject({
    required String projectPath,
    required String expectedOperationId,
    required String expectedEventId,
    required String expectedMapId,
    required NarrativeEventSourceRef expectedSource,
  }) async {
    final target = delegate;
    if (target == null) {
      throw StateError('recoverProject must be gated in this test.');
    }
    return target.recoverProject(
      projectPath: projectPath,
      expectedOperationId: expectedOperationId,
      expectedEventId: expectedEventId,
      expectedMapId: expectedMapId,
      expectedSource: expectedSource,
    );
  }
}

final class _RecordingRegistryGateway
    implements NarrativeEventRegistryPersistenceGateway {
  _RecordingRegistryGateway({
    required this.delegate,
    required this.steps,
    this.beforePersist,
  });

  final NarrativeEventRegistryPersistenceGateway delegate;
  final List<String> steps;
  final Future<void> Function(NarrativeEventRegistryWriteRequest request)?
  beforePersist;
  final persistRequests = <NarrativeEventRegistryWriteRequest>[];
  int recoverCalls = 0;

  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) {
    return delegate.inspectRecovery(projectPath);
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) async {
    steps.add('registry');
    persistRequests.add(request);
    await beforePersist?.call(request);
    return delegate.persist(request);
  }

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) {
    recoverCalls++;
    steps.add('registry-recover');
    return delegate.recover(projectPath);
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) {
    return delegate.undo(undoPath);
  }
}

final class _NeverRegistryGateway
    implements NarrativeEventRegistryPersistenceGateway {
  int calls = 0;

  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) {
    calls++;
    throw StateError('Registry gateway must be gated in this test.');
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) {
    calls++;
    throw StateError('Registry gateway must be gated in this test.');
  }

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) {
    calls++;
    throw StateError('Registry gateway must be gated in this test.');
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) {
    calls++;
    throw StateError('Registry gateway must be gated in this test.');
  }
}
