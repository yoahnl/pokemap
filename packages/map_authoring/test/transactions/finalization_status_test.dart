import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/transaction_test_fixture.dart';

void main() {
  test('direct and JSONL status inspect recovery and completed replay',
      () async {
    final root = await Directory.systemTemp.createTemp('finalization-status-');
    addTearDown(() => root.delete(recursive: true));
    await File('${root.path}/project.json').writeAsString(jsonEncode(
      const ProjectManifest(name: 'Status fixture', maps: [], tilesets: [])
          .toJson(),
    ));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final read = AuthoringReadApi(
      openService: ProjectOpenService(
          policy: policy, fileReader: reader, handles: handles),
      snapshotLoader: snapshots,
    );
    var interrupted = false;
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
      faultInjector: (context) {
        if (!interrupted &&
            context.checkpoint ==
                AuthoringTransactionCheckpoint.afterJournalCommitted) {
          interrupted = true;
          throw StateError('finalization failed');
        }
      },
    );
    final opened = await read.openProject(root.path);
    addTearDown(() async {
      await mutations.detachWorkspace(opened.workspaceHandle);
      await read.closeWorkspace(opened.workspaceHandle);
    });
    await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    const operation = 'status-create-map';
    final snapshot = await snapshots.load(opened.projectHandle);
    final plan = await mutations.planMutation(
        opened.projectHandle,
        AuthoringRequest(
          requestId: operation,
          actionId: 'map.create',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          idempotencyKey: operation,
          expectedRevision: snapshot.revision,
          parameters: const {
            'mapId': 'town',
            'name': 'Town',
            'width': 2,
            'height': 2
          },
        ));
    await expectLater(
        () => mutations.applyMutation(opened.projectHandle,
            planId: plan.planId, operationId: operation),
        throwsA(isA<JournaledAuthoringTransactionException>()));
    final pending = await mutations.recoveryStatus(opened.projectHandle,
        operationId: operation);
    expect(pending['committed'], true);
    expect(pending['finalized'], false);
    final worker = JsonlWorker(api: read, mutations: mutations);
    final response = jsonDecode(await worker.processLine(jsonEncode({
      'id': 'status',
      'command': 'recovery_status',
      'args': {
        'projectHandle': opened.projectHandle.value,
        'operationId': operation,
      },
    }))) as Map;
    expect(response['status'], 'success');
    expect(response['data'], pending);
    await mutations.recoverMutation(opened.projectHandle,
        operationId: operation);
    final completed = await mutations.recoveryStatus(opened.projectHandle,
        operationId: operation);
    expect(completed['committed'], true);
    expect(completed['finalized'], true);
    expect(completed['recoverable'], false);
    expect(
        (await mutations.recoveryStatus(opened.projectHandle,
            operationId: 'unknown'))['disposition'],
        'notFound');
    expect(await File('${root.path}/maps/town.json').exists(), true);
  });

  test('reports committed data without claiming completed finalization',
      () async {
    final harness = await TransactionTestHarness.create();
    addTearDown(harness.dispose);
    final hook = _FailOnceHook();
    final transaction = JournaledAuthoringTransaction(
      plans: harness.planStore,
      gateway: harness.gateway,
      idempotency: harness.ledger,
      clock: () => harness.now,
      commitHook: hook,
    );
    Object? failure;
    try {
      await transaction.apply(
        planId: harness.plan.planId,
        request: harness.plan.request,
        currentProjectRevision: harness.currentProjectRevision,
        scope: harness.scope,
        operationId: harness.operationId,
      );
    } on Object catch (error) {
      failure = error;
    }
    expect(failure, isA<JournaledAuthoringTransactionException>());
    final response = jsonDecode(await JsonlWorker(
      api: _ThrowingReadApi(failure!),
    ).processLine(jsonEncode({
      'id': 'failed-finalization',
      'command': 'describe',
      'args': <String, Object?>{},
    }))) as Map;
    expect(response['status'], 'failure');
    final error = response['error'] as Map;
    expect(error['retryable'], isFalse);
    final details = error['details'] as Map;
    expect(details['domainCode'], 'transaction.finalization_required');
    expect(details['operationId'], harness.operationId);
    expect(details['receiptId'], harness.plan.receiptId);
    expect(details['committed'], isTrue);
    expect(details['recoverable'], isNull);
    expect(details['recoveryRequired'], isTrue);
    expect(details['finalized'], isFalse);
    expect(jsonEncode(response), isNot(contains('private-secret')));
    expect(await harness.readA(), TransactionTestHarness.afterA);
    expect(await harness.readB(), TransactionTestHarness.afterB);

    final recovery = AuthoringRecoveryService(
      gateway: harness.gateway,
      idempotency: harness.ledger,
      clock: () => harness.now,
      commitHook: hook,
    );
    final pending = (await recovery.inspect()).single.toJson();
    expect(pending['committed'], isTrue);
    expect(pending['recoverable'], isTrue);
    expect(pending['finalized'], isFalse);
    expect(pending['receiptId'], harness.plan.receiptId);
    final recovered = await recovery.resume(harness.operationId);
    final completed = (await recovery.inspect()).single.toJson();
    expect(completed['committed'], isTrue);
    expect(completed['finalized'], isTrue);
    expect(completed['recoverable'], isFalse);
    expect(hook.recorded, [harness.plan.receiptId]);
    final replay = await harness.apply();
    expect(replay.toJson(), recovered.toJson());
    expect(hook.recorded, [harness.plan.receiptId]);
    expect(await harness.readA(), TransactionTestHarness.afterA);
  });

  test('does not classify a partial promotion as a durable commit', () async {
    final harness = await TransactionTestHarness.create(
      faultInjector: (context) {
        if (context.checkpoint ==
                AuthoringTransactionCheckpoint.afterResourcePromoted &&
            context.promotionIndex == 0) {
          throw const AuthoringTransactionSimulatedCrash();
        }
      },
    );
    addTearDown(harness.dispose);
    await expectLater(
        harness.apply, throwsA(isA<AuthoringTransactionSimulatedCrash>()));
    final recovery = await harness.reopenRecovery();
    final status = (await recovery.inspect()).single.toJson();
    expect(status['committed'], isFalse);
    expect(status['finalized'], isFalse);
    expect(status['recoverable'], isTrue);
    expect(await harness.readA(), TransactionTestHarness.afterA);
    expect(await harness.readB(), TransactionTestHarness.beforeB);
  });

  test('reports a recoverable runtime error after partial promotion', () async {
    final harness = await TransactionTestHarness.create(
      faultInjector: (context) {
        if (context.checkpoint ==
                AuthoringTransactionCheckpoint.afterResourcePromoted &&
            context.promotionIndex == 0) {
          throw StateError('storage failed');
        }
      },
    );
    addTearDown(harness.dispose);
    Object? failure;
    try {
      await harness.apply();
    } on Object catch (error) {
      failure = error;
    }
    expect(failure, isA<JournaledAuthoringTransactionException>());
    final response = jsonDecode(
        await JsonlWorker(api: _ThrowingReadApi(failure!)).processLine(
            jsonEncode(
                {'id': 'partial', 'command': 'describe', 'args': {}}))) as Map;
    final details = (response['error'] as Map)['details'] as Map;
    expect(details['domainCode'], 'transaction.recovery_required');
    expect(details['committed'], false);
    expect(details['finalized'], false);
    expect(details['recoverable'], isNull);
    expect(details['recoveryRequired'], true);
    expect(await harness.readA(), TransactionTestHarness.afterA);
    expect(await harness.readB(), TransactionTestHarness.beforeB);
  });
}

final class _FailOnceHook implements AuthoringTransactionCommitHook {
  var failed = false;
  final recorded = <String>[];

  @override
  Future<void> record(AuthoringCommittedMutation mutation) async {
    if (!failed) {
      failed = true;
      throw StateError('/Users/private/private-secret');
    }
    recorded.add(mutation.receipt.receiptId);
  }
}

final class _ThrowingReadApi implements AuthoringReadApiPort {
  _ThrowingReadApi(this.error);

  final Object error;

  @override
  Map<String, Object?> describe() => throw error;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
