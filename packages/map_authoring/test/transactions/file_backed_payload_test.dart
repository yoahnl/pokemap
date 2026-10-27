import 'package:map_authoring/src/transactions/local_authoring_payload.dart';
import 'dart:io';
import 'package:map_authoring/src/support/authoring_performance_observer.dart';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_authoring/src/infrastructure/local_resource_pack_store.dart';
import 'package:map_authoring/src/ports/file_backed_payload_store.dart';
import '../support/transaction_test_fixture.dart';
import 'package:map_authoring/src/transactions/authoring_payload.dart';
import 'package:test/test.dart';

void main() {
  test(
      'staged payload verifies its framed identity in one pass and rechecks consumption',
      () async {
    final directory = await Directory.systemTemp.createTemp('staged-one-pass-');
    addTearDown(() => directory.delete(recursive: true));
    final observer = _GatewayByteObserver();
    final gateway = await LocalTransactionFileGateway.open(
        projectRoot: directory.path, performanceObserver: observer);
    final bytes = List<int>.generate(100620, (index) => index % 251);
    await gateway.stagePayload(
        operationId: 'one-pass',
        storageKey: 'source.bin',
        kind: TransactionPayloadKind.after,
        bytes: bytes);
    observer.counters.clear();
    final staged = await gateway.readStagedPayload(
        operationId: 'one-pass',
        storageKey: 'source.bin',
        kind: TransactionPayloadKind.after);
    expect(
        (observer.counters['io.gateway.verification.readBytes'] ?? 0) +
            (observer.counters['io.gateway.resource.readBytes'] ?? 0),
        bytes.length);
    observer.counters.clear();
    expect(await staged.payload!.readBytes(), bytes);
    expect(observer.counters['io.gateway.resource.readBytes'], bytes.length);
    final file = (await Directory('${directory.path}/.pokemap')
            .list(recursive: true)
            .where(
                (entry) => entry is File && entry.path.endsWith('.after.bin'))
            .cast<File>()
            .toList())
        .single;
    final corrupted = bytes.toList()..[bytes.length - 1] ^= 1;
    await file.writeAsBytes(corrupted);
    await expectLater(
        staged.payload!.readBytes(),
        throwsA(isA<AuthoringPayloadException>()
            .having((error) => error.code, 'code', 'payload.source_mismatch')));
    await staged.payload!.release();
  });
  test('gateway counts real streaming bytes after each completed write',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('gateway-observed-');
    addTearDown(() => directory.delete(recursive: true));
    final observer = _GatewayByteObserver();
    final gateway = await LocalTransactionFileGateway.open(
        projectRoot: directory.path, performanceObserver: observer);
    expect(gateway, isA<StreamingTransactionFileGateway>());
    final bytes = utf8.encode('é😀');
    var staging = false;
    int? writtenBeforeSecondChunk;
    Stream<List<int>> chunks() async* {
      yield bytes.sublist(0, 3);
      if (staging) {
        writtenBeforeSecondChunk = observer
            .counters['io.gateway.stagedPayload.completedWriteInputBytes'];
      }
      yield bytes.sublist(3);
    }

    final payload = await AuthoringPayload.verifiedSource(
        storageKey: 'assets/été😀.bin',
        byteLength: bytes.length,
        rawSha256: sha256.convert(bytes).toString(),
        openRead: chunks);
    addTearDown(payload.release);
    expect(() => payload.inlineBytes, throwsStateError);
    staging = true;
    await gateway.stageAuthoringPayload(
        operationId: 'observed',
        storageKey: 'assets/été😀.bin',
        kind: TransactionPayloadKind.after,
        payload: payload);
    staging = false;
    expect(writtenBeforeSecondChunk, 3);
    final descriptor = (await Directory('${directory.path}/.pokemap')
            .list(recursive: true)
            .where((file) => file is File && file.path.endsWith('.json'))
            .cast<File>()
            .toList())
        .single;
    expect(
        observer.counters['io.gateway.stagedPayload.completedWriteInputBytes'],
        bytes.length);
    expect(
        observer.counters['io.gateway.verification.readBytes'], bytes.length);
    expect(observer.counters['io.gateway.descriptor.completedWriteInputBytes'],
        await descriptor.length());
    observer.counters.clear();
    final staged = await gateway.readStagedPayload(
        operationId: 'observed',
        storageKey: 'assets/été😀.bin',
        kind: TransactionPayloadKind.after);
    expect(staged.payload!.isInline, isFalse);
    expect(observer.counters['io.gateway.verification.readBytes'] ?? 0, 0);
    expect(observer.counters['io.gateway.resource.readBytes'], bytes.length);
    observer.counters.clear();
    expect(await staged.payload!.openRead().expand((chunk) => chunk).toList(),
        bytes);
    expect(observer.counters['io.gateway.resource.readBytes'], bytes.length);
    final descriptorBytes = await descriptor.readAsBytes();
    expect(descriptorBytes.length,
        greaterThan((await descriptor.readAsString()).length));
    await descriptor.writeAsBytes([0xef, 0xbb, 0xbf, ...descriptorBytes]);
    expect(
        (await gateway.readStagedPayload(
                operationId: 'observed',
                storageKey: 'assets/été😀.bin',
                kind: TransactionPayloadKind.after))
            .payload!
            .byteLength,
        bytes.length);
    await descriptor.writeAsBytes([0xff]);
    await expectLater(
        gateway.readStagedPayload(
            operationId: 'observed',
            storageKey: 'assets/été😀.bin',
            kind: TransactionPayloadKind.after),
        throwsA(isA<TransactionFileGatewayException>().having(
            (error) => error.code, 'code', 'transaction.stage_corrupt')));
    await descriptor.delete();
    await expectLater(
        gateway.readStagedPayload(
            operationId: 'observed',
            storageKey: 'assets/été😀.bin',
            kind: TransactionPayloadKind.after),
        throwsA(isA<TransactionFileGatewayException>().having(
            (error) => error.code, 'code', 'transaction.stage_missing')));
    expect(observer.counters.containsKey('io.gateway.descriptor.readBytes'),
        isFalse);
    expect(await gateway.readResource('assets/missing.bin'), isNull);
  });

  test('gateway counts repeated real resource reads and captures separately',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('gateway-read-observed-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/source.bin');
    final bytes = utf8.encode('été😀');
    await file.writeAsBytes(bytes);
    final observer = _GatewayByteObserver();
    final gateway = await LocalTransactionFileGateway.open(
        projectRoot: directory.path, performanceObserver: observer);
    final first = await gateway.readResource('source.bin');
    expect(first, bytes);
    expect(() => first!.add(0), throwsUnsupportedError);
    expect(await gateway.readResource('source.bin'), bytes);
    expect(
        observer.counters['io.gateway.resource.readBytes'], bytes.length * 2);
    await gateway.readResourceRevision('source.bin');
    expect(
        observer.counters['io.gateway.verification.readBytes'], bytes.length);
    final capture = await gateway.captureResourcePayload('source.bin');
    addTearDown(capture!.release);
    expect(
        observer.counters['io.gateway.resource.readBytes'], bytes.length * 3);
    expect(observer.counters['io.gateway.verification.readBytes'],
        bytes.length * 2);
    expect(await capture.readBytes(), bytes);
    expect(
        observer.counters['io.gateway.resource.readBytes'], bytes.length * 3);
  });

  test(
      'gateway journals count completed UTF8 writes while read bytes stay unknown',
      () async {
    final harness = await TransactionTestHarness.create();
    addTearDown(harness.dispose);
    final applied = await harness.apply();
    final json = applied.toJson();
    json['extensions'] = {'label': 'été😀'};
    final journal = AuthoringTransactionJournal(
        operationId: harness.operationId,
        planId: harness.plan.planId,
        scope: harness.scope,
        status: AuthoringTransactionStatus.prepared,
        createdAt: harness.now,
        updatedAt: harness.now,
        intendedReceipt:
            AuthoringReceipt.fromJson(Map<String, dynamic>.from(json)),
        entries: [
          for (final change in harness.plan.changeSet.changes)
            AuthoringTransactionJournalEntry(
                resource: change.resource,
                storageKey: change.storageKey,
                beforeRevision: change.beforeRevision,
                afterRevision: change.afterRevision)
        ]);
    final observer = _GatewayByteObserver();
    final gateway = await LocalTransactionFileGateway.open(
        projectRoot: harness.projectDirectory.path,
        performanceObserver: observer);
    await gateway.writeJournal(journal);
    final encoded = utf8.encode(jsonEncode(journal.toJson()));
    expect(encoded.length, greaterThan(jsonEncode(journal.toJson()).length));
    expect(observer.counters['io.gateway.journal.completedWriteInputBytes'],
        encoded.length);
    expect(observer.counters['journal.completedWrites'], 1);
    expect((await gateway.readJournal(journal.operationId))!.toJson(),
        journal.toJson());
    final file = File(
        '${harness.projectDirectory.path}/.pokemap/authoring/transactions/${journal.operationId}/journal.json');
    await file.writeAsBytes([0xef, 0xbb, 0xbf, ...encoded]);
    expect((await gateway.readJournal(journal.operationId))!.toJson(),
        journal.toJson());
    await file.writeAsBytes([0xff]);
    await expectLater(
        gateway.readJournal(journal.operationId),
        throwsA(isA<TransactionFileGatewayException>().having(
            (error) => error.code, 'code', 'transaction.journal_corrupt')));
    expect(await gateway.readJournal('missing'), isNull);
    expect(
        observer.counters.containsKey('io.gateway.journal.readBytes'), isFalse);
  });

  for (final length in [0, 1, 1024 * 1024, 2 * 1024 * 1024 + 7]) {
    test('stored payload verifies framed and raw hashes at $length bytes',
        () async {
      final bytes = List<int>.generate(length, (index) => index % 251);
      final payload = await captureAuthoringPayload(
        storageKey: 'assets/source.bin',
        chunks: Stream.fromIterable([
          for (var offset = 0; offset < bytes.length; offset += 65536)
            bytes.sublist(offset, (offset + 65536).clamp(0, bytes.length)),
        ]),
        byteLength: bytes.length,
      );
      addTearDown(payload.release);
      expect(payload.isInline, isFalse);
      expect(payload.byteLength, bytes.length);
      expect(payload.rawSha256, sha256.convert(bytes).toString());
      expect(
          payload.resourceRevision,
          computeAuthoringBytesFingerprint(bytes,
              logicalName: 'assets/source.bin'));
      expect(() => payload.inlineBytes, throwsStateError);
      expect(await payload.readBytes(), bytes);
      final change = AuthoringResourceChange.withPayloads(
        resource: AuthoringResourceRef(kind: 'asset', id: 'source'),
        storageKey: 'assets/source.bin',
        beforePayload: payload,
        afterPayload: null,
      );
      expect(change.beforePayload, isNotNull);
      expect(change.beforeRevision, payload.resourceRevision);
      expect(change.toJson()['beforeByteLength'], length);
      expect(() => change.beforeBytes, throwsStateError);
    });
  }

  test('stored payload owns a plan lease independently of the staging owner',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('payload-plan-lease-');
    addTearDown(() => directory.delete(recursive: true));
    var now = DateTime.utc(2026, 10, 16);
    final store = LocalResourcePackStore(
        cacheDirectory: directory.path,
        allowedSourceRoots: const [],
        clock: () => now);
    addTearDown(store.close);
    const scope = FileBackedPayloadScope(
        sessionId: 'session-one', projectId: 'project-one');
    final staged = await store.stage(
        scope: scope, chunks: Stream.value([1, 2, 3]), byteLength: 3);
    await expectLater(
        AuthoringPayload.stored(
            store: store,
            scope: scope,
            payload: StoredFilePayload(
                handle: staged.payload.handle,
                byteLength: 2,
                rawSha256: staged.payload.rawSha256),
            storageKey: 'assets/data.bin'),
        throwsA(isA<AuthoringPayloadException>()));
    final payload = await AuthoringPayload.stored(
        store: store,
        scope: scope,
        payload: staged.payload,
        storageKey: 'assets/data.bin');
    await store.release(scope: scope, leaseId: staged.leaseId);
    now = now.add(const Duration(days: 2));
    await store.collectExpired();
    expect(await payload.readBytes(), [1, 2, 3]);
    await payload.release();
    now = now.add(const Duration(days: 2));
    await store.collectExpired();
    expect(store.cachedBytes, 0);
    await expectLater(
        AuthoringPayload.stored(
            store: store,
            scope: scope,
            payload: staged.payload,
            storageKey: 'assets/data.bin'),
        throwsA(isA<FileBackedPayloadException>()));
  });

  test('planner keeps binary images on disk and discard awaits owned cleanup',
      () async {
    final harness = await TransactionTestHarness.create();
    addTearDown(harness.dispose);
    final snapshot = ProjectSnapshot(
        projectHandle: const ProjectHandle('prj_payload'),
        revision: harness.plan.baseRevision,
        manifest: ProjectManifest(
            name: 'Payload', maps: const [], tilesets: const []),
        maps: const [],
        resourceFingerprints: const {});
    final store = AuthoringPlanStore();
    final resource = AuthoringResourceRef(kind: 'asset', id: 'binary');
    final plan = await AuthoringActionPlanner(store: store).plan(
        request: harness.plan.request,
        snapshot: snapshot,
        build: (_) => AuthoringMutationDraft(
                changeSet: AuthoringChangeSet(
                    changes: [
                  AuthoringResourceChange(
                      resource: resource,
                      storageKey: 'assets/binary.bin',
                      beforeBytes: null,
                      afterBytes: List.filled(1024 * 1024, 7))
                ],
                    diff: AuthoringDiff([
                      AuthoringDiffEntry(
                          operation: AuthoringDiffOperation.add,
                          resource: resource,
                          path: '/',
                          after: 'binary')
                    ]))));
    final payload = plan.changeSet.changes.single.afterPayload!;
    expect(payload.isInline, isFalse);
    expect(await store.discard(plan.planId), isTrue);
    expect(store.length, 0);
    await expectLater(
        payload.readBytes(), throwsA(isA<AuthoringPayloadException>()));
  });

  test(
      'cleanup failure after durable commit returns the applied receipt and refresh diagnostic',
      () async {
    final root = await Directory.systemTemp.createTemp('committed-cleanup-');
    addTearDown(() => root.delete(recursive: true));
    final manifest = ProjectManifest(
        name: 'Before',
        version: ProjectVersion.v8,
        maps: const [],
        tilesets: const []);
    await File('${root.path}/project.json')
        .writeAsString(jsonEncode(manifest.toJson()));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final opened = await ProjectOpenService(
            policy: policy, handles: handles, fileReader: reader)
        .openProject(root.path);
    final loader = ProjectSnapshotLoader(handles: handles);
    var releases = 0;
    final dispatcher = MapMutationDispatcher([
      MapMutationActionRegistration(
          descriptor: AuthoringActionDescriptor(
              id: 'fixture.cleanup',
              version: 1,
              summary: 'Fixture cleanup',
              inputSchemaId: 'fixture.input',
              outputSchemaId: 'fixture.output',
              riskLevel: AuthoringRiskLevel.high,
              guarantees: const [
                AuthoringGuarantee.dryRun,
                AuthoringGuarantee.idempotent,
                AuthoringGuarantee.revisionChecked,
                AuthoringGuarantee.undoable
              ],
              requiredPermissions: const [
                AuthoringPermission.projectWrite
              ]),
          build: (context) async {
            final before = context.snapshot.resourceBytes('project');
            final payload = await AuthoringPayload.verifiedSource(
                storageKey: 'project.json',
                byteLength: before.length,
                rawSha256: sha256.convert(before).toString(),
                openRead: () => Stream.value(before),
                release: () async {
                  releases++;
                  throw StateError('fixture cleanup failed');
                });
            final resource =
                AuthoringResourceRef(kind: 'project', id: 'project');
            return AuthoringMutationDraft(
                changeSet: AuthoringChangeSet(
                    changes: [
                  AuthoringResourceChange.withPayloads(
                      resource: resource,
                      storageKey: 'project.json',
                      beforePayload: payload,
                      afterPayload: AuthoringPayload.inline(
                          utf8.encode(jsonEncode(
                              manifest.copyWith(name: 'After').toJson())),
                          storageKey: 'project.json'))
                ],
                    diff: AuthoringDiff([
                      AuthoringDiffEntry(
                          operation: AuthoringDiffOperation.replace,
                          resource: resource,
                          path: '/name',
                          before: 'Before',
                          after: 'After')
                    ])));
          })
    ]);
    final mutations = LocalMapAuthoringMutationApi(
        policy: policy, snapshotLoader: loader, dispatcher: dispatcher);
    addTearDown(() async {
      try {
        await mutations.detachWorkspace(opened.workspaceHandle);
      } on StateError catch (error) {
        expect(error.message, 'fixture cleanup failed');
      }
      handles.closeWorkspace(opened.workspaceHandle);
    });
    await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    final snapshot = await loader.load(opened.projectHandle);
    final plan = await mutations.planMutation(
        opened.projectHandle,
        AuthoringRequest(
            requestId: 'cleanup',
            actionId: 'fixture.cleanup',
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: 'cleanup'));
    final token = await mutations.confirmMutation(opened.projectHandle,
        planId: plan.planId);
    final result = await mutations.applyMutation(opened.projectHandle,
        planId: plan.planId,
        operationId: 'cleanup',
        confirmationToken: token.confirmationToken);
    expect(result.receipt.status, AuthoringReceiptStatus.applied);
    expect(result.snapshotRevision, isNull);
    expect(result.diagnostic!.code, 'snapshot.refresh_unavailable');
    expect(releases, 1);
    expect(
        (await mutations.listMutationHistory(opened.projectHandle, limit: 10))
            .entries,
        hasLength(1));
    expect(
        (jsonDecode(await File('${root.path}/project.json').readAsString())
            as Map)['name'],
        'After');
  });

  test('failed planning releases a captured resource before rejecting',
      () async {
    final harness = await TransactionTestHarness.create();
    addTearDown(harness.dispose);
    var releases = 0;
    final payload = await AuthoringPayload.verifiedSource(
        storageKey: 'assets/source.bin',
        byteLength: 1,
        rawSha256: sha256.convert([7]).toString(),
        openRead: () => Stream.value([7]),
        release: () async {
          await Future<void>.delayed(Duration.zero);
          releases++;
        });
    final snapshot = ProjectSnapshot(
        projectHandle: const ProjectHandle('prj_failure'),
        revision: harness.plan.baseRevision,
        manifest: ProjectManifest(
            name: 'Failure', maps: const [], tilesets: const []),
        maps: const [],
        resourceFingerprints: {'asset:source': payload.resourceRevision},
        resourceStorageKeys: const {'asset:source': 'assets/source.bin'},
        storedResources: {
          'asset:source': ProjectStoredResource(
              byteLength: 1,
              rawSha256: payload.rawSha256,
              resourceRevision: payload.resourceRevision)
        },
        resourcePayloadReader: (_, __, ___, ____) async => payload);
    final store = AuthoringPlanStore();
    await expectLater(
        AuthoringActionPlanner(store: store).plan(
            request: harness.plan.request,
            snapshot: snapshot,
            build: (context) async {
              await context.snapshot.captureResourcePayload('asset:source');
              throw StateError('fixture planner failed');
            }),
        throwsStateError);
    expect(releases, 1);
    expect(store.length, 0);
  });

  test(
      'cleanup awaits every owned payload and does not retry a failing release',
      () async {
    var firstReleases = 0;
    var secondReleases = 0;
    final before = await AuthoringPayload.verifiedSource(
        storageKey: 'assets/data.bin',
        byteLength: 1,
        rawSha256: sha256.convert([1]).toString(),
        openRead: () => Stream.value([1]),
        release: () {
          firstReleases++;
          throw StateError('fixture cleanup failed');
        });
    final after = await AuthoringPayload.verifiedSource(
        storageKey: 'assets/data.bin',
        byteLength: 1,
        rawSha256: sha256.convert([2]).toString(),
        openRead: () => Stream.value([2]),
        release: () async {
          await Future<void>.delayed(Duration.zero);
          secondReleases++;
        });
    final resource = AuthoringResourceRef(kind: 'asset', id: 'source');
    final changes = AuthoringChangeSet(
        changes: [
          AuthoringResourceChange.withPayloads(
              resource: resource,
              storageKey: 'assets/data.bin',
              beforePayload: before,
              afterPayload: after)
        ],
        diff: AuthoringDiff([
          AuthoringDiffEntry(
              operation: AuthoringDiffOperation.replace,
              resource: resource,
              path: '/',
              before: 'one',
              after: 'two')
        ]));
    await expectLater(changes.releasePayloads(), throwsStateError);
    await expectLater(changes.releasePayloads(), throwsStateError);
    expect(firstReleases, 1);
    expect(secondReleases, 1);
  });

  test('expiry removes the plan and awaits its unique owned release', () async {
    final harness = await TransactionTestHarness.create();
    addTearDown(harness.dispose);
    var now = harness.now;
    var releases = 0;
    final payload = await AuthoringPayload.verifiedSource(
        storageKey: 'assets/data.bin',
        byteLength: 1,
        rawSha256: sha256.convert([7]).toString(),
        openRead: () => Stream.value([7]),
        release: () async {
          await Future<void>.delayed(Duration.zero);
          releases++;
        });
    final resource = AuthoringResourceRef(kind: 'asset', id: 'binary');
    final plan = AuthoringPlan(
        planId: 'plan_expiring',
        receiptId: 'receipt_expiring',
        request: harness.plan.request,
        baseRevision: harness.plan.baseRevision,
        seed: 1,
        createdAt: now,
        expiresAt: now.add(const Duration(seconds: 1)),
        changeSet: AuthoringChangeSet(
            changes: [
              AuthoringResourceChange.withPayloads(
                  resource: resource,
                  storageKey: 'assets/data.bin',
                  beforePayload: null,
                  afterPayload: payload)
            ],
            diff: AuthoringDiff([
              AuthoringDiffEntry(
                  operation: AuthoringDiffOperation.add,
                  resource: resource,
                  path: '/',
                  after: 'binary')
            ])));
    final store = AuthoringPlanStore(clock: () => now)..save(plan);
    now = now.add(const Duration(seconds: 2));
    await expectLater(store.resolveActive(plan.planId),
        throwsA(isA<AuthoringPlanException>()));
    expect(store.length, 0);
    expect(releases, 1);
    await store.dispose();
    expect(releases, 1);
  });

  test(
      'gateway stages verifies and promotes stored payload without inline bytes',
      () async {
    final directory = await Directory.systemTemp.createTemp('payload-gateway-');
    addTearDown(() => directory.delete(recursive: true));
    final gateway =
        await LocalTransactionFileGateway.open(projectRoot: directory.path);
    final bytes =
        List<int>.generate(2 * 1024 * 1024 + 9, (index) => index % 253);
    final payload = await captureAuthoringPayload(
        storageKey: 'assets/data.bin',
        chunks: Stream.value(bytes),
        byteLength: bytes.length);
    addTearDown(payload.release);
    await gateway.stageAuthoringPayload(
        operationId: 'operation_one',
        storageKey: 'assets/data.bin',
        kind: TransactionPayloadKind.after,
        payload: payload);
    final staged = await gateway.readStagedPayload(
        operationId: 'operation_one',
        storageKey: 'assets/data.bin',
        kind: TransactionPayloadKind.after);
    expect(staged.payload!.isInline, isFalse);
    expect(() => staged.bytes, throwsStateError);
    await gateway.promoteStaged(
        operationId: 'operation_one',
        storageKey: 'assets/data.bin',
        kind: TransactionPayloadKind.after,
        expectedCurrentRevision: null);
    expect(await gateway.readResourceRevision('assets/data.bin'),
        payload.resourceRevision);
    final captured = await gateway.captureResourcePayload('assets/data.bin');
    addTearDown(captured!.release);
    await File('${directory.path}/assets/data.bin').writeAsBytes([99]);
    expect(await captured.readBytes(), bytes);
    await gateway.deleteTransaction('operation_one');
  });

  test('stored capability rejects changed source before exposing it', () async {
    final directory = await Directory.systemTemp.createTemp('payload-source-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/source')..writeAsBytesSync([1, 2, 3]);
    final payload = await AuthoringPayload.verifiedSource(
      storageKey: 'assets/source.bin',
      byteLength: 3,
      rawSha256: sha256.convert([1, 2, 3]).toString(),
      openRead: file.openRead,
    );
    await file.writeAsBytes([1, 2, 4]);
    await expectLater(
        payload.readBytes(), throwsA(isA<AuthoringPayloadException>()));
  });

  test('stored factory rejects false metadata before returning capability',
      () async {
    await expectLater(
      AuthoringPayload.verifiedSource(
        storageKey: 'assets/source.bin',
        byteLength: 2,
        rawSha256: sha256.convert([1, 2, 3]).toString(),
        openRead: () => Stream.value([1, 2, 3]),
      ),
      throwsA(isA<AuthoringPayloadException>()),
    );
  });

  test('owned capture releases once and refuses subsequent reads', () async {
    final payload = await captureAuthoringPayload(
      storageKey: 'assets/source.bin',
      chunks: Stream.value([1]),
      byteLength: 1,
    );
    await payload.release();
    await payload.release();
    await expectLater(
        payload.readBytes(), throwsA(isA<AuthoringPayloadException>()));
  });
}

final class _GatewayByteObserver implements AuthoringPerformanceObserver {
  final counters = <String, int>{};
  @override
  AuthoringPerformanceSpan? startSpan(String name) => null;
  @override
  void incrementCounter(String name, {int by = 1}) {
    counters.update(name, (value) => value + by, ifAbsent: () => by);
  }
}
