import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_migration_persistence_models.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:map_editor/src/application/models/narrative_event_registry_persistence_models.dart';
import 'package:map_editor/src/application/use_cases/narrative_event_migration_preview_use_case.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_event_migration_persistence_repository.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_event_registry_persistence.dart';
import 'package:path/path.dart' as p;

import 'support/event_registry_persistence_fixtures.dart';

void main() {
  group('I4 migration preview and persistence', () {
    test('preview is byte-identical and exposes a complete planner summary',
        () async {
      final fixture = await createPersistenceFixture(map: _legacyMap());
      addTearDown(fixture.dispose);
      final before = await fixture.readBytes();
      final preview = await _useCase().preview(fixture.projectPath);

      expect(await fixture.readBytes(), before);
      expect(preview.plan.status, NarrativeEventMigrationPlanStatus.ready);
      expect(preview.canCommit, isTrue);
      expect(preview.legacyItemCount, 1);
      expect(preview.proposedEventCount, 1);
      expect(preview.proposedClaimCount, 1);
      expect(preview.choiceCount, 1);
      expect(preview.receipt, isNotNull);
      expect(preview.modeBefore, EventSystemMode.legacyOnly);
      expect(preview.modeAfter, EventSystemMode.legacyOnly);
    });

    test('commit reloads reproducibly and compensation restores exact bytes',
        () async {
      final fixture = await createPersistenceFixture(map: _legacyMap());
      addTearDown(fixture.dispose);
      final before = await fixture.readBytes();
      final preview = await _useCase().preview(fixture.projectPath);
      final repository = NarrativeEventMigrationPersistenceRepository();

      final committed = await repository.commit(
        NarrativeEventMigrationCommitRequest(preview: preview),
      );
      expect(
        committed.status,
        NarrativeEventMigrationPersistenceStatus.committed,
        reason: '${committed.code}: ${committed.message}',
      );
      final reloaded = await NarrativeEventAuthoringSession.prepare(
        fixture.projectPath,
      );
      expect(reloaded.manifest.eventRegistry?.mode, EventSystemMode.legacyOnly);
      expect(reloaded.manifest.eventRegistry?.records, hasLength(1));
      expect(reloaded.manifest.eventRegistry?.legacyClaims, hasLength(1));

      final compensated = await repository.compensate(
        NarrativeEventMigrationCompensationRequest(
          projectPath: fixture.projectPath,
          receiptId: preview.receipt!.receiptId,
        ),
      );
      expect(
        compensated.status,
        NarrativeEventMigrationPersistenceStatus.compensated,
      );
      expect(await fixture.readBytes(), before);
    });

    test('recovers a prepared journal and blocks divergent compensation',
        () async {
      final recoveryFixture = await createPersistenceFixture(map: _legacyMap());
      addTearDown(recoveryFixture.dispose);
      final recoveryBefore = await recoveryFixture.readBytes();
      final recoveryPreview =
          await _useCase().preview(recoveryFixture.projectPath);
      final crashing = NarrativeEventMigrationPersistenceRepository(
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventMigrationWriteCheckpoint.afterJournalPrepared) {
            throw const FileSystemException('simulated crash');
          }
        },
      );

      final interrupted = await crashing.commit(
        NarrativeEventMigrationCommitRequest(preview: recoveryPreview),
      );
      expect(
        interrupted.status,
        NarrativeEventMigrationPersistenceStatus.recoveryRequired,
        reason: '${interrupted.code}: ${interrupted.message}',
      );
      expect((await crashing.inspect(recoveryFixture.projectPath)).status,
          NarrativeEventMigrationInspectionStatus.recoveryRequired);
      final recovered = await crashing.recover(recoveryFixture.projectPath);
      expect(
          recovered.status, NarrativeEventMigrationPersistenceStatus.recovered);
      expect(await recoveryFixture.readBytes(), recoveryBefore);

      final divergentFixture =
          await createPersistenceFixture(map: _legacyMap());
      addTearDown(divergentFixture.dispose);
      final divergentPreview =
          await _useCase().preview(divergentFixture.projectPath);
      final repository = NarrativeEventMigrationPersistenceRepository();
      final committed = await repository.commit(
        NarrativeEventMigrationCommitRequest(preview: divergentPreview),
      );
      expect(committed.succeeded, isTrue);
      final file = File(divergentFixture.projectPath);
      await file.writeAsString(
        '${await file.readAsString()}\n',
        flush: true,
      );
      final divergentBytes = await file.readAsBytes();

      final blocked = await repository.compensate(
        NarrativeEventMigrationCompensationRequest(
          projectPath: divergentFixture.projectPath,
          receiptId: divergentPreview.receipt!.receiptId,
        ),
      );
      expect(blocked.status, NarrativeEventMigrationPersistenceStatus.blocked);
      expect(blocked.code, 'projectRevisionDiverged');
      expect(await file.readAsBytes(), divergentBytes);
      expect(await File(committed.journalPath!).exists(), isTrue);
    });

    test('rejects a commit when project bytes changed after preview', () async {
      final fixture = await createPersistenceFixture(map: _legacyMap());
      addTearDown(fixture.dispose);
      final preview = await _useCase().preview(fixture.projectPath);
      final projectFile = File(fixture.projectPath);
      await projectFile.writeAsString(
        '${await projectFile.readAsString()}\n',
        flush: true,
      );
      final changedBytes = await projectFile.readAsBytes();

      final result = await NarrativeEventMigrationPersistenceRepository()
          .commit(NarrativeEventMigrationCommitRequest(preview: preview));

      expect(
        result.status,
        NarrativeEventMigrationPersistenceStatus.staleRevision,
      );
      expect(result.code, 'staleProjectRevision');
      expect(await projectFile.readAsBytes(), changedBytes);
    });

    test('finalizes an applied project after a crash before journal commit',
        () async {
      final fixture = await createPersistenceFixture(map: _legacyMap());
      addTearDown(fixture.dispose);
      final preview = await _useCase().preview(fixture.projectPath);
      final repository = NarrativeEventMigrationPersistenceRepository(
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventMigrationWriteCheckpoint.afterProjectRenamed) {
            throw const FileSystemException('simulated applied crash');
          }
        },
      );

      final interrupted = await repository.commit(
        NarrativeEventMigrationCommitRequest(preview: preview),
      );
      expect(
        interrupted.status,
        NarrativeEventMigrationPersistenceStatus.recoveryRequired,
      );
      final recovered = await repository.recover(fixture.projectPath);
      expect(
        recovered.status,
        NarrativeEventMigrationPersistenceStatus.recovered,
      );
      expect(recovered.code, 'preparedMigrationFinalized');
      final reloaded = await NarrativeEventAuthoringSession.prepare(
        fixture.projectPath,
      );
      expect(reloaded.manifest.eventRegistry?.records, hasLength(1));
    });

    test('blocks recovery when prepared receipt evidence was altered',
        () async {
      final fixture = await createPersistenceFixture(map: _legacyMap());
      addTearDown(fixture.dispose);
      final before = await fixture.readBytes();
      final preview = await _useCase().preview(fixture.projectPath);
      final repository = NarrativeEventMigrationPersistenceRepository(
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventMigrationWriteCheckpoint.afterJournalPrepared) {
            throw const FileSystemException('simulated prepared crash');
          }
        },
      );
      final interrupted = await repository.commit(
        NarrativeEventMigrationCommitRequest(preview: preview),
      );
      final receiptFile = File(interrupted.receiptPath!);
      await receiptFile.writeAsString(
        '${await receiptFile.readAsString()}\n',
        flush: true,
      );

      final recovered = await repository.recover(fixture.projectPath);

      expect(
        recovered.status,
        NarrativeEventMigrationPersistenceStatus.blocked,
      );
      expect(recovered.code, 'migrationReceiptMismatch');
      expect(await fixture.readBytes(), before);
    });

    test('blocks an unsafe receipt path stored in a prepared journal',
        () async {
      final fixture = await createPersistenceFixture(map: _legacyMap());
      addTearDown(fixture.dispose);
      final before = await fixture.readBytes();
      final preview = await _useCase().preview(fixture.projectPath);
      final repository = NarrativeEventMigrationPersistenceRepository(
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventMigrationWriteCheckpoint.afterJournalPrepared) {
            throw const FileSystemException('simulated prepared crash');
          }
        },
      );
      final interrupted = await repository.commit(
        NarrativeEventMigrationCommitRequest(preview: preview),
      );
      await _mutateJson(interrupted.journalPath!, (json) {
        json['receiptId'] = '../outside';
      });

      final recovered = await repository.recover(fixture.projectPath);

      expect(
        recovered.status,
        NarrativeEventMigrationPersistenceStatus.blocked,
      );
      expect(recovered.code, 'invalidReceiptId');
      expect(await fixture.readBytes(), before);
    });

    test('blocks compensation when receipt evidence was altered', () async {
      final committed = await _committedFixture();
      addTearDown(committed.fixture.dispose);
      final projectBytes = await committed.fixture.readBytes();
      final receiptFile = File(committed.result.receiptPath!);
      await receiptFile.writeAsString(
        '${await receiptFile.readAsString()}\n',
        flush: true,
      );

      final result = await committed.repository.compensate(
        NarrativeEventMigrationCompensationRequest(
          projectPath: committed.fixture.projectPath,
          receiptId: committed.preview.receipt!.receiptId,
        ),
      );

      expect(result.status, NarrativeEventMigrationPersistenceStatus.blocked);
      expect(result.code, 'migrationReceiptMismatch');
      expect(await committed.fixture.readBytes(), projectBytes);
    });

    test('blocks compensation when backup evidence was altered', () async {
      final committed = await _committedFixture();
      addTearDown(committed.fixture.dispose);
      final projectBytes = await committed.fixture.readBytes();
      final backupFile = File(
        p.join(
          p.dirname(committed.result.journalPath!),
          'project.before.json',
        ),
      );
      await backupFile.writeAsString(
        '${await backupFile.readAsString()}\n',
        flush: true,
      );

      final result = await committed.repository.compensate(
        NarrativeEventMigrationCompensationRequest(
          projectPath: committed.fixture.projectPath,
          receiptId: committed.preview.receipt!.receiptId,
        ),
      );

      expect(result.status, NarrativeEventMigrationPersistenceStatus.blocked);
      expect(result.code, 'backupHashMismatch');
      expect(await committed.fixture.readBytes(), projectBytes);
    });

    test('blocks coordinated backup and journal hash tampering', () async {
      final committed = await _committedFixture();
      addTearDown(committed.fixture.dispose);
      final projectBytes = await committed.fixture.readBytes();
      final backupFile = File(
        p.join(
          p.dirname(committed.result.journalPath!),
          'project.before.json',
        ),
      );
      await backupFile.writeAsString(
        '{"name":"backup falsifié"}',
        flush: true,
      );
      final forgedHash = narrativeEventBytesFingerprint(
        await backupFile.readAsBytes(),
      );
      await _mutateJson(committed.result.journalPath!, (json) {
        json['backupHash'] = forgedHash;
      });

      final result = await committed.repository.compensate(
        NarrativeEventMigrationCompensationRequest(
          projectPath: committed.fixture.projectPath,
          receiptId: committed.preview.receipt!.receiptId,
        ),
      );

      expect(result.status, NarrativeEventMigrationPersistenceStatus.blocked);
      expect(result.code, 'backupHashMismatch');
      expect(await committed.fixture.readBytes(), projectBytes);
    });

    test('anchors coordinated journal revisions in the immutable receipt',
        () async {
      final committed = await _committedFixture();
      addTearDown(committed.fixture.dispose);
      final projectBytes = await committed.fixture.readBytes();
      final backupFile = File(
        p.join(
          p.dirname(committed.result.journalPath!),
          'project.before.json',
        ),
      );
      await backupFile.writeAsString(
        '{"name":"backup entièrement falsifié"}',
        flush: true,
      );
      final forgedRevision = narrativeEventBytesFingerprint(
        await backupFile.readAsBytes(),
      );
      await _mutateJson(committed.result.journalPath!, (json) {
        json['backupHash'] = forgedRevision;
        json['beforeRevision'] = forgedRevision;
        json['ownerFingerprint'] = 'sha256:${narrativeEventCanonicalSha256({
              'receiptId': json['receiptId'],
              'projectPath': json['projectPath'],
              'beforeRevision': forgedRevision,
              'expectedManifestHashAfter': json['expectedManifestHashAfter'],
            })}';
      });

      final result = await committed.repository.compensate(
        NarrativeEventMigrationCompensationRequest(
          projectPath: committed.fixture.projectPath,
          receiptId: committed.preview.receipt!.receiptId,
        ),
      );

      expect(result.status, NarrativeEventMigrationPersistenceStatus.blocked);
      expect(result.code, 'migrationReceiptMismatch');
      expect(await committed.fixture.readBytes(), projectBytes);
    });

    test('blocks compensation when journal ownership was altered', () async {
      final committed = await _committedFixture();
      addTearDown(committed.fixture.dispose);
      final projectBytes = await committed.fixture.readBytes();
      await _mutateJson(committed.result.journalPath!, (json) {
        json['ownerFingerprint'] =
            'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
      });

      final result = await committed.repository.compensate(
        NarrativeEventMigrationCompensationRequest(
          projectPath: committed.fixture.projectPath,
          receiptId: committed.preview.receipt!.receiptId,
        ),
      );

      expect(result.status, NarrativeEventMigrationPersistenceStatus.blocked);
      expect(result.code, 'migrationOwnershipMismatch');
      expect(await committed.fixture.readBytes(), projectBytes);
    });

    test('blocks compensation on semantic drift even with matching bytes hash',
        () async {
      final committed = await _committedFixture();
      addTearDown(committed.fixture.dispose);
      final projectFile = File(committed.fixture.projectPath);
      await _mutateJson(projectFile.path, (json) {
        json['name'] = 'Projet modifié après migration';
      });
      final changedBytes = await projectFile.readAsBytes();
      await _mutateJson(committed.result.journalPath!, (json) {
        json['afterRevision'] = narrativeEventBytesFingerprint(changedBytes);
      });

      final result = await committed.repository.compensate(
        NarrativeEventMigrationCompensationRequest(
          projectPath: committed.fixture.projectPath,
          receiptId: committed.preview.receipt!.receiptId,
        ),
      );

      expect(result.status, NarrativeEventMigrationPersistenceStatus.blocked);
      expect(result.code, 'migrationFingerprintMismatch');
      expect(await projectFile.readAsBytes(), changedBytes);
    });

    test('blocks migration while the canonical registry gate needs recovery',
        () async {
      final fixture = await createPersistenceFixture(map: _legacyMap());
      addTearDown(fixture.dispose);
      final preview = await _useCase().preview(fixture.projectPath);
      final interruptedRegistry = await NarrativeEventRegistryPersistence(
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventRegistryWriteCheckpoint.afterJournalPrepared) {
            throw const FileSystemException('simulated registry crash');
          }
        },
      ).write(
        persistenceRequest(
          fixture: fixture,
          operationId: 'i4_registry_recovery_gate',
          previousRegistry: null,
          nextRegistry: persistenceRegistry(),
        ),
      );
      expect(
        interruptedRegistry.status,
        NarrativeEventRegistryPersistenceStatus.ioFailure,
      );
      final repository = NarrativeEventMigrationPersistenceRepository();

      final inspection = await repository.inspect(fixture.projectPath);
      final commit = await repository.commit(
        NarrativeEventMigrationCommitRequest(preview: preview),
      );

      expect(
        inspection.status,
        NarrativeEventMigrationInspectionStatus.blocked,
      );
      expect(inspection.code, 'eventRegistryRecoveryGate');
      expect(commit.status, NarrativeEventMigrationPersistenceStatus.blocked);
      expect(commit.code, 'migrationRecoveryGate');
    });
  });
}

Future<
    ({
      EventRegistryPersistenceFixture fixture,
      NarrativeEventMigrationPreview preview,
      NarrativeEventMigrationPersistenceRepository repository,
      NarrativeEventMigrationPersistenceResult result,
    })> _committedFixture() async {
  final fixture = await createPersistenceFixture(map: _legacyMap());
  final preview = await _useCase().preview(fixture.projectPath);
  final repository = NarrativeEventMigrationPersistenceRepository();
  final result = await repository.commit(
    NarrativeEventMigrationCommitRequest(preview: preview),
  );
  expect(result.status, NarrativeEventMigrationPersistenceStatus.committed);
  return (
    fixture: fixture,
    preview: preview,
    repository: repository,
    result: result,
  );
}

Future<void> _mutateJson(
  String path,
  void Function(Map<String, Object?> json) mutate,
) async {
  final file = File(path);
  final decoded = jsonDecode(await file.readAsString());
  final json = Map<String, Object?>.from(decoded as Map);
  mutate(json);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(json),
    flush: true,
  );
}

NarrativeEventMigrationPreviewUseCase _useCase() {
  return NarrativeEventMigrationPreviewUseCase(
    ids: _Ids(),
    clock: () => DateTime.utc(2026, 7, 17, 10),
  );
}

MapData _legacyMap() {
  return const MapData(
    id: 'map_a',
    name: 'Map A',
    size: GridSize(width: 8, height: 6),
    layers: [MapLayer.object(id: 'events', name: 'Events')],
    entities: [
      MapEntity(
        id: 'npc_a',
        name: 'NPC A',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 1, y: 1),
      ),
    ],
    events: [
      MapEventDefinition(
        id: 'legacy_a',
        title: 'Rencontre legacy',
        position: EventPosition(layerId: 'events', x: 1, y: 1),
        metadata: {
          LegacyMapEventCompatibilityMetadataKeys.entityId: 'npc_a',
        },
        pages: [
          MapEventPage(
            pageNumber: 0,
            sceneTarget: MapEventSceneTarget(sceneId: 'scene_a'),
          ),
        ],
      ),
    ],
  );
}

final class _Ids implements NarrativeEventMigrationIdSource {
  var _event = 0;
  var _receipt = 0;

  @override
  String nextEventId() {
    _event++;
    return 'evt_019abcde-0000-7000-8000-${_event.toString().padLeft(12, '0')}';
  }

  @override
  String nextReceiptId() {
    _receipt++;
    return 'evmr_019abcde-0000-7000-8000-${_receipt.toString().padLeft(12, '0')}';
  }
}
