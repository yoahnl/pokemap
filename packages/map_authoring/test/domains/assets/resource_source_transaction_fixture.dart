import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_local.dart'
    show ResourceSourceActions;

import 'resource_source_fixture.dart';

final class ResourceSourceTransactionFixture {
  ResourceSourceTransactionFixture(
      this.root,
      this.source,
      this.store,
      this.plan,
      this.plans,
      this.gateway,
      this.ledger,
      this.transaction,
      this.now);

  final Directory root;
  final ResourceSourceFixture source;
  final MemoryArtifactStore store;
  final AuthoringPlan plan;
  final AuthoringPlanStore plans;
  final LocalTransactionFileGateway gateway;
  final AuthoringIdempotencyLedger ledger;
  final JournaledAuthoringTransaction transaction;
  final DateTime now;

  static Future<ResourceSourceTransactionFixture> create(
      {bool addressed = false,
      bool shared = false,
      bool remove = false,
      AuthoringTransactionFaultInjector? faultInjector}) async {
    final root = await Directory.systemTemp.createTemp('uwu4-source-');
    final source = ResourceSourceFixture(addressed: addressed, shared: shared);
    final snapshot = source.snapshot();
    for (final entry in snapshot.resourceStorageKeys.entries) {
      final file = File('${root.path}/${entry.value}');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(snapshot.resourceBytes(entry.key));
    }
    final file = File('${root.path}/${source.path}');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(source.oldBytes);
    if (shared) {
      await File('${root.path}/assets/other.png').writeAsBytes(source.oldBytes);
    }
    final store = MemoryArtifactStore(maximumArtifactBytes: 1024 * 1024);
    final staged = await store.put(sourcePng(red: 255));
    final now = DateTime.utc(2026, 10, 2, 12);
    final plans = AuthoringPlanStore(clock: () => now);
    final request = AuthoringRequest(
        requestId: 'request',
        actionId: remove ? 'tileset.remove' : 'tileset.source.replace',
        actionVersion: 1,
        workspaceHandle: 'workspace',
        expectedRevision: snapshot.revision,
        idempotencyKey: 'key',
        parameters: {
          'tilesetId': 'sheet',
          if (remove)
            'removeSource': true
          else
            'artifactHandle': staged.reference.handle
        });
    final plan = await AuthoringActionPlanner(store: plans).plan(
        request: request,
        snapshot: snapshot,
        build: ResourceSourceActions(artifactStore: store).build);
    final gateway =
        await LocalTransactionFileGateway.open(projectRoot: root.path);
    final ledger = AuthoringIdempotencyLedger(
        store: FileIdempotencyStore(
            filePath: '${root.path}/.pokemap/authoring/idempotency.jsonl'),
        clock: () => now);
    final transaction = JournaledAuthoringTransaction(
        plans: plans,
        gateway: gateway,
        idempotency: ledger,
        clock: () => now,
        faultInjector: faultInjector);
    return ResourceSourceTransactionFixture(
        root, source, store, plan, plans, gateway, ledger, transaction, now);
  }

  Future<AuthoringReceipt> apply() => transaction.apply(
      planId: plan.planId,
      request: plan.request,
      currentProjectRevision: plan.baseRevision,
      scope: AuthoringIdempotencyScope(
          actorId: 'test',
          projectId: 'project',
          actionId: plan.request.actionId,
          actionVersion: 1,
          key: 'key'),
      operationId: 'source-operation');

  Future<AuthoringRecoveryService> recovery() async => AuthoringRecoveryService(
      gateway: await LocalTransactionFileGateway.open(projectRoot: root.path),
      idempotency: AuthoringIdempotencyLedger(
          store: FileIdempotencyStore(
              filePath: '${root.path}/.pokemap/authoring/idempotency.jsonl'),
          clock: () => now),
      clock: () => now);

  Future<void> dispose() => root.delete(recursive: true);
}
