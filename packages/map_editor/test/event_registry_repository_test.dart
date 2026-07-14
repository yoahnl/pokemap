import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:map_editor/src/application/models/narrative_event_registry_persistence_models.dart';
import 'package:map_editor/src/application/ports/narrative_event_registry_persistence_gateway.dart';
import 'package:map_editor/src/application/use_cases/narrative_event_registry_persistence_use_cases.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_event_registry_persistence.dart';

import 'support/event_registry_persistence_fixtures.dart';

void main() {
  group('NS-EVENT-V2 Phase E4 registry repository', () {
    test('writes an absent registry through the existing project repository',
        () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      final nextRecord = persistenceDraft();
      final nextRegistry = persistenceRegistry(records: [nextRecord]);
      final repository = FileProjectRepository();
      final context = fixture.session.context;
      final result = await repository.persistNarrativeEventAuthoringResult(
        session: fixture.session,
        operationId: 'e4_absent_registry',
        result: persistenceAuthoringResult(
          previousRegistry: null,
          nextRegistry: nextRegistry,
          expectedRevision: fixture.revision,
          context: context,
        ),
      );

      expect(result.status, NarrativeEventRegistryPersistenceStatus.committed);
      expect(result.beforeRevision, fixture.revision);
      expect(result.afterRevision, isNot(fixture.revision));
      expect(
          result.journal!.state, NarrativeEventRegistryJournalState.committed);
      expect(result.undoEntry!.previousRegistry, isNull);
      expect(result.undoEntry!.nextRegistry, nextRegistry);
      final afterRoot = await fixture.readRoot();
      expect(
        decodeNarrativeEventRegistry(afterRoot['eventRegistry']).registryOrNull,
        nextRegistry,
      );
      expect(
        withoutRegistry(afterRoot),
        withoutRegistry(fixture.initialRoot),
      );
      expect(
        await File(narrativeEventRegistryJournalPath(
          fixture.projectPath,
          'e4_absent_registry',
        )).exists(),
        isTrue,
      );
      expect(
        await File(narrativeEventRegistryUndoPath(
          fixture.projectPath,
          'e4_absent_registry',
        )).exists(),
        isTrue,
      );
      expect(
        await fixture.readSentinelBytes(),
        fixture.initialSentinelBytes,
      );
    });

    test('exposes write recovery and undo through application use cases',
        () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      final repository = FileProjectRepository();
      expect(repository, isA<NarrativeEventRegistryPersistenceGateway>());
      final write = await PersistNarrativeEventRegistryUseCase(repository)(
        persistenceRequest(
          fixture: fixture,
          operationId: 'e4_application_gateway',
          previousRegistry: null,
          nextRegistry: persistenceRegistry(),
        ),
      );
      final recovery =
          await RecoverNarrativeEventRegistryWritesUseCase(repository)(
        fixture.projectPath,
      );
      final undo = await UndoNarrativeEventRegistryWriteUseCase(repository)(
        narrativeEventRegistryUndoPath(
          fixture.projectPath,
          'e4_application_gateway',
        ),
      );

      expect(write.status, NarrativeEventRegistryPersistenceStatus.committed);
      expect(
        recovery.map((entry) => entry.code),
        contains('alreadyCommitted'),
      );
      expect(undo.status, NarrativeEventRegistryPersistenceStatus.committed);
    });

    test('generic saves preserve current registry and unknown root fields',
        () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      final repository = FileProjectRepository();
      final staleManifest = await repository.loadProject(fixture.projectPath);
      final write = await NarrativeEventRegistryPersistence().write(
        persistenceRequest(
          fixture: fixture,
          operationId: 'e4_generic_save_guard',
          previousRegistry: null,
          nextRegistry: persistenceRegistry(),
        ),
      );
      final bytesAfterWrite = await fixture.readBytes();

      await expectLater(
        repository.saveProject(
          staleManifest.copyWith(name: 'Stale overwrite'),
          fixture.projectPath,
        ),
        throwsA(isA<EditorConflictException>()),
      );
      expect(await fixture.readBytes(), bytesAfterWrite);

      final currentManifest = await repository.loadProject(fixture.projectPath);
      await repository.saveProject(
        currentManifest.copyWith(name: 'Updated outside Event authoring'),
        fixture.projectPath,
      );
      final root = await fixture.readRoot();
      expect(root['name'], 'Updated outside Event authoring');
      expect(root['futureRoot'], fixture.initialRoot['futureRoot']);
      expect(
        decodeNarrativeEventRegistry(root['eventRegistry']).registryOrNull,
        persistenceRegistry(),
      );
      expect(write.status, NarrativeEventRegistryPersistenceStatus.committed);
      expect(
        await fixture.readSentinelBytes(),
        fixture.initialSentinelBytes,
      );
    });

    test('modifies records while preserving schema mode claims and scope',
        () async {
      final claim = persistenceClaim();
      final currentRecord = persistenceConfigured();
      final current = persistenceRegistry(
        records: [currentRecord],
        mode: EventSystemMode.dualRead,
        claims: [claim],
      );
      final nextRecord = persistenceConfigured(name: 'Renamed');
      final next = persistenceRegistry(
        records: [nextRecord],
        mode: EventSystemMode.dualRead,
        claims: [claim],
      );
      final fixture = await createPersistenceFixture(registry: current);
      addTearDown(fixture.dispose);
      final result = await NarrativeEventRegistryPersistence().write(
        persistenceRequest(
          fixture: fixture,
          operationId: 'e4_preserve_claims',
          previousRegistry: current,
          nextRegistry: next,
          mutation: 'rename',
        ),
      );

      expect(result.status, NarrativeEventRegistryPersistenceStatus.committed);
      final root = await fixture.readRoot();
      final stored =
          decodeNarrativeEventRegistry(root['eventRegistry']).registryOrNull!;
      expect(stored.schemaVersion, current.schemaVersion);
      expect(stored.mode, current.mode);
      expect(stored.legacyClaims, current.legacyClaims);
      expect(stored.records.single.definitionOrNull!.name, 'Renamed');
      expect(withoutRegistry(root), withoutRegistry(fixture.initialRoot));
      final names = await fixture.root
          .list()
          .map((entry) => entry.uri.pathSegments.lastWhere(
                (segment) => segment.isNotEmpty,
              ))
          .toList();
      expect(names.where((name) => name.contains('migration')), isEmpty);
      expect(names.where((name) => name.contains('receipt')), isEmpty);
    });

    test('rejects mode and claim mutations before writing artifacts', () async {
      final claim = persistenceClaim();
      final record = persistenceConfigured();
      final current = persistenceRegistry(
        records: [record],
        mode: EventSystemMode.dualRead,
        claims: [claim],
      );
      final fixture = await createPersistenceFixture(registry: current);
      addTearDown(fixture.dispose);
      final changedMode = persistenceRegistry(
        records: [record],
        mode: EventSystemMode.v2Only,
        claims: [claim],
      );
      final changedClaims = persistenceRegistry(
        records: [record],
        mode: EventSystemMode.dualRead,
      );

      for (final entry in [
        ('e4_changed_mode', changedMode),
        ('e4_changed_claims', changedClaims),
      ]) {
        final forged = NarrativeEventAuthoringResult.applied(
          mutation: NarrativeEventAuthoringMutation.rename,
          previousRegistry: current,
          nextRegistry: entry.$2,
          previousRecord: record,
          nextRecord: record,
          expectedRevision: fixture.revision,
        );
        expect(
          () => NarrativeEventRegistryWriteRequest.fromAuthoringSession(
            session: fixture.session,
            operationId: entry.$1,
            result: forged,
          ),
          throwsArgumentError,
        );
        expect(
          await File(narrativeEventRegistryJournalPath(
            fixture.projectPath,
            entry.$1,
          )).exists(),
          isFalse,
        );
      }
      expect(await fixture.readBytes(), fixture.initialBytes);
    });

    test('rejects concurrent unknown-root changes', () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      final next = persistenceRegistry();
      final service = NarrativeEventRegistryPersistence();
      final concurrentRoot = Map<String, Object?>.from(fixture.initialRoot)
        ..['concurrentFuture'] = {'preserve': true};
      final concurrentBytes =
          canonicalizeNarrativeEventJsonUtf8(concurrentRoot);
      await File(fixture.projectPath)
          .writeAsBytes(concurrentBytes, flush: true);
      final concurrent = await service.write(
        persistenceRequest(
          fixture: fixture,
          operationId: 'e4_concurrent',
          previousRegistry: null,
          nextRegistry: next,
        ),
      );
      expect(concurrent.status,
          NarrativeEventRegistryPersistenceStatus.staleAuthoringSnapshot);
      expect(await fixture.readBytes(), concurrentBytes);
    });

    test('rejects a registry mismatch and no-op authoring requests', () async {
      final current = persistenceRegistry(
        records: [persistenceDraft(name: 'Current')],
      );
      final fixture = await createPersistenceFixture(registry: current);
      addTearDown(fixture.dispose);
      final other = persistenceRegistry(
        records: [persistenceDraft(name: 'Other')],
      );
      final forgedMismatch = NarrativeEventAuthoringResult.applied(
        mutation: NarrativeEventAuthoringMutation.rename,
        previousRegistry: other,
        nextRegistry: current,
        previousRecord: other.records.single,
        nextRecord: current.records.single,
        expectedRevision: fixture.revision,
      );
      final noOpResult = NarrativeEventAuthoringResult.noOp(
        mutation: NarrativeEventAuthoringMutation.rename,
        registry: current,
        record: current.records.single,
        expectedRevision: fixture.revision,
      );

      expect(
        () => NarrativeEventRegistryWriteRequest.fromAuthoringSession(
          session: fixture.session,
          operationId: 'e4_registry_mismatch',
          result: forgedMismatch,
        ),
        throwsArgumentError,
      );
      expect(
        () => NarrativeEventRegistryWriteRequest.fromAuthoringSession(
          session: fixture.session,
          operationId: 'e4_registry_noop',
          result: noOpResult,
        ),
        throwsArgumentError,
      );
      expect(await fixture.readBytes(), fixture.initialBytes);
      expect(
        await File(narrativeEventRegistryJournalPath(
          fixture.projectPath,
          'e4_registry_noop',
        )).exists(),
        isFalse,
      );
    });

    test('binds persistence revision to the attested session', () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      final nextRecord = persistenceDraft();
      final nextRegistry = persistenceRegistry(records: [nextRecord]);
      final result = persistenceAuthoringResult(
        previousRegistry: null,
        nextRegistry: nextRegistry,
        expectedRevision: 'sha256:authoring',
      );

      expect(
        () => NarrativeEventRegistryWriteRequest.fromAuthoringSession(
          session: fixture.session,
          operationId: 'e4_revision_binding',
          result: result,
        ),
        throwsArgumentError,
      );
    });

    test('rechecks the live manifest immediately before rename', () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      final concurrentRoot = Map<String, Object?>.from(fixture.initialRoot)
        ..['changedDuringPreparation'] = true;
      final concurrentBytes =
          canonicalizeNarrativeEventJsonUtf8(concurrentRoot);
      final service = NarrativeEventRegistryPersistence(
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventRegistryWriteCheckpoint.beforeRename) {
            await File(fixture.projectPath).writeAsBytes(
              concurrentBytes,
              flush: true,
            );
          }
        },
      );
      final result = await service.write(
        persistenceRequest(
          fixture: fixture,
          operationId: 'e4_race_before_rename',
          previousRegistry: null,
          nextRegistry: persistenceRegistry(),
        ),
      );

      expect(
          result.status, NarrativeEventRegistryPersistenceStatus.staleRevision);
      expect(result.code, 'staleRevisionBeforeRename');
      expect(await fixture.readBytes(), concurrentBytes);
      expect(
          result.journal!.state, NarrativeEventRegistryJournalState.recovered);
      expect(await File(result.journal!.backupPath).exists(), isFalse);
      expect(await File(result.journal!.tempPath).exists(), isFalse);
    });

    test('serializes overlapping Event writers with a shared project lock',
        () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      final atRename = Completer<void>();
      final releaseRename = Completer<void>();
      final firstService = NarrativeEventRegistryPersistence(
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventRegistryWriteCheckpoint.beforeRename) {
            atRename.complete();
            await releaseRename.future;
          }
        },
      );
      final first = firstService.write(
        persistenceRequest(
          fixture: fixture,
          operationId: 'e4_concurrent_writer_a',
          previousRegistry: null,
          nextRegistry: persistenceRegistry(),
        ),
      );
      await atRename.future;
      var secondCompleted = false;
      final second = NarrativeEventRegistryPersistence()
          .write(
            persistenceRequest(
              fixture: fixture,
              operationId: 'e4_concurrent_writer_b',
              previousRegistry: null,
              nextRegistry: persistenceRegistry(
                records: [
                  persistenceDraft(
                    id: persistenceEventB,
                    name: 'Concurrent B',
                  ),
                ],
              ),
            ),
          )
          .whenComplete(() => secondCompleted = true);
      await Future<void>.delayed(const Duration(milliseconds: 25));

      expect(secondCompleted, isFalse);
      releaseRename.complete();
      final results = await Future.wait([first, second]);
      expect(
        results.map((result) => result.status),
        containsAll([
          NarrativeEventRegistryPersistenceStatus.committed,
          NarrativeEventRegistryPersistenceStatus.staleAuthoringSnapshot,
        ]),
      );
    });

    test('shares the project lock with generic manifest saves', () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      final repository = FileProjectRepository();
      final staleManifest = await repository.loadProject(fixture.projectPath);
      final atRename = Completer<void>();
      final releaseRename = Completer<void>();
      final eventWrite = NarrativeEventRegistryPersistence(
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventRegistryWriteCheckpoint.beforeRename) {
            atRename.complete();
            await releaseRename.future;
          }
        },
      ).write(
        persistenceRequest(
          fixture: fixture,
          operationId: 'e4_event_vs_generic_save',
          previousRegistry: null,
          nextRegistry: persistenceRegistry(),
        ),
      );
      await atRename.future;
      var genericCompleted = false;
      final genericSave = repository
          .saveProject(
            staleManifest.copyWith(name: 'Concurrent generic save'),
            fixture.projectPath,
          )
          .whenComplete(() => genericCompleted = true);
      final genericExpectation =
          expectLater(genericSave, throwsA(isA<EditorConflictException>()));
      await Future<void>.delayed(const Duration(milliseconds: 25));

      expect(genericCompleted, isFalse);
      releaseRename.complete();
      final eventResult = await eventWrite;
      await genericExpectation;
      final root = await fixture.readRoot();
      expect(eventResult.status,
          NarrativeEventRegistryPersistenceStatus.committed);
      expect(root['name'], fixture.initialRoot['name']);
      expect(
        decodeNarrativeEventRegistry(root['eventRegistry']).registryOrNull,
        persistenceRegistry(),
      );
    });

    test('rejects a forged activation with unresolved references', () async {
      final configured = persistenceConfigured(name: 'Invalid activation');
      final previous = persistenceRegistry(records: [configured]);
      final invalidDefinition = NarrativeEventDefinition(
        id: configured.id,
        name: 'Invalid activation',
        source: NarrativeEventSourceRef.mapEnter('missing_map'),
        conditions: const [],
        sceneId: 'missing_scene',
        reusePolicy: NarrativeEventReusePolicy.oneShot,
        priority: 0,
        order: 0,
      );
      final active = NarrativeEventRecord.configuredStructurallyUnchecked(
        invalidDefinition,
        enabled: true,
      );
      final next = persistenceRegistry(records: [active]);
      final fixture = await createPersistenceFixture(registry: previous);
      addTearDown(fixture.dispose);
      final forged = NarrativeEventAuthoringResult.applied(
        mutation: NarrativeEventAuthoringMutation.activate,
        previousRegistry: previous,
        nextRegistry: next,
        previousRecord: configured,
        nextRecord: active,
        expectedRevision: fixture.revision,
      );

      expect(
        () => NarrativeEventRegistryWriteRequest.fromAuthoringSession(
          session: fixture.session,
          operationId: 'e4_invalid_activation',
          result: forged,
        ),
        throwsArgumentError,
      );
    });

    test('blocks duplicate escaped unsupported and invalid project JSON',
        () async {
      final cases = <(String, String)>[
        (
          'duplicate',
          '{"name":"A","name":"B","maps":[],"tilesets":[]}',
        ),
        (
          'escaped_duplicate',
          '{"name":"A","\\u006eame":"B","maps":[],"tilesets":[]}',
        ),
        (
          'unsupported',
          '{"name":"A","maps":[],"tilesets":[],"eventRegistry":{"schemaVersion":99}}',
        ),
        (
          'invalid',
          '{"name":"A","maps":[],"tilesets":[],"eventRegistry":{"schemaVersion":1,"mode":"legacyOnly","records":"bad","legacyClaims":[]}}',
        ),
      ];
      for (final entry in cases) {
        final fixture = await createPersistenceFixture();
        addTearDown(fixture.dispose);
        final bytes = utf8.encode(entry.$2);
        await File(fixture.projectPath).writeAsBytes(bytes, flush: true);
        await expectLater(
          NarrativeEventAuthoringSession.prepare(fixture.projectPath),
          throwsA(isA<NarrativeEventAuthoringSessionException>()),
          reason: entry.$1,
        );
        expect(await fixture.readBytes(), bytes, reason: entry.$1);
      }
    });
  });
}
