import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_authoring/src/history/authoring_history.dart';
import 'package:map_authoring/src/ports/idempotency_store.dart';
import 'package:map_authoring/src/support/authoring_fingerprint.dart';
import 'package:map_authoring/src/support/map_authoring_worker_trace.dart';
import 'package:map_authoring/src/transactions/file_idempotency_store.dart';
import 'package:map_authoring/src/transactions/idempotency_ledger.dart';
import 'package:map_authoring/src/transactions/journaled_transaction.dart';
import 'package:map_authoring/src/transactions/local_transaction_file_gateway.dart';
import 'package:map_authoring/src/transactions/plan_store.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  late WorkspacePolicy policy;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('editor_state_');
    root = Directory(await root.resolveSymbolicLinks());
    await Directory('${root.path}/maps').create();
    await File('${root.path}/maps/shore.json')
        .writeAsString('map must not be decoded');
    await File('${root.path}/project.json')
        .writeAsString('project must not be decoded');
    policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path],
        fileReader: const LocalProjectFileReader());
  });
  tearDown(() => root.delete(recursive: true));

  for (final worker in [false, true]) {
    test('incomplete visibility cannot erase hidden state worker=$worker',
        () async {
      final service =
          LocalMapEditorAuthoring(policy: policy, runInWorker: worker);
      final initial =
          await service.inspect(projectRoot: root.path, mapId: 'shore');
      final state = MapEditorState(
          lockedElements: {'model:lamp'},
          hiddenElements: {'layer:path'},
          hiddenFamilies: {'effect'});
      final saved = await service.set(
          projectRoot: root.path,
          mapId: 'shore',
          expectedRevision: initial.revision,
          state: state,
          operationId: 'complete_hidden');
      final file = File('${root.path}/maps/shore.editor.json');
      final original = await file.readAsBytes();
      for (final fields in [(false, true), (true, false), (false, false)]) {
        await expectLater(
            service.set(
                projectRoot: root.path,
                mapId: 'shore',
                expectedRevision: saved.afterRevision,
                state: state.copyWith(
                    hiddenElements: fields.$1 ? null : {},
                    hiddenFamilies: fields.$2 ? null : {}),
                hiddenElementsProvided: fields.$1,
                hiddenFamiliesProvided: fields.$2,
                operationId: 'incomplete_${fields.$1}_${fields.$2}'),
            throwsA(predicate(
                (error) => error.toString().contains('map_editor_inspect'))));
        expect(await file.readAsBytes(), original);
      }
      final cleared = await service.set(
          projectRoot: root.path,
          mapId: 'shore',
          expectedRevision: saved.afterRevision,
          state: state.copyWith(hiddenElements: {}, hiddenFamilies: {}),
          operationId: 'complete_clear');
      expect(cleared.afterState.hiddenElements, isEmpty);
      expect(cleared.afterState.hiddenFamilies, isEmpty);
      expect(cleared.afterState.lockedElements, state.lockedElements);
    });

    test(
        'legacy visible input and replay remain supported after later hiding worker=$worker',
        () async {
      final file = File('${root.path}/maps/shore.editor.json');
      await file.writeAsString(jsonEncode({
        'schemaVersion': 1,
        'mapId': 'shore',
        'state': {'lockedElements': <String>[], 'lockedFamilies': <String>[]}
      }));
      final service =
          LocalMapEditorAuthoring(policy: policy, runInWorker: worker);
      final initial =
          await service.inspect(projectRoot: root.path, mapId: 'shore');
      final legacyState = MapEditorState(lockedElements: {'model:lamp'});
      final legacy = await service.set(
          projectRoot: root.path,
          mapId: 'shore',
          expectedRevision: initial.revision,
          state: legacyState,
          hiddenElementsProvided: false,
          hiddenFamiliesProvided: false,
          operationId: 'legacy_visible');
      expect(legacy.afterState.hiddenElements, isEmpty);
      await service.set(
          projectRoot: root.path,
          mapId: 'shore',
          expectedRevision: legacy.afterRevision,
          state: legacyState.copyWith(hiddenElements: {'layer:path'}),
          operationId: 'later_hidden');
      final hidden = await file.readAsBytes();
      final replay = await service.set(
          projectRoot: root.path,
          mapId: 'shore',
          expectedRevision: initial.revision,
          state: legacyState,
          hiddenElementsProvided: false,
          hiddenFamiliesProvided: false,
          operationId: 'legacy_visible');
      expect(replay.receipt.receiptId, legacy.receipt.receiptId);
      expect(await file.readAsBytes(), hidden);
    });
  }

  for (final worker in [false, true]) {
    for (final interrupted in [false, true]) {
      test(
          'legacy v1 request identity replays and recovers worker=$worker interrupted=$interrupted',
          () async {
        final service =
            LocalMapEditorAuthoring(policy: policy, runInWorker: worker);
        final before =
            await service.inspect(projectRoot: root.path, mapId: 'shore');
        const operationId = 'legacy_v1_lock';
        final state = MapEditorState(lockedElements: {'model:mist'});
        final legacyState = <String, Object?>{
          'lockedElements': ['model:mist'],
          'lockedFamilies': <String>[],
        };
        final bytes = utf8.encode(jsonEncode({
          'schemaVersion': 1,
          'mapId': 'shore',
          'state': legacyState,
        }));
        final afterRevision = computeAuthoringBytesFingerprint(bytes,
            logicalName: 'maps/shore.editor.json');
        final projectId =
            'local_project_${computeAuthoringJsonFingerprint(root.path, logicalName: 'local-project-root.json').substring(7)}';
        final request = AuthoringRequest(
          requestId: operationId,
          actionId: 'map.editor.set',
          actionVersion: 1,
          workspaceHandle: projectId,
          parameters: {
            'mapId': 'shore',
            'mapRelativePath': 'maps/shore.json',
            'state': legacyState,
            'documentPresent': true,
          },
          expectedRevision: before.revision,
          idempotencyKey: operationId,
          extensions: {'history': AuthoringHistoryContext().toJson()},
        );
        final scope = AuthoringIdempotencyScope(
            actorId: 'local_cli',
            projectId: projectId,
            actionId: 'map.editor.set',
            actionVersion: 1,
            key: operationId);
        final gateway = await LocalTransactionFileGateway.open(
          projectRoot: root.path,
          expectedProjectRoot: root.path,
          transactionNamespace:
              'editor_${computeAuthoringJsonFingerprint('shore', logicalName: 'editor-map.json').substring(7)}',
        );
        final ledger = AuthoringIdempotencyLedger(
            store: await FileIdempotencyStore.forScope(
                filePath: '${root.path}/.pokemap/authoring/idempotency.jsonl',
                scope: scope));
        final plans = AuthoringPlanStore();
        final resource = AuthoringResourceRef(kind: 'mapEditor', id: 'shore');
        final plan = AuthoringPlan(
          planId: 'plan_document_11111111111111111111111111111111',
          receiptId: 'receipt_document_11111111111111111111111111111111',
          request: request,
          baseRevision: before.revision,
          seed: 0,
          createdAt: plans.now,
          expiresAt: plans.now.add(plans.ttl),
          changeSet: AuthoringChangeSet(
              changes: [
                AuthoringResourceChange(
                    resource: resource,
                    storageKey: 'maps/shore.editor.json',
                    beforeBytes: null,
                    afterBytes: bytes)
              ],
              diff: AuthoringDiff([
                AuthoringDiffEntry(
                    operation: AuthoringDiffOperation.replace,
                    resource: resource,
                    path: '/editor',
                    before: {
                      'lockedElements': <String>[],
                      'lockedFamilies': <String>[]
                    },
                    after: legacyState,
                    extensions: {
                      'documentBeforeRevision': before.revision,
                      'documentAfterRevision': afterRevision,
                      'documentBeforePresent': false,
                      'documentAfterPresent': true
                    }),
              ])),
        );
        plans.save(plan);
        final transaction = JournaledAuthoringTransaction(
          plans: plans,
          gateway: gateway,
          idempotency: ledger,
          clock: DateTime.now,
          faultInjector: interrupted
              ? (context) {
                  if (context.checkpoint ==
                      AuthoringTransactionCheckpoint.afterResourcePromoted) {
                    throw const AuthoringTransactionSimulatedCrash();
                  }
                }
              : null,
        );
        final apply = transaction.apply(
            planId: plan.planId,
            request: request,
            currentProjectRevision: before.revision,
            scope: scope,
            operationId: operationId);
        if (interrupted) {
          await expectLater(
              apply, throwsA(isA<AuthoringTransactionSimulatedCrash>()));
        } else {
          await apply;
        }
        final replay = await service.set(
            projectRoot: root.path,
            mapId: 'shore',
            expectedRevision: before.revision,
            state: state,
            operationId: operationId);
        expect(replay.receipt.receiptId, plan.receiptId);
        expect(replay.afterState, state);
        expect(await File('${root.path}/maps/shore.editor.json').readAsBytes(),
            bytes);
        await expectLater(
            service.set(
                projectRoot: root.path,
                mapId: 'shore',
                expectedRevision: before.revision,
                state: state.copyWith(hiddenElements: {'layer:path'}),
                operationId: operationId),
            throwsA(isA<AuthoringIdempotencyException>()));
        if (interrupted) {
          final undone = await service.undoReceipt(
            projectRoot: root.path,
            mapId: 'shore',
            receiptId: replay.receipt.receiptId,
            expectedRevision: replay.afterRevision,
            operationId: 'undo_legacy_v1',
          );
          expect(undone.afterState, MapEditorState());
          expect(await File('${root.path}/maps/shore.editor.json').exists(),
              isFalse);
        }
      });
    }
  }

  test('first and repeated lock saves only touch the selected bounded document',
      () async {
    final blocked = <String>[];
    for (final relative in [
      'project.json',
      'maps/shore.json',
      'maps/unrelated.json',
      '.pokemap/authoring/history.jsonl',
      '.pokemap/authoring/audit.jsonl',
      '.pokemap/authoring/idempotency.jsonl',
      '.pokemap/authoring/transactions/foreign/journal.json'
    ]) {
      final file = File('${root.path}/$relative');
      await file.parent.create(recursive: true);
      if (!await file.exists()) await file.writeAsString('x' * 2000000);
      blocked.add(file.path);
    }
    final outside = Zone.current;
    final attempts = <String>[];
    await IOOverrides.runZoned(() async {
      for (var i = 0; i < 3; i++) {
        final service = LocalMapEditorAuthoring(policy: policy);
        final before =
            await service.inspect(projectRoot: root.path, mapId: 'shore');
        final state = MapEditorState(
            lockedElements: {'model:mist_$i', 'decor:mist_$i'},
            hiddenElements: {'model:wind_$i', 'layer:border_$i'},
            hiddenFamilies: {'effect'});
        final result = await service.set(
            projectRoot: root.path,
            mapId: 'shore',
            expectedRevision: before.revision,
            state: state,
            operationId: 'lock_$i');
        final reopened = await LocalMapEditorAuthoring(policy: policy)
            .inspect(projectRoot: root.path, mapId: 'shore');
        expect(reopened.state, state);
        expect(reopened.revision, result.afterRevision);
      }
    }, createFile: (path) {
      final file = outside.run(() => File(path));
      return blocked.contains(file.path)
          ? _UnreadableFile(file, attempts)
          : file;
    });
    expect(attempts, isEmpty);
    expect(await File('${root.path}/maps/shore.editor.json').length(),
        lessThan(1024));
  });

  test('replay is idempotent and stale writers and undo preserve newer edits',
      () async {
    final service = LocalMapEditorAuthoring(policy: policy);
    final before =
        await service.inspect(projectRoot: root.path, mapId: 'shore');
    final state = MapEditorState(lockedElements: {'model:mist'});
    final result = await service.set(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: before.revision,
        state: state,
        operationId: 'lock');
    final replay = await service.set(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: before.revision,
        state: state,
        operationId: 'lock');
    expect(replay.receipt.receiptId, result.receipt.receiptId);
    await expectLater(
        service.set(
            projectRoot: root.path,
            mapId: 'shore',
            expectedRevision: before.revision,
            state: MapEditorState(),
            operationId: 'stale'),
        throwsFormatException);
    final changed = await service.set(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: result.afterRevision,
        state: state.copyWith(lockedFamilies: {'effect'}),
        operationId: 'family');
    await expectLater(
        service.undo(
            projectRoot: root.path,
            mapId: 'shore',
            mutation: result,
            operationId: 'stale_undo'),
        throwsFormatException);
    final undone = await service.undo(
        projectRoot: root.path,
        mapId: 'shore',
        mutation: changed,
        operationId: 'undo_family');
    expect(undone.afterState, state);
  });

  test('interrupted promotion requires recovery and resumes the same intent',
      () async {
    final service = LocalMapEditorAuthoring(policy: policy);
    final before =
        await service.inspect(projectRoot: root.path, mapId: 'shore');
    final state = MapEditorState(lockedElements: {'model:mist'});
    final crash = LocalMapEditorAuthoring(
        policy: policy,
        faultInjector: (context) {
          if (context.checkpoint ==
              AuthoringTransactionCheckpoint.afterResourcePromoted) {
            throw const AuthoringTransactionSimulatedCrash();
          }
        });
    await expectLater(
        crash.set(
            projectRoot: root.path,
            mapId: 'shore',
            expectedRevision: before.revision,
            state: state,
            operationId: 'resume'),
        throwsA(anything));
    final afterCrash =
        await service.inspect(projectRoot: root.path, mapId: 'shore');
    await expectLater(
        service.set(
            projectRoot: root.path,
            mapId: 'shore',
            expectedRevision: afterCrash.revision,
            state: MapEditorState(),
            operationId: 'pending'),
        throwsA(anything));
    final recovered = await service.set(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: before.revision,
        state: state,
        operationId: 'resume');
    expect(recovered.afterState, state);
    final undone = await service.undo(
        projectRoot: root.path,
        mapId: 'shore',
        mutation: recovered,
        operationId: 'undo');
    expect(undone.afterState, MapEditorState());
    expect(await File('${root.path}/maps/shore.editor.json').exists(), isFalse);
  });

  test('unknown future or corrupted documents preserve original bytes',
      () async {
    final service = LocalMapEditorAuthoring(policy: policy);
    final before =
        await service.inspect(projectRoot: root.path, mapId: 'shore');
    final file = File('${root.path}/maps/shore.editor.json');
    for (final raw in [
      'invalid',
      '{"schemaVersion":3,"mapId":"shore","state":{}}',
      '{"schemaVersion":2,"mapId":"shore","state":{}}',
      '{"schemaVersion":1,"mapId":"shore","state":{"hiddenElements":[]}}',
      jsonEncode(
          MapEditorDocument(mapId: 'other', state: MapEditorState()).toJson()),
      'x' * 65537
    ]) {
      await file.writeAsString(raw);
      await expectLater(
          service.set(
              projectRoot: root.path,
              mapId: 'shore',
              expectedRevision: before.revision,
              state: MapEditorState(lockedElements: {'model:mist'}),
              operationId: 'invalid_${raw.length}'),
          throwsA(anything));
      expect(await file.readAsString(), raw);
    }
  });

  test('cold worker preserves locks replay conflicts and receipt undo',
      () async {
    final service = LocalMapEditorAuthoring(policy: policy, runInWorker: true);
    final before =
        await service.inspect(projectRoot: root.path, mapId: 'shore');
    final originalMap =
        await File('${root.path}/maps/shore.json').readAsBytes();
    final state = MapEditorState(
        lockedElements: {'model:mist'},
        hiddenElements: {'model:wind', 'layer:path', 'layer:border'},
        hiddenFamilies: {'effect'});
    final result = await service.set(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: before.revision,
        state: state,
        operationId: 'worker_first');
    final reopened = await LocalMapEditorAuthoring(policy: policy)
        .inspect(projectRoot: root.path, mapId: 'shore');
    expect(reopened.state, state);
    expect(reopened.revision, result.afterRevision);
    final replay = await service.set(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: before.revision,
        state: state,
        operationId: 'worker_first');
    expect(replay.receipt.receiptId, result.receipt.receiptId);
    await expectLater(
        service.set(
            projectRoot: root.path,
            mapId: 'shore',
            expectedRevision: before.revision,
            state: MapEditorState(),
            operationId: 'worker_stale'),
        throwsFormatException);
    final undo = await service.undo(
        projectRoot: root.path,
        mapId: 'shore',
        mutation: result,
        operationId: 'worker_undo');
    expect(undo.afterState, MapEditorState());
    expect(await File('${root.path}/maps/shore.editor.json').exists(), isFalse);
    expect(
        await File('${root.path}/maps/shore.json').readAsBytes(), originalMap);
  });

  test(
      'worker resumes an interrupted promotion and preserves unsupported bytes',
      () async {
    final direct = LocalMapEditorAuthoring(policy: policy);
    final before = await direct.inspect(projectRoot: root.path, mapId: 'shore');
    final state = MapEditorState(
        lockedElements: {'decor:mist'}, hiddenElements: {'layer:border'});
    final crash = LocalMapEditorAuthoring(
        policy: policy,
        faultInjector: (context) {
          if (context.checkpoint ==
              AuthoringTransactionCheckpoint.afterResourcePromoted) {
            throw const AuthoringTransactionSimulatedCrash();
          }
        });
    await expectLater(
        crash.set(
            projectRoot: root.path,
            mapId: 'shore',
            expectedRevision: before.revision,
            state: state,
            operationId: 'worker_resume'),
        throwsA(anything));
    final worker = LocalMapEditorAuthoring(policy: policy, runInWorker: true);
    final result = await worker.set(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: before.revision,
        state: state,
        operationId: 'worker_resume');
    expect(result.afterState, state);
    final file = File('${root.path}/maps/shore.editor.json');
    const future = '{"schemaVersion":3,"mapId":"shore","state":{}}';
    await file.writeAsString(future);
    await expectLater(
        worker.set(
            projectRoot: root.path,
            mapId: 'shore',
            expectedRevision: result.afterRevision,
            state: MapEditorState(),
            operationId: 'worker_future'),
        throwsFormatException);
    expect(await file.readAsString(), future);
  });
  for (final secondWorker in [false, true]) {
    test('worker shares host project queue with secondWorker=$secondWorker',
        () async {
      final worker = LocalMapEditorAuthoring(policy: policy, runInWorker: true);
      final other =
          LocalMapEditorAuthoring(policy: policy, runInWorker: secondWorker);
      final before =
          await worker.inspect(projectRoot: root.path, mapId: 'shore');
      final entered = Completer<void>();
      final release = Completer<void>();
      final held = withLocalProjectWriteQueue(root.path, () async {
        entered.complete();
        await release.future;
      });
      await entered.future;
      var completed = 0;
      Future<bool> attempt(LocalMapEditorAuthoring service, String id) async {
        try {
          await service.set(
              projectRoot: root.path,
              mapId: 'shore',
              expectedRevision: before.revision,
              state: MapEditorState(lockedElements: {'model:$id'}),
              operationId: id);
          return true;
        } on Object catch (error) {
          expect(error.toString(), contains('revision'));
          return false;
        } finally {
          completed++;
        }
      }

      final first = attempt(worker, 'worker_queued');
      final second = attempt(other, 'other_queued');
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(completed, 0);
      expect(
          await File('${root.path}/maps/shore.editor.json').exists(), isFalse);
      release.complete();
      await held;
      expect(
          (await Future.wait([first, second])).where((value) => value).length,
          1);
      final reopened =
          await worker.inspect(projectRoot: root.path, mapId: 'shore');
      expect(reopened.state.lockedElements, hasLength(1));
    });
  }
  test('worker diagnostics count real I/O and exclude unrelated content',
      () async {
    final port = ReceivePort();
    final report = port.first;
    final service = LocalMapEditorAuthoring(
        policy: policy, runInWorker: true, diagnosticsPort: port.sendPort);
    final direct = LocalMapEditorAuthoring(policy: policy);
    final before = await direct.inspect(projectRoot: root.path, mapId: 'shore');
    await service.set(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: before.revision,
        state: MapEditorState(lockedElements: {'model:mist'}),
        operationId: 'traced_worker');
    final trace = await report as Map;
    port.close();
    final rows = (trace['rows'] as List).cast<Map>();
    expect(rows.where((row) => row['operation'] == 'write'), isNotEmpty);
    expect(rows.where((row) => row['operation'] == 'flush'), isNotEmpty);
    final reads = rows.where((row) => [
          'read',
          'streamDelivered',
          'list',
          'listRecursive'
        ].contains(row['operation']));
    expect(
        reads.where((row) =>
            row['path'] == 'project.json' ||
            row['path'] == '.pokemap/authoring/history.jsonl' ||
            row['path'] == '.pokemap/authoring/idempotency.jsonl' ||
            (row['path'] as String).startsWith('assets/')),
        isEmpty);
    expect(reads.where((row) => row['path'] == 'maps/shore.json'), isEmpty);
  });

  for (final worker in [false, true]) {
    test(
        'version one reads without rewriting and visibility undo worker=$worker',
        () async {
      final file = File('${root.path}/maps/shore.editor.json');
      final legacy = utf8.encode(jsonEncode({
        'schemaVersion': 1,
        'mapId': 'shore',
        'state': {
          'lockedElements': ['model:mist'],
          'lockedFamilies': ['layer']
        }
      }));
      await file.writeAsBytes(legacy);
      final service =
          LocalMapEditorAuthoring(policy: policy, runInWorker: worker);
      final readTrace = MapAuthoringWorkerTrace(root.path);
      final before = await readTrace
          .run(() => service.inspect(projectRoot: root.path, mapId: 'shore'));
      expect(before.state.lockedElements, {'model:mist'});
      expect(before.state.lockedFamilies, {'layer'});
      expect(before.state.hiddenElements, isEmpty);
      expect(before.state.hiddenFamilies, isEmpty);
      expect(await file.readAsBytes(), legacy);
      final readRows = (readTrace.snapshot()['rows']! as List).cast<Map>();
      expect(
          readRows.where((row) => ['write', 'rename', 'delete', 'flush']
              .contains(row['operation'])),
          isEmpty);
      final state = before.state.copyWith(
          hiddenElements: {'model:wind', 'layer:path', 'layer:border'},
          hiddenFamilies: {'effect'});
      final result = await service.set(
          projectRoot: root.path,
          mapId: 'shore',
          expectedRevision: before.revision,
          state: state,
          operationId: 'legacy_hide');
      expect(jsonDecode(await file.readAsString())['schemaVersion'], 2);
      final reopened = await LocalMapEditorAuthoring(policy: policy)
          .inspect(projectRoot: root.path, mapId: 'shore');
      expect(reopened.state, state);
      final replay = await service.set(
          projectRoot: root.path,
          mapId: 'shore',
          expectedRevision: before.revision,
          state: state,
          operationId: 'legacy_hide');
      expect(replay.receipt.receiptId, result.receipt.receiptId);
      await expectLater(
          service.set(
              projectRoot: root.path,
              mapId: 'shore',
              expectedRevision: before.revision,
              state: state.copyWith(hiddenElements: {}),
              operationId: 'legacy_hide'),
          throwsA(predicate(
              (error) => error.toString().contains('payload_conflict'))));
      final undone = await service.undo(
          projectRoot: root.path,
          mapId: 'shore',
          mutation: result,
          operationId: 'legacy_hide_undo');
      expect(undone.afterState, before.state);
      expect(
          (await LocalMapEditorAuthoring(policy: policy)
                  .inspect(projectRoot: root.path, mapId: 'shore'))
              .state,
          before.state);
    });
  }

  test(
      'visibility cold worker work is unchanged with zero or 2000 unrelated maps',
      () async {
    Map<String, int>? baseline;
    for (final unrelated in [0, 2000]) {
      final directory = Directory('${root.path}/case_$unrelated');
      await Directory('${directory.path}/maps').create(recursive: true);
      await File('${directory.path}/maps/shore.json')
          .writeAsString('do not decode');
      await File('${directory.path}/project.json')
          .writeAsString('do not decode');
      for (var index = 0; index < unrelated; index++) {
        await File('${directory.path}/maps/other_$index.editor.json')
            .writeAsString('unrelated');
      }
      final localPolicy = await WorkspacePolicy.create(
          allowedRootPaths: [directory.path],
          fileReader: const LocalProjectFileReader());
      final before = await LocalMapEditorAuthoring(policy: localPolicy)
          .inspect(projectRoot: directory.path, mapId: 'shore');
      final port = ReceivePort();
      final report = port.first;
      final service = LocalMapEditorAuthoring(
          policy: localPolicy,
          runInWorker: true,
          diagnosticsPort: port.sendPort);
      final state = MapEditorState(
          lockedElements: {'model:mist'},
          hiddenElements: {'layer:path', 'layer:border', 'model:wind'},
          hiddenFamilies: {'effect'});
      await service.set(
          projectRoot: directory.path,
          mapId: 'shore',
          expectedRevision: before.revision,
          state: state,
          operationId: 'hide_bounded');
      final trace = await report as Map;
      port.close();
      final rows = (trace['rows'] as List).cast<Map>();
      final work = <String, int>{};
      for (final row in rows) {
        final operation = row['operation'] as String;
        work.update(operation, (count) => count + (row['calls'] as int),
            ifAbsent: () => row['calls'] as int);
      }
      if (baseline == null) {
        baseline = work;
      } else {
        expect(work, baseline);
      }
      expect(
          rows.where((row) =>
              (row['bytes'] as int) > 0 &&
              ((row['path'] as String).startsWith('maps/other_') ||
                  row['path'] == 'maps/shore.json' ||
                  row['path'] == 'project.json')),
          isEmpty);
      expect(
          (await LocalMapEditorAuthoring(policy: localPolicy)
                  .inspect(projectRoot: directory.path, mapId: 'shore'))
              .state,
          state);
    }
  });

  test('all four collections share the unchanged 64 KiB document limit',
      () async {
    final service = LocalMapEditorAuthoring(policy: policy);
    final before =
        await service.inspect(projectRoot: root.path, mapId: 'shore');
    final original = await service.set(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: before.revision,
        state: MapEditorState(lockedElements: {'model:mist'}),
        operationId: 'small_state');
    final file = File('${root.path}/maps/shore.editor.json');
    final bytes = await file.readAsBytes();
    final large = MapEditorState(lockedElements: {
      for (var index = 0; index < 100; index++)
        'model:locked_$index'.padRight(320, 'x')
    }, hiddenElements: {
      for (var index = 0; index < 110; index++)
        'model:hidden_$index'.padRight(320, 'x')
    });
    await expectLater(
        service.set(
            projectRoot: root.path,
            mapId: 'shore',
            expectedRevision: original.afterRevision,
            state: large,
            operationId: 'too_large'),
        throwsFormatException);
    expect(await file.readAsBytes(), bytes);
  });
}

final class _UnreadableFile implements File {
  _UnreadableFile(this.delegate, this.attempts);
  final File delegate;
  final List<String> attempts;
  Never deny() {
    attempts.add(path);
    throw StateError('Unrelated file read: $path');
  }

  @override
  String get path => delegate.path;
  @override
  Uri get uri => delegate.uri;
  @override
  bool get isAbsolute => delegate.isAbsolute;
  @override
  File get absolute => delegate.absolute;
  @override
  Directory get parent => delegate.parent;
  @override
  Future<Uint8List> readAsBytes() async => deny();
  @override
  Future<String> readAsString({Encoding encoding = utf8}) async => deny();
  @override
  Stream<List<int>> openRead([int? start, int? end]) => deny();
  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) async =>
      deny();
  @override
  Future<bool> exists() => delegate.exists();
  @override
  Future<FileStat> stat() => delegate.stat();
  @override
  Future<String> resolveSymbolicLinks() => delegate.resolveSymbolicLinks();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
