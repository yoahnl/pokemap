import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_authoring_transaction.dart';
import 'package:map_editor/src/application/models/narrative_event_registry_persistence_models.dart';
import 'package:map_editor/src/infrastructure/repositories/atomic_project_manifest_persistence.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_event_registry_persistence.dart';
import 'package:map_editor/src/infrastructure/repositories/project_manifest_write_lock.dart';

import 'support/event_registry_persistence_fixtures.dart';

void main() {
  group('AtomicProjectManifestPersistence', () {
    test('commits atomically while preserving unknown root and Event data',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final eventRegistryBefore = fixture.initialRoot['eventRegistry'];
      String? tempPath;
      final persistence = AtomicProjectManifestPersistence(
        faultInjector: (checkpoint, context) async {
          if (checkpoint ==
              AtomicProjectManifestWriteCheckpoint.afterTempFlushed) {
            tempPath = context.tempPath;
            expect(
              File(context.tempPath).parent.path,
              File(await fixture.file.resolveSymbolicLinks()).parent.path,
            );
            expect(await File(context.tempPath).exists(), isTrue);
          }
        },
      );

      final result = await persistence.persist(fixture.transaction);

      expect(result.status, NarrativeAuthoringPersistenceStatus.committed);
      expect(result.code, 'projectManifestCommitted');
      final stored = await fixture.readRoot();
      expect(stored['futureRoot'], fixture.initialRoot['futureRoot']);
      expect(
        (stored['futureRoot'] as Map)['nested'],
        <Object?>['preserve', 7, true],
      );
      expect(stored['eventRegistry'], eventRegistryBefore);
      expect((stored['cinematics'] as List), hasLength(1));
      expect(
        (stored['cinematics'] as List).single,
        fixture.transaction.after.cinematics.single.toJson(),
      );
      expect(tempPath, isNotNull);
      expect(await File(tempPath!).exists(), isFalse);
    });

    test('rejects a stale semantic before snapshot without changing disk',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final external = fixture.before.copyWith(name: 'External change');
      await fixture.writeRoot(
        Map<String, Object?>.from(fixture.initialRoot)
          ..addAll(external.toJson())
          ..['eventRegistry'] = fixture.initialRoot['eventRegistry'],
      );
      final externalBytes = await fixture.file.readAsBytes();

      final result = await const AtomicProjectManifestPersistence().persist(
        fixture.transaction,
      );

      expect(
        result.status,
        NarrativeAuthoringPersistenceStatus.persistenceFailed,
      );
      expect(result.code, 'staleProjectRevision');
      expect(await fixture.file.readAsBytes(), externalBytes);
      expect(await fixture.tempFiles(), isEmpty);
    });

    test('refuses to write while Event recovery is required', () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      final eventWriter = NarrativeEventRegistryPersistence(
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventRegistryWriteCheckpoint.afterJournalPrepared) {
            throw const FileSystemException('Injected prepared Event write');
          }
        },
      );
      final interrupted = await eventWriter.write(
        persistenceRequest(
          fixture: fixture,
          operationId: 'atomic_gate_required',
          previousRegistry: null,
          nextRegistry: persistenceRegistry(),
        ),
      );
      expect(
        interrupted.status,
        NarrativeEventRegistryPersistenceStatus.ioFailure,
      );
      final bytesBeforeAtomicWrite = await fixture.readBytes();
      final mutation = NarrativeAssetMutation.createCinematic(
        fixture.session.manifest,
        title: 'Blocked cinematic',
      );
      final transaction = NarrativeAuthoringTransaction.fromMutation(
        projectPath: fixture.projectPath,
        operationId: 'blocked-by-event-recovery',
        mutation: mutation,
      );

      final result = await const AtomicProjectManifestPersistence().persist(
        transaction,
      );

      expect(
        result.status,
        NarrativeAuthoringPersistenceStatus.recoveryRequired,
      );
      expect(result.code, 'eventRegistryRecoveryRequired');
      expect(await fixture.readBytes(), bytesBeforeAtomicWrite);
    });

    test('refuses to write while Event recovery is blocked', () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final journalPath = narrativeEventRegistryJournalPath(
        await fixture.file.resolveSymbolicLinks(),
        'atomic_gate_blocked',
      );
      await File(journalPath).writeAsString('{}', flush: true);
      final beforeBytes = await fixture.file.readAsBytes();
      final inspection = await NarrativeEventRegistryPersistence()
          .inspectProject(fixture.file.path);
      expect(
        inspection.status,
        NarrativeEventRegistryRecoveryGateStatus.recoveryBlocked,
      );

      final result = await const AtomicProjectManifestPersistence().persist(
        fixture.transaction,
      );

      expect(
        result.status,
        NarrativeAuthoringPersistenceStatus.recoveryRequired,
      );
      expect(result.code, 'eventRegistryRecoveryBlocked');
      expect(await fixture.file.readAsBytes(), beforeBytes);
    });

    test('second CAS detects a byte-level concurrent change before rename',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      List<int>? concurrentBytes;
      final persistence = AtomicProjectManifestPersistence(
        faultInjector: (checkpoint, _) async {
          if (checkpoint ==
              AtomicProjectManifestWriteCheckpoint.beforeSecondCompareAndSwap) {
            final concurrentRoot = Map<String, Object?>.from(
              await fixture.readRoot(),
            )..['concurrentFuture'] = <String, Object?>{'kept': true};
            await fixture.writeRoot(concurrentRoot);
            concurrentBytes = await fixture.file.readAsBytes();
          }
        },
      );

      final result = await persistence.persist(fixture.transaction);

      expect(
        result.status,
        NarrativeAuthoringPersistenceStatus.persistenceFailed,
      );
      expect(result.code, 'projectChangedBeforeCommit');
      expect(concurrentBytes, isNotNull);
      expect(await fixture.file.readAsBytes(), concurrentBytes);
      expect(await fixture.tempFiles(), isEmpty);
    });

    test('a failure before rename leaves project bytes unchanged', () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final beforeBytes = await fixture.file.readAsBytes();
      final persistence = AtomicProjectManifestPersistence(
        faultInjector: (checkpoint, _) {
          if (checkpoint ==
              AtomicProjectManifestWriteCheckpoint.afterTempFlushed) {
            throw const FileSystemException('Injected pre-rename failure');
          }
        },
      );

      final result = await persistence.persist(fixture.transaction);

      expect(
        result.status,
        NarrativeAuthoringPersistenceStatus.persistenceFailed,
      );
      expect(result.code, 'projectManifestWriteFailed');
      expect(await fixture.file.readAsBytes(), beforeBytes);
      expect(await fixture.tempFiles(), isEmpty);
    });

    test('a post-rename callback failure is verified as committed', () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final persistence = AtomicProjectManifestPersistence(
        faultInjector: (checkpoint, _) {
          if (checkpoint ==
              AtomicProjectManifestWriteCheckpoint.afterProjectRenamed) {
            throw const FileSystemException('Injected post-rename failure');
          }
        },
      );

      final result = await persistence.persist(fixture.transaction);

      expect(
        result.status,
        NarrativeAuthoringPersistenceStatus.committed,
      );
      expect(
        result.code,
        'projectManifestCommittedAfterInterruptedVerification',
      );
      final stored = await fixture.readProject();
      expect(stored, fixture.transaction.after);
    });

    test('a divergent post-rename callback failure remains recovery required',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final persistence = AtomicProjectManifestPersistence(
        faultInjector: (checkpoint, _) async {
          if (checkpoint ==
              AtomicProjectManifestWriteCheckpoint.afterProjectRenamed) {
            await fixture.file.writeAsString(
              '{"divergent":true}',
              flush: true,
            );
            throw const FileSystemException('Injected divergent commit');
          }
        },
      );

      final result = await persistence.persist(fixture.transaction);

      expect(
        result.status,
        NarrativeAuthoringPersistenceStatus.recoveryRequired,
      );
      expect(result.code, 'projectManifestCommitAmbiguous');
      expect(await fixture.file.readAsString(), '{"divergent":true}');
    });

    test('re-reads the renamed file and requires recovery on hash mismatch',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final persistence = AtomicProjectManifestPersistence(
        faultInjector: (checkpoint, _) async {
          if (checkpoint ==
              AtomicProjectManifestWriteCheckpoint.beforeCommitVerification) {
            await fixture.file.writeAsString(
              '{"interrupted":true}',
              flush: true,
            );
          }
        },
      );

      final result = await persistence.persist(fixture.transaction);

      expect(
        result.status,
        NarrativeAuthoringPersistenceStatus.recoveryRequired,
      );
      expect(result.code, 'projectManifestVerificationFailed');
      expect(await fixture.file.readAsString(), '{"interrupted":true}');
    });

    test('a symlink manifest updates its canonical target without forking',
        () async {
      if (Platform.isWindows) return;
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final aliasRoot = await Directory.systemTemp.createTemp(
        'pokemap_atomic_manifest_alias_',
      );
      addTearDown(() => aliasRoot.delete(recursive: true));
      final aliasPath = '${aliasRoot.path}/project.json';
      await Link(aliasPath).create(fixture.file.path);
      final transaction = NarrativeAuthoringTransaction.fromMutation(
        projectPath: aliasPath,
        operationId: 'create-through-symlink',
        mutation: fixture.transaction.mutation,
      );

      final result =
          await const AtomicProjectManifestPersistence().persist(transaction);

      expect(result.status, NarrativeAuthoringPersistenceStatus.committed);
      expect(
        await FileSystemEntity.type(aliasPath, followLinks: false),
        FileSystemEntityType.link,
      );
      expect(await fixture.readProject(), transaction.after);
      expect(
        await File(aliasPath).readAsString(),
        await fixture.file.readAsString(),
      );
    });

    test('shares the project manifest lock with existing writers', () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final releasePersistence = Completer<void>();
      final persistenceReachedLock = Completer<void>();
      final secondWriterEntered = Completer<void>();
      final persistence = AtomicProjectManifestPersistence(
        faultInjector: (checkpoint, _) async {
          if (checkpoint ==
              AtomicProjectManifestWriteCheckpoint.afterInitialRead) {
            persistenceReachedLock.complete();
            await releasePersistence.future;
          }
        },
      );

      final first = persistence.persist(fixture.transaction);
      await persistenceReachedLock.future;
      final second = withProjectManifestWriteLock(fixture.file.path, () async {
        secondWriterEntered.complete();
      });
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(secondWriterEntered.isCompleted, isFalse);
      releasePersistence.complete();
      expect((await first).succeeded, isTrue);
      await second;
      expect(secondWriterEntered.isCompleted, isTrue);
    });
  });
}

final class _Fixture {
  _Fixture({
    required this.root,
    required this.file,
    required this.before,
    required this.initialRoot,
    required this.transaction,
  });

  static Future<_Fixture> create() async {
    final root = await Directory.systemTemp.createTemp(
      'pokemap_atomic_manifest_',
    );
    final file = File('${root.path}/project.json');
    final registry = NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.legacyOnly,
      records: const [],
      legacyClaims: const [],
    );
    final before = ProjectManifest(
      name: 'Atomic persistence test',
      maps: const [],
      tilesets: const [],
      eventRegistry: registry,
    );
    final initialRoot = <String, Object?>{
      ...before.toJson(),
      'futureRoot': <String, Object?>{
        'nested': <Object?>['preserve', 7, true],
      },
    };
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(initialRoot),
      flush: true,
    );
    final mutation = NarrativeAssetMutation.createCinematic(
      before,
      title: 'Arrivée au port',
    );
    final transaction = NarrativeAuthoringTransaction.fromMutation(
      projectPath: file.path,
      operationId: 'create-cinematic-port',
      mutation: mutation,
    );
    return _Fixture(
      root: root,
      file: file,
      before: before,
      initialRoot: initialRoot,
      transaction: transaction,
    );
  }

  final Directory root;
  final File file;
  final ProjectManifest before;
  final Map<String, Object?> initialRoot;
  final NarrativeAuthoringTransaction transaction;

  Future<Map<String, Object?>> readRoot() async {
    final decoded = jsonDecode(await file.readAsString()) as Map;
    return <String, Object?>{
      for (final entry in decoded.entries) entry.key as String: entry.value,
    };
  }

  Future<ProjectManifest> readProject() async {
    final root = await readRoot();
    return ProjectManifest.fromJson(Map<String, dynamic>.from(root));
  }

  Future<void> writeRoot(Map<String, Object?> root) {
    return file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(root),
      flush: true,
    );
  }

  Future<List<FileSystemEntity>> tempFiles() async {
    return root
        .list(followLinks: false)
        .where((entry) => entry.path.endsWith('.tmp'))
        .toList();
  }

  Future<void> dispose() => root.delete(recursive: true);
}
