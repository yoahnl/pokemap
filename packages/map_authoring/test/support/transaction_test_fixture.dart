import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

final class TransactionTestHarness {
  TransactionTestHarness._({
    required this.projectDirectory,
    required this.planStore,
    required this.plan,
    required this.scope,
    required this.gateway,
    required this.ledger,
    required this.transaction,
    required this.now,
  });

  static Future<TransactionTestHarness> create({
    AuthoringTransactionFaultInjector? faultInjector,
  }) async {
    final projectDirectory = await Directory.systemTemp.createTemp(
      'pokemap_transaction_',
    );
    final dataDirectory = await Directory(
      _join(projectDirectory.path, 'data'),
    ).create();
    await File(_join(dataDirectory.path, 'a.json')).writeAsBytes(beforeA);
    await File(_join(dataDirectory.path, 'b.json')).writeAsBytes(beforeB);
    await File(_join(dataDirectory.path, 'deleted.json'))
        .writeAsBytes(beforeDeleted);

    final now = DateTime.utc(2026, 7, 31, 12);
    final snapshotRevision = computeAuthoringBytesFingerprint(
      utf8.encode('transaction-test-snapshot'),
      logicalName: 'snapshot',
    );
    final snapshot = ProjectSnapshot(
      projectHandle: const ProjectHandle('prj_transaction'),
      revision: snapshotRevision,
      manifest: ProjectManifest(
        name: 'Transaction Fixture',
        maps: const [],
        tilesets: const [],
      ),
      maps: const [],
      resourceFingerprints: {'project': snapshotRevision},
    );
    final planStore = AuthoringPlanStore(clock: () => now);
    var token = 0;
    final planner = AuthoringActionPlanner(
      store: planStore,
      tokenFactory: (prefix) => '$prefix${token++}',
      seedFactory: () => 404,
    );
    final plan = await planner.plan(
      request: AuthoringRequest(
        requestId: 'req-transaction',
        actionId: 'fixture.multiWrite',
        actionVersion: 1,
        workspaceHandle: 'workspace:transaction',
        parameters: const {'fixture': true},
        expectedRevision: snapshotRevision,
        idempotencyKey: 'idem-transaction',
      ),
      snapshot: snapshot,
      build: (_) => _draft(),
    );
    final scope = AuthoringIdempotencyScope(
      actorId: 'actor-transaction',
      projectId: 'project-transaction',
      actionId: plan.request.actionId,
      actionVersion: plan.request.actionVersion,
      key: plan.request.idempotencyKey!,
    );
    final gateway = await LocalTransactionFileGateway.open(
      projectRoot: projectDirectory.path,
    );
    final ledger = _ledger(projectDirectory.path, now);
    return TransactionTestHarness._(
      projectDirectory: projectDirectory,
      planStore: planStore,
      plan: plan,
      scope: scope,
      gateway: gateway,
      ledger: ledger,
      transaction: JournaledAuthoringTransaction(
        plans: planStore,
        gateway: gateway,
        idempotency: ledger,
        clock: () => now,
        faultInjector: faultInjector,
      ),
      now: now,
    );
  }

  static final List<int> beforeA = utf8.encode('{"id":"a","value":0}');
  static final List<int> afterA = utf8.encode('{"id":"a","value":1}');
  static final List<int> beforeB = utf8.encode('{"id":"b","value":0}');
  static final List<int> afterB = utf8.encode('{"id":"b","value":1}');
  static final List<int> afterCreated = utf8.encode('{"id":"created"}');
  static final List<int> beforeDeleted = utf8.encode('{"id":"deleted"}');

  final Directory projectDirectory;
  final AuthoringPlanStore planStore;
  final AuthoringPlan plan;
  final AuthoringIdempotencyScope scope;
  final LocalTransactionFileGateway gateway;
  final AuthoringIdempotencyLedger ledger;
  final JournaledAuthoringTransaction transaction;
  final DateTime now;

  String get operationId => 'operation-transaction';
  String get currentProjectRevision => plan.baseRevision;
  String get ledgerPath => _join(
        projectDirectory.path,
        '.pokemap',
        'authoring',
        'idempotency.jsonl',
      );

  Future<AuthoringReceipt> apply() {
    return transaction.apply(
      planId: plan.planId,
      request: plan.request,
      currentProjectRevision: currentProjectRevision,
      scope: scope,
      operationId: operationId,
    );
  }

  Future<List<int>?> readA() => gateway.readResource('data/a.json');
  Future<List<int>?> readB() => gateway.readResource('data/b.json');
  Future<List<int>?> readCreated() => gateway.readResource('data/created.json');
  Future<List<int>?> readDeleted() => gateway.readResource('data/deleted.json');

  Future<void> writeExternalA(List<int> bytes) =>
      File(_join(projectDirectory.path, 'data', 'a.json')).writeAsBytes(bytes);

  Future<void> writeExternalB(List<int> bytes) =>
      File(_join(projectDirectory.path, 'data', 'b.json')).writeAsBytes(bytes);

  Future<AuthoringTransactionJournal?> readJournal() =>
      gateway.readJournal(operationId);

  Future<AuthoringRecoveryService> reopenRecovery({
    void Function()? mutationGuard,
  }) async {
    final reopenedGateway = await LocalTransactionFileGateway.open(
      projectRoot: projectDirectory.path,
    );
    return AuthoringRecoveryService(
      gateway: reopenedGateway,
      idempotency: _ledger(projectDirectory.path, now),
      clock: () => now,
      mutationGuard: mutationGuard,
    );
  }

  Future<void> dispose() => projectDirectory.delete(recursive: true);
}

AuthoringIdempotencyLedger _ledger(String projectPath, DateTime now) {
  return AuthoringIdempotencyLedger(
    store: FileIdempotencyStore(
      filePath: _join(
        projectPath,
        '.pokemap',
        'authoring',
        'idempotency.jsonl',
      ),
    ),
    clock: () => now,
  );
}

AuthoringMutationDraft _draft() {
  final resourceA = AuthoringResourceRef(kind: 'fixture', id: 'a');
  final resourceB = AuthoringResourceRef(kind: 'fixture', id: 'b');
  final changeA = AuthoringResourceChange(
    resource: resourceA,
    storageKey: 'data/a.json',
    beforeBytes: TransactionTestHarness.beforeA,
    afterBytes: TransactionTestHarness.afterA,
  );
  final changeB = AuthoringResourceChange(
    resource: resourceB,
    storageKey: 'data/b.json',
    beforeBytes: TransactionTestHarness.beforeB,
    afterBytes: TransactionTestHarness.afterB,
  );
  final createdResource = AuthoringResourceRef(kind: 'fixture', id: 'created');
  final deletedResource = AuthoringResourceRef(kind: 'fixture', id: 'deleted');
  final create = AuthoringResourceChange(
    resource: createdResource,
    storageKey: 'data/created.json',
    beforeBytes: null,
    afterBytes: TransactionTestHarness.afterCreated,
  );
  final delete = AuthoringResourceChange(
    resource: deletedResource,
    storageKey: 'data/deleted.json',
    beforeBytes: TransactionTestHarness.beforeDeleted,
    afterBytes: null,
  );
  return AuthoringMutationDraft(
    changeSet: AuthoringChangeSet(
      changes: [delete, changeB, create, changeA],
      diff: AuthoringDiff([
        AuthoringDiffEntry(
          operation: AuthoringDiffOperation.replace,
          resource: resourceB,
          path: r'$.value',
          before: 0,
          after: 1,
        ),
        AuthoringDiffEntry(
          operation: AuthoringDiffOperation.replace,
          resource: resourceA,
          path: r'$.value',
          before: 0,
          after: 1,
        ),
        AuthoringDiffEntry(
          operation: AuthoringDiffOperation.add,
          resource: createdResource,
          path: r'$',
          after: const {'id': 'created'},
        ),
        AuthoringDiffEntry(
          operation: AuthoringDiffOperation.remove,
          resource: deletedResource,
          path: r'$',
          before: const {'id': 'deleted'},
        ),
      ]),
    ),
  );
}

String _join(
  String first,
  String second, [
  String? third,
  String? fourth,
]) =>
    [
      first,
      second,
      if (third != null) third,
      if (fourth != null) fourth,
    ].join(Platform.pathSeparator);
