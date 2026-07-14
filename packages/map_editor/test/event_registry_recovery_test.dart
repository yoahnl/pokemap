import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:map_editor/src/application/models/narrative_event_registry_persistence_models.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_event_registry_persistence.dart';
import 'package:path/path.dart' as p;

import 'support/event_registry_persistence_fixtures.dart';

void main() {
  group('NS-EVENT-V2 Phase E4 recovery', () {
    test('rolls back a prepared before-hash journal idempotently', () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      const operationId = 'e4_recover_before';
      await _interrupt(
        fixture,
        operationId,
        NarrativeEventRegistryWriteCheckpoint.afterTempFlush,
      );
      final journalPath = narrativeEventRegistryJournalPath(
        fixture.projectPath,
        operationId,
      );
      final service = NarrativeEventRegistryPersistence();
      final first = await service.recoverJournal(journalPath);
      final second = await service.recoverJournal(journalPath);

      expect(first.status, NarrativeEventRegistryPersistenceStatus.recovered);
      expect(first.code, 'rolledBackBeforeCommit');
      expect(await fixture.readBytes(), fixture.initialBytes);
      expect(
          first.journal!.state, NarrativeEventRegistryJournalState.recovered);
      expect(await File(first.journal!.backupPath).exists(), isFalse);
      expect(await File(first.journal!.tempPath).exists(), isFalse);
      expect(second.status, NarrativeEventRegistryPersistenceStatus.noOp);
      expect(second.code, 'alreadyRecovered');
      expect(
        await fixture.readSentinelBytes(),
        fixture.initialSentinelBytes,
      );
    });

    test('isolates journals for manifests sharing a directory and operation id',
        () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      final secondProjectPath = p.join(fixture.root.path, 'project_b.json');
      await File(secondProjectPath).writeAsBytes(
        fixture.initialBytes,
        flush: true,
      );
      final canonicalSecondProjectPath =
          await File(secondProjectPath).resolveSymbolicLinks();
      const operationId = 'e4_shared_operation';
      await _interruptProject(
        fixture.projectPath,
        fixture.revision,
        operationId,
        NarrativeEventRegistryWriteCheckpoint.afterJournalPrepared,
      );
      await _interruptProject(
        canonicalSecondProjectPath,
        fixture.revision,
        operationId,
        NarrativeEventRegistryWriteCheckpoint.afterJournalPrepared,
      );

      final firstResults = await NarrativeEventRegistryPersistence()
          .recoverProject(fixture.projectPath);
      final secondJournalPath = narrativeEventRegistryJournalPath(
        canonicalSecondProjectPath,
        operationId,
      );

      expect(firstResults, hasLength(1));
      expect(firstResults.single.code, 'rolledBackBeforeCommit');
      expect(await File(secondJournalPath).exists(), isTrue);
      final secondResults = await NarrativeEventRegistryPersistence()
          .recoverProject(canonicalSecondProjectPath);
      expect(secondResults, hasLength(1));
      expect(secondResults.single.code, 'rolledBackBeforeCommit');
    });

    test('blocks a backup orphaned before journal publication', () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      await _interrupt(
        fixture,
        'e4_orphan_backup',
        NarrativeEventRegistryWriteCheckpoint.afterBackup,
      );
      final results = await NarrativeEventRegistryPersistence()
          .recoverProject(fixture.projectPath);

      expect(results, hasLength(1));
      expect(results.single.status,
          NarrativeEventRegistryPersistenceStatus.blocked);
      expect(results.single.code, 'orphanBackup');
      expect(await fixture.readBytes(), fixture.initialBytes);
      expect(
        (await NarrativeEventRegistryPersistence()
                .recoverProject(fixture.projectPath))
            .single
            .code,
        'orphanBackup',
      );
    });

    test('finalizes a visible rename without rewriting project bytes',
        () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      const operationId = 'e4_recover_after';
      await _interrupt(
        fixture,
        operationId,
        NarrativeEventRegistryWriteCheckpoint.afterRename,
      );
      final beforeRecovery = await fixture.readBytes();
      final recovery = await NarrativeEventRegistryPersistence().recoverJournal(
        narrativeEventRegistryJournalPath(fixture.projectPath, operationId),
      );

      expect(
          recovery.status, NarrativeEventRegistryPersistenceStatus.recovered);
      expect(recovery.code, 'commitFinalized');
      expect(await fixture.readBytes(), beforeRecovery);
      expect(recovery.journal!.state,
          NarrativeEventRegistryJournalState.committed);
      expect(recovery.undoEntry, isNotNull);
      expect(
        await File(narrativeEventRegistryUndoPath(
          fixture.projectPath,
          operationId,
        )).exists(),
        isTrue,
      );
    });

    test('blocks unknown project hashes without any recovery write', () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      const operationId = 'e4_recover_unknown';
      await _interrupt(
        fixture,
        operationId,
        NarrativeEventRegistryWriteCheckpoint.afterJournalPrepared,
      );
      final root = Map<String, Object?>.from(await fixture.readRoot())
        ..['concurrent'] = 'unknown hash';
      final unknownBytes = canonicalizeNarrativeEventJsonUtf8(root);
      await File(fixture.projectPath).writeAsBytes(unknownBytes, flush: true);
      final recovery = await NarrativeEventRegistryPersistence().recoverJournal(
        narrativeEventRegistryJournalPath(fixture.projectPath, operationId),
      );

      expect(recovery.status, NarrativeEventRegistryPersistenceStatus.blocked);
      expect(recovery.code, 'unknownProjectRevision');
      expect(await fixture.readBytes(), unknownBytes);
    });

    test('blocks multiple prepared journals without choosing one', () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      await _interrupt(
        fixture,
        'e4_prepared_one',
        NarrativeEventRegistryWriteCheckpoint.afterJournalPrepared,
      );
      final firstPath = narrativeEventRegistryJournalPath(
        fixture.projectPath,
        'e4_prepared_one',
      );
      final secondPath = narrativeEventRegistryJournalPath(
        fixture.projectPath,
        'e4_prepared_two',
      );
      final firstJson = jsonObject(
        jsonDecode(await File(firstPath).readAsString()),
      );
      final firstStem = firstPath.substring(
        0,
        firstPath.length -
            NarrativeEventRegistryPersistence.journalSuffix.length,
      );
      final secondStem = secondPath.substring(
        0,
        secondPath.length -
            NarrativeEventRegistryPersistence.journalSuffix.length,
      );
      final secondBackup =
          '$secondStem${NarrativeEventRegistryPersistence.backupSuffix}';
      final secondJson = Map<String, Object?>.from(firstJson)
        ..['operationId'] = 'e4_prepared_two'
        ..['journalPath'] = secondPath
        ..['tempPath'] =
            '$secondStem${NarrativeEventRegistryPersistence.tempSuffix}'
        ..['backupPath'] = secondBackup;
      await File(
        '$firstStem${NarrativeEventRegistryPersistence.backupSuffix}',
      ).copy(secondBackup);
      await File(secondPath).writeAsString(jsonEncode(secondJson), flush: true);
      final beforeRecovery = await fixture.readBytes();
      final results = await NarrativeEventRegistryPersistence()
          .recoverProject(fixture.projectPath);

      expect(
        results.map((result) => result.code),
        contains('multiplePreparedJournals'),
      );
      expect(await fixture.readBytes(), beforeRecovery);
    });

    test('blocks missing and corrupt backups', () async {
      for (final corrupt in [false, true]) {
        final fixture = await createPersistenceFixture();
        addTearDown(fixture.dispose);
        final operationId = corrupt ? 'e4_backup_corrupt' : 'e4_backup_missing';
        await _interrupt(
          fixture,
          operationId,
          NarrativeEventRegistryWriteCheckpoint.afterJournalPrepared,
        );
        final journalPath = narrativeEventRegistryJournalPath(
          fixture.projectPath,
          operationId,
        );
        final journalJson = jsonObject(decodeNarrativeEventJsonStrict(
          await File(journalPath).readAsString(),
        ));
        final backup = File(journalJson['backupPath']! as String);
        if (corrupt) {
          await backup.writeAsString('corrupt', flush: true);
        } else {
          await backup.delete();
        }
        final beforeRecovery = await fixture.readBytes();
        final recovery = await NarrativeEventRegistryPersistence()
            .recoverJournal(journalPath);

        expect(
            recovery.status, NarrativeEventRegistryPersistenceStatus.blocked);
        expect(
          recovery.code,
          corrupt ? 'backupCorrupt' : 'backupMissing',
        );
        expect(await fixture.readBytes(), beforeRecovery);
      }
    });

    test('discards a corrupt temp when the project is still before', () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      const operationId = 'e4_corrupt_temp_rollback';
      await _interrupt(
        fixture,
        operationId,
        NarrativeEventRegistryWriteCheckpoint.afterTempFlush,
      );
      final journalPath = narrativeEventRegistryJournalPath(
        fixture.projectPath,
        operationId,
      );
      final journalJson = jsonObject(decodeNarrativeEventJsonStrict(
        await File(journalPath).readAsString(),
      ));
      final temp = File(journalJson['tempPath']! as String);
      await temp.writeAsString('corrupt', flush: true);
      final recovery =
          await NarrativeEventRegistryPersistence().recoverJournal(journalPath);

      expect(
          recovery.status, NarrativeEventRegistryPersistenceStatus.recovered);
      expect(recovery.code, 'rolledBackBeforeCommit');
      expect(await fixture.readBytes(), fixture.initialBytes);
      expect(await temp.exists(), isFalse);
    });

    test('keeps a backup when its journal is unreadable during project scan',
        () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      const operationId = 'e4_unreadable_journal_backup';
      await _interrupt(
        fixture,
        operationId,
        NarrativeEventRegistryWriteCheckpoint.afterJournalPrepared,
      );
      final journalPath = narrativeEventRegistryJournalPath(
        fixture.projectPath,
        operationId,
      );
      final journal = jsonObject(decodeNarrativeEventJsonStrict(
        await File(journalPath).readAsString(),
      ));
      final backup = File(journal['backupPath']! as String);
      await File(journalPath).writeAsString('{invalid', flush: true);

      final results = await NarrativeEventRegistryPersistence()
          .recoverProject(fixture.projectPath);

      expect(results.map((result) => result.code), contains('invalidJournal'));
      expect(await backup.exists(), isTrue);
      expect(await fixture.readBytes(), fixture.initialBytes);
    });

    test('recovers safely when a journal rewrite temp is already present',
        () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      const operationId = 'e4_journal_rewrite_window';
      await _interrupt(
        fixture,
        operationId,
        NarrativeEventRegistryWriteCheckpoint.afterJournalPrepared,
      );
      final journalPath = narrativeEventRegistryJournalPath(
        fixture.projectPath,
        operationId,
      );
      final rewritePath = '$journalPath.rewrite.tmp';
      await File(journalPath).copy(rewritePath);

      final results = await NarrativeEventRegistryPersistence()
          .recoverProject(fixture.projectPath);

      expect(
        results.map((result) => result.code),
        contains('rolledBackBeforeCommit'),
      );
      expect(await File(rewritePath).exists(), isFalse);
      expect(await fixture.readBytes(), fixture.initialBytes);
    });

    test('ignores completed historical journals after a later write', () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      final firstRegistry = persistenceRegistry();
      final service = NarrativeEventRegistryPersistence();
      final first = await service.write(
        persistenceRequest(
          fixture: fixture,
          operationId: 'e4_history_first',
          previousRegistry: null,
          nextRegistry: firstRegistry,
        ),
      );
      final secondRegistry = persistenceRegistry(
        records: [persistenceDraft(name: 'Second')],
      );
      expect(first.status, NarrativeEventRegistryPersistenceStatus.committed);
      final secondSession = await NarrativeEventAuthoringSession.prepare(
        fixture.projectPath,
      );
      final second = await service.write(
        persistenceRequest(
          fixture: fixture,
          operationId: 'e4_history_second',
          session: secondSession,
          previousRegistry: firstRegistry,
          nextRegistry: secondRegistry,
          mutation: 'rename',
        ),
      );
      final bytesBeforeRecovery = await fixture.readBytes();
      final results = await service.recoverProject(fixture.projectPath);

      expect(second.status, NarrativeEventRegistryPersistenceStatus.committed);
      expect(results, hasLength(2));
      expect(
        results.map((result) => result.status),
        everyElement(NarrativeEventRegistryPersistenceStatus.noOp),
      );
      expect(await fixture.readBytes(), bytesBeforeRecovery);
    });
  });
}

Future<void> _interrupt(
  EventRegistryPersistenceFixture fixture,
  String operationId,
  NarrativeEventRegistryWriteCheckpoint target,
) async {
  return _interruptProject(
    fixture.projectPath,
    fixture.revision,
    operationId,
    target,
  );
}

Future<void> _interruptProject(
  String projectPath,
  String revision,
  String operationId,
  NarrativeEventRegistryWriteCheckpoint target,
) async {
  final service = NarrativeEventRegistryPersistence(
    faultInjector: (checkpoint) async {
      if (checkpoint == target) throw _RecoveryFault();
    },
  );
  final session = await NarrativeEventAuthoringSession.prepare(projectPath);
  expect(session.projectRevision, revision);
  await expectLater(
    service.write(
      NarrativeEventRegistryWriteRequest.fromAuthoringSession(
        session: session,
        operationId: operationId,
        result: persistenceAuthoringResult(
          previousRegistry: null,
          nextRegistry: persistenceRegistry(),
          expectedRevision: revision,
          context: session.context,
        ),
      ),
    ),
    throwsA(isA<_RecoveryFault>()),
  );
}

final class _RecoveryFault implements Exception {}
