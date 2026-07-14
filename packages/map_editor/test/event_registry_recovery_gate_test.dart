import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/narrative_event_registry_persistence_models.dart';
import 'package:map_editor/src/application/ports/narrative_event_registry_persistence_gateway.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_event_registry_persistence.dart';
import 'package:path/path.dart' as p;

import 'support/event_registry_persistence_fixtures.dart';

void main() {
  group('NS-EVENT-V2 Phase E-bis-C recovery gate', () {
    test('prepared journal blocks event write generic save and load', () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      final repository = FileProjectRepository();
      final manifest = await repository.loadProject(fixture.projectPath);
      await _interruptPrepared(fixture, 'e_bis_pending');
      final bytesBefore = await fixture.readBytes();
      final journalPath = narrativeEventRegistryJournalPath(
        fixture.projectPath,
        'e_bis_pending',
      );

      final inspection = await NarrativeEventRegistryPersistence()
          .inspectProject(fixture.projectPath);
      final NarrativeEventRegistryPersistenceGateway gateway = repository;
      final gatewayInspection = await gateway.inspectRecovery(
        fixture.projectPath,
      );
      final eventResult = await NarrativeEventRegistryPersistence().write(
        persistenceRequest(
          fixture: fixture,
          operationId: 'e_bis_blocked_write',
          previousRegistry: null,
          nextRegistry: persistenceRegistry(),
        ),
      );

      expect(
        inspection.status,
        NarrativeEventRegistryRecoveryGateStatus.recoveryRequired,
      );
      expect(
        eventResult.status,
        NarrativeEventRegistryPersistenceStatus.recoveryRequired,
      );
      expect(gatewayInspection.status, inspection.status);
      expect(eventResult.recoveryInspection?.issues.single.path, journalPath);
      await expectLater(
        repository.saveProject(manifest, fixture.projectPath),
        throwsA(
          isA<ProjectRecoveryRequiredException>()
              .having((error) => error.code, 'code', 'preparedJournal')
              .having((error) => error.path, 'path', journalPath),
        ),
      );
      await expectLater(
        repository.loadProject(fixture.projectPath),
        throwsA(isA<ProjectRecoveryRequiredException>()),
      );
      expect(await fixture.readBytes(), bytesBefore);
      expect(await File(journalPath).exists(), isTrue);
      expect(
        await File(narrativeEventRegistryJournalPath(
          fixture.projectPath,
          'e_bis_blocked_write',
        )).exists(),
        isFalse,
      );
    });

    test('explicit recovery is the only action that unlocks access', () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      final repository = FileProjectRepository();
      await _interruptPrepared(fixture, 'e_bis_unlock');

      await expectLater(
        repository.loadProject(fixture.projectPath),
        throwsA(isA<ProjectRecoveryRequiredException>()),
      );
      final recovered = await NarrativeEventRegistryPersistence()
          .recoverProject(fixture.projectPath);
      final inspection = await NarrativeEventRegistryPersistence()
          .inspectProject(fixture.projectPath);
      final manifest = await repository.loadProject(fixture.projectPath);
      await repository.saveProject(
        manifest.copyWith(name: 'Unlocked'),
        fixture.projectPath,
      );

      expect(recovered.single.code, 'rolledBackBeforeCommit');
      expect(inspection.status, NarrativeEventRegistryRecoveryGateStatus.clear);
      expect((await fixture.readRoot())['name'], 'Unlocked');
    });

    test('invalid prepared prerequisites block without partial mutation',
        () async {
      await _expectPreparedRecoveryBlocker(
        operationId: 'e_bis_backup_missing',
        expectedCode: 'backupMissing',
        corrupt: (fixture, journal) => File(journal.backupPath).delete(),
      );
      await _expectPreparedRecoveryBlocker(
        operationId: 'e_bis_backup_corrupt',
        expectedCode: 'backupCorrupt',
        corrupt: (fixture, journal) =>
            File(journal.backupPath).writeAsString('corrupt', flush: true),
      );
      await _expectPreparedRecoveryBlocker(
        operationId: 'e_bis_unknown_revision',
        expectedCode: 'unknownProjectRevision',
        corrupt: (fixture, journal) =>
            File(fixture.projectPath).writeAsString('unknown', flush: true),
      );
      await _expectPreparedRecoveryBlocker(
        operationId: 'e_bis_temp_corrupt',
        expectedCode: 'tempCorrupt',
        corrupt: (fixture, journal) async {
          await File(fixture.projectPath).writeAsString('after', flush: true);
          await File(journal.tempPath).writeAsString('corrupt', flush: true);
        },
      );
    });

    test('associated undo rewrite is removed by explicit recovery', () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      const operationId = 'e_bis_undo_rewrite';
      await _writePreparedJournal(
        projectPath: fixture.projectPath,
        projectBytes: fixture.initialBytes,
        operationId: operationId,
      );
      final rewritePath =
          '${narrativeEventRegistryUndoPath(fixture.projectPath, operationId)}.rewrite.tmp';
      await File(rewritePath).writeAsString('partial', flush: true);

      final before = await NarrativeEventRegistryPersistence()
          .inspectProject(fixture.projectPath);
      final recovery = await NarrativeEventRegistryPersistence()
          .recoverProject(fixture.projectPath);
      final after = await NarrativeEventRegistryPersistence()
          .inspectProject(fixture.projectPath);

      expect(
        before.status,
        NarrativeEventRegistryRecoveryGateStatus.recoveryRequired,
      );
      expect(recovery.single.code, 'rolledBackBeforeCommit');
      expect(await File(rewritePath).exists(), isFalse);
      expect(after.status, NarrativeEventRegistryRecoveryGateStatus.clear);
    });

    test('project recovery resolves a symbolic-link alias', () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      const operationId = 'e_bis_symlink_recovery';
      await _writePreparedJournal(
        projectPath: fixture.projectPath,
        projectBytes: fixture.initialBytes,
        operationId: operationId,
      );
      final aliasPath = p.join(fixture.root.path, 'project-alias.json');
      await Link(aliasPath).create(fixture.projectPath);

      final recovery =
          await NarrativeEventRegistryPersistence().recoverProject(aliasPath);
      final inspection = await NarrativeEventRegistryPersistence()
          .inspectProject(fixture.projectPath);

      expect(recovery.single.code, 'rolledBackBeforeCommit');
      expect(inspection.status, NarrativeEventRegistryRecoveryGateStatus.clear);
    });

    test('unreadable journal blocks fail-closed without partial recovery',
        () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      final repository = FileProjectRepository();
      final manifest = await repository.loadProject(fixture.projectPath);
      final validJournal = await _writePreparedJournal(
        projectPath: fixture.projectPath,
        projectBytes: fixture.initialBytes,
        operationId: 'e_bis_valid_pending',
      );
      final unreadableJournal = await _writePreparedJournal(
        projectPath: fixture.projectPath,
        projectBytes: fixture.initialBytes,
        operationId: 'e_bis_unreadable',
      );
      await File(unreadableJournal.journalPath).writeAsString(
        '{not-json',
        flush: true,
      );
      final bytesBefore = await fixture.readBytes();
      final validBackupBytes =
          await File(validJournal.backupPath).readAsBytes();

      final inspection = await NarrativeEventRegistryPersistence()
          .inspectProject(fixture.projectPath);
      final eventResult = await NarrativeEventRegistryPersistence().write(
        persistenceRequest(
          fixture: fixture,
          operationId: 'e_bis_unreadable_blocked_write',
          previousRegistry: null,
          nextRegistry: persistenceRegistry(),
        ),
      );
      final results = await NarrativeEventRegistryPersistence()
          .recoverProject(fixture.projectPath);
      final singleRecovery = await NarrativeEventRegistryPersistence()
          .recoverJournal(validJournal.journalPath);

      expect(
        inspection.status,
        NarrativeEventRegistryRecoveryGateStatus.recoveryBlocked,
      );
      expect(results, hasLength(1));
      expect(results.single.status,
          NarrativeEventRegistryPersistenceStatus.blocked);
      expect(
          eventResult.status, NarrativeEventRegistryPersistenceStatus.blocked);
      expect(singleRecovery.status,
          NarrativeEventRegistryPersistenceStatus.blocked);
      expect(
        eventResult.recoveryInspection?.issues
            .where((issue) => issue.code == 'invalidJournal')
            .single
            .path,
        unreadableJournal.journalPath,
      );
      await expectLater(
        repository.saveProject(manifest, fixture.projectPath),
        throwsA(isA<ProjectRecoveryBlockedException>()),
      );
      await expectLater(
        repository.loadProject(fixture.projectPath),
        throwsA(
          isA<ProjectRecoveryBlockedException>()
              .having(
                (error) => error.message,
                'message',
                contains('inspectée'),
              )
              .having((error) => error.code, 'code', 'invalidJournal')
              .having(
                (error) => error.path,
                'path',
                unreadableJournal.journalPath,
              ),
        ),
      );
      expect(await fixture.readBytes(), bytesBefore);
      expect(await File(validJournal.journalPath).exists(), isTrue);
      expect(
        await File(validJournal.backupPath).readAsBytes(),
        validBackupBytes,
      );
    });

    test('multiple prepared journals and orphan rewrite temp block', () async {
      final multiple = await createPersistenceFixture();
      addTearDown(multiple.dispose);
      final repository = FileProjectRepository();
      final manifest = await repository.loadProject(multiple.projectPath);
      await _writePreparedJournal(
        projectPath: multiple.projectPath,
        projectBytes: multiple.initialBytes,
        operationId: 'e_bis_multiple_a',
      );
      await _writePreparedJournal(
        projectPath: multiple.projectPath,
        projectBytes: multiple.initialBytes,
        operationId: 'e_bis_multiple_b',
      );

      final multipleInspection = await NarrativeEventRegistryPersistence()
          .inspectProject(multiple.projectPath);

      expect(
        multipleInspection.status,
        NarrativeEventRegistryRecoveryGateStatus.recoveryBlocked,
      );
      expect(
        multipleInspection.issues.map((issue) => issue.code),
        contains('multiplePreparedJournals'),
      );
      final blockedWrite = await NarrativeEventRegistryPersistence().write(
        persistenceRequest(
          fixture: multiple,
          operationId: 'e_bis_multiple_blocked_write',
          previousRegistry: null,
          nextRegistry: persistenceRegistry(),
        ),
      );
      expect(
          blockedWrite.status, NarrativeEventRegistryPersistenceStatus.blocked);
      await expectLater(
        repository.saveProject(manifest, multiple.projectPath),
        throwsA(isA<ProjectRecoveryBlockedException>()),
      );
      await expectLater(
        repository.loadProject(multiple.projectPath),
        throwsA(isA<ProjectRecoveryBlockedException>()),
      );

      final rewrite = await createPersistenceFixture();
      addTearDown(rewrite.dispose);
      final journalPath = narrativeEventRegistryJournalPath(
        rewrite.projectPath,
        'e_bis_orphan_rewrite',
      );
      await File('$journalPath.rewrite.tmp').writeAsString('{}', flush: true);
      final rewriteInspection = await NarrativeEventRegistryPersistence()
          .inspectProject(rewrite.projectPath);

      expect(
        rewriteInspection.status,
        NarrativeEventRegistryRecoveryGateStatus.recoveryBlocked,
      );
      expect(
        rewriteInspection.issues.map((issue) => issue.code),
        contains('orphanJournalRewrite'),
      );
    });

    test('coherent committed and recovered history does not block', () async {
      final committed = await createPersistenceFixture();
      addTearDown(committed.dispose);
      final write = await NarrativeEventRegistryPersistence().write(
        persistenceRequest(
          fixture: committed,
          operationId: 'e_bis_committed_history',
          previousRegistry: null,
          nextRegistry: persistenceRegistry(),
        ),
      );
      final committedInspection = await NarrativeEventRegistryPersistence()
          .inspectProject(committed.projectPath);

      expect(write.status, NarrativeEventRegistryPersistenceStatus.committed);
      expect(
        committedInspection.status,
        NarrativeEventRegistryRecoveryGateStatus.clear,
      );
      expect(
        await FileProjectRepository().loadProject(committed.projectPath),
        isA<ProjectManifest>(),
      );

      final recovered = await createPersistenceFixture();
      addTearDown(recovered.dispose);
      await _interruptPrepared(recovered, 'e_bis_recovered_history');
      await NarrativeEventRegistryPersistence().recoverProject(
        recovered.projectPath,
      );
      final recoveredInspection = await NarrativeEventRegistryPersistence()
          .inspectProject(recovered.projectPath);

      expect(
        recoveredInspection.status,
        NarrativeEventRegistryRecoveryGateStatus.clear,
      );
      expect(
        await FileProjectRepository().loadProject(recovered.projectPath),
        isA<ProjectManifest>(),
      );
    });

    for (final corruptUndo in [false, true]) {
      test(
          'recovered journal with ${corruptUndo ? 'corrupt' : 'coherent'} undo blocks all access',
          () async {
        final fixture = await createPersistenceFixture();
        addTearDown(fixture.dispose);
        final repository = FileProjectRepository();
        final manifest = await repository.loadProject(fixture.projectPath);
        final operationId = corruptUndo
            ? 'e_bis_recovered_corrupt_undo'
            : 'e_bis_recovered_coherent_undo';
        final prepared = await _writePreparedJournal(
          projectPath: fixture.projectPath,
          projectBytes: fixture.initialBytes,
          operationId: operationId,
        );
        final recovery = await NarrativeEventRegistryPersistence()
            .recoverProject(fixture.projectPath);
        expect(recovery.single.code, 'rolledBackBeforeCommit');
        final undoPath = narrativeEventRegistryUndoPath(
          fixture.projectPath,
          operationId,
        );
        if (corruptUndo) {
          await File(undoPath).writeAsString('{invalid', flush: true);
        } else {
          final undo = NarrativeEventRegistryUndoEntry(
            schemaVersion: 1,
            operationId: prepared.operationId,
            projectPath: prepared.projectPath,
            beforeRevision: prepared.beforeHash,
            afterRevision: prepared.expectedAfterHash,
            previousRegistry: prepared.previousRegistry,
            nextRegistry: prepared.nextRegistry,
            previousRegistryHash: prepared.previousRegistryHash,
            nextRegistryHash: prepared.nextRegistryHash,
            eventIds: prepared.eventIds,
            createdAt: prepared.preparedAt.add(const Duration(seconds: 1)),
          );
          await File(undoPath).writeAsBytes(
            canonicalizeNarrativeEventJsonUtf8(undo.toJson()),
            flush: true,
          );
        }
        final before = await fixture.readBytes();

        final inspection = await NarrativeEventRegistryPersistence()
            .inspectProject(fixture.projectPath);
        final eventResult = await NarrativeEventRegistryPersistence().write(
          persistenceRequest(
            fixture: fixture,
            operationId: '${operationId}_blocked_write',
            previousRegistry: null,
            nextRegistry: persistenceRegistry(),
          ),
        );
        final undoResult =
            await NarrativeEventRegistryPersistence().undo(undoPath);

        expect(
          inspection.status,
          NarrativeEventRegistryRecoveryGateStatus.recoveryBlocked,
        );
        expect(
          inspection.issues.map((issue) => issue.code),
          contains('unexpectedRecoveredUndo'),
        );
        expect(
          eventResult.status,
          NarrativeEventRegistryPersistenceStatus.blocked,
        );
        expect(
          undoResult.status,
          NarrativeEventRegistryPersistenceStatus.blocked,
        );
        await expectLater(
          repository.saveProject(manifest, fixture.projectPath),
          throwsA(isA<ProjectRecoveryBlockedException>()),
        );
        await expectLater(
          repository.loadProject(fixture.projectPath),
          throwsA(isA<ProjectRecoveryBlockedException>()),
        );
        expect(await fixture.readBytes(), before);
        expect(await File(undoPath).exists(), isTrue);
      });
    }

    test('unsafe journal paths and ambiguous orphan artifacts block', () async {
      final unsafe = await createPersistenceFixture();
      addTearDown(unsafe.dispose);
      final journal = await _writePreparedJournal(
        projectPath: unsafe.projectPath,
        projectBytes: unsafe.initialBytes,
        operationId: 'e_bis_unsafe',
      );
      final unsafeJson = journal.toJson()
        ..['journalPath'] = p.join(unsafe.root.path, 'unsafe.json');
      await File(journal.journalPath).writeAsString(
        jsonEncode(unsafeJson),
        flush: true,
      );
      final unsafeInspection = await NarrativeEventRegistryPersistence()
          .inspectProject(unsafe.projectPath);
      expect(
        unsafeInspection.status,
        NarrativeEventRegistryRecoveryGateStatus.recoveryBlocked,
      );
      expect(
        unsafeInspection.issues.map((issue) => issue.code),
        contains('unsafeJournalPaths'),
      );

      final orphan = await createPersistenceFixture();
      addTearDown(orphan.dispose);
      final orphanJournal = narrativeEventRegistryJournalPath(
        orphan.projectPath,
        'e_bis_orphan',
      );
      final orphanStem = orphanJournal.substring(
        0,
        orphanJournal.length -
            NarrativeEventRegistryPersistence.journalSuffix.length,
      );
      await File(
        '$orphanStem${NarrativeEventRegistryPersistence.backupSuffix}',
      ).writeAsBytes(orphan.initialBytes, flush: true);
      await File(
        '$orphanStem${NarrativeEventRegistryPersistence.tempSuffix}',
      ).writeAsString('orphan', flush: true);
      final orphanInspection = await NarrativeEventRegistryPersistence()
          .inspectProject(orphan.projectPath);
      expect(
        orphanInspection.status,
        NarrativeEventRegistryRecoveryGateStatus.recoveryBlocked,
      );
      expect(
        orphanInspection.issues.map((issue) => issue.code),
        contains('orphanBackup'),
      );
      expect(
        orphanInspection.issues.map((issue) => issue.code),
        contains('orphanTemp'),
      );
    });

    test('orphan undo blocks inspection and cannot mutate the project',
        () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      const operationId = 'e_bis_orphan_undo';
      final persistence = NarrativeEventRegistryPersistence();
      final write = await persistence.write(
        persistenceRequest(
          fixture: fixture,
          operationId: operationId,
          previousRegistry: null,
          nextRegistry: persistenceRegistry(),
        ),
      );
      expect(write.status, NarrativeEventRegistryPersistenceStatus.committed);
      final journalPath = narrativeEventRegistryJournalPath(
        fixture.projectPath,
        operationId,
      );
      final undoPath = narrativeEventRegistryUndoPath(
        fixture.projectPath,
        operationId,
      );
      await File(journalPath).delete();
      final before = await fixture.readBytes();

      final inspection = await persistence.inspectProject(fixture.projectPath);
      final undo = await persistence.undo(undoPath);

      expect(
        inspection.status,
        NarrativeEventRegistryRecoveryGateStatus.recoveryBlocked,
      );
      expect(
        inspection.issues.map((issue) => issue.code),
        contains('orphanUndo'),
      );
      expect(undo.status, NarrativeEventRegistryPersistenceStatus.blocked);
      expect(undo.recoveryInspection?.issues.single.path, undoPath);
      expect(await fixture.readBytes(), before);
    });

    test('symbolic-link persistence artifact blocks fail-closed', () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      final targetPath = p.join(fixture.root.path, 'foreign-journal.json');
      await File(targetPath).writeAsString('{}', flush: true);
      final journalPath = narrativeEventRegistryJournalPath(
        fixture.projectPath,
        'e_bis_link_artifact',
      );
      await Link(journalPath).create(targetPath);

      final inspection = await NarrativeEventRegistryPersistence()
          .inspectProject(fixture.projectPath);

      expect(
        inspection.status,
        NarrativeEventRegistryRecoveryGateStatus.recoveryBlocked,
      );
      expect(
        inspection.issues.map((issue) => issue.code),
        contains('unsafeArtifactLink'),
      );
      expect(inspection.issues.single.path, journalPath);
    });

    test('artifacts belonging to another project are ignored', () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      final secondPath = p.join(fixture.root.path, 'project_b.json');
      await File(secondPath).writeAsBytes(fixture.initialBytes, flush: true);
      final canonicalSecondPath = await File(secondPath).resolveSymbolicLinks();
      await _writePreparedJournal(
        projectPath: canonicalSecondPath,
        projectBytes: fixture.initialBytes,
        operationId: 'e_bis_foreign',
      );

      final inspection = await NarrativeEventRegistryPersistence()
          .inspectProject(fixture.projectPath);

      expect(inspection.status, NarrativeEventRegistryRecoveryGateStatus.clear);
      expect(
        await FileProjectRepository().loadProject(fixture.projectPath),
        isA<ProjectManifest>(),
      );
    });

    test('corrupt committed undo blocks manifest access', () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      const operationId = 'e_bis_corrupt_undo';
      final write = await NarrativeEventRegistryPersistence().write(
        persistenceRequest(
          fixture: fixture,
          operationId: operationId,
          previousRegistry: null,
          nextRegistry: persistenceRegistry(),
        ),
      );
      expect(write.status, NarrativeEventRegistryPersistenceStatus.committed);
      await File(narrativeEventRegistryUndoPath(
        fixture.projectPath,
        operationId,
      )).writeAsString('{invalid', flush: true);

      final inspection = await NarrativeEventRegistryPersistence()
          .inspectProject(fixture.projectPath);

      expect(
        inspection.status,
        NarrativeEventRegistryRecoveryGateStatus.recoveryBlocked,
      );
      await expectLater(
        FileProjectRepository().loadProject(fixture.projectPath),
        throwsA(isA<ProjectRecoveryBlockedException>()),
      );
    });
  });
}

Future<void> _expectPreparedRecoveryBlocker({
  required String operationId,
  required String expectedCode,
  required Future<void> Function(
    EventRegistryPersistenceFixture fixture,
    NarrativeEventRegistryWriteJournal journal,
  ) corrupt,
}) async {
  final fixture = await createPersistenceFixture();
  addTearDown(fixture.dispose);
  final journal = await _writePreparedJournal(
    projectPath: fixture.projectPath,
    projectBytes: fixture.initialBytes,
    operationId: operationId,
  );
  await corrupt(fixture, journal);
  final paths = [
    fixture.projectPath,
    journal.journalPath,
    journal.backupPath,
    journal.tempPath,
    '${journal.journalPath}.rewrite.tmp',
    narrativeEventRegistryUndoPath(fixture.projectPath, operationId),
    '${narrativeEventRegistryUndoPath(fixture.projectPath, operationId)}.rewrite.tmp',
  ];
  final before = await _readExistingArtifacts(paths);

  final inspection = await NarrativeEventRegistryPersistence()
      .inspectProject(fixture.projectPath);
  final recovery = await NarrativeEventRegistryPersistence()
      .recoverProject(fixture.projectPath);
  final after = await _readExistingArtifacts(paths);

  expect(
    inspection.status,
    NarrativeEventRegistryRecoveryGateStatus.recoveryBlocked,
  );
  expect(inspection.issues.map((issue) => issue.code), contains(expectedCode));
  expect(recovery, hasLength(1));
  expect(
      recovery.single.status, NarrativeEventRegistryPersistenceStatus.blocked);
  expect(recovery.single.code, expectedCode);
  expect(after, before);
}

Future<Map<String, List<int>>> _readExistingArtifacts(
  Iterable<String> paths,
) async {
  final artifacts = <String, List<int>>{};
  for (final path in paths) {
    final file = File(path);
    if (await file.exists()) artifacts[path] = await file.readAsBytes();
  }
  return artifacts;
}

Future<void> _interruptPrepared(
  EventRegistryPersistenceFixture fixture,
  String operationId,
) async {
  final service = NarrativeEventRegistryPersistence(
    faultInjector: (checkpoint) async {
      if (checkpoint ==
          NarrativeEventRegistryWriteCheckpoint.afterJournalPrepared) {
        throw const _RecoveryGateFault();
      }
    },
  );
  await expectLater(
    service.write(
      persistenceRequest(
        fixture: fixture,
        operationId: operationId,
        previousRegistry: null,
        nextRegistry: persistenceRegistry(),
      ),
    ),
    throwsA(isA<_RecoveryGateFault>()),
  );
}

Future<NarrativeEventRegistryWriteJournal> _writePreparedJournal({
  required String projectPath,
  required List<int> projectBytes,
  required String operationId,
}) async {
  final journalPath = narrativeEventRegistryJournalPath(
    projectPath,
    operationId,
  );
  final stem = journalPath.substring(
    0,
    journalPath.length - NarrativeEventRegistryPersistence.journalSuffix.length,
  );
  final previousHash = narrativeEventBytesFingerprint(
    canonicalizeNarrativeEventJsonUtf8(null),
  );
  final nextRegistry = persistenceRegistry();
  final nextHash = narrativeEventBytesFingerprint(
    canonicalizeNarrativeEventJsonUtf8(nextRegistry.toJson()),
  );
  final journal = NarrativeEventRegistryWriteJournal(
    schemaVersion: 1,
    operationId: operationId,
    projectPath: projectPath,
    journalPath: journalPath,
    beforeHash: narrativeEventBytesFingerprint(projectBytes),
    expectedAfterHash: narrativeEventBytesFingerprint(utf8.encode('after')),
    tempPath: '$stem${NarrativeEventRegistryPersistence.tempSuffix}',
    backupPath: '$stem${NarrativeEventRegistryPersistence.backupSuffix}',
    state: NarrativeEventRegistryJournalState.prepared,
    preparedAt: DateTime.utc(2026, 7, 14),
    eventIds: const [persistenceEventA],
    mutation: 'createDraft',
    previousRegistryHash: previousHash,
    nextRegistryHash: nextHash,
    previousRegistry: null,
    nextRegistry: nextRegistry,
  );
  await File(journal.backupPath).writeAsBytes(projectBytes, flush: true);
  await File(journal.journalPath).writeAsBytes(
    canonicalizeNarrativeEventJsonUtf8(journal.toJson()),
    flush: true,
  );
  return journal;
}

final class _RecoveryGateFault implements Exception {
  const _RecoveryGateFault();
}
