import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_registry_persistence_models.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_event_registry_persistence.dart';

import 'support/event_registry_persistence_fixtures.dart';

void main() {
  group('NS-EVENT-V2 Phase E4 write journal', () {
    test('records a strict committed journal and immutable undo entry',
        () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      final result = await NarrativeEventRegistryPersistence(
        clock: () => DateTime.utc(2026, 7, 14, 10, 30),
      ).write(
        persistenceRequest(
          fixture: fixture,
          operationId: 'e4_journal_contract',
          previousRegistry: null,
          nextRegistry: persistenceRegistry(),
        ),
      );

      final journalPath = narrativeEventRegistryJournalPath(
        fixture.projectPath,
        'e4_journal_contract',
      );
      final undoPath = narrativeEventRegistryUndoPath(
        fixture.projectPath,
        'e4_journal_contract',
      );
      final journalJson = jsonObject(decodeNarrativeEventJsonStrict(
        await File(journalPath).readAsString(),
      ));
      final undoJson = jsonObject(decodeNarrativeEventJsonStrict(
        await File(undoPath).readAsString(),
      ));

      expect(result.status, NarrativeEventRegistryPersistenceStatus.committed);
      expect(journalJson['schemaVersion'], 1);
      expect(journalJson['operationId'], 'e4_journal_contract');
      expect(journalJson['projectPath'], fixture.projectPath);
      expect(journalJson['beforeHash'], fixture.revision);
      expect(journalJson['expectedAfterHash'], result.afterRevision);
      expect(journalJson['state'], 'committed');
      expect(journalJson['preparedAt'], '2026-07-14T10:30:00.000Z');
      expect(journalJson['committedAt'], '2026-07-14T10:30:00.000Z');
      expect(journalJson['eventIds'], [persistenceEventA]);
      expect(journalJson['mutation'], 'createDraft');
      expect(journalJson['previousRegistryHash'], startsWith('sha256:'));
      expect(journalJson['nextRegistryHash'], startsWith('sha256:'));
      expect(undoJson['beforeRevision'], fixture.revision);
      expect(undoJson['afterRevision'], result.afterRevision);
      expect(undoJson['previousRegistry'], isNull);
      expect(undoJson['nextRegistry'], isA<Map>());
      expect(await File(result.journal!.backupPath).exists(), isFalse);
      expect(await File(result.journal!.tempPath).exists(), isFalse);
    });

    test('fault matrix leaves an honest recoverable state at every checkpoint',
        () async {
      for (final checkpoint in NarrativeEventRegistryWriteCheckpoint.values) {
        final fixture = await createPersistenceFixture();
        addTearDown(fixture.dispose);
        final operationId = 'e4_fault_${checkpoint.name}';
        final service = NarrativeEventRegistryPersistence(
          faultInjector: (current) async {
            if (current == checkpoint) throw _InjectedFault(checkpoint);
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
          throwsA(isA<_InjectedFault>()),
        );
        final currentHash = narrativeEventRegistryProjectRevision(
          await fixture.readBytes(),
        );
        final journalPath = narrativeEventRegistryJournalPath(
          fixture.projectPath,
          operationId,
        );
        final journalExists = await File(journalPath).exists();
        final renameVisible = checkpoint.index >=
            NarrativeEventRegistryWriteCheckpoint.afterRename.index;
        expect(
          currentHash == fixture.revision,
          !renameVisible,
          reason: checkpoint.name,
        );
        expect(
          journalExists,
          checkpoint.index >=
              NarrativeEventRegistryWriteCheckpoint.afterJournalPrepared.index,
          reason: checkpoint.name,
        );
        if (journalExists) {
          final recovery = await NarrativeEventRegistryPersistence()
              .recoverJournal(journalPath);
          expect(
            recovery.status,
            NarrativeEventRegistryPersistenceStatus.recovered,
            reason: checkpoint.name,
          );
          if (renameVisible) {
            expect(
              recovery.afterRevision,
              isNot(fixture.revision),
              reason: checkpoint.name,
            );
            expect(
              await File(narrativeEventRegistryUndoPath(
                fixture.projectPath,
                operationId,
              )).exists(),
              isTrue,
              reason: checkpoint.name,
            );
          } else {
            expect(await fixture.readBytes(), fixture.initialBytes,
                reason: checkpoint.name);
          }
        }
      }
    });

    test('rejects a duplicate-key journal without touching the project',
        () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      const operationId = 'e4_corrupt_journal';
      final service = NarrativeEventRegistryPersistence(
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventRegistryWriteCheckpoint.afterJournalPrepared) {
            throw _InjectedFault(checkpoint);
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
        throwsA(isA<_InjectedFault>()),
      );
      final journalPath = narrativeEventRegistryJournalPath(
        fixture.projectPath,
        operationId,
      );
      final source = await File(journalPath).readAsString();
      final duplicate = source.replaceFirst(
        '{',
        '{"schemaVersion":1,',
      );
      await File(journalPath).writeAsString(duplicate, flush: true);
      final beforeRecovery = await fixture.readBytes();
      final recovery =
          await NarrativeEventRegistryPersistence().recoverJournal(journalPath);

      expect(recovery.status, NarrativeEventRegistryPersistenceStatus.blocked);
      expect(recovery.code, 'invalidJournal');
      expect(await fixture.readBytes(), beforeRecovery);
    });

    test('rejects tampered hashes lifecycle and fields in journal metadata',
        () async {
      for (final kind in ['hash', 'lifecycle', 'field']) {
        final fixture = await createPersistenceFixture();
        addTearDown(fixture.dispose);
        final operationId = 'e4_tampered_journal_$kind';
        final service = NarrativeEventRegistryPersistence(
          faultInjector: (checkpoint) async {
            if (checkpoint ==
                NarrativeEventRegistryWriteCheckpoint.afterJournalPrepared) {
              throw _InjectedFault(checkpoint);
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
          throwsA(isA<_InjectedFault>()),
        );
        final journalPath = narrativeEventRegistryJournalPath(
          fixture.projectPath,
          operationId,
        );
        final journalJson = jsonObject(decodeNarrativeEventJsonStrict(
          await File(journalPath).readAsString(),
        ));
        switch (kind) {
          case 'hash':
            journalJson['nextRegistryHash'] =
                'sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
          case 'lifecycle':
            journalJson['committedAt'] = journalJson['preparedAt'];
          case 'field':
            journalJson['unexpected'] = true;
        }
        await File(journalPath).writeAsBytes(
          canonicalizeNarrativeEventJsonUtf8(journalJson),
          flush: true,
        );
        final beforeRecovery = await fixture.readBytes();
        final recovery = await NarrativeEventRegistryPersistence()
            .recoverJournal(journalPath);

        expect(
          recovery.status,
          NarrativeEventRegistryPersistenceStatus.blocked,
          reason: kind,
        );
        expect(recovery.code, 'invalidJournal', reason: kind);
        expect(await fixture.readBytes(), beforeRecovery, reason: kind);
      }
    });

    test('blocks a committed journal paired with inconsistent undo metadata',
        () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      const operationId = 'e4_inconsistent_undo';
      final result = await NarrativeEventRegistryPersistence().write(
        persistenceRequest(
          fixture: fixture,
          operationId: operationId,
          previousRegistry: null,
          nextRegistry: persistenceRegistry(),
        ),
      );
      final undoPath = narrativeEventRegistryUndoPath(
        fixture.projectPath,
        operationId,
      );
      final undoJson = jsonObject(decodeNarrativeEventJsonStrict(
        await File(undoPath).readAsString(),
      ))
        ..['eventIds'] = [persistenceEventB];
      await File(undoPath).writeAsBytes(
        canonicalizeNarrativeEventJsonUtf8(undoJson),
        flush: true,
      );
      final bytesBeforeRecovery = await fixture.readBytes();
      final recovery = await NarrativeEventRegistryPersistence()
          .recoverJournal(result.journal!.journalPath);

      expect(recovery.status, NarrativeEventRegistryPersistenceStatus.blocked);
      expect(recovery.code, 'inconsistentUndo');
      expect(await fixture.readBytes(), bytesBeforeRecovery);
    });

    test('blocks a committed journal paired with corrupt undo JSON', () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      const operationId = 'e4_corrupt_committed_undo';
      final result = await NarrativeEventRegistryPersistence().write(
        persistenceRequest(
          fixture: fixture,
          operationId: operationId,
          previousRegistry: null,
          nextRegistry: persistenceRegistry(),
        ),
      );
      await File(narrativeEventRegistryUndoPath(
        fixture.projectPath,
        operationId,
      )).writeAsString('{"schemaVersion":1', flush: true);
      final bytesBeforeRecovery = await fixture.readBytes();
      final recovery = await NarrativeEventRegistryPersistence()
          .recoverJournal(result.journal!.journalPath);

      expect(recovery.status, NarrativeEventRegistryPersistenceStatus.blocked);
      expect(recovery.code, 'invalidUndo');
      expect(await fixture.readBytes(), bytesBeforeRecovery);
    });

    test('reports recovery required after a post-rename IO failure', () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      const operationId = 'e4_post_rename_io';
      final service = NarrativeEventRegistryPersistence(
        faultInjector: (checkpoint) async {
          if (checkpoint == NarrativeEventRegistryWriteCheckpoint.afterRename) {
            throw const FileSystemException('Injected post-rename failure');
          }
        },
      );
      final result = await service.write(
        persistenceRequest(
          fixture: fixture,
          operationId: operationId,
          previousRegistry: null,
          nextRegistry: persistenceRegistry(),
        ),
      );

      expect(result.status,
          NarrativeEventRegistryPersistenceStatus.recoveryRequired);
      expect(result.code, 'recoveryRequired');
      expect(await fixture.readBytes(), isNot(fixture.initialBytes));
      final recovery = await NarrativeEventRegistryPersistence().recoverProject(
        fixture.projectPath,
      );
      expect(
        recovery.map((entry) => entry.status),
        contains(NarrativeEventRegistryPersistenceStatus.recovered),
      );
    });
  });
}

final class _InjectedFault implements Exception {
  const _InjectedFault(this.checkpoint);

  final NarrativeEventRegistryWriteCheckpoint checkpoint;

  @override
  String toString() => 'Injected fault at ${checkpoint.name}';
}
