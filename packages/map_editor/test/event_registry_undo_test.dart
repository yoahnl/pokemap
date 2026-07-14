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
  group('NS-EVENT-V2 Phase E4 undo', () {
    test('restores an absent registry through the journaled pipeline',
        () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      const operationId = 'e4_undo_absent';
      final service = NarrativeEventRegistryPersistence();
      final write = await service.write(
        persistenceRequest(
          fixture: fixture,
          operationId: operationId,
          previousRegistry: null,
          nextRegistry: persistenceRegistry(),
        ),
      );
      final undo = await service.undo(
        narrativeEventRegistryUndoPath(fixture.projectPath, operationId),
      );

      expect(write.status, NarrativeEventRegistryPersistenceStatus.committed);
      expect(undo.status, NarrativeEventRegistryPersistenceStatus.committed);
      expect(undo.beforeRevision, write.afterRevision);
      expect(undo.afterRevision, isNot(write.afterRevision));
      final root = await fixture.readRoot();
      expect(root.containsKey('eventRegistry'), isFalse);
      expect(withoutRegistry(root), withoutRegistry(fixture.initialRoot));

      final repeated = await service.undo(
        narrativeEventRegistryUndoPath(fixture.projectPath, operationId),
      );
      expect(
        repeated.status,
        NarrativeEventRegistryPersistenceStatus.staleUndo,
      );
      expect(repeated.code, 'staleUndo');
      expect(
        await fixture.readSentinelBytes(),
        fixture.initialSentinelBytes,
      );
    });

    test('rejects corrupt or copied undo metadata without changing project',
        () async {
      for (final copied in [false, true]) {
        final fixture = await createPersistenceFixture();
        addTearDown(fixture.dispose);
        final operationId = copied ? 'e4_copied_undo' : 'e4_corrupt_undo';
        await NarrativeEventRegistryPersistence().write(
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
        late final String requestedPath;
        if (copied) {
          requestedPath = p.join(fixture.root.path, 'copied.undo.json');
          await File(undoPath).copy(requestedPath);
        } else {
          requestedPath = undoPath;
          final undoJson = jsonObject(decodeNarrativeEventJsonStrict(
            await File(undoPath).readAsString(),
          ))
            ..['nextRegistryHash'] =
                'sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
          await File(undoPath).writeAsBytes(
            canonicalizeNarrativeEventJsonUtf8(undoJson),
            flush: true,
          );
        }
        final bytesBeforeUndo = await fixture.readBytes();
        final undo =
            await NarrativeEventRegistryPersistence().undo(requestedPath);

        expect(undo.status, NarrativeEventRegistryPersistenceStatus.blocked);
        expect(undo.code, copied ? 'unsafeUndoPath' : 'invalidUndo');
        expect(await fixture.readBytes(), bytesBeforeUndo);
      }
    });

    test('rejects undo after an unrelated root change without overwriting it',
        () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      const operationId = 'e4_undo_root_stale';
      final service = NarrativeEventRegistryPersistence();
      await service.write(
        persistenceRequest(
          fixture: fixture,
          operationId: operationId,
          previousRegistry: null,
          nextRegistry: persistenceRegistry(),
        ),
      );
      final changedRoot = Map<String, Object?>.from(await fixture.readRoot())
        ..['newerUnknownRoot'] = {'keep': true};
      final changedBytes = canonicalizeNarrativeEventJsonUtf8(changedRoot);
      await File(fixture.projectPath).writeAsBytes(changedBytes, flush: true);
      final undo = await service.undo(
        narrativeEventRegistryUndoPath(fixture.projectPath, operationId),
      );

      expect(undo.status, NarrativeEventRegistryPersistenceStatus.staleUndo);
      expect(await fixture.readBytes(), changedBytes);
    });

    test('rejects an old undo after a later registry write', () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      final service = NarrativeEventRegistryPersistence();
      final firstRegistry = persistenceRegistry();
      final first = await service.write(
        persistenceRequest(
          fixture: fixture,
          operationId: 'e4_undo_first',
          previousRegistry: null,
          nextRegistry: firstRegistry,
        ),
      );
      final secondRegistry = persistenceRegistry(
        records: [persistenceDraft(name: 'Later')],
      );
      expect(first.status, NarrativeEventRegistryPersistenceStatus.committed);
      final secondSession = await NarrativeEventAuthoringSession.prepare(
        fixture.projectPath,
      );
      final second = await service.write(
        persistenceRequest(
          fixture: fixture,
          operationId: 'e4_undo_later',
          session: secondSession,
          previousRegistry: firstRegistry,
          nextRegistry: secondRegistry,
          mutation: 'rename',
        ),
      );
      final bytesBeforeUndo = await fixture.readBytes();
      final undo = await service.undo(
        narrativeEventRegistryUndoPath(
          fixture.projectPath,
          'e4_undo_first',
        ),
      );

      expect(second.status, NarrativeEventRegistryPersistenceStatus.committed);
      expect(undo.status, NarrativeEventRegistryPersistenceStatus.staleUndo);
      expect(await fixture.readBytes(), bytesBeforeUndo);
    });

    test('restores records while preserving dual-read mode and claims',
        () async {
      final claim = persistenceClaim();
      final previousRecord = persistenceConfigured(name: 'Before');
      final previous = persistenceRegistry(
        records: [previousRecord],
        mode: EventSystemMode.dualRead,
        claims: [claim],
      );
      final next = persistenceRegistry(
        records: [persistenceConfigured(name: 'After')],
        mode: EventSystemMode.dualRead,
        claims: [claim],
      );
      final fixture = await createPersistenceFixture(registry: previous);
      addTearDown(fixture.dispose);
      const operationId = 'e4_undo_claims';
      final service = NarrativeEventRegistryPersistence();
      final write = await service.write(
        persistenceRequest(
          fixture: fixture,
          operationId: operationId,
          previousRegistry: previous,
          nextRegistry: next,
          mutation: 'rename',
        ),
      );
      final undo = await service.undo(
        narrativeEventRegistryUndoPath(fixture.projectPath, operationId),
      );
      final root = await fixture.readRoot();
      final restored =
          decodeNarrativeEventRegistry(root['eventRegistry']).registryOrNull!;

      expect(write.status, NarrativeEventRegistryPersistenceStatus.committed);
      expect(undo.status, NarrativeEventRegistryPersistenceStatus.committed);
      expect(restored.records.single.definitionOrNull!.name, 'Before');
      expect(restored.mode, EventSystemMode.dualRead);
      expect(restored.legacyClaims, [claim]);
      expect(withoutRegistry(root), withoutRegistry(fixture.initialRoot));
    });

    test('recovers a crash during undo after the registry rename', () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      const operationId = 'e4_undo_crash';
      final initialService = NarrativeEventRegistryPersistence();
      await initialService.write(
        persistenceRequest(
          fixture: fixture,
          operationId: operationId,
          previousRegistry: null,
          nextRegistry: persistenceRegistry(),
        ),
      );
      final crashingService = NarrativeEventRegistryPersistence(
        faultInjector: (checkpoint) async {
          if (checkpoint == NarrativeEventRegistryWriteCheckpoint.afterRename) {
            throw _UndoFault();
          }
        },
      );
      await expectLater(
        crashingService.undo(
          narrativeEventRegistryUndoPath(fixture.projectPath, operationId),
        ),
        throwsA(isA<_UndoFault>()),
      );
      final recovery = await NarrativeEventRegistryPersistence()
          .recoverProject(fixture.projectPath);
      final root = await fixture.readRoot();

      expect(
        recovery.map((result) => result.status),
        contains(NarrativeEventRegistryPersistenceStatus.recovered),
      );
      expect(root.containsKey('eventRegistry'), isFalse);
      expect(withoutRegistry(root), withoutRegistry(fixture.initialRoot));
    });

    test('rolls back a crash during undo before the registry rename', () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      const operationId = 'e4_undo_pre_rename_crash';
      await NarrativeEventRegistryPersistence().write(
        persistenceRequest(
          fixture: fixture,
          operationId: operationId,
          previousRegistry: null,
          nextRegistry: persistenceRegistry(),
        ),
      );
      final bytesBeforeUndo = await fixture.readBytes();
      final crashingService = NarrativeEventRegistryPersistence(
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventRegistryWriteCheckpoint.afterTempFlush) {
            throw _UndoFault();
          }
        },
      );
      await expectLater(
        crashingService.undo(
          narrativeEventRegistryUndoPath(fixture.projectPath, operationId),
        ),
        throwsA(isA<_UndoFault>()),
      );
      expect(await fixture.readBytes(), bytesBeforeUndo);
      final recovery = await NarrativeEventRegistryPersistence()
          .recoverProject(fixture.projectPath);
      final root = await fixture.readRoot();

      expect(
        recovery.map((result) => result.code),
        contains('rolledBackBeforeCommit'),
      );
      expect(root.containsKey('eventRegistry'), isTrue);
      expect(
        await fixture.readSentinelBytes(),
        fixture.initialSentinelBytes,
      );
      final retry = await NarrativeEventRegistryPersistence().undo(
        narrativeEventRegistryUndoPath(fixture.projectPath, operationId),
      );
      final retriedRoot = await fixture.readRoot();

      expect(retry.status, NarrativeEventRegistryPersistenceStatus.committed);
      expect(retriedRoot.containsKey('eventRegistry'), isFalse);
    });

    test('blocks a recovered retry with unsafe embedded paths', () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      const operationId = 'e4_undo_unsafe_recovered_path';
      await NarrativeEventRegistryPersistence().write(
        persistenceRequest(
          fixture: fixture,
          operationId: operationId,
          previousRegistry: null,
          nextRegistry: persistenceRegistry(),
        ),
      );
      final crashingService = NarrativeEventRegistryPersistence(
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventRegistryWriteCheckpoint.afterTempFlush) {
            throw _UndoFault();
          }
        },
      );
      await expectLater(
        crashingService.undo(
          narrativeEventRegistryUndoPath(fixture.projectPath, operationId),
        ),
        throwsA(isA<_UndoFault>()),
      );
      await NarrativeEventRegistryPersistence()
          .recoverProject(fixture.projectPath);
      final undoOperationHash = narrativeEventCanonicalSha256({
        'operationId': operationId,
        'afterRevision': narrativeEventBytesFingerprint(
          await fixture.readBytes(),
        ),
      }).substring(0, 20);
      final journalPath = narrativeEventRegistryJournalPath(
        fixture.projectPath,
        'undo_$undoOperationHash',
      );
      final sentinelPath = p.join(fixture.root.path, 'do-not-delete.txt');
      final sentinel = File(sentinelPath);
      await sentinel.writeAsString('keep', flush: true);
      final journalJson = jsonObject(
        jsonDecode(await File(journalPath).readAsString()),
      )..['journalPath'] = sentinelPath;
      await File(journalPath).writeAsString(
        jsonEncode(journalJson),
        flush: true,
      );
      final bytesBeforeRetry = await fixture.readBytes();

      final retry = await NarrativeEventRegistryPersistence().undo(
        narrativeEventRegistryUndoPath(fixture.projectPath, operationId),
      );

      expect(retry.status, NarrativeEventRegistryPersistenceStatus.blocked);
      expect(retry.code, 'unsafeJournalPaths');
      expect(await sentinel.readAsString(), 'keep');
      expect(await fixture.readBytes(), bytesBeforeRetry);
      expect(await File(journalPath).exists(), isTrue);
    });
  });
}

final class _UndoFault implements Exception {}
