import 'package:map_authoring/src/transactions/local_authoring_payload.dart';
import 'dart:io';
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
