import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_registry_persistence_models.dart';
import 'package:map_editor/src/application/models/narrative_event_spatial_link_journal_models.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_event_registry_persistence.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_event_spatial_link_journal_repository.dart';

import 'support/event_registry_persistence_fixtures.dart';

void main() {
  group('NS-EVENT-V2-25 spatial link journal repository', () {
    test('commits one source with a strict durable mapCommitted journal',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      final request = _request(fixture);
      final result = await NarrativeEventSpatialLinkJournalRepository(
        clock: () => DateTime.utc(2026, 7, 15, 8),
      ).commitMap(request);

      expect(
        result.status,
        NarrativeEventSpatialLinkOperationStatus.mapCommitted,
      );
      final journal = result.journal!;
      expect(journal.state, NarrativeEventSpatialLinkJournalState.mapCommitted);
      expect(journal.operationId, 'phase_g_add_source');
      expect(journal.projectRevision, fixture.revision);
      expect(journal.mapId, 'map_a');
      expect(journal.eventId, persistenceEventA);
      expect(
        journal.eventRecordFingerprintBefore,
        _eventRecordFingerprintBefore,
      );
      expect(journal.source, _source);
      expect(journal.beforeMapHash, fixture.session.mapByteHashes['map_a']);
      expect(journal.afterMapHash, startsWith('sha256:'));
      expect(journal.sourceOwnerFingerprint, _ownerFingerprint);
      expect(
          journal.cleanupMarker, NarrativeEventSpatialLinkCleanupMarker.none);
      expect(journal.preparedAt, DateTime.utc(2026, 7, 15, 8));
      expect(journal.mapCommittedAt, DateTime.utc(2026, 7, 15, 8));
      expect(journal.eventCommittedAt, isNull);
      expect(await File(journal.journalPath).exists(), isTrue);
      expect(await File(journal.mapTempPath).exists(), isFalse);

      final raw =
          _object(jsonDecode(await File(journal.journalPath).readAsString()));
      expect(
        raw.keys.toSet(),
        {
          'schemaVersion',
          'operationId',
          'projectPath',
          'projectRevision',
          'journalPath',
          'mapPath',
          'mapTempPath',
          'mapId',
          'eventId',
          'eventRecordFingerprintBefore',
          'source',
          'sourceOwnerJson',
          'sourceOwnerFingerprint',
          'beforeMapHash',
          'afterMapHash',
          'state',
          'preparedAt',
          'mapCommittedAt',
          'eventCommittedAt',
          'cleanupMarker',
          'cleanupRequestedAt',
        },
      );
      final roundTrip = NarrativeEventSpatialLinkJournal.fromJson(raw);
      expect(
        roundTrip.eventRecordFingerprintBefore,
        _eventRecordFingerprintBefore,
      );
      final missingFingerprint = Map<String, Object?>.from(raw)
        ..remove('eventRecordFingerprintBefore');
      expect(
        () => NarrativeEventSpatialLinkJournal.fromJson(missingFingerprint),
        throwsA(isA<FormatException>()),
      );
      final unknownField = Map<String, Object?>.from(raw)
        ..['futureField'] = true;
      expect(
        () => NarrativeEventSpatialLinkJournal.fromJson(unknownField),
        throwsA(isA<FormatException>()),
      );
      final diskMap = await _readMap(fixture);
      expect(diskMap.entities.single.id, 'entity_event');
      expect(
        canonicalizeNarrativeEventJson(
          _ownerEnvelope(diskMap.entities.single),
        ),
        canonicalizeNarrativeEventJson(_ownerJson),
      );
    });

    test('commits and round-trips a real 1x1 trigger owner as strict JSON',
        () async {
      final fixture = await _triggerFixture();
      addTearDown(fixture.dispose);

      final result = await NarrativeEventSpatialLinkJournalRepository()
          .commitMap(_triggerRequest(fixture));

      expect(
        result.status,
        NarrativeEventSpatialLinkOperationStatus.mapCommitted,
      );
      final journal = result.journal!;
      expect(journal.source, _triggerSource);
      expect(journal.sourceOwnerJson, _triggerOwnerJsonSafe);
      expect(journal.sourceOwnerFingerprint, _triggerOwnerFingerprint);
      final strictJournalJson = _object(decodeNarrativeEventJsonStrict(
        await File(journal.journalPath).readAsString(),
      ));
      final roundTrip = NarrativeEventSpatialLinkJournal.fromJson(
        strictJournalJson,
      );
      expect(roundTrip.sourceOwnerJson, _triggerOwnerJsonSafe);
      final diskMap = await _readMap(fixture);
      expect(diskMap.triggers.map((trigger) => trigger.id), [
        'existing_trigger',
        'trigger_event',
      ]);
      expect(diskMap.triggers.last.area, _trigger.area);
      expect(
          diskMap.triggers.last.area.size, const GridSize(width: 1, height: 1));
    });

    test('cleanup removes only the exact 1x1 trigger from current disk map',
        () async {
      final fixture = await _triggerFixture();
      addTearDown(fixture.dispose);
      final repository = NarrativeEventSpatialLinkJournalRepository();
      await repository.commitMap(_triggerRequest(fixture));

      final cleanup = await repository.cleanupSource(
        projectPath: fixture.projectPath,
        operationId: 'phase_g_add_trigger',
        confirmed: true,
      );

      expect(cleanup.status, NarrativeEventSpatialLinkOperationStatus.cleaned);
      final diskMap = await _readMap(fixture);
      expect(diskMap.triggers.map((trigger) => trigger.id), [
        'existing_trigger',
      ]);
    });

    test('CAS checks project revision under the shared lock before map rename',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      final beforeMapBytes = await File(_mapPath(fixture)).readAsBytes();
      final repository = NarrativeEventSpatialLinkJournalRepository(
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventSpatialLinkCheckpoint.beforeMapRename) {
            final root = _object(jsonDecode(
              await File(fixture.projectPath).readAsString(),
            ));
            root['externalRevision'] = 2;
            await File(fixture.projectPath).writeAsString(
              jsonEncode(root),
              flush: true,
            );
          }
        },
      );

      final result = await repository.commitMap(_request(fixture));

      expect(result.status, NarrativeEventSpatialLinkOperationStatus.conflict);
      expect(result.code, 'staleProjectRevisionBeforeMapRename');
      expect(await File(_mapPath(fixture)).readAsBytes(), beforeMapBytes);
      expect(result.journal?.state,
          NarrativeEventSpatialLinkJournalState.prepared);
    });

    test('rejects a request whose canonical Event-before fingerprint is stale',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      final staleRequest = NarrativeEventSpatialLinkMapCommitRequest(
        projectPath: fixture.projectPath,
        projectRevision: fixture.revision,
        operationId: 'phase_g_stale_event',
        eventId: persistenceEventA,
        eventRecordFingerprintBefore:
            'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        beforeMap: _beforeMap,
        afterMap: _afterMap,
        source: _source,
        sourceOwnerJson: _ownerJson,
        sourceOwnerFingerprint: _ownerFingerprint,
      );

      final result = await NarrativeEventSpatialLinkJournalRepository()
          .commitMap(staleRequest);

      expect(result.status, NarrativeEventSpatialLinkOperationStatus.conflict);
      expect(result.code, 'eventRecordFingerprintMismatch');
      expect((await _readMap(fixture)).entities, isEmpty);
    });

    test('blocks map commit while Event registry recovery is pending',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      final previous = persistenceRegistry(records: [persistenceDraft()]);
      final interrupted = await NarrativeEventRegistryPersistence(
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventRegistryWriteCheckpoint.afterJournalPrepared) {
            throw const FileSystemException('simulated registry crash');
          }
        },
      ).write(
        persistenceRequest(
          fixture: fixture,
          operationId: 'event_registry_pending',
          previousRegistry: previous,
          nextRegistry: persistenceRegistry(records: [
            persistenceDraft(name: 'Renamed draft'),
          ]),
          mutation: 'rename',
        ),
      );
      expect(interrupted.status,
          NarrativeEventRegistryPersistenceStatus.ioFailure);

      final result = await NarrativeEventSpatialLinkJournalRepository()
          .commitMap(_request(fixture));

      expect(result.status, NarrativeEventSpatialLinkOperationStatus.blocked);
      expect(result.code, 'eventRegistryRecoveryRequired');
      expect((await _readMap(fixture)).entities, isEmpty);
    });

    test('a crash after prepared is recovered as a no-op when source is absent',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      final repository = NarrativeEventSpatialLinkJournalRepository(
        clock: () => DateTime.utc(2026, 7, 15, 8),
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventSpatialLinkCheckpoint.afterJournalPrepared) {
            throw const FileSystemException('simulated process crash');
          }
        },
      );
      await expectLater(
        repository.commitMap(_request(fixture)),
        throwsA(isA<FileSystemException>()),
      );
      await _writeRegistry(
        fixture,
        persistenceRegistry(records: [
          persistenceDraft(name: 'Changed while map remained untouched'),
        ]),
      );

      final restarted = NarrativeEventSpatialLinkJournalRepository();
      final inspection = await restarted.inspectProject(fixture.projectPath);
      expect(
        inspection.status,
        NarrativeEventSpatialLinkInspectionStatus.preparedSourceAbsent,
      );
      final recovery = await _recoverExact(
        restarted,
        fixture.projectPath,
        inspection.journal!,
      );
      expect(
          recovery.status, NarrativeEventSpatialLinkOperationStatus.recovered);
      expect(recovery.code, 'preparedNoOpRemoved');
      expect((await restarted.inspectProject(fixture.projectPath)).status,
          NarrativeEventSpatialLinkInspectionStatus.clear);
    });

    test(
        'recovery refuses journal B swapped after inspecting journal A without mutation',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      final interrupted = NarrativeEventSpatialLinkJournalRepository(
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventSpatialLinkCheckpoint.afterJournalPrepared) {
            throw const FileSystemException('simulated process crash');
          }
        },
      );
      await expectLater(
        interrupted.commitMap(_request(fixture)),
        throwsA(isA<FileSystemException>()),
      );
      final restarted = NarrativeEventSpatialLinkJournalRepository();
      final inspected = await restarted.inspectProject(fixture.projectPath);
      final journalA = inspected.journal!;
      expect(
        inspected.status,
        NarrativeEventSpatialLinkInspectionStatus.preparedSourceAbsent,
      );
      final journalB = await _replaceJournalOperation(
        journalA,
        'phase_g_swapped_recovery_b',
      );
      final journalBBytes = await File(journalB.journalPath).readAsBytes();
      final projectBytes = await File(fixture.projectPath).readAsBytes();
      final mapBytes = await File(_mapPath(fixture)).readAsBytes();

      final recovery = await _recoverExact(
        restarted,
        fixture.projectPath,
        journalA,
      );

      expect(
          recovery.status, NarrativeEventSpatialLinkOperationStatus.conflict);
      expect(recovery.code, 'recoveryJournalMismatch');
      expect(await File(journalB.journalPath).readAsBytes(), journalBBytes);
      expect(await File(fixture.projectPath).readAsBytes(), projectBytes);
      expect(await File(_mapPath(fixture)).readAsBytes(), mapBytes);
      expect(await File(journalA.journalPath).exists(), isFalse);
    });

    test(
        'prepared no-op recovery removes artifacts even when target Event was deleted',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      final repository = NarrativeEventSpatialLinkJournalRepository(
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventSpatialLinkCheckpoint.afterJournalPrepared) {
            throw const FileSystemException('simulated process crash');
          }
        },
      );
      await expectLater(
        repository.commitMap(_request(fixture)),
        throwsA(isA<FileSystemException>()),
      );
      await _writeRegistry(
        fixture,
        persistenceRegistry(records: const []),
      );

      final restarted = NarrativeEventSpatialLinkJournalRepository();
      final inspection = await restarted.inspectProject(fixture.projectPath);
      expect(
        inspection.status,
        NarrativeEventSpatialLinkInspectionStatus.preparedSourceAbsent,
      );
      final recovery = await _recoverExact(
        restarted,
        fixture.projectPath,
        inspection.journal!,
      );
      expect(recovery.code, 'preparedNoOpRemoved');
      expect((await restarted.inspectProject(fixture.projectPath)).status,
          NarrativeEventSpatialLinkInspectionStatus.clear);
    });

    test('a crash after rename promotes exact prepared source to mapCommitted',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      final repository = NarrativeEventSpatialLinkJournalRepository(
        clock: () => DateTime.utc(2026, 7, 15, 8),
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventSpatialLinkCheckpoint.afterMapRename) {
            throw const FileSystemException('simulated process crash');
          }
        },
      );
      await expectLater(
        repository.commitMap(_request(fixture)),
        throwsA(isA<FileSystemException>()),
      );

      final restarted = NarrativeEventSpatialLinkJournalRepository(
        clock: () => DateTime.utc(2026, 7, 15, 9),
      );
      final inspection = await restarted.inspectProject(fixture.projectPath);
      expect(
        inspection.status,
        NarrativeEventSpatialLinkInspectionStatus.preparedSourcePresent,
      );
      final recovery = await _recoverExact(
        restarted,
        fixture.projectPath,
        inspection.journal!,
      );
      expect(
          recovery.status, NarrativeEventSpatialLinkOperationStatus.recovered);
      expect(recovery.code, 'preparedPromotedToMapCommitted');
      expect(recovery.journal?.state,
          NarrativeEventSpatialLinkJournalState.mapCommitted);
      expect((await _readMap(fixture)).entities.single.id, 'entity_event');
    });

    test('unknown malformed and multiple journals block fail-closed', () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      final repository = NarrativeEventSpatialLinkJournalRepository();
      final committed = await repository.commitMap(_request(fixture));
      final journalFile = File(committed.journal!.journalPath);
      final raw = _object(jsonDecode(await journalFile.readAsString()));
      raw['schemaVersion'] = 99;
      await journalFile.writeAsString(jsonEncode(raw), flush: true);

      final unknown = await repository.inspectProject(fixture.projectPath);
      expect(unknown.status, NarrativeEventSpatialLinkInspectionStatus.blocked);
      expect(unknown.issues.single.code, 'invalidJournal');
      expect(await _readMap(fixture), _afterMap);

      await File('${journalFile.path}.copy.journal.json').writeAsString(
        '{broken',
        flush: true,
      );
      final multiple = await repository.inspectProject(fixture.projectPath);
      expect(
          multiple.status, NarrativeEventSpatialLinkInspectionStatus.blocked);
      expect(multiple.issues.map((issue) => issue.code),
          contains('multipleJournals'));
    });

    test(
        'eventCommitted is accepted only for the exact Event and waits for acknowledgement',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      final repository = NarrativeEventSpatialLinkJournalRepository();
      await repository.commitMap(_request(fixture));

      final rejected = await repository.markEventCommitted(
        projectPath: fixture.projectPath,
        operationId: 'phase_g_add_source',
      );
      expect(rejected.status, NarrativeEventSpatialLinkOperationStatus.blocked);
      expect(rejected.code, 'eventNotLinked');

      await _writeRegistrySource(fixture, source: _source);
      final committed = await repository.markEventCommitted(
        projectPath: fixture.projectPath,
        operationId: 'phase_g_add_source',
      );
      expect(
        committed.status,
        NarrativeEventSpatialLinkOperationStatus.eventCommitted,
      );
      expect(committed.journal?.state,
          NarrativeEventSpatialLinkJournalState.eventCommitted);
      expect(await File(committed.journal!.journalPath).exists(), isTrue);
      expect(
        (await repository.inspectProject(fixture.projectPath)).status,
        NarrativeEventSpatialLinkInspectionStatus.eventAlreadyLinked,
      );

      final acknowledged = await repository.acknowledgeEventCommitted(
        projectPath: fixture.projectPath,
        operationId: 'phase_g_add_source',
      );

      expect(
        acknowledged.status,
        NarrativeEventSpatialLinkOperationStatus.eventCommitted,
      );
      expect(acknowledged.code, 'eventCommitAcknowledged');
      expect(await File(committed.journal!.journalPath).exists(), isFalse);
      expect(
        (await repository.inspectProject(fixture.projectPath)).status,
        NarrativeEventSpatialLinkInspectionStatus.clear,
      );
    });

    test(
        'inspection blocks retry when the target Event changed after map commit',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      final repository = NarrativeEventSpatialLinkJournalRepository();
      await repository.commitMap(_request(fixture));
      await _writeRegistry(
        fixture,
        persistenceRegistry(records: [
          persistenceDraft(name: 'Changed after map commit'),
        ]),
      );

      final inspection = await repository.inspectProject(fixture.projectPath);

      expect(
          inspection.status, NarrativeEventSpatialLinkInspectionStatus.blocked);
      expect(inspection.issues.single.code, 'eventRecordChanged');
    });

    test(
        'inspection blocks retry when the target Event was deleted after map commit',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      final repository = NarrativeEventSpatialLinkJournalRepository();
      await repository.commitMap(_request(fixture));
      await _writeRegistry(
        fixture,
        persistenceRegistry(records: const []),
      );

      final inspection = await repository.inspectProject(fixture.projectPath);

      expect(
          inspection.status, NarrativeEventSpatialLinkInspectionStatus.blocked);
      expect(inspection.issues.single.code, 'eventRecordMissing');
    });

    test('cleanup deletes only the unchanged owner from the current disk map',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      final repository = NarrativeEventSpatialLinkJournalRepository();
      await repository.commitMap(_request(fixture));
      final current = await _readMap(fixture);
      const unrelated = MapEntity(
        id: 'unrelated',
        name: 'Keep me',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 6, y: 4),
      );
      await _writeMap(
          fixture,
          current.copyWith(entities: [
            ...current.entities,
            unrelated,
          ]));

      final cleanup = await repository.cleanupSource(
        projectPath: fixture.projectPath,
        operationId: 'phase_g_add_source',
        confirmed: true,
      );

      expect(cleanup.status, NarrativeEventSpatialLinkOperationStatus.cleaned);
      final afterCleanup = await _readMap(fixture);
      expect(afterCleanup.entities, [unrelated]);
      expect(await File(cleanup.journal!.journalPath).exists(), isFalse);
    });

    test(
        'cleanup refuses no confirmation modified owner and incoherent absence',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      final repository = NarrativeEventSpatialLinkJournalRepository();
      await repository.commitMap(_request(fixture));

      final notConfirmed = await repository.cleanupSource(
        projectPath: fixture.projectPath,
        operationId: 'phase_g_add_source',
        confirmed: false,
      );
      expect(notConfirmed.code, 'confirmationRequired');
      expect((await _readMap(fixture)).entities, isNotEmpty);

      final changed = (await _readMap(fixture)).copyWith(entities: [
        _entity.copyWith(name: 'Changed after creation'),
      ]);
      await _writeMap(fixture, changed);
      final modified = await repository.cleanupSource(
        projectPath: fixture.projectPath,
        operationId: 'phase_g_add_source',
        confirmed: true,
      );
      expect(modified.code, 'sourceFingerprintMismatch');
      expect((await _readMap(fixture)).entities.single.name,
          'Changed after creation');

      await _writeMap(fixture, changed.copyWith(entities: const []));
      final absent = await repository.cleanupSource(
        projectPath: fixture.projectPath,
        operationId: 'phase_g_add_source',
        confirmed: true,
      );
      expect(absent.code, 'sourceUnexpectedlyAbsent');
    });

    test('cleanup refuses when any other Event record references the source',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      final repository = NarrativeEventSpatialLinkJournalRepository();
      await repository.commitMap(_request(fixture));
      await _writeRegistry(
        fixture,
        persistenceRegistry(records: [
          persistenceDraft(),
          persistenceDraft(id: persistenceEventB, source: _source),
        ]),
      );
      final mapBytesBefore = await File(_mapPath(fixture)).readAsBytes();

      final cleanup = await repository.cleanupSource(
        projectPath: fixture.projectPath,
        operationId: 'phase_g_add_source',
        confirmed: true,
      );

      expect(cleanup.status, NarrativeEventSpatialLinkOperationStatus.blocked);
      expect(cleanup.code, 'sourceReferencedByAnotherEvent');
      expect(await File(_mapPath(fixture)).readAsBytes(), mapBytesBefore);
      expect((await _readMap(fixture)).entities.single.id, 'entity_event');
    });

    test('cleanup refuses a legacy claim that directly owns the atomic source',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      final repository = NarrativeEventSpatialLinkJournalRepository();
      await repository.commitMap(_request(fixture));
      await _writeRegistry(
        fixture,
        persistenceRegistry(
          mode: EventSystemMode.dualRead,
          records: [persistenceDraft()],
          claims: [_legacyClaimFor(_source)],
        ),
      );
      final mapBytesBefore = await File(_mapPath(fixture)).readAsBytes();

      final cleanup = await repository.cleanupSource(
        projectPath: fixture.projectPath,
        operationId: 'phase_g_add_source',
        confirmed: true,
      );

      expect(cleanup.status, NarrativeEventSpatialLinkOperationStatus.blocked);
      expect(cleanup.code, 'sourceReferencedByLegacyClaim');
      expect(await File(_mapPath(fixture)).readAsBytes(), mapBytesBefore);
    });

    test('cleanup preserves an unrelated manifest change made before it starts',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      final repository = NarrativeEventSpatialLinkJournalRepository();
      await repository.commitMap(_request(fixture));
      final changedRoot = await _readProjectRoot(fixture)
        ..['unrelatedAfterMapCommit'] = {
          'preserve': true,
        };
      await File(fixture.projectPath).writeAsBytes(
        canonicalizeNarrativeEventJsonUtf8(changedRoot),
        flush: true,
      );

      final cleanup = await repository.cleanupSource(
        projectPath: fixture.projectPath,
        operationId: 'phase_g_add_source',
        confirmed: true,
      );

      expect(cleanup.status, NarrativeEventSpatialLinkOperationStatus.cleaned);
      expect((await _readMap(fixture)).entities, isEmpty);
      expect(
        (await _readProjectRoot(fixture))['unrelatedAfterMapCommit'],
        {'preserve': true},
      );
    });

    test('cleanup CAS blocks a manifest mutation during cleanup without rename',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      await NarrativeEventSpatialLinkJournalRepository()
          .commitMap(_request(fixture));
      final mapBytesBefore = await File(_mapPath(fixture)).readAsBytes();
      final repository = NarrativeEventSpatialLinkJournalRepository(
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventSpatialLinkCheckpoint.beforeCleanupRename) {
            final root = await _readProjectRoot(fixture)
              ..['changedDuringCleanup'] = true;
            await File(fixture.projectPath).writeAsBytes(
              canonicalizeNarrativeEventJsonUtf8(root),
              flush: true,
            );
          }
        },
      );

      final cleanup = await repository.cleanupSource(
        projectPath: fixture.projectPath,
        operationId: 'phase_g_add_source',
        confirmed: true,
      );

      expect(cleanup.status, NarrativeEventSpatialLinkOperationStatus.conflict);
      expect(cleanup.code, 'projectChangedDuringCleanup');
      expect(await File(_mapPath(fixture)).readAsBytes(), mapBytesBefore);
      expect((await _readProjectRoot(fixture))['changedDuringCleanup'], isTrue);
    });

    test('recovers cleanup after its exact-owner map rename became durable',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      await NarrativeEventSpatialLinkJournalRepository()
          .commitMap(_request(fixture));
      final crashing = NarrativeEventSpatialLinkJournalRepository(
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventSpatialLinkCheckpoint.afterCleanupRename) {
            throw const FileSystemException('simulated cleanup crash');
          }
        },
      );

      await expectLater(
        crashing.cleanupSource(
          projectPath: fixture.projectPath,
          operationId: 'phase_g_add_source',
          confirmed: true,
        ),
        throwsA(isA<FileSystemException>()),
      );

      final restarted = NarrativeEventSpatialLinkJournalRepository();
      final inspection = await restarted.inspectProject(fixture.projectPath);
      expect(
        inspection.status,
        NarrativeEventSpatialLinkInspectionStatus.cleanupCompleted,
      );
      final recovery = await _recoverExact(
        restarted,
        fixture.projectPath,
        inspection.journal!,
      );
      expect(recovery.code, 'cleanupRecovered');
      expect((await _readMap(fixture)).entities, isEmpty);
      expect((await restarted.inspectProject(fixture.projectPath)).status,
          NarrativeEventSpatialLinkInspectionStatus.clear);
    });

    test('refuses a map changed into a symbolic link immediately before rename',
        () async {
      final fixture = await _fixture();
      addTearDown(fixture.dispose);
      final mapPath = _mapPath(fixture);
      final backupPath = '$mapPath.external';
      await File(backupPath).writeAsBytes(
        await File(mapPath).readAsBytes(),
        flush: true,
      );
      final repository = NarrativeEventSpatialLinkJournalRepository(
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventSpatialLinkCheckpoint.beforeMapRename) {
            await File(mapPath).delete();
            await Link(mapPath).create(backupPath);
          }
        },
      );

      final result = await repository.commitMap(_request(fixture));

      expect(result.status, NarrativeEventSpatialLinkOperationStatus.blocked);
      expect(result.code, 'symbolicLinkRefused');
      expect(
        await FileSystemEntity.type(mapPath, followLinks: false),
        FileSystemEntityType.link,
      );
      expect((await _readMap(fixture)).entities, isEmpty);
    });

    test('refuses a manifest map reached through a symbolic link', () async {
      final fixture = await createPersistenceFixture(
        map: _beforeMap,
        mapViaSymbolicLink: true,
        registry: persistenceRegistry(records: [persistenceDraft()]),
      );
      addTearDown(fixture.dispose);

      final result = await NarrativeEventSpatialLinkJournalRepository()
          .commitMap(_request(fixture));

      expect(result.status, NarrativeEventSpatialLinkOperationStatus.blocked);
      expect(result.code, 'symbolicLinkRefused');
      expect((await _readMap(fixture)).entities, isEmpty);
    });
  });
}

final _source = NarrativeEventSourceRef.entityInteract('map_a', 'entity_event');
const _entity = MapEntity(
  id: 'entity_event',
  name: 'Invisible event source',
  kind: MapEntityKind.custom,
  pos: GridPos(x: 2, y: 3),
  blocksMovement: false,
);
const _beforeMap = MapData(
  id: 'map_a',
  name: 'Map A',
  size: GridSize(width: 8, height: 6),
);
const _afterMap = MapData(
  id: 'map_a',
  name: 'Map A',
  size: GridSize(width: 8, height: 6),
  entities: [_entity],
);
const _existingTrigger = MapTrigger(
  id: 'existing_trigger',
  name: 'Existing trigger',
  type: TriggerType.custom,
  area: MapRect(
    pos: GridPos(x: 0, y: 0),
    size: GridSize(width: 2, height: 1),
  ),
);
const _trigger = MapTrigger(
  id: 'trigger_event',
  name: 'Event zone',
  type: TriggerType.event,
  area: MapRect(
    pos: GridPos(x: 3, y: 2),
    size: GridSize(width: 1, height: 1),
  ),
);
const _triggerBeforeMap = MapData(
  id: 'map_a',
  name: 'Map A',
  size: GridSize(width: 8, height: 6),
  triggers: [_existingTrigger],
);
const _triggerAfterMap = MapData(
  id: 'map_a',
  name: 'Map A',
  size: GridSize(width: 8, height: 6),
  triggers: [_existingTrigger, _trigger],
);

final _ownerJson = _ownerEnvelope(_entity);
final _ownerFingerprint = narrativeEventBytesFingerprint(
  canonicalizeNarrativeEventJsonUtf8(_ownerJson),
);
final _eventRecordFingerprintBefore = narrativeEventBytesFingerprint(
  canonicalizeNarrativeEventJsonUtf8(persistenceDraft().toJson()),
);
final _triggerSource =
    NarrativeEventSourceRef.triggerEnter('map_a', 'trigger_event');
final _triggerOwnerJsonRaw = <String, Object?>{
  'schemaVersion': 1,
  'ownerKind': 'mapTrigger',
  'mapId': 'map_a',
  'sourceId': 'trigger_event',
  'owner': _trigger.toJson(),
};
final _triggerOwnerJsonSafe = _object(
  jsonDecode(jsonEncode(_triggerOwnerJsonRaw)),
);
final _triggerOwnerFingerprint = narrativeEventBytesFingerprint(
  canonicalizeNarrativeEventJsonUtf8(_triggerOwnerJsonSafe),
);

Future<EventRegistryPersistenceFixture> _fixture() {
  return createPersistenceFixture(
    map: _beforeMap,
    registry: persistenceRegistry(records: [persistenceDraft()]),
  );
}

Future<EventRegistryPersistenceFixture> _triggerFixture() {
  return createPersistenceFixture(
    map: _triggerBeforeMap,
    registry: persistenceRegistry(records: [persistenceDraft()]),
  );
}

NarrativeEventSpatialLinkMapCommitRequest _request(
  EventRegistryPersistenceFixture fixture,
) {
  return NarrativeEventSpatialLinkMapCommitRequest(
    projectPath: fixture.projectPath,
    projectRevision: fixture.revision,
    operationId: 'phase_g_add_source',
    eventId: persistenceEventA,
    eventRecordFingerprintBefore: _eventRecordFingerprintBefore,
    beforeMap: _beforeMap,
    afterMap: _afterMap,
    source: _source,
    sourceOwnerJson: _ownerJson,
    sourceOwnerFingerprint: _ownerFingerprint,
  );
}

NarrativeEventSpatialLinkMapCommitRequest _triggerRequest(
  EventRegistryPersistenceFixture fixture,
) {
  return NarrativeEventSpatialLinkMapCommitRequest(
    projectPath: fixture.projectPath,
    projectRevision: fixture.revision,
    operationId: 'phase_g_add_trigger',
    eventId: persistenceEventA,
    eventRecordFingerprintBefore: _eventRecordFingerprintBefore,
    beforeMap: _triggerBeforeMap,
    afterMap: _triggerAfterMap,
    source: _triggerSource,
    sourceOwnerJson: _triggerOwnerJsonRaw,
    sourceOwnerFingerprint: _triggerOwnerFingerprint,
  );
}

Map<String, Object?> _ownerEnvelope(MapEntity owner) => {
      'schemaVersion': 1,
      'ownerKind': 'mapEntity',
      'mapId': 'map_a',
      'sourceId': owner.id,
      'owner': owner.toJson(),
    };

String _mapPath(EventRegistryPersistenceFixture fixture) =>
    fixture.session.mapPaths['map_a']!;

Future<MapData> _readMap(EventRegistryPersistenceFixture fixture) async {
  final bytes = await File(_mapPath(fixture)).readAsBytes();
  final value = _object(decodeNarrativeEventJsonStrict(utf8.decode(bytes)));
  return MapData.fromJson(value.cast<String, dynamic>());
}

Future<void> _writeMap(
  EventRegistryPersistenceFixture fixture,
  MapData map,
) {
  return File(_mapPath(fixture)).writeAsBytes(
    canonicalizeNarrativeEventJsonUtf8(map.toJson()),
    flush: true,
  );
}

Future<void> _writeRegistrySource(
  EventRegistryPersistenceFixture fixture, {
  required NarrativeEventSourceRef source,
}) async {
  await _writeRegistry(
    fixture,
    persistenceRegistry(records: [
      persistenceDraft(source: source),
    ]),
  );
}

Future<void> _writeRegistry(
  EventRegistryPersistenceFixture fixture,
  NarrativeEventRegistry registry,
) async {
  final bytes = await File(fixture.projectPath).readAsBytes();
  final root = _object(decodeNarrativeEventJsonStrict(utf8.decode(bytes)));
  root['eventRegistry'] = registry.toJson();
  await File(fixture.projectPath).writeAsBytes(
    canonicalizeNarrativeEventJsonUtf8(root),
    flush: true,
  );
}

Future<NarrativeEventSpatialLinkJournal> _replaceJournalOperation(
  NarrativeEventSpatialLinkJournal journal,
  String operationId,
) async {
  final raw = _object(jsonDecode(jsonEncode(journal.toJson())));
  raw['operationId'] = operationId;
  raw['journalPath'] =
      journal.journalPath.replaceFirst(journal.operationId, operationId);
  raw['mapTempPath'] =
      journal.mapTempPath.replaceFirst(journal.operationId, operationId);
  final replacement = NarrativeEventSpatialLinkJournal.fromJson(raw);
  await File(replacement.journalPath).writeAsBytes(
    canonicalizeNarrativeEventJsonUtf8(replacement.toJson()),
    flush: true,
  );
  await File(journal.journalPath).delete();
  return replacement;
}

Future<NarrativeEventSpatialLinkOperationResult> _recoverExact(
  NarrativeEventSpatialLinkJournalRepository repository,
  String projectPath,
  NarrativeEventSpatialLinkJournal journal,
) {
  return repository.recoverProject(
    projectPath: projectPath,
    expectedOperationId: journal.operationId,
    expectedEventId: journal.eventId,
    expectedMapId: journal.mapId,
    expectedSource: journal.source,
  );
}

Future<Map<String, Object?>> _readProjectRoot(
  EventRegistryPersistenceFixture fixture,
) async {
  return _object(decodeNarrativeEventJsonStrict(
    await File(fixture.projectPath).readAsString(),
  ));
}

LegacySourceClaim _legacyClaimFor(NarrativeEventSourceRef source) {
  final member = LegacySourceClaimMember(
    provenance: LegacySourceRef.mapEvent('map_a', 'legacy_source'),
    sourceFingerprint:
        'sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
  );
  final cohortId = 'lsc_${narrativeEventCanonicalSha256({
        'source': source.toJson(),
        'provenances': [member.provenance.toJson()],
      })}';
  return LegacySourceClaim(
    cohortId: cohortId,
    source: source,
    members: [member],
    cohortFingerprint: 'sha256:${narrativeEventCanonicalSha256({
          'cohortId': cohortId,
          'members': [member.toJson()],
        })}',
    targetEventIds: const [persistenceEventA],
    migrationReceiptId: 'phase_g_legacy_claim',
  );
}

Map<String, Object?> _object(Object? value) {
  if (value is! Map) throw StateError('Expected a JSON object.');
  return value.map((key, value) => MapEntry(key as String, value));
}
